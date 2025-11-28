#!/bin/bash

APP_NAME="MenuBarScroller"
APP_BUNDLE="$APP_NAME.app"
OUTPUT_DIR="."

echo "Building Release Configuration..."
swift build -c release

echo "Creating App Bundle Structure..."
mkdir -p "$OUTPUT_DIR/$APP_BUNDLE/Contents/MacOS"
mkdir -p "$OUTPUT_DIR/$APP_BUNDLE/Contents/Resources"

echo "Copying Binary..."
cp .build/release/$APP_NAME "$OUTPUT_DIR/$APP_BUNDLE/Contents/MacOS/"

echo "Copying Info.plist..."
cp Info.plist "$OUTPUT_DIR/$APP_BUNDLE/Contents/"

echo "Signing App (Ad-hoc)..."
codesign --force --deep --sign - "$OUTPUT_DIR/$APP_BUNDLE"

echo "Done! App created at $OUTPUT_DIR/$APP_BUNDLE"
