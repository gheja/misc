#!/bin/bash

if [ $# -lt 1 ]; then
	echo "$0 <domain> [domain2] [domain3]"
	exit 1
fi

param="$1"

if [ -e "${param}" ]; then
	key="${param}"
elif  [ -e "${param}.key" ]; then
	key="${param}.key"
elif  [ -e "files/${param}" ]; then
	key="files/${param}"
elif  [ -e "files/${param}.key" ]; then
	key="files/${param}.key"
else
	echo "Could not find private key for ${param}, exiting."
	exit 1
fi

domain="$param"
now=`date +%Y%m%d%H%M%S`

{
	cat openssl_defaults.cnf
	
	echo "[alt_names]"
	
	i=1
	
	### SANs
	for j in $@; do
		echo "DNS.$i = $j"
		i=$((i + 1))
	done
} > /tmp/openssl_tmp.cnf

csr=$(echo "$key" | sed -r 's/\.key$//g')
csr="${csr}.${now}.csr"

openssl req -new -config /tmp/openssl_tmp.cnf -key ${key} -out ${csr} -subj "/C=HU/ST=Budapest/O=none/CN=${domain}"

echo "Certificate Signing Request: $csr"
