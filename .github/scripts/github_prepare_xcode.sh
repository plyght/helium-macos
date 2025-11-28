#!/bin/bash -eux

set -o pipefail

# Find the default Xcode or Xcode 26.x installation
# On macos-26 runner, default is at /Applications/Xcode.app or /Applications/Xcode_26.0.app
TARGET_XCODE_PATH=/Applications/Xcode_26.app

# Try to find any Xcode 26 installation
if [ -e "/Applications/Xcode.app" ]; then
  BASE_XCODE_PATH=/Applications/Xcode.app
elif [ -e "/Applications/Xcode_26.0.app" ]; then
  BASE_XCODE_PATH=/Applications/Xcode_26.0.app
elif [ -e "/Applications/Xcode_26.0.1.app" ]; then
  BASE_XCODE_PATH=/Applications/Xcode_26.0.1.app
elif [ -e "/Applications/Xcode_26.1.app" ]; then
  BASE_XCODE_PATH=/Applications/Xcode_26.1.app
elif [ -e "/Applications/Xcode_26.1.1.app" ]; then
  BASE_XCODE_PATH=/Applications/Xcode_26.1.1.app
else
  echo "Failed to find a suitable version of Xcode"
  ls -la /Applications/ | grep -i xcode || true
  exit 1
fi

echo "Found Xcode at: $BASE_XCODE_PATH"

# Create target symlink/path if needed
if [ ! -e "$TARGET_XCODE_PATH" ]; then
  if [ -L "$BASE_XCODE_PATH" ]; then
    REAL_XCODE_PATH="$(greadlink -f "$BASE_XCODE_PATH")"
    sudo ln -s "$REAL_XCODE_PATH" "$TARGET_XCODE_PATH"
  else
    sudo ln -s "$BASE_XCODE_PATH" "$TARGET_XCODE_PATH"
  fi
fi

# Switch to target Xcode and clean simulators
sudo xcode-select --switch "$TARGET_XCODE_PATH"
sudo xcrun simctl delete all || true

# Make sure metal toolchain is installed
xcodebuild -downloadComponent MetalToolchain || true
