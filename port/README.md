# The Sealed Belfry on a handheld (PortMaster)

This folder is the PortMaster package for ARM64 Linux handhelds with 1 GB of memory or more, such as
the Anbernic RG35XX Plus, H, SP and 2024. The game runs as an exported `.pck` on PortMaster's stock
Godot 4.7.1 runtime, drawn through Westonpack with Godot's Compatibility (OpenGL ES) renderer.

## Build it (on the PC)

```bash
bash tools/build_handheld_port.sh
```

This exports `sealedbelfry.pck` with the "Handheld (Linux arm64)" preset and assembles
`builds/handheld/ports/`, ready to copy, plus `builds/handheld/sealedbelfry.zip`.
Set `GODOT` to the Godot 4.7.2 console executable if it isn't in the default place.

## What the handheld needs

- **Custom firmware with PortMaster: Knulli or muOS.** Anbernic's stock firmware can't run Godot ports:
  it has no OpenGL display (Weston) for them. Put the custom firmware on a second microSD card to
  keep the stock card as it is.
- **PortMaster** (built into Knulli and muOS; update it from its own menu).
- **Wi-Fi the first time:** the first start downloads the `godot_4.7.1` and `weston_pkg_0.2`
  runtimes. Without Wi-Fi, download both `.squashfs` files on a PC (see the Runtimes page of the
  PortMaster wiki) and copy them into `PortMaster/libs/` on the card.

## Install

Copy the **contents** of `builds/handheld/ports/` (the `Sealed Belfry.sh` file and the `sealedbelfry`
folder) into the card's ports folder:

| Firmware | Ports folder on the SD card |
|---|---|
| Knulli | `roms/ports/` (on the SHARE partition; `/userdata/roms/ports` on the device) |
| muOS | `ROMS/Ports/` (`/mnt/mmc/ROMS/Ports` on the device) |

Then refresh the game list (Knulli: Game Settings → Update Gamelists; muOS: it appears under
Explore Content → Ports) and start **The Sealed Belfry** from Ports.

## Controls

| Button | Action |
|---|---|
| D-pad left / right | Walk |
| D-pad up | Interact, read |
| D-pad down | Crouch (hold, then A for a charged jump) |
| A | Jump |
| B | Echo |
| X | Heal |
| Y | Reload |
| L1 | Sprint |
| R1 or R2 | Cast a fireball (hold d-pad up or down to aim up or down) |
| L2 | Carry a rune cube |
| Select | Rune overview |
| Start | Pause menu (map, settings, reset room) |

PortMaster's own exit hotkey quits the game (on most firmwares Select + Start, or the Menu button).

## Good to know

- Saves and settings live in `sealedbelfry/conf/`. Graphics start on Low; you can change it in the
  pause menu's settings.
- `sealedbelfry/log.txt` has the launcher's and the game's output, including the frame rate
  (`--print-fps`); send it along if something goes wrong.
- The game is designed for 1152×648 and drawn at about half size on a 640×480 screen, so small
  text is small.
