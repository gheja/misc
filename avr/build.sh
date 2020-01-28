#!/bin/bash

if [ $# != 1 ]; then
	echo "$0 <program>"
	exit 1
fi

program="$1"

if [ ! -e "${program}.c" ]; then
	echo "${program}.c: file does not exist, exiting."
	exit 1
fi

avr-gcc -g -Os -mmcu=atmega328p ${program}.c -o ${program}.o || exit 1
avr-objcopy -j .text -j .data -O ihex ${program}.o ${program}.hex || exit 1

sudo avrdude -c usbasp -p m328p -U flash:w:${program}.hex
