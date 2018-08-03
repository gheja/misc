#!/bin/bash

if [ $# -lt 1 ]; then
	echo "$0 <csr>"
	exit 1
fi

param="$1"

if [ -e "$param" ]; then
	csr="${param}"
elif  [ -e "${param}.csr" ]; then
	csr="${param}.csr"
elif  [ -e "files/${param}" ]; then
	csr="files/${param}"
elif  [ -e "files/${param}.csr" ]; then
	csr="files/${param}.csr"
else
	echo "Could not find CSR ${param}, exiting."
	exit 1
fi

key=$(echo "$csr" | sed -r 's/\.[0-9]+\.csr$/\.key/g')
crt=$(echo "$csr" | sed -r 's/\.csr$/\.crt/g')
tmp=`tempfile`

./dehydrated --signcsr $csr --full-chain --challenge dns-01 --hook ./dehydrated_hook.sh 2>&1 | tee $tmp

# TODO: a CRT-ba belerakni a kimenetet... (a --out nem mukodik)
rm $tmp
