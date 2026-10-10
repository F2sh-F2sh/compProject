#!/bin/bash
# PORTMASTER: sealedbelfry.zip, Sealed Belfry.sh
#
# The Sealed Belfry on PortMaster handhelds (aarch64 with 1 GB or more, such as the Anbernic
# RG35XX Plus / H / SP / 2024 on Knulli or muOS): the game's pck on PortMaster's stock Godot
# 4.7.1 runtime, drawn through Westonpack on the Compatibility (OpenGL ES) renderer.
# Built by tools/build_handheld_port.sh. The controller renumbering below (mapping_pad,
# godot_joy_mapping) is adapted from crxssrazr93's Dome Keeper and Pathogenic ports (MIT,
# see sealedbelfry/licenses/LICENSE.crxssrazr93-ports.txt).

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR="/$directory/ports/sealedbelfry"
CONFDIR="$GAMEDIR/conf"
godot_runtime="godot_4.7.1"
godot_executable="godot471.$DEVICE_ARCH"
weston_runtime="weston_pkg_0.2"

cd "$GAMEDIR"
# the previous run's log is kept as log.prev.txt
mv -f "$GAMEDIR/log.txt" "$GAMEDIR/log.prev.txt" 2>/dev/null
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
echo "The Sealed Belfry launcher: $CFW_NAME on $DEVICE_NAME, ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}, $DEVICE_ARCH"
mkdir -p "$CONFDIR"

if [ ! -f "$GAMEDIR/sealedbelfry.pck" ]; then
  pm_message "Missing sealedbelfry.pck in ports/sealedbelfry/. Copy the whole ports folder from the build again."
  sleep 8
  pm_finish
  exit 1
fi

# The Godot and Weston runtimes: downloaded by PortMaster on the first start (Wi-Fi needed),
# or copied by hand into PortMaster/libs/ (see README.md)
for runtime in "$godot_runtime" "$weston_runtime"; do
  if [ ! -f "$controlfolder/libs/${runtime}.squashfs" ]; then
    if [ ! -f "$controlfolder/harbourmaster" ]; then
      pm_message "This port requires the latest PortMaster to run, please go to https://portmaster.games/ for more info."
      sleep 5
      exit 1
    fi
    $ESUDO $controlfolder/harbourmaster --quiet --no-check runtime_check "${runtime}.squashfs"
  fi
done

godot_dir=/tmp/godot
weston_dir=/tmp/weston
$ESUDO mkdir -p "$godot_dir" "$weston_dir"
if [[ "$PM_CAN_MOUNT" != "N" ]]; then
  $ESUDO umount "$godot_dir" 2>/dev/null
  $ESUDO umount "$weston_dir" 2>/dev/null
fi
$ESUDO mount "$controlfolder/libs/${godot_runtime}.squashfs" "$godot_dir"
$ESUDO mount "$controlfolder/libs/${weston_runtime}.squashfs" "$weston_dir"
if [ ! -x "$godot_dir/$godot_executable" ] || [ ! -f "$weston_dir/westonwrap.sh" ]; then
  echo "runtime missing: $godot_dir/$godot_executable or $weston_dir/westonwrap.sh"
  pm_message "The Godot 4.7.1 or Weston runtime is missing. Connect to Wi-Fi and start the game again, or see README.md."
  sleep 8
  $ESUDO umount "$godot_dir" "$weston_dir" 2>/dev/null
  pm_finish
  exit 1
fi

