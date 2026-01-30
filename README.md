# Runs - GitHub Actions Menu Bar App

A native macOS menu bar application that monitors GitHub Actions workflow runs in real-time.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2015.0+-lightgrey.svg)
![Swift](https://img.shields.io/badge/swift-6.0-orange.svg)

## Features

- **Menu Bar Integration** - Lives in your macOS menu bar for quick access
- **GitHub OAuth** - Secure authentication with your GitHub account
- **Biometric Protection** - Optional Touch ID / Face ID for token access
- **Repository Selection** - Choose which repositories to monitor
- **Real-time Updates** - Auto-refresh every 5 minutes + manual refresh
- **Workflow Status** - See latest runs with status (success/failure/in-progress)
- **Quick Actions** - Click any run to copy its GitHub URL
- **Native UI** - Built with SwiftUI and NSStatusBar

## Installation

### Quick Start

```bash
git clone https://github.com/yourusername/runs.git
cd runs
chmod +x build_and_install.sh
./build_and_install.sh
```

Then launch: `open -a Runs` or use Spotlight (Cmd+Space → "Runs")

### Requirements

- macOS 15.0+
- Xcode 16.0+ (for building from source)
- GitHub account

## Usage

1. Launch the app from `/Applications`
2. Click the menu bar icon (⚡)
3. Click "Login with GitHub"
4. Authorize the app in your browser
5. Select repositories to monitor
6. View workflow runs in the menu bar popup

**Tips:**
- Click the refresh icon to manually update
- Click any workflow run to copy its URL
- The app auto-refreshes every 5 minutes

## Configuration

The app works out of the box with pre-configured OAuth credentials. To use your own GitHub OAuth app:

### Option 1: Environment Variables

In Xcode: Product → Scheme → Edit Scheme → Run → Arguments

Add:
- `GITHUB_CLIENT_ID` = your_client_id
- `GITHUB_CLIENT_SECRET` = your_client_secret

### Option 2: .env File

```bash
cp .env.example .env
# Edit .env with your credentials
```

### Creating Your Own OAuth App

1. Go to https://github.com/settings/developers
2. Click "New OAuth App"
3. Fill in:
   - **Application name:** Runs - GitHub Actions Menu Bar
   - **Homepage URL:** https://github.com/yourusername/runs
   - **Authorization callback URL:** `dev.kekayan.runs://oauth-callback`
4. Copy Client ID and Client Secret
5. Configure via Option 1 or 2 above

## Architecture

### Tech Stack
- **SwiftUI** - Modern declarative UI
- **NSStatusBar** - Native menu bar integration
- **GitHub REST API** - Workflow data
- **Keychain** - Secure token storage

### Project Structure
```
Runs/
├── Models/              # Data models
├── Services/            # Business logic
├── Views/               # UI components
├── Utilities/           # Helpers
├── AppDelegate.swift    # App lifecycle
├── RunsApp.swift        # Main entry
└── Info.plist          # App configuration
```

## Security

### Biometric Authentication

The app supports optional biometric authentication (Touch ID / Face ID) to protect your GitHub token:

1. Open Settings (gear icon)
2. Toggle "Use Touch ID" (or Face ID)
3. Your token will be protected by biometric authentication

When enabled:
- Token is stored with biometric access control in Keychain
- You'll be prompted for biometric auth when accessing the token
- Background auto-refresh continues to work after initial authentication

### Token Storage

- OAuth tokens are stored in macOS Keychain
- Encrypted and only accessible when device is unlocked
- Optional biometric protection layer
- Tokens persist across app updates

## Development

### Building from Source

```bash
# Build debug version
xcodebuild -project Runs.xcodeproj -scheme Runs -configuration Debug build

# Or open in Xcode
open Runs.xcodeproj
```

### Project Setup

1. Fork the repository
2. Build and run (pre-configured credentials included)
3. Or configure your own OAuth app (see Configuration)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI and AppKit
- Uses GitHub's REST API
- Inspired by native macOS menu bar apps

---

**Note:** The app identifiers (Client ID, bundle identifier, URL scheme) are public identifiers that identify the OAuth app to GitHub. The Client Secret should be kept private. Contributors can use their own OAuth credentials via environment variables.
