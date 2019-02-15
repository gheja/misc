#!/bin/bash

if [ $# != 3 ]; then
	echo "$0 <name> <user> <command>"
	exit 1
fi

name="$1"
user="$2"
command="$3"

file="/etc/systemd/system/$name.service"

if [ -e "$file" ]; then
	echo "$file: exists, exiting."
	exit 1
fi

cat > $file <<EOF
[Unit]
Description=$name
After=network.target

[Service]
Type=simple
User=$user
ExecStart=$command
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable $name
systemctl start $name
