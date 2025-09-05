# Raycast Setup

This document outlines the specific configurations and settings I use in Raycast.

---

## Core Settings & Hotkeys

My core Raycast settings are configured for speed and ease of use.

**Primary Hotkey:**  
I use `Cmd + Space` to launch the main Raycast window. This requires disabling the default Spotlight shortcut in macOS.

**How to disable Spotlight shortcut:**

1. Go to **System Settings** > **Keyboard** > **Keyboard Shortcuts...**
2. Select **Spotlight** in the left menu.
3. Uncheck **Show Spotlight search**.

---

## Extensions

These are the extensions I have installed to integrate my most-used tools directly into Raycast. All of these are available for free in the [Raycast Store](https://raycast.com/store).

---

### Brew

- **What it does:**  
  Allows me to search, install, and manage Homebrew packages (formulae and casks) directly from Raycast.

- **How to install:**  
  Open Raycast, go to the **Store** command, and search for **Brew**. Click **Install**.

---

### Color Picker

- **What it does:**  
  Provides a quick way to pick colors from anywhere on the screen and copy them in various formats (hex, RGB, HSL).

- **How to install:**  
  Open Raycast, go to the **Store** command, and search for **Color Picker**. Click **Install**.

---

### Kill Process

- **What it does:**  
  A simple but powerful tool to quickly find and terminate a running process.

- **How to install:**  
  This functionality is often found within the **Port Manager** extension.  
  Open Raycast, search for the **Store** command, and install **Port Manager**.  
  The **Kill Process** command will be included.

---

### Spotify Player

- **What it does:**  
  Lets me control Spotify playback, search for music, and view what's currently playing without leaving Raycast.

- **How to install:**  
  Open Raycast, go to the **Store** command, and search for **Spotify Player**. Click **Install**.  
  You will need to authenticate with your Spotify account upon first use.

---

### VS Code

- **What it does:**  
  Provides commands to quickly open recent projects, files, or specific folders in Visual Studio Code.

- **How to install:**  
  Open Raycast, go to the **Store** command, and search for **Visual Studio Code**. Click **Install**.

---

## Script Commands

I use a custom script to quickly open new windows of Terminal, iTerm, and Chrome.  
To manage these, I've configured Raycast to read from a dedicated directory in my dotfiles.

**How to set up:**

1. In Raycast, open **Settings** (`Cmd + ,`).
2. Navigate to **Extensions** and select **Script Commands** from the list.
3. Click **Add Directory** and select your `~/dotfiles/macos/raycast/` directory.

Raycast will now automatically read any scripts you place in this folder, and they will become accessible as commands.

---

## My Schedule & Calendar Sync

Raycast's **My Schedule** command is a built-in feature that automatically syncs with the default macOS Calendar app.

**How it works:**

- Raycast requires permission to access your calendars.  
  The first time you use a calendar-related command, it will prompt you to grant access.

- To ensure all your calendars are visible:
  1. Go to **System Settings** > **Privacy & Security** > **Calendars**
  2. Make sure **Raycast** is enabled.

- As long as your Mac's **Internet Accounts** are correctly configured to sync with your calendars (iCloud, Google, etc.), Raycast will display all your events.

- To use this feature, simply launch Raycast and type **My Schedule**.

---
