#!/usr/bin/env bash
set -euo pipefail

# Validate arguments
if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <board_type> <ip> <password> [ssh_user] [dest_root]"
  echo "Example: $0 pi4 192.168.1.100 mypassword dietpi /var/lib/smirror/frontend"
  exit 1
fi

BOARD=$1
IP=$2
PASSWORD=$3
SSH_USER=${4:-dietpi}                     # Defaults to 'dietpi'
DEST_ROOT=${5:-/var/lib/smirror/frontend} # Defaults to '/var/lib/smirror/frontend'

# Determine CPU arguments for flutterpi_tool based on board type
CPU_ARGS=""
if [[ "$BOARD" == "pi4" ]]; then
  CPU_ARGS="--cpu=pi4"
fi

# Ensure sshpass is installed on the host
if ! command -v sshpass &> /dev/null; then
  echo "❌ Error: 'sshpass' is required but not installed on this host."
  echo "   Please install it (e.g., 'sudo apt install sshpass')."
  exit 1
fi

echo "=========================================="
echo "==> 1. Cleaning and Building UI ($BOARD)"
echo "=========================================="
fvm flutter clean

# Build the arm64 binary for the target board
fvm dart run flutterpi_tool build --arch=arm64 ${CPU_ARGS} --release

# Find the newly generated build output containing app.so
BUILD_DIR=$(find build -type f -name app.so -printf '%T@ %h\n' | sort -nr | head -1 | cut -d' ' -f2-)
[[ -f "$BUILD_DIR/app.so" ]] || { echo "❌ Build failed - app.so not found!"; exit 1; }

echo "==> Staging build assets..."
STAGE="/tmp/smirror-ui-test"
rm -rf "$STAGE"; mkdir -p "$STAGE"

# Copy all necessary files and subdirectories
for f in app.so libflutter_engine.so flutter-pi icudtl.dat \
         AssetManifest.bin FontManifest.json NativeAssetsManifest.json \
         version.json NOTICES.Z; do
  [[ -f "$BUILD_DIR/$f" ]] && cp "$BUILD_DIR/$f" "$STAGE/"
done
for d in fonts packages shaders; do
  [[ -d "$BUILD_DIR/$d" ]] && cp -r "$BUILD_DIR/$d" "$STAGE/"
done
chmod 755 "$STAGE/flutter-pi" "$STAGE/libflutter_engine.so" "$STAGE/app.so" 2>/dev/null || true

echo "=========================================="
echo "==> 2. Deploying to Target via Rsync"
echo "=========================================="
echo "Connecting to $SSH_USER@$IP..."

VERSION_DIR="${DEST_ROOT}/versions/test"

# Step 1: Wipe target directory, recreate it, and temporarily grant ownership to SSH_USER
# so we don't hit "Permission Denied" errors during rsync!
echo "Preparing target folder: $VERSION_DIR..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$IP" \
  "sudo rm -rf \"$VERSION_DIR\" && sudo mkdir -p \"$VERSION_DIR\" && sudo chown -R $SSH_USER \"$VERSION_DIR\""

# Step 2: Sync the staged contents of our local build directly to the Pi
echo "Transferring UI assets..."
sshpass -p "$PASSWORD" rsync -avz --delete \
  -e "ssh -o StrictHostKeyChecking=no" \
  "$STAGE/" \
  "$SSH_USER@$IP:$VERSION_DIR/"

# Step 3: Restore proper ownership back to the 'smirror' service user
echo "Restoring ownership of $VERSION_DIR to smirror:smirror..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$IP" \
  "sudo chown -R smirror:smirror \"$VERSION_DIR\""

# Step 4: Atomically update the system symlink and set correct ownership
echo "Updating live system symlink..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$IP" \
  "sudo ln -sfn \"versions/test\" \"${DEST_ROOT}/current\" && sudo chown -h smirror:smirror \"${DEST_ROOT}/current\""

# Clean up local staging area
rm -rf "$STAGE"

echo "=========================================="
echo "✅ UI Test deployment completed successfully!"
echo "   Target Folder: $SSH_USER@$IP:$VERSION_DIR"
echo "   Live Symlink:  ${DEST_ROOT}/current -> versions/test"
echo "=========================================="