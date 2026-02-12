# AI Cost Tracker

A macOS menu bar app that tracks your AI usage costs. Currently supports **GitHub Copilot** (personal billing).

## What it does

Shows a mini progress bar in your menu bar representing your monthly GitHub Copilot premium request usage. When you exceed your included allowance, it displays the billed amount.

Click the menu bar item to see:
- Included requests consumed (e.g., "150 / 300")
- Month-to-date billed amount
- Time until monthly reset (00:00 UTC on the 1st)
- Last updated timestamp

## Requirements

- macOS 13+
- Swift 5.9+
- GitHub personal access token with **User: Plan (read)** permission

## Building

```bash
./scripts/build_app.sh
```

This compiles the project, assembles `build/AICostTracker.app`, and ad-hoc code-signs it. The signature is required for persistent Keychain access (so you aren't prompted for your password on every refresh).

## Running

```bash
# Install to Applications
cp -r build/AICostTracker.app /Applications/

# Launch
open /Applications/AICostTracker.app
```

Or run directly from the build directory:

```bash
open build/AICostTracker.app
```

## Setup

1. Generate a fine-grained GitHub PAT with **User permissions: "Plan" (read)**
2. Open the app and enter your GitHub username and PAT in Settings
3. Adjust your included allowance if needed (default: 300 requests)

## Notes

- Only supports GitHub Copilot personal billing currently
- Future providers (OpenAI, Anthropic) planned
- App runs as a menu bar-only app (no dock icon)
