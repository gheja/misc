#!/bin/bash

# Auto-pause VLC when screensaver is activated and unpause when deactivated.
# Start VLC with remote control interface:
# vlc --extraintf rc --rc-host 127.0.0.1:63999

export DISPLAY=:0.0
export PATH=/usr/bin:/bin

last_active=-1
started=-1
was_playing=-1
pause_limit=1800

if [ -e /tmp/screensaver_vlc.lock ]; then
	a=`date +%s`
	b=`stat --format %Y /tmp/screensaver_vlc.lock`
	
	if [ $((a - b)) -lt 65 ]; then
		exit 0
	fi
fi

while [ 1 ]; do
	now=`date +%s`
	
	mate-screensaver-command --query 2>/dev/null | grep -q 'The screensaver is inactive'
	
	if [ $? == 0 ]; then
		active=0
	else
		active=1
	fi
	
	if [ $active == 1 ] && [ $last_active == 0 ]; then
		# lock
		started=$now
		was_playing=0
		
		echo "status" | nc -q 1 127.0.0.1 63999 2>/dev/null| grep -q '( state playing )'
		
		if [ $? == 0 ]; then
			was_playing=1
		fi
		
		if [ $was_playing == 1 ]; then
			echo "pause" | nc -q 1 127.0.0.1 63999 2>/dev/null >/dev/null
		fi
	elif [ $active == 0 ] && [ $last_active == 1 ]; then
		# unlock
		
		if [ $((now - started)) -lt $pause_limit ] && [ $was_playing == 1 ]; then
			echo "play" | nc -q 1 127.0.0.1 63999 2>/dev/null >/dev/null
		fi
	fi
	
	last_active=$active
	
	touch /tmp/screensaver_vlc.lock
	
	sleep 1
done