# The input device a mapping line is for: by its SDL GUID first (bus, vendor, product and
# version, little endian; bytes 2 and 3 hold a CRC of the name in current SDL, so they are
# skipped), then by name, then the only joystick with buttons.
mapping_pad() {
  local guid="${1%%,*}" name="${1#*,}" ev id pads=()
  name="${name%%,*}"
  le16() { local v=$((16#$(cat "$1" 2>/dev/null || echo 0))); printf '%02x%02x' $((v & 255)) $((v >> 8 & 255)); }
  for ev in /sys/class/input/event*/device; do
    [ -d "$ev/id" ] && ls -d "$ev"/js* >/dev/null 2>&1 || continue
    id="$(le16 "$ev/id/bustype")0000$(le16 "$ev/id/vendor")0000$(le16 "$ev/id/product")0000$(le16 "$ev/id/version")0000"
    [ "${id:0:4}${id:8}" = "${guid:0:4}${guid:8}" ] && { echo "$ev"; return; }
  done
  for ev in /sys/class/input/event*/device; do
    [ "$(cat "$ev/name" 2>/dev/null)" = "$name" ] && { echo "$ev"; return; }
  done
  for ev in /sys/class/input/event*/device; do
    ls -d "$ev"/js* >/dev/null 2>&1 || continue
    [ -n "$(cat "$ev/capabilities/key" 2>/dev/null)" ] && pads+=("$ev")
  done
  [ ${#pads[@]} -eq 1 ] && echo "${pads[0]}"
}
# Godot numbers joypad buttons from BTN_JOYSTICK (0x120) upwards, then BTN_MISC to
# BTN_JOYSTICK, and skips lower key codes. SDL numbers every key code in ascending order, so on
# pads that also report keys like volume, the SDL mapping's bN indices point at the wrong
# buttons in Godot. Renumber them using the pad's key bitmap.
godot_joy_mapping() {
  local mapping="$1" dev="" wbits=64 n i b w code
  dev="$(mapping_pad "$mapping")"
  [ -n "$dev" ] || { echo "$mapping"; return; }
  case "$(uname -m)" in aarch64|x86_64) ;; *) wbits=32 ;; esac
  local words=($(cat "$dev/capabilities/key")) codes=()
  n=${#words[@]}
  for ((i = 0; i < n; i++)); do
    w=$((16#${words[n-1-i]}))
    for ((b = 0; b < wbits; b++)); do
      (( (w >> b) & 1 )) && codes+=($((i * wbits + b)))
    done
  done
  local -A godot_idx=()
  local g=0 sdl=0 out="" f
  for code in "${codes[@]}"; do (( code >= 0x120 )) && godot_idx[$code]=$((g++)); done
  for code in "${codes[@]}"; do (( code >= 0x100 && code < 0x120 )) && godot_idx[$code]=$((g++)); done
  local -A sdl_to_godot=()
  for code in "${codes[@]}"; do
    [ -n "${godot_idx[$code]}" ] && sdl_to_godot[$sdl]=${godot_idx[$code]}
    sdl=$((sdl + 1))
  done
  IFS=, read -ra fields <<< "$mapping"
  for f in "${fields[@]}"; do
    if [[ "$f" =~ ^([^:]+):b([0-9]+)$ ]]; then
      [ -n "${sdl_to_godot[${BASH_REMATCH[2]}]}" ] || continue
      f="${BASH_REMATCH[1]}:b${sdl_to_godot[${BASH_REMATCH[2]}]}"
    fi
    out+="$f,"
  done
  echo "$out"
}

# The game reads the built-in pad itself (Godot joypad input) with PortMaster's mapping for the
# device, renumbered for Godot. It reaches the game as a westonwrap VAR=value argument (westonwrap
# sources control.txt again, which on muOS would export the original mapping over ours), on one
# line with the spaces in its name made dots (only the GUID is matched).
godot_mapping=""
while IFS= read -r line; do
  [ -n "$line" ] || continue
  godot_mapping="$(godot_joy_mapping "$line")"
  break
done <<< "$SDL_GAMECONTROLLERCONFIG"
godot_mapping="$(printf '%s' "$godot_mapping" | tr ' ' '.')"
echo "controller mapping for the game: ${godot_mapping:-none, Godot database}"

# gptokeyb maps no buttons (sealedbelfry.gptk): it only supplies PortMaster's exit hotkey.
# gptokeyb1 is unresponsive on muOS, where gptokeyb2 is used instead.
if [ "$CFW_NAME" = "muOS" ] && [ -n "$GPTOKEYB2" ]; then
  $GPTOKEYB2 "$godot_executable" -c "$GAMEDIR/sealedbelfry.gptk" &
else
  $GPTOKEYB "$godot_executable" -c "$GAMEDIR/sealedbelfry.gptk" &
fi
pm_platform_helper "$godot_dir/$godot_executable"

# --handheld (after --, for the game): Low graphics on the first start, pad prompts, Rune Carry
# on L2, no mouse cursor, no tiny text (Settings.handheld). Saves and settings go to conf/.
# westonwrap replaces XDG_RUNTIME_DIR; pass the real one on so ALSA can reach PipeWire for sound.
REAL_XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
$ESUDO env $weston_dir/westonwrap.sh headless noop kiosk crusty_x11egl \
  LD_PRELOAD= ${godot_mapping:+SDL_GAMECONTROLLERCONFIG="$godot_mapping"} XDG_DATA_HOME="$CONFDIR" XDG_RUNTIME_DIR="$REAL_XDG_RUNTIME_DIR" \
  "$godot_dir/$godot_executable" --resolution "${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}" -f \
  --rendering-method gl_compatibility --rendering-driver opengl3_es --audio-driver ALSA --print-fps \
  --main-pack "$GAMEDIR/sealedbelfry.pck" -- --handheld

$ESUDO $weston_dir/westonwrap.sh cleanup
if [[ "$PM_CAN_MOUNT" != "N" ]]; then
  $ESUDO umount "$godot_dir"
  $ESUDO umount "$weston_dir"
fi
pm_finish
