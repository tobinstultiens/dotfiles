#!/bin/sh
monitorfile="monitor.dat"

if [ ! -f "$monitorfile" ]; then
	MONITOR1="PC"
	MONITOR2="PC"
else
	MONITORS=$(cat "$monitorfile")
	arrIN=(${MONITORS//|/ })
	MONITOR1=${arrIN[0]}
	MONITOR2=${arrIN[1]}
fi

store_values() {
	echo "${MONITOR1}|${MONITOR2}" > "$monitorfile"
}

case $1 in
	1)
		if [ "$MONITOR1" = "LAPTOP" ]; then
			(sudo ddcutil -b 5 setvcp 0x60 0x0f)
			export MONITOR1="PC"
		else
			(sudo ddcutil -b 5 setvcp 0x60 0x13)
			echo "$MONITOR1"
			export MONITOR1="LAPTOP"
		fi
		;;
	2)
		if [ "$MONITOR2" = "LAPTOP" ]; then
			(sudo ddcutil -b 7 setvcp 0x60 0x0f)
			echo "Switch to PC"
			MONITOR2="PC"
		else
			(sudo ddcutil -b 7 setvcp 0x60 0x11)
			(sudo ddcutil -b 7 setvcp 0x60 0x11)
			(sudo ddcutil -b 7 setvcp 0x60 0x11)
			echo "Switch to Laptop"
			MONITOR2="LAPTOP"
		fi
		;;
esac

store_values
