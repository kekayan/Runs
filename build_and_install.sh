#!/bin/bash

# Runs App - Build and Install Script
# This script builds the app and installs it to /Applications

set -e  # Exit on error

echo "🔨 Building Runs.app..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
APP_NAME="Runs"
SCHEME="Runs"

# Check if Xcode is properly configured
if ! xcode-select -p &> /dev/null; then
    echo -e "${RED}❌ Xcode command line tools not found${NC}"
    echo "Please run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

# Clean previous builds
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build the app
echo -e "${BLUE}🔨 Building $APP_NAME in Release mode...${NC}"
xcodebuild \
    -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA" \
    clean build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Check if build succeeded
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Find the built app
BUILT_APP="$DERIVED_DATA/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$BUILT_APP" ]; then
    echo -e "${RED}❌ Built app not found at $BUILT_APP${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"
echo ""

# Install to /Applications
echo -e "${BLUE}📦 Installing to /Applications...${NC}"

# Remove old version if exists
if [ -d "/Applications/$APP_NAME.app" ]; then
    echo -e "${YELLOW}⚠️  Removing old version...${NC}"
    rm -rf "/Applications/$APP_NAME.app"
fi

# Copy new version
cp -R "$BUILT_APP" "/Applications/"

# Verify installation
if [ -d "/Applications/$APP_NAME.app" ]; then
    echo -e "${GREEN}✅ $APP_NAME.app installed to /Applications${NC}"
    echo ""
    echo -e "${GREEN}🎉 Installation complete!${NC}"
    echo ""
    echo -e "${BLUE}To launch the app:${NC}"
    echo "  1. Open Spotlight (Cmd+Space)"
    echo "  2. Type 'Runs' and press Enter"
    echo ""
    echo "Or run from Terminal:"
    echo "  open -a Runs"
    echo ""
    echo -e "${YELLOW}Note: On first launch, you may need to:${NC}"
    echo "  1. Right-click the app in /Applications"
    echo "  2. Click 'Open'"
    echo "  3. Click 'Open' in the security dialog"
else
    echo -e "${RED}❌ Installation failed${NC}"
    exit 1
fi
