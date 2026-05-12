#!/usr/bin/env bash
# Builds TermHere from source, installs it into /Applications, and registers
# the Finder Sync extension exactly once. Safe to re-run — each invocation
# unregisters any stale copies (including the one Xcode auto-registers from
# DerivedData) before re-registering the canonical /Applications/TermHere.app.
#
# Usage:
#   ./scripts/install.sh                # Release build, ad-hoc signed
#   CONFIG=Debug ./scripts/install.sh   # Debug build instead

set -euo pipefail

CONFIG="${CONFIG:-Release}"
SCHEME="TermHere"
APP_NAME="TermHere.app"
INSTALL_DIR="/Applications"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

cd "$(dirname "$0")/.."

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# --- 1. Preflight ----------------------------------------------------------

step "Checking prerequisites"
command -v xcodegen >/dev/null || { echo "xcodegen not found. Run: brew install xcodegen"; exit 1; }
command -v xcodebuild >/dev/null || { echo "xcodebuild not found. Install full Xcode (not just CLT)."; exit 1; }

# --- 2. Regenerate Xcode project ------------------------------------------

step "Regenerating Xcode project"
xcodegen generate

# --- 3. Build --------------------------------------------------------------

step "Building $SCHEME ($CONFIG, ad-hoc signed)"
xcodebuild \
    -project TermHere.xcodeproj \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    CODE_SIGN_IDENTITY="-" \
    clean build \
    | tail -n 20

BUILT_DIR=$(xcodebuild \
    -project TermHere.xcodeproj \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -showBuildSettings 2>/dev/null \
    | awk -F' = ' '/^ *BUILT_PRODUCTS_DIR/{print $2; exit}')

if [[ -z "$BUILT_DIR" || ! -d "$BUILT_DIR/$APP_NAME" ]]; then
    echo "Could not locate built $APP_NAME — aborting." >&2
    exit 1
fi

# --- 4. Unregister stale copies -------------------------------------------

step "Unregistering stale TermHere copies"
# DerivedData copies that Xcode auto-registers during build.
shopt -s nullglob
for app in "$BUILT_DIR/$APP_NAME" \
           "$HOME/Library/Developer/Xcode/DerivedData/TermHere-"*/Build/Products/*/"$APP_NAME"; do
    [[ -d "$app" ]] && "$LSREGISTER" -u "$app" 2>/dev/null || true
done
# Any previous /Applications install.
[[ -d "$INSTALL_DIR/$APP_NAME" ]] && "$LSREGISTER" -u "$INSTALL_DIR/$APP_NAME" 2>/dev/null || true

# --- 5. Install ------------------------------------------------------------

step "Installing $APP_NAME into $INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME"
cp -R "$BUILT_DIR/$APP_NAME" "$INSTALL_DIR/"

# --- 6. Register the canonical copy ---------------------------------------

step "Registering $INSTALL_DIR/$APP_NAME with Launch Services"
"$LSREGISTER" -f -R "$INSTALL_DIR/$APP_NAME"

# --- 7. Launch once so LaunchServices discovers the embedded extension ----
# Also triggers ConfigBootstrapper so any new bundled presets get copied
# into ~/Library/Application Support/TermHere/. `-gj` runs hidden in the
# background; we quit it immediately after.

step "Launching app once to seed extension + presets"
open -gj "$INSTALL_DIR/$APP_NAME"
sleep 3
osascript -e 'tell application "TermHere" to quit' >/dev/null 2>&1 || true

# --- 8. Restart Finder so it picks up the (re)registered extension --------

step "Restarting Finder"
killall Finder 2>/dev/null || true
sleep 2

# --- 9. Verify -------------------------------------------------------------

step "Verifying registration"
MATCHES=$(pluginkit -m -p com.apple.FinderSync -v 2>/dev/null | grep -i 'com.termhere' || true)
if [[ -z "$MATCHES" ]]; then
    echo "⚠️  No TermHereFinder registration found. Open TermHere.app from /Applications manually."
else
    echo "$MATCHES"
fi

cat <<'EOF'

✅ Install complete.

Next steps:
  1. Open  System Settings → General → Login Items & Extensions
     → enable "TermHereFinder" (only the one under /Applications should be listed).
  2. Right-click any folder in Finder → TermHere ▸ to use it.

The first time you click "Open Terminal Here" macOS will ask for permission
to control Terminal — click "OK".
EOF
