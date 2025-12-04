#!/bin/sh

LEFT_NUMBER=4
RIGHT_NUMBER=8

for pid in $(pidof -x "switch-monitor-input.sh"); do
    if [ "$pid" != $$ ]; then
        exit 1
    fi
done

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
			exit 1
		elif echo "$MONITOR" | grep -q "does not exist"; then
			notify-send -e "Could not find monitor"
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
			exit 1
		elif echo "$MONITOR" | grep -q "does not exist"; then
			notify-send -e "Could not find monitor"
			exit 1
		else
			notify-send -e "Switching Monitor 2"
			retryUntilSwitchedSecondPc "$RIGHT_NUMBER" "0x0f"
		fi
		;;
esac
