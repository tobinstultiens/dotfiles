#!/bin/sh

# Retrieve the screensaver timeout
timeout=$(xset q | grep 'timeout:' | awk '{print $2}')

# When the timeout is equal to 0 it means the screensaver is off.
if [ "$timeout" -eq 0 ]; then
	xset s 120 120
	notify-send "Turned on the screensaver"
else
	xset s off && xset -dpms
	notify-send "⚠ Disabled the screensaver"
fi
