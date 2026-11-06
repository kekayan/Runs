# Runs App - Installation Guide

Complete guide to building and installing the GitHub Actions menu bar app.

---

## 🚀 Quick Install (Recommended)

### Option 1: Automated Build Script

```bash
git clone https://github.com/yourusername/runs.git
cd runs
chmod +x build_and_install.sh
./build_and_install.sh
```

This script will:
1. Clean previous builds
2. Build the app in Release mode
3. Install to /Applications
4. Verify installation

---

## 🛠️ Manual Build (Xcode)

### Prerequisites

- macOS 15.0+
- Xcode 16.0+
- GitHub account (for OAuth)

### Step 1: Clone and Open

```bash
git clone https://github.com/yourusername/runs.git
cd runs
open Runs.xcodeproj
```

### Step 2: Configure (Optional)

Sign-in uses GitHub's **OAuth Device Flow**: the app shows a short code, opens github.com, and you approve there. No client secret is used or shipped.

The app comes with a client ID. To use your own GitHub OAuth app instead:

1. Go to https://github.com/settings/developers and click "New OAuth App"
2. Fill in any homepage and callback URL (the callback isn't used)
3. Tick **Enable Device Flow** and save
4. Copy the Client ID (you don't need a client secret)
5. In Xcode: Product → Scheme → Edit Scheme → Run → Arguments, add `GITHUB_CLIENT_ID` = your_client_id

### Step 3: Build

1. Select **My Mac** as run destination
2. Press **Cmd+B** to build
3. Press **Cmd+R** to run

### Step 4: Install

**From Build Script:**
```bash
./build_and_install.sh
```

**Manual:**
```bash
# Find built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Runs.app" -type d | grep "Release" | head -1)
cp -R "$APP_PATH" /Applications/
```

---

## 🎯 Launch the App

### First Launch

1. **Spotlight:**
   - Press `Cmd+Space`
   - Type "Runs"
   - Press Enter

2. **Terminal:**
   ```bash
   open -a Runs
   ```

### Gatekeeper Warning

On first launch, macOS may show:
**"Runs.app can't be opened because it is from an unidentified developer"**

**Fix:**
1. System Settings → Privacy & Security
2. Find "Runs.app was blocked"
3. Click "Open Anyway"
4. Click "Open" in confirmation dialog

Or right-click the app → Open → Open

---

## 🔧 Troubleshooting

### Build Issues

**"Active developer directory not found"**
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

**"Sandbox does not allow network access"**
- Signing & Capabilities → App Sandbox → Check "Outgoing Connections"

### Runtime Issues

**"Menu bar icon doesn't appear"**
- Check Console.app for crash logs
- Try: `killall Runs` then relaunch
- Verify app is running: `ps aux | grep Runs`

**"Device Flow is not enabled for this OAuth app"**
- Open the OAuth app at https://github.com/settings/developers and tick **Enable Device Flow**

**"App crashes on launch"**
1. Open Console.app
2. Filter for "Runs"
3. Check crash logs in ~/Library/Logs/DiagnosticReports/

---

## 🔄 Updating

```bash
cd /path/to/runs
./build_and_install.sh
killall Runs
open -a Runs
```

---

## 📁 Project Structure

```
Runs/
├── Models/              # Data models (WorkflowRun, Repository, etc.)
├── Services/            # Business logic (AppState, GitHubService, etc.)
├── Views/               # UI components
├── Utilities/           # Helpers (Constants.swift)
├── AppDelegate.swift    # App lifecycle
├── RunsApp.swift        # Main entry
├── Info.plist          # App configuration
└── Runs.entitlements   # Security settings
```

---

## ✅ Quick Reference

```bash
# Build & Install
./build_and_install.sh

# Launch
open -a Runs

# Quit
killall Runs

# Uninstall
rm -rf /Applications/Runs.app

# Check Status
ps aux | grep Runs
```

---

## 📝 Configuration Reference

**Default OAuth App:**
- Client ID: `Ov23liiRWGLaXVGnEIN0`
- Redirect URI: `dev.kekayan.runs://oauth-callback`
- Bundle ID: `dev.kekayan.runs`

**Environment Variables:**
- `GITHUB_CLIENT_ID` - Override default Client ID
- `GITHUB_CLIENT_SECRET` - Override default Client Secret
- `GITHUB_REDIRECT_URI` - Override redirect URI

---

🎉 **Ready to use!** Click the menu bar icon (⚡) to get started.
