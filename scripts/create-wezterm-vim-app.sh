#!/bin/bash
# Creates a macOS .app bundle for opening files in WezTerm + Vim
# This allows file associations to work properly

APP_NAME="WezTermVim"
APP_PATH="/Applications/$APP_NAME.app"

echo "Creating $APP_NAME.app bundle..."

# Create app bundle structure
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Create the executable script
cat > "$APP_PATH/Contents/MacOS/$APP_NAME" << 'EOF'
#!/bin/bash
# Open files in WezTerm with vim

# Get the file path from arguments
FILE=""

# Handle different ways macOS passes file paths
for arg in "$@"; do
  if [[ -f "$arg" ]]; then
    FILE="$arg"
    break
  fi
done

if [ -z "$FILE" ]; then
  # No file provided, just open WezTerm
  /Applications/WezTerm.app/Contents/MacOS/wezterm start
else
  # Open WezTerm with vim and the file
  /Applications/WezTerm.app/Contents/MacOS/wezterm start vim "$FILE"
fi
EOF

# Make it executable
chmod +x "$APP_PATH/Contents/MacOS/$APP_NAME"

# Create Info.plist
cat > "$APP_PATH/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>WezTermVim</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.weztermvim</string>
    <key>CFBundleName</key>
    <string>WezTerm Vim</string>
    <key>CFBundleDisplayName</key>
    <string>WezTerm Vim</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>txt</string>
                <string>md</string>
                <string>markdown</string>
                <string>sh</string>
                <string>bash</string>
                <string>zsh</string>
                <string>py</string>
                <string>js</string>
                <string>json</string>
                <string>yaml</string>
                <string>yml</string>
                <string>toml</string>
                <string>conf</string>
                <string>config</string>
                <string>log</string>
                <string>xml</string>
                <string>html</string>
                <string>css</string>
                <string>rs</string>
                <string>go</string>
                <string>c</string>
                <string>cpp</string>
                <string>h</string>
                <string>hpp</string>
                <string>lua</string>
                <string>vim</string>
                <string>*</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
        </dict>
    </array>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
</dict>
</plist>
EOF

echo ""
echo "✓ Created $APP_PATH"
echo ""
echo "You can now use this app as a file handler."
echo "To set it as default for text files, run:"
echo "  ./scripts/set-vim-default.sh"
