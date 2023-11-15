#!/bin/sh

retryUntilSwitchedMainPc() {
	notify-send -e "Switching Monitor to PC"
	while echo "$MONITOR" | grep -qv "DisplayPort-1" && echo "$MONITOR" | grep -q "Invalid"; do
		notify-send -e "Switching Monitor"
		(sudo ddcutil -b "$1" setvcp 0x60 "$2")
		MONITOR=$(sudo ddcutil -b "$1" getvcp 0x60)
	done
}

retryUntilSwitchedSecondPc() {
	notify-send -e "Switching Monitor to PC"
	while echo "$MONITOR" | grep -qv "DisplayPort-1"; do
		notify-send -e "Switching Monitor"
		(sudo ddcutil -b "$1" setvcp 0x60 "$2")
		MONITOR=$(sudo ddcutil -b "$1" getvcp 0x60)
	done
}

retryUntilSwitchedLaptop() {
	notify-send -e "Switching Monitor to laptop"
	while echo "$MONITOR" | grep -q "DisplayPort-1" ; do
		notify-send -e "Switching Monitor"
		(sudo ddcutil -b "$1" setvcp 0x60 "$2")
		MONITOR=$(sudo ddcutil -b "$1" getvcp 0x60)
	done
}


case $1 in
	1)
		MONITOR=$(sudo ddcutil -b 5 getvcp 0x60)
		if expr "$MONITOR" : '.*0x0f' >/dev/null; then
			notify-send -e "Switching Monitor 1"
			retryUntilSwitchedLaptop "5" "0x13"
		else
			notify-send -e "Switching Monitor 1"
			retryUntilSwitchedMainPc "5" "0x0f"
		fi
		;;
	2)
		MONITOR=$(sudo ddcutil -b 7 getvcp 0x60)
		if expr "$MONITOR" : '.*0x0f' >/dev/null; then
			retryUntilSwitchedLaptop "7" "0x11"
		else
			notify-send -e "Switching Monitor 2"
			retryUntilSwitchedSecondPc "7" "0x0f"
		fi
		;;
esac
