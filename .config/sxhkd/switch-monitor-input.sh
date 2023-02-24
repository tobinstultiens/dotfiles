#!/bin/sh

# Retrieve information on what input is being used.
PC=sudo ddcutil -b 7 getvcp 0x60
LAPTOP=sudo ddcutil -b 4 getvcp 0x60

if [[ "$PC" == *"DisplayPort-1"* ]]; then
	laptopSwitch
elif [[ "$PC" == *"HDMI-1"* ]]; then
	pcSwitch
fi

# Set the display inputs to laptop
function laptopSwitch{
sudo ddcutil -b 7 setvcp 0x60 0x11
sudo ddcutil -b 4 setvcp 0x60 0x11
}

# Set the display inputs to pc
function pcSwitch{
sudo ddcutil -b 7 setvcp 0x60 0x0f
sudo ddcutil -b 4 setvcp 0x60 0x12
}
