#!/bin/bash
# Adjust active window's PipeWire stream volume and show the OSD.
WIN_JSON=$(hyprctl activewindow -j)
PID=$(printf '%s' "$WIN_JSON" | jq -r '.pid')
DIRECTION="$1"   # up | down | mute

[ -z "$PID" ] || [ "$PID" = "null" ] && exit 0

# Find the first audio output node owned by this PID
NODE_ID=$(pw-dump 2>/dev/null | jq -r --arg pid "$PID" '
    .[] |
    select(
        .type == "PipeWire:Interface:Node" and
        ((.info.props["application.process.id"] // -1) | tostring) == $pid and
        ((.info.props["media.class"] // "") | test("Audio/Sink|Stream/Output"))
    ) | .id' | head -1)

[ -z "$NODE_ID" ] && exit 0

case "$DIRECTION" in
    up)   wpctl set-volume "$NODE_ID" -l 1 2%+ ;;
    down) wpctl set-volume "$NODE_ID" 2%- ;;
    mute) wpctl set-mute   "$NODE_ID" toggle ;;
esac

VOL_OUT=$(wpctl get-volume "$NODE_ID" 2>/dev/null)
VOL=$(printf '%s' "$VOL_OUT" | grep -oP '[\d.]+' | head -1)
echo "$VOL_OUT" | grep -qi "MUTED" && MUTED=1 || MUTED=0
PCT=$(awk "BEGIN { printf \"%d\", ${VOL:-0} * 100 }")

# Capitalize first letter of window class, truncate to 10 chars
APP=$(printf '%s' "$WIN_JSON" | jq -r '.class // ""' | cut -c1-10)
APP=$(printf '%s' "$APP" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')

qs ipc call osd volumeApp "$PCT" "$MUTED" "$APP"
