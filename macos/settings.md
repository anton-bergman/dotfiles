# macOS Settings

This document lists my personal macOS configuration preferences for setting up a new MacBook from scratch.

## Contents

- [Desktop & Dock](#desktop--dock)
- [Finder](#finder)
- [Control Centre](#control-centre)
- [Keyboard](#keyboard)
- [Ubersicht](#ubersicht)

---

## Desktop & Dock

Navigate to `System Settings` > `Desktop & Dock`

- **Automatically hide and show the Dock:** ON
- **Animate opening applications:** OFF
- **Show indicators for open applications:** ON
- **Show suggested and recent apps in Dock:** OFF

### Displays have separate Spaces

Navigate to `System Settings` > `Desktop & Dock` > Scroll to "Displays"

- **Displays have separate Spaces:** OFF

**Required for:** AeroSpace window manager users with multiple monitors

**Issue:** When using AeroSpace with Chromium-based browsers (Chrome, Edge, Brave, etc.) across multiple monitors, you may experience a focus conflict where:

- Switching workspaces causes focus to jump back to Chrome on another monitor
- Windows flicker between monitors
- Workspace switches fail to complete

**Root Cause:** AeroSpace uses virtual workspaces (hiding/showing windows) rather than native macOS Spaces. Chromium browsers frequently send `makeKeyAndOrderFront:` commands to maintain focus on the "most recently active" window. This creates a race condition between AeroSpace trying to show your target workspace and Chrome trying to restore focus to its last active window.

**Solution:**

1. Open **System Settings** → **Desktop & Dock**
2. Scroll down to "Displays"
3. Turn **OFF** "Displays have separate Spaces"
4. Log out and log back in (required for the change to take effect)

**Trade-offs:**

- Fixes: Chrome focus race condition completely
- Benefit: All monitors treated as single unified space
- Limitation: Menu bar only appears on primary monitor
- Limitation: Can't have different wallpapers per monitor (unified wallpaper)

**Alternative:** If you must keep separate Spaces enabled, consider using Safari or Firefox as your primary browser, as they don't exhibit this focus-stealing behavior.

## Finder

### General

Navigate to `Finder Settings` > `General`

- **Show these items on the desktop:** OFF (All)
- **New Finder windows show:** Home Directory

### Tags

Navigate to `Finder Settings` > `Tags`

- **Show these tags in the sidebar:** OFF (All)

### Sidebar

Navigate to `Finder Settings` > `Sidebar`

- **Show these items in the sidebar:** OFF — Recents, Desktop, Movies, Music, Pictures

### Advanced

Navigate to `Finder Settings` > `Advanced`

- **Show all filename extensions:** ON
- **When performing a search:** Search the Current Folder

### View

Navigate to `Finder` > `View` > `Show Path Bar`

- **Show Path Bar:** ON

## Control Centre

Navigate to `System Settings` > `Control Centre`

- **Automatically hide and show the menu bar**: NEVER
  _(Only relevant if using SketchyBar or Simple-bar for menu bar management)_

## Keyboard

Navigate to `System Settings` > `Keyboard`

- **Key repeat rate:** Fast
- **Delay until repeat:** Short

### Modifier Keys

Navigate to `System Settings` > `Keyboard` > `Keyboard Shortcuts...` > `Modifier Keys`

- **Caps Lock key:** Escape
  **Note:** You'll need to set this for each keyboard (built-in and external keyboards are configured separately).

## Ubersicht

_(Only relevant if using Simple-bar for menu bar management)_

Navigate to `Übersicht` > `Preferences`

- **Launch Übersicht when I login:** ON
