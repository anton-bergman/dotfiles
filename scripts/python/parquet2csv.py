#!/usr/bin/env python3

import argparse
import sys
from pathlib import Path

import pyarrow.parquet as pq


def convert() -> None:
    parser = argparse.ArgumentParser(
        description="Convert Parquet to CSV in chunks with an optional row limit."
    )
    parser.add_argument("input", type=Path, help="Input Parquet file")
    parser.add_argument(
        "output", type=Path, nargs="?", help="Output CSV file (optional)"
    )
    parser.add_argument(
        "-n", "--limit", type=int, help="Maximum number of rows to convert"
    )
    parser.add_argument(
        "-c",
        "--chunk-size",
        type=int,
        default=10000,
        help="Number of rows to process per chunk (default: 10000)",
    )

    args = parser.parse_args()
    input_path = args.input
    output_path = args.output or input_path.with_suffix(".csv")

    if not input_path.exists():
        print(f"Error: File {input_path} not found.", file=sys.stderr)
        sys.exit(1)

    try:
        rows_written = 0
        total_cols = 0

        with pq.ParquetFile(input_path) as pf:
            total_cols = pf.metadata.num_columns

            for batch in pf.iter_batches(batch_size=args.chunk_size):
                df = batch.to_pandas()

                # Handle row limit
                if args.limit is not None and rows_written + len(df) > args.limit:
                    df = df.head(args.limit - rows_written)

                if df.empty:
                    break

                # Write to CSV: overwrite on first chunk, append thereafter
                mode = "w" if rows_written == 0 else "a"
                header = rows_written == 0
                df.to_csv(output_path, mode=mode, index=False, header=header)

                rows_written += len(df)

                # Stop if limit reached
                if args.limit is not None and rows_written >= args.limit:
                    break

        if rows_written > 0:
            print(
                f"✓ {input_path.name} ➜ {output_path.name} [{rows_written} rows, {total_cols} cols]"
            )
        else:
            print(f"⚠ {input_path.name} resulted in an empty CSV.", file=sys.stderr)

    except Exception as e:
        print(f"Conversion Failed: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    convert()
