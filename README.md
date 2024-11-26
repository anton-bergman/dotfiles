# .dotfiles

This repository contains the dotfiles for configuring my development environment, including terminal settings, plugins, and other personal customizations.

## Installation and Setup

### Prerequisites

1. **Homebrew:** Ensure Homebrew is installed. You can install it via:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. **iTerm2:** Install your terminal of choice. I prefer iTerm2 (recommended for macOS), install it using Homebrew:

```bash
brew install --cask iterm2
```

### Install .dotfiles

To set up your development environment, run the following installation script. This will install required software, clone necessary plugins, and set up your dotfiles.

1. Clone this repository:

```bash
git clone https://github.com/anton-bergman/.dotfiles.git ~/.dotfiles
```

2. Run the `install.sh` script to set up your environment:

```bash
cd ~/.dotfiles && ./install.sh
```

The script `install.sh` will:

- Install **Oh-My-Posh**.
- Install the **Hack Nerd Font**.
- Clone zsh plugins.
- Set up symbolic links for the dotfiles.

### Managing zsh Plugins

This **.dotfiles** repository includes custom plugins for zsh. To install or update the plugins, you can run the `install.sh` and `update.sh` scripts:

- **To install the plugins for the first time:** Run `install.sh` as mentioned above. This will clone the plugins: `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `zsh-completions` and set them up.

- **To update existing plugins:** Run the `update.sh` script to pull the latest changes from the plugin repositories:

```bash
cd ~/.dotfiles && ./update.sh
```

### Configure iTerm2.

1. **Create a Custom Profile:**

   - Open iTerm2 and go to `Settings` > `Profiles`.
   - Click the "+" button to create a new profile and name it **Custom theme**.
   - Select the newly created profile, click on `Other Actions`, and choose `Set as Default` to make it the default profile.

2. **Disable Dimming on Inactive Split Panes:**

   - Navigate to `Settings` > `Appearance` > `Dimming`.
   - Uncheck the option `Dim inactive split panes`.

3. **Select a Color Theme:**

   - Navigate to `Settings` > `Profiles` > `Colors` tab.
   - Select `Color Presets`, choose `Import` and select your preferred color theme from `~/.dotfiles/iterm2-color-themes`.

4. **Select Font:**

   - Navigate to `Settings` > `Profiles` > `Text` tab.
   - In the **Font**-dropdown menu select `Hack Nerd Font Mono`.

5. **Configure Key Mappings:**

   - Go to `Settings` > `Profiles` > `Keys` tab > `Key Mappings`.
   - Select `Presets` and chose the option `Natural Text Editing`.

### Customize Terminal Color Theme and Prompt Theme

This repository includes a collection of custom color themes for iTerm2 and prompt themes for Oh-My-Posh.

- **Oh-My-Posh Prompt Theme:** Create or customize your own Oh-My-Posh prompt theme by modifying or adding YAML configuration files located under `.dotfiles/oh-my-posh`. These themes can be easily switched by changing the theme path in the configuration file `.dotfiles/zshrc`.

- **iTerm2 Color Theme:** To customize the color theme of your iTerm2 terminal you have two main options.

  - **Download a Theme:** Download a iTerm2 color theme from [iTerm2 Color Schemes](https://iterm2colorschemes.com/).

  - **Create your own theme / Customize an existing theme:** To create your own theme or customize an existing theme, navigate to `Settings` > `Profiles` > `Colors`. From there, you can tweak the colors to your liking. Once you have customized a theme, save it under `.dotfiles/iterm2-color-themes` by selecting `Color Presets` > `Export`.
