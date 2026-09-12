#!/usr/bin/env python3
"""
BigQuery Local Schema Synchronizer

This script queries Google Cloud BigQuery INFORMATION_SCHEMA views for a
specified list of datasets and exports their table/column mappings to a
local JSON file.

This JSON file is consumed by Neovim's autocompletion engine (`nvim-cmp`) to
provide sub-millisecond, offline-capable SQL column and table auto-suggestions
with zero network latency.

Configuration:
    - Target GCP Project: Resolved from BIGQUERY_PROJECT env var, active gcloud
      auth context, or `gcloud config get-value project`.
    - Datasets to synchronize: Passed via CLI arguments (e.g. `sync_bq_schema.py dataset1 dataset2`)
      or defined as comma-separated values in BIGQUERY_DATASETS env var.

Dependencies:
    - google-cloud-bigquery

Usage:
    python3 sync_bq_schema.py [dataset1 dataset2 ...]
"""

import json
import os
import subprocess
import sys
from typing import List, Optional

import google.auth.exceptions
from google.cloud import bigquery

# Output location for Neovim's auto-suggestions
OUTPUT_FILE = os.path.expanduser("~/.cache/nvim/bq_schema.json")


def resolve_active_project() -> Optional[str]:
    """
    Dynamically resolve the active GCP project name.
    Order of precedence:
      1. BIGQUERY_PROJECT environment variable
      2. google.auth.default() credentials
      3. gcloud CLI active config
    """
    env_project = os.environ.get("BIGQUERY_PROJECT")
    if env_project:
        return env_project.strip()

    try:
        _, project = google.auth.default()
        if project:
            return project
    except Exception:
        pass

    try:
        result = subprocess.run(
            ["gcloud", "config", "get-value", "project"],
            capture_output=True,
            text=True,
            check=True,
        )
        project = result.stdout.strip()
        if project:
            return project
    except Exception:
        pass

    return None


def resolve_target_datasets() -> List[str]:
    """
    Resolve datasets to synchronize from command line arguments or environment variable.
    """
    # 1. CLI positional arguments (filtering out flags)
    cli_datasets = [arg.strip() for arg in sys.argv[1:] if not arg.startswith("-")]
    if cli_datasets:
        return cli_datasets

    # 2. Environment variable (comma or space separated)
    env_datasets = os.environ.get("BIGQUERY_DATASETS", "")
    if env_datasets:
        return [d.strip() for d in env_datasets.replace(",", " ").split() if d.strip()]

    return []


def sync_schema():
    project_id = resolve_active_project()
    if not project_id:
        print("\033[1;31m[ERROR] Could not resolve a BigQuery project ID.\033[0m")
        print("Please configure your GCP project using one of:")
        print(
            '  1. export BIGQUERY_PROJECT="your-gcp-project" (e.g. in ~/.zshrc.local)'
        )
        print("  2. gcloud config set project your-gcp-project")
        sys.exit(1)

    datasets = resolve_target_datasets()
    if not datasets:
        print("\033[1;31m[ERROR] No BigQuery datasets specified to synchronize.\033[0m")
        print("Please specify one or more datasets using:")
        print("  1. Arguments: sync-bq-schema <dataset1> [dataset2 ...]")
        print(
            '  2. export BIGQUERY_DATASETS="dataset1,dataset2" (e.g. in ~/.zshrc.local)'
        )
        sys.exit(1)

    print(
        f"==> Initializing BigQuery schema sync for project: \033[1;34m{project_id}\033[0m"
    )

    try:
        client = bigquery.Client(project=project_id)
    except google.auth.exceptions.DefaultCredentialsError:
        print("\n\033[1;31m[ERROR] GCP Authentication Error:\033[0m")
        print("Could not find Application Default Credentials (ADC).")
        print("Please authenticate your local environment by running:")
        print("\n    \033[1;32mgcloud auth application-default login\033[0m\n")
        sys.exit(1)
    except Exception as e:
        print(f"\n\033[1;31m[ERROR] Connection Initialization Failed:\033[0m {e}")
        sys.exit(1)

    schema_map = {}

    for dataset_id in datasets:
        print(
            f"  -> Fetching schema metadata for dataset: \033[1;33m{dataset_id}\033[0m..."
        )

        # Query to list all columns of all tables/views within the dataset
        query = f"""
            SELECT table_name, column_name 
            FROM `{project_id}.{dataset_id}.INFORMATION_SCHEMA.COLUMNS`
            ORDER BY table_name, ordinal_position
        """

        try:
            query_job = client.query(query)
            results = query_job.result()

            count = 0
            for row in results:
                table = row["table_name"]
                column = row["column_name"]

                # We register dual-entries for maximum Lua lookups speed:
                # 1. Short name (e.g., "my_table")
                # 2. Qualified name (e.g., "my_dataset.my_table")
                short_key = table
                qualified_key = f"{dataset_id}.{table}"

                for key in (short_key, qualified_key):
                    if key not in schema_map:
                        schema_map[key] = []
                    # Avoid duplicates if tables share short names across datasets (though qualified will be unique)
                    if column not in schema_map[key]:
                        schema_map[key].append(column)

                count += 1

            print(
                f"   [OK] Retrieved {count} columns across tables/views in \033[1;32m{dataset_id}\033[0m."
            )

        except Exception as e:
            print(
                f"   \033[1;31m[WARN] Error fetching dataset {dataset_id}:\033[0m {e}"
            )
            print(
                "   Make sure the dataset exists in this project and your user has access."
            )

    if not schema_map:
        print(
            "\n\033[1;31m[ERROR] Sync aborted:\033[0m No schema data retrieved from BigQuery."
        )
        sys.exit(1)

    # Ensure Neovim's config directory exists
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    try:
        with open(OUTPUT_FILE, "w") as f:
            json.dump(schema_map, f, indent=2)
        print(
            f"\n\033[1;32m==> [SUCCESS] Schema sync complete!\033[0m Saved to: \033[1;36m{OUTPUT_FILE}\033[0m"
        )
    except Exception as e:
        print(f"\n\033[1;31m[ERROR] Failed to write local cache file:\033[0m {e}")
        sys.exit(1)


if __name__ == "__main__":
    sync_schema()
