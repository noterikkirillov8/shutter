# Shutter

Hide menu bar icons behind one click. No permissions needed.

<p align="center"><img src="https://img.shields.io/badge/macOS-15%2B-D8DDE6?style=flat-square&labelColor=1B1C1F" alt="macOS 15+"> <img src="https://img.shields.io/badge/Swift-6-D8DDE6?style=flat-square&labelColor=1B1C1F" alt="Swift 6"> <img src="https://img.shields.io/badge/licence-MIT-D8DDE6?style=flat-square&labelColor=1B1C1F" alt="licence MIT"> <img src="https://img.shields.io/badge/telemetry-none-D8DDE6?style=flat-square&labelColor=1B1C1F" alt="telemetry none"></p>

## How to use
1. Icons left of the thin divider line are the ones Shutter hides. At first that is all of them, so **⌘-drag** the ones you always want (battery, Wi-Fi) to the right of the line.
2. **Click Shutter** (the three slats) to hide or show them. Right-click, or Option-click, for the menu.
3. Or just **hover over Shutter** for a moment: the icons appear, and hide again when you leave the menu bar (Settings turns this off).
4. They **hide again** a few seconds after you show them (8 s by default, 0 turns it off). The timer only runs while icons are shown.

## How it works
Shutter adds two menu bar items: its icon and a divider. Hiding makes the divider very wide, so macOS pushes everything left of it off the screen; showing sets it back. Nothing is moved or read from other apps, so there are no Accessibility or Screen Recording prompts. On Macs with a notch this also clears icons that would sit behind it. If the divider sits to the right of the Shutter icon, Shutter won't hide anything: it shows a small hint (no blocking dialog) asking you to ⌘-drag the divider to its left. Quitting Shutter always restores the divider.

Hide and show with ⌃⌥⌘H (changeable). Auto-hide waits while the pointer is in the menu bar.

## Settings
- **General**: launch at login, shortcut, sounds, show the tip again.
- **Behaviour**: show on hover, hide-again seconds, hide icons when Shutter starts.

## Install
Build from source (needs Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen)):

```
scripts/test.sh                  # tests
NO_OPEN=1 scripts/install.sh      # build Release and install to /Applications
```
Shutter isn't notarised, so the first time macOS may block it: open System Settings → Privacy & Security, scroll down and click Open Anyway (on macOS 15 and later right-click → Open no longer works).

## Privacy
No network, no telemetry. Settings stay on your Mac.

## Credits
MIT licence. Interface sounds by Kenney (kenney.nl), CC0.
