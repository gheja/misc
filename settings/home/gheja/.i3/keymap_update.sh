#!/bin/bash

export PATH="/usr/bin:/bin:$PATH"

setxkbmap -print | grep -q 'qwerty'
if [ $? == 0 ]; then
	setxkbmap hu
else
	setxkbmap us
fi
