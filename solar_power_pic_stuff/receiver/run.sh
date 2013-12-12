#!/bin/bash

tmp="/var/tmp/solapowa.tmp"
output="/var/tmp/solapowa.txt"

cd /mnt/nas0/works/solapowa/receiver || exit 1

while [ 1 ]; do
	sudo tcpdump -w a.dmp -c 1 -s 0 -i any 'udp and dst port 6392' 2>/dev/null
	./a.out | tee $tmp
	mv $tmp $output
	sleep 1
done
