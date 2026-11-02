# macOS Apps

This file lists my essential macOS applications with quick install commands for setting up a new Mac.

## Contents

- [Batch Installation](#batch-installation)
- [System Tools](#system-tools)
- [Development](#development)
- [Media](#media)

---

## Batch Installation

Standalone macOS desktop applications (without dedicated configuration scripts) are defined in `macos/apps.manifest`.

Install all standalone desktop apps in one command:

```bash
./macos/install_apps.sh
```

Inspect installation status without installing:

```bash
./macos/install_apps.sh --list
```

Exclude specific applications (comma-separated or multiple flags):

```bash
./macos/install_apps.sh --exclude spotify,google-chrome
```

Install only targeted applications:

```bash
./macos/install_apps.sh --only raycast
```

---

## System Tools

- **Homebrew** - Package manager for macOS
  _(Install from official instructions — see Homebrew website)_
- **AeroSpace** - Tiling window manager for macOS  
  `brew install --cask nikitabobko/tap/aerospace`
- **Karabiner-Elements** - Keyboard customizer for dual-role Caps Lock navigation  
  `brew install --cask karabiner-elements`
- **JankyBorders** - Add borders to windows for easier visual focus  
  `brew install --cask jankyborders`
- **Raycast** - Productivity launcher and command palette for macOS  
  `brew install --cask raycast`

---

## Development

- **Neovim** - Text editor _(See `dotfiles/README.md` for installation & setup)_
- **VS Code** - IDE _(See `dotfiles/vscode/vscode-extensions.md` for extensions list & `dotfiles/README.md` for installation)_

---

## Media

- **Google Chrome** - Web browser
  `brew install --cask google-chrome`
- **Spotify** – Music streaming  
  `brew install --cask spotify`
