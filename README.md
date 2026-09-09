# SwapComment for YouTube

<p align="center">
  <img src="Resources/AppIcon.icns" width="128" height="128" alt="SwapComment App Icon" />
</p>

<p align="center">
  <strong>A lightweight, native macOS client that brings YouTube comments to the sidebar so you can read and watch simultaneously.</strong>
</p>

<p align="center">
  <a href="https://github.com/junhyun1001/SwapComment-for-YouTube/releases"><img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue?style=flat-square&logo=apple" alt="macOS" /></a>
  <a href="https://github.com/junhyun1001/SwapComment-for-YouTube/releases"><img src="https://img.shields.io/badge/architecture-Universal%20(Apple%20Silicon%20%2B%20Intel)-orange?style=flat-square" alt="Universal Binary" /></a>
  <a href="https://github.com/junhyun1001/SwapComment-for-YouTube/releases"><img src="https://img.shields.io/badge/release-v1.0.0-red?style=flat-square" alt="Release" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License" /></a>
</p>

---

## Overview

**SwapComment for YouTube** is a minimalist, battery-efficient macOS desktop application built with Swift and native WebKit. 

Unlike the default YouTube desktop experience that forces you to scroll past the video to read discussions, **SwapComment** automatically rearranges the layout:
* **Comments** are pinned to a dedicated, independently scrollable **sidebar on the right**.
* **Recommended videos** move under the player and adapt into a **responsive, multi-column grid**.

<p align="center">
  <img src="https://raw.githubusercontent.com/junhyun1001/SwapComment-for-YouTube/main/docs/demo.png" alt="SwapComment Demo Screenshot" width="850" />
</p>

---

## Features

* **Sticky Sidebar Comments**  
  Browse, read, and write comments on the right sidebar without pausing or scrolling away from the video.

* **Responsive Recommendation Grid**  
  Related videos are relocated beneath the video player and adapt into a clean, multi-column grid that scales with your window size.

* **100% Pure YouTube Experience**  
  Sign in, subscriptions, playlists, history, picture-in-picture, and all original YouTube features work seamlessly without third-party interface modifications.

* **Lightweight Native Performance**  
  Zero Electron bloat. Powered by macOS's native `WKWebView` for near-zero memory footprint and exceptional battery efficiency.

* **Universal Binary**  
  Compiled natively for both Apple Silicon (M1/M2/M3/M4) and Intel-based Mac systems.

---

## Installation

### Option 1: Direct Download (Recommended)

1. Download the latest `SwapComment-for-YouTube.zip` (or `.dmg`) from the **[Releases](https://github.com/junhyun1001/SwapComment-for-YouTube/releases)** page.
2. Unzip the file and drag `SwapComment for YouTube.app` into your `/Applications` folder.
3. Open the app and enjoy!

> **Note on macOS Gatekeeper**: Because the app is signed with an ad-hoc certificate, macOS may show an *"unidentified developer"* notice on first launch. Right-click `SwapComment for YouTube.app` and select **Open**, or run this command in Terminal:
> ```bash
> xattr -cr "/Applications/SwapComment for YouTube.app"
> ```

> **Note on Google Sign-in (Passkeys)**: If Google prompts you with a Passkey / Bluetooth verification screen during sign-in, click **"Try another way"** at the bottom and select **Password + 2-Step Verification** (e.g., Authenticator, SMS, or phone prompt). Embedded web views (`WKWebView`) cannot access system Bluetooth for cross-device passkeys due to macOS sandboxing. Once signed in, your session is saved persistently in macOS's native data store and will remain active across app restarts.

---

### Option 2: Homebrew Cask

If you prefer managing apps via Homebrew:

```bash
brew tap junhyun1001/tap
brew install --cask swapcomment-for-youtube
```

---

### Option 3: Build from Source

Requirements: macOS 13+ with Xcode Command Line Tools installed (`xcode-select --install`).

```bash
# 1. Clone the repository
git clone https://github.com/junhyun1001/SwapComment-for-YouTube.git
cd SwapComment-for-YouTube

# 2. Build the application (Generates Universal Binary)
chmod +x build.sh
./build.sh

# 3. Launch the app
open "build/SwapComment for YouTube.app"
```

---

## Tech Stack

* **Language**: Swift
* **Frameworks**: Cocoa (AppKit), WebKit (`WKWebView`)
* **Injection**: Vanilla JavaScript (`MutationObserver`) & Custom CSS Grid Layout
* **Build System**: Bash script compiling Universal Binary via `swiftc` and `lipo`

---

## License

This project is licensed under the [MIT License](LICENSE).
