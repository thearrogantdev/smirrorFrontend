#!/usr/bin/env bash
set -euo pipefail

MIN_BACKEND="0.1.0"

# --- auto-detect repo ---
get_repo() {
  local url; url=$(git remote get-url origin 2>/dev/null || true)
  url=${url#*github.com:}; url=${url#*github.com/}; url=${url%.git}
  echo "$url"
}
REPO=${REPO:-$(get_repo)}
[[ -z "$REPO" ]] && { echo "No git remote found"; exit 1; }

[[ -f pubspec.yaml ]] || { echo "Run in Flutter root"; exit 1; }
VERSION=$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f1)

echo "==> Repo: $REPO  Version: $VERSION"

OUT_DIR="$(pwd)/release"; mkdir -p "$OUT_DIR"

build_variant() {
  local name=$1; shift
  local cpu_args=("$@")   # e.g. --cpu=pi4 or empty

  echo ""
  echo "==> Building $name..."
  fvm dart run flutterpi_tool build --arch=arm64 "${cpu_args[@]}" --release

  # find newest build output containing app.so
  local BUILD_DIR
  BUILD_DIR=$(find build -type f -name app.so -printf '%T@ %h\n' | sort -nr | head -1 | cut -d' ' -f2-)
  [[ -f "$BUILD_DIR/app.so" ]] || { echo "Build failed"; exit 1; }

  local STAGE="/tmp/smirror-ui-${VERSION}-${name}"
  rm -rf "$STAGE"; mkdir -p "$STAGE"

  for f in app.so libflutter_engine.so flutter-pi icudtl.dat \
           AssetManifest.bin FontManifest.json NativeAssetsManifest.json \
           version.json NOTICES.Z; do
    [[ -f "$BUILD_DIR/$f" ]] && cp "$BUILD_DIR/$f" "$STAGE/"
  done
  for d in fonts packages shaders; do
    [[ -d "$BUILD_DIR/$d" ]] && cp -r "$BUILD_DIR/$d" "$STAGE/"
  done
  chmod 755 "$STAGE/flutter-pi" "$STAGE/libflutter_engine.so" "$STAGE/app.so" 2>/dev/null || true

  local ZIP_NAME="smirror-ui-${VERSION}-aarch64-${name}.zip"
  local ZIP_PATH="${OUT_DIR}/${ZIP_NAME}"
  ( cd "$STAGE" && zip -9 -r -q "$ZIP_PATH" . )

  local SHA=$(sha256sum "$ZIP_PATH" | awk '{print $1}')
  local SIZE=$(stat -c%s "$ZIP_PATH")
  local TAG="ui-${VERSION}"
  local URL="https://github.com/${REPO}/releases/download/${TAG}/${ZIP_NAME}"
  local JSON="${OUT_DIR}/update-ui-aarch64-${name}.json"

  cat > "$JSON" <<EOF
{
  "version": "${VERSION}",
  "variant": "${name}",
  "url": "${URL}",
  "sha256": "${SHA}",
  "min_backend": "${MIN_BACKEND}",
  "size": ${SIZE}
}
EOF

  echo "  ✓ $ZIP_NAME  (${SIZE} bytes)"
  echo "  ✓ $(basename "$JSON")"
}

# --- build both ---
build_variant "pi4" --cpu=pi4
build_variant "generic"

echo ""
echo "All done. Upload both zips to the same GitHub release:"