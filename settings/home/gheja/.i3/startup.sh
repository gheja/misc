#!/bin/bash

export PATH="/usr/bin:/bin:$PATH"

sleep 2

~/.i3/screen_update.sh

setxkbmap us

nohup clipit &
