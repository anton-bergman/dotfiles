# Secure Static Storage Vault

This hidden directory is a private, secure vault for storing offline backups, recovery codes, local SSH configurations, and other sensitive machine-specific keys.

## Security & Git Integration

To guarantee that no sensitive keys or raw recovery codes ever leak to Git, this directory is governed by a **strict whitelist pattern** in the root `.gitignore`.

- **Tracked by Git:** Only `.gitkeep` directories, this `README.md`, and any files ending in `.example` (templates) are tracked.
- **Ignored by Git:** All other files—such as raw text files, private keys, or actual configuration scripts—are strictly and automatically ignored.

## Vault Structure

- `github/` ➜ For GitHub 2FA recovery codes (e.g., `.secrets/github/recovery-codes.txt`).
- `ssh/` ➜ For machine-specific, local-only SSH configurations (e.g., `.secrets/ssh/config`).

## Setup on a New Machine

1.  Copy any `.example` file to its real counterpart name (without the `.example` extension).
2.  Populate it with your actual keys or codes.
    - _Example:_ Copy `github/recovery-codes.txt.example` to `github/recovery-codes.txt` and populate your GitHub keys.
