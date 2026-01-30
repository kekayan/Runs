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

The app comes pre-configured with OAuth credentials and works out of the box. However, if you want to use your own GitHub OAuth app:

**Option A: Environment Variables (Recommended for Development)**

1. In Xcode: Product → Scheme → Edit Scheme → Run → Arguments
2. Add Environment Variables:
   - `GITHUB_CLIENT_ID` = your_client_id
   - `GITHUB_CLIENT_SECRET` = your_client_secret

**Option B: .env File**

```bash
cp .env.example .env
# Edit .env with your credentials
```

**Option C: Create Your Own OAuth App**

1. Go to https://github.com/settings/developers
2. Click "New OAuth App"
3. Fill in:
   - Application name: `Runs - GitHub Actions Menu Bar`
   - Homepage URL: `https://github.com/yourusername/runs`
   - Authorization callback URL: `dev.kekayan.runs://oauth-callback`
4. Copy Client ID and Client Secret
5. Configure via Option A or B above

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

**"OAuth redirect doesn't work"**
- Verify callback URL in GitHub OAuth app: `dev.kekayan.runs://oauth-callback`
- Test with: `open "dev.kekayan.runs://test"`
- Check URL scheme in Info.plist

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
