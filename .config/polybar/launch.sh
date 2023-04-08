#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

BAR_NAME=example
BAR_CONFIG=/home/$USER/.config/polybar/config.ini

PRIMARY=$(xrandr --query | grep " connected" | grep "primary" | cut -d" " -f1)
OTHERS=$(xrandr --query | grep " connected" | grep -v "primary" | cut -d" " -f1)

# Launch on second monitor
MONITOR=DP-2 polybar --reload $BAR_NAME &
sleep 1


# Launch on all other monitors
for m in $PRIMARY; do
 MONITOR=$m polybar --reload $BAR_NAME &
done

## Launch Polybar, using default config location ~/.config/polybar/config
#for m in $(polybar --list-monitors | cut -d":" -f1); do
#    MONITOR=$m polybar --reload example &
#done

echo "Polybar launched..."
