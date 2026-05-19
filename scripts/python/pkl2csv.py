#!/usr/bin/env python3

import pickle
import sys
from pathlib import Path

import pandas as pd


class LegacyUnpickler(pickle.Unpickler):
    """
    A custom unpickler that intercepts legacy module imports
    and redirects them to their modern LTS (Numpy 2.x / Pandas 2.x) equivalents.
    """

    def find_class(self, module, name):
        # Handle Numpy 1.x -> Numpy 2.x core module shifts
        if module.startswith("numpy.core"):
            module = module.replace("numpy.core", "numpy._core")

        try:
            return super().find_class(module, name)
        except Exception as e:
            raise ImportError(f"Legacy mapping failed for {module}.{name}: {e}")


def robust_read_pickle(file_path: Path) -> pd.DataFrame:
    """Attempts standard pandas read, falls back to compat unpickler."""
    try:
        return pd.read_pickle(file_path)
    except (ModuleNotFoundError, ImportError, TypeError):
        with open(file_path, "rb") as f:
            data = LegacyUnpickler(f).load()

        if isinstance(data, pd.DataFrame):
            return data.convert_dtypes()
        else:
            raise ValueError("Pickled object is not a Pandas DataFrame.")


def convert():
    if len(sys.argv) < 2:
        print("Usage: pkl2csv <input.pkl> [output.csv]", file=sys.stderr)
        sys.exit(1)

    input_path = Path(sys.argv[1])
    output_path = (
        Path(sys.argv[2]) if len(sys.argv) > 2 else input_path.with_suffix(".csv")
    )

    if not input_path.exists():
        print(f"Error: File {input_path} not found.", file=sys.stderr)
        sys.exit(1)

    try:
        df = robust_read_pickle(input_path)
        df.to_csv(output_path, index=False)

        print(
            f"✓ {input_path.name} ➜ {output_path.name} [{len(df)} rows, {len(df.columns)} cols]"
        )

    except Exception as e:
        print(f"Conversion Failed: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    convert()
