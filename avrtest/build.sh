#!/bin/bash

for i in *.c; do
	a=`basename "$i" | sed -r 's/\.c$//g'`
	
	avr-gcc -mmcu=attiny13 -Os -o ${a}.elf ${a}.c
	
	avr-objcopy -O binary ${a}.elf ${a}.bin
done

du -b *.bin

