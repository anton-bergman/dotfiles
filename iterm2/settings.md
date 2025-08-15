# iTerm2 Settings

This document lists my personal configuration preferences for iTerm2 settings and Oh-My-Posh prompt themes.

## Contents

- [iTerm2](#iterm2)
- [Terminal Theme & Prompt](#terminal-theme--prompt)

---

## iTerm2

Navigate to `iTerm2` > `Settings` > `Profiles`

### General

- **Set custom profile as default:** Create a new profile named **Custom theme** and set it as default via `Other Actions` > `Set as Default`.
- **Automatically run Fastfetch:** In `Send text at start`, add `fastfetch` to show system info on terminal startup.

### Appearance

- **Disable dimming on inactive split panes:** Navigate to `Appearance` > `Dimming` and uncheck `Dim inactive split panes`.

### Colors

- **Select color theme:** Navigate to `Colors` tab > `Color Presets` > `Import` and select your preferred theme from `~/dotfiles/iterm2/color-themes`.

### Text

- **Select font:** In `Text` tab > Font dropdown, select `Hack Nerd Font Mono`.

### Keys

- **Configure key mappings:** Navigate to `Keys` tab > `Key Mappings` > `Presets` and select `Natural Text Editing`.

---

## Terminal Theme & Prompt

### Oh-My-Posh Prompt Theme

- **Custom themes:** Add or modify YAML configuration files under `dotfiles/zsh/oh-my-posh`.
- **Switch themes:** Update the theme path in your `dotfiles/zsh/zshrc` configuration file.

### iTerm2 Color Theme

- **Download a theme:** Get iTerm2 color themes from [iTerm2 Color Schemes](https://iterm2colorschemes.com/).
- **Create/customize a theme:** Navigate to `Settings` > `Profiles` > `Colors`, tweak colors, then export under `dotfiles/iterm2/color-themes` via `Color Presets` > `Export`.
