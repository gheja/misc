#!/bin/bash

find . -maxdepth 1 -type f -printf '%TY%Tm%Td %f\n' | while read a; do
	ymd=`echo "$a" | cut -d ' ' -f 1`
	filename=`echo "$a" | cut -d ' ' -f 2-`
	
	[ -e $ymd ] || mkdir -v $ymd
	[ -e "$ymd/$filename" ] || mv -v "$filename" $ymd/
done
