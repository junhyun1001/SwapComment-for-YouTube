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
  <a href="https://github.com/junhyun1001/SwapComment-for-YouTube/releases"><img src="https://img.shields.io/badge/release-v1.0.1-red?style=flat-square" alt="Release" /></a>
  <a href="https://github.com/junhyun1001/SwapComment-for-YouTube/actions/workflows/codeql.yml"><img src="https://img.shields.io/github/actions/workflow/status/junhyun1001/SwapComment-for-YouTube/codeql.yml?branch=main&label=CodeQL&style=flat-square&logo=github" alt="CodeQL Status" /></a>
  <a href="#security--privacy"><img src="https://img.shields.io/badge/privacy-Zero--Telemetry-brightgreen?style=flat-square&logo=shield" alt="Privacy" /></a>
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

> **Note on macOS Gatekeeper**: Because the app is signed with an ad-hoc certificate, macOS may show an *"unidentified developer"* or *"cannot verify"* dialog on first launch. You can allow it via:
> - **System Settings**: Go to **System Settings ➔ Privacy & Security ➔ Security**, and click **"Open Anyway"** next to the SwapComment notice.
> - **Or via Terminal**:
>   ```bash
>   sudo xattr -rd com.apple.quarantine "/Applications/SwapComment for YouTube.app"
>   ```

> **Note on Google Sign-in (Passkeys)**: If Google prompts you with a Passkey / Bluetooth verification screen during sign-in, click **"Try another way"** at the bottom and select **Password + 2-Step Verification** (e.g., Authenticator, SMS, or phone prompt). Embedded web views (`WKWebView`) cannot access system Bluetooth for cross-device passkeys due to macOS sandboxing. Once signed in, your session is saved persistently in macOS's native data store and will remain active across app restarts.

### Option 1: Homebrew Cask (Recommended)

The easiest way to install and stay updated:

```bash
# 1. Tap the repository & trust third-party cask
brew tap junhyun1001/tap
brew trust junhyun1001/tap

# 2. Install the application
brew install --cask swapcomment-for-youtube
```

---

### Option 2: Direct Download

1. Download the latest `SwapComment-for-YouTube.zip` from the **[Releases](https://github.com/junhyun1001/SwapComment-for-YouTube/releases)** page.
2. Unzip the file and move `SwapComment for YouTube.app` into your `/Applications` folder.
3. Open the app and enjoy!

---

### Option 3: Build from Source

Requirements: macOS 13+ with Xcode Command Line Tools installed (`xcode-select --install`).

```bash
# 1. Clone the repository
git clone https://github.com/junhyun1001/SwapComment-for-YouTube.git
cd SwapComment-for-YouTube

# 2. Build the application (Compiles Universal Binary for Apple Silicon & Intel)
chmod +x build.sh
./build.sh

# 3. Install to /Applications (or run directly from build/)
cp -R "build/SwapComment for YouTube.app" /Applications/
open "/Applications/SwapComment for YouTube.app"
```

---

## Usage

Once installed, you can launch **SwapComment for YouTube** via:

* **Spotlight**: Press <kbd>Cmd</kbd> + <kbd>Space</kbd>, type `SwapComment for YouTube`, and press <kbd>Enter</kbd>.
* **Launchpad**: Click the **SwapComment for YouTube** icon.
* **Terminal**:
  ```bash
  open -a "SwapComment for YouTube"
  ```

---

## Uninstallation

### Option 1: If installed via Homebrew Cask

```bash
# Standard uninstall (removes the application)
brew uninstall --cask swapcomment-for-youtube

# Complete uninstall (removes application, saved login sessions, cookies, and cache)
brew uninstall --zap --cask swapcomment-for-youtube
```

### Option 2: If installed manually (Direct Download or Build from Source)

```bash
# 1. Quit the application if running
pkill -x "SwapComment for YouTube" || true

# 2. Remove the app from Applications
rm -rf "/Applications/SwapComment for YouTube.app"

# 3. (If built from source) Remove the local build directory to clear Spotlight index
rm -rf build/

# 4. (Optional) Remove persistent session data, cookies, and cache
rm -rf ~/Library/WebKit/com.junhyun.SwapCommentForYouTube
rm -rf "~/Library/Saved Application State/com.junhyun.SwapCommentForYouTube.savedState"
```

---

## Tech Stack

* **Language**: Swift
* **Frameworks**: Cocoa (AppKit), WebKit (`WKWebView`)
* **Injection**: Vanilla JavaScript (`MutationObserver`) & Custom CSS Grid Layout
* **Build System**: Bash script compiling Universal Binary via `swiftc` and `lipo`

---

## Security & Privacy

We take user privacy and system security seriously. Because **SwapComment for YouTube** is distributed outside the Mac App Store as free and open-source software, we guarantee safety through total transparency:

* 🔒 **Zero Telemetry & Analytics**: SwapComment does not collect, log, track, or transmit any user data, watching history, or keystrokes. Everything runs strictly inside macOS's native `WKWebView`.
* 🔑 **Direct Google Authentication**: All logins are processed directly through Google's official OAuth servers inside Apple WebKit. Your credentials are never intercepted, stored, or accessed by our app.
* 🔎 **100% Open Source & Auditable**: The entire codebase is concise (~400 lines of Swift in [`Sources/main.swift`](Sources/main.swift)). Anyone can freely inspect, build, and verify the application from source.
* 🤖 **Verified CI/CD Cloud Builds**: Releases are automatically compiled in clean macOS virtual machines by **GitHub Actions** directly from the public source code, preventing any local tampering.
* 🛡️ **Cryptographic Checksums**: Every release artifact includes cryptographic `SHA256` checksums so you can independently verify that your download has not been modified.

---

## License

This project is licensed under the [MIT License](LICENSE).
