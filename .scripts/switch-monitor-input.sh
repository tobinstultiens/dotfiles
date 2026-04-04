#!/bin/sh

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/switch-monitor-input.conf"

# Load persisted bus numbers if available
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
fi

for pid in $(pidof -x "switch-monitor-input.sh"); do
    if [ "$pid" != $$ ]; then
        exit 1
    fi
done

detect_monitors() {
    notify-send -e "Detecting monitors via ddcutil..."
    DETECT_OUTPUT=$(ddcutil detect 2>/dev/null)
    BUSES=$(echo "$DETECT_OUTPUT" | grep "I2C bus:" | sed 's|.*i2c-||' | sort -n)
    COUNT=$(echo "$BUSES" | grep -c .)

    if [ "$COUNT" -lt 2 ]; then
        notify-send -e "Monitor detection failed: found $COUNT monitor(s), need 2"
        exit 1
    fi

    LEFT_NUMBER=$(echo "$BUSES" | sed -n '1p')
    RIGHT_NUMBER=$(echo "$BUSES" | sed -n '2p')

    mkdir -p "$(dirname "$CONFIG_FILE")"
    printf 'LEFT_NUMBER=%s\nRIGHT_NUMBER=%s\n' "$LEFT_NUMBER" "$RIGHT_NUMBER" > "$CONFIG_FILE"
    notify-send -e "Detected monitors: Left=bus $LEFT_NUMBER, Right=bus $RIGHT_NUMBER"
}

if [ -z "${LEFT_NUMBER}" ] || [ -z "${RIGHT_NUMBER}" ]; then
    detect_monitors
fi

retryUntilSwitchedMainPc() {
	notify-send -e "Switching Monitor to PC"
	while echo "$MONITOR" | grep -qv "DisplayPort-1" && echo "$MONITOR" | grep -q "Invalid"; do
		notify-send -e "Switching Monitor"
		(ddcutil -b "$1" setvcp 0x60 "$2")
		MONITOR=$(ddcutil -b "$1" getvcp 0x60)
	done
}

retryUntilSwitchedSecondPc() {
	notify-send -e "Switching Monitor to PC"
	while echo "$MONITOR" | grep -qv "DisplayPort-1"; do
		notify-send -e "Switching Monitor"
		(ddcutil -b "$1" setvcp 0x60 "$2")
		MONITOR=$(ddcutil -b "$1" getvcp 0x60)
	done
}

retryUntilSwitchedLaptop() {
	notify-send -e "Switching Monitor to laptop"
	while echo "$MONITOR" | grep -q "DisplayPort-1" ; do
		notify-send -e "Switching Monitor"
		(ddcutil -b "$1" setvcp 0x60 "$2")
		MONITOR=$(ddcutil -b "$1" getvcp 0x60)
	done
}


case $1 in
	1)
		MONITOR=$(ddcutil -b $LEFT_NUMBER getvcp 0x60)
		if expr "$MONITOR" : '.*0x0f' >/dev/null; then
			notify-send -e "Switching Monitor 1"
			retryUntilSwitchedLaptop "$LEFT_NUMBER" "0x13"
		elif echo "$MONITOR" | grep -q "No monitor detected on bus"; then
			notify-send -e "Could not find monitor"
			detect_monitors
			exit 1
		elif echo "$MONITOR" | grep -q "does not exist"; then
			notify-send -e "Could not find monitor"
			detect_monitors
			exit 1
		else
			notify-send -e "Switching Monitor 1"
			retryUntilSwitchedMainPc "$LEFT_NUMBER" "0x0f"
		fi
		;;
	2)
		MONITOR=$(ddcutil -b $RIGHT_NUMBER getvcp 0x60)
		if expr "$MONITOR" : '.*0x0f' >/dev/null; then
			retryUntilSwitchedLaptop "$RIGHT_NUMBER" "0x11"
		elif echo "$MONITOR" | grep -q "No monitor detected on bus"; then
			notify-send -e "Could not find monitor"
			detect_monitors
			exit 1
		elif echo "$MONITOR" | grep -q "does not exist"; then
			notify-send -e "Could not find monitor"
			detect_monitors
			exit 1
		else
			notify-send -e "Switching Monitor 2"
			retryUntilSwitchedSecondPc "$RIGHT_NUMBER" "0x0f"
		fi
		;;
esac
