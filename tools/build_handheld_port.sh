#!/bin/bash
# Builds the PortMaster handheld package (port/README.md):
#   bash tools/build_handheld_port.sh
# Exports sealedbelfry.pck with the "Handheld (Linux arm64)" preset and assembles
# builds/handheld/ports/ (copy its contents to the handheld's ports folder) and
# builds/handheld/sealedbelfry.zip. Set GODOT to the Godot 4.7.2 console executable.
set -e
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/c/Users/Ishaan/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
OUT=builds/handheld
PORT="$OUT/ports/sealedbelfry"

rm -rf "$OUT/ports" "$OUT/sealedbelfry.zip"
mkdir -p "$PORT/licenses"

echo "exporting the pck..."
"$GODOT" --headless --path . --export-pack "Handheld (Linux arm64)" "$OUT/sealedbelfry.pck" > "$OUT/export_log.txt" 2>&1
[ -s "$OUT/sealedbelfry.pck" ] || { echo "export failed, see $OUT/export_log.txt"; exit 1; }
cp "$OUT/sealedbelfry.pck" "$PORT/"

cp "port/Sealed Belfry.sh" "$OUT/ports/"
cp port/sealedbelfry/sealedbelfry.gptk port/sealedbelfry/screenshot.png "$PORT/"
cp port/sealedbelfry/licenses/* "$PORT/licenses/"
cp port/README.md port/port.json port/gameinfo.xml "$PORT/"
for font in assets/fonts/*/; do
  cp "$font/OFL.txt" "$PORT/licenses/OFL-$(basename "$font").txt"
done
# The handheld runs these with bash: Unix line endings, executable
sed -i 's/\r$//' "$OUT/ports/Sealed Belfry.sh" "$PORT/sealedbelfry.gptk"
chmod +x "$OUT/ports/Sealed Belfry.sh"

if command -v powershell.exe >/dev/null; then
  powershell.exe -NoProfile -Command "Compress-Archive -Path '$OUT/ports/*' -DestinationPath '$OUT/sealedbelfry.zip' -Force" >/dev/null
elif command -v zip >/dev/null; then
  (cd "$OUT/ports" && zip -qr ../sealedbelfry.zip .)
fi

echo "done: $OUT/ports/ ($(du -sh "$OUT/ports" | cut -f1))"
ls -la "$OUT/ports" "$PORT"
