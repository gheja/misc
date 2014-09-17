#!/bin/bash

export PATH="/usr/bin:/bin:$PATH"

if [ $HOSTNAME == "gheja-work" ]; then
	xrandr --output LVDS1 --primary --mode 1366x768
	
	xrandr | grep -q 'VGA1 connected'
	if [ $? == 0 ]; then
		xrandr --output VGA1 --mode 1680x1050 --right-of LVDS1
	else
		xrandr --output VGA1 --off
	fi
fi
