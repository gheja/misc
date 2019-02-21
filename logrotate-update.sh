#!/bin/bash

run()
{
	local root="$1"
	local i
	
	# known ignored: create, copytruncate, prerotate, postrotate, run-parts, sharedscripts
	local expression='(^\s*(daily|weekly|monthly|rotate|compress|delaycompress|missingok|notifempty).*)'
	
	# we need logrotate.conf
	if [ ! -f "$root/etc/logrotate.conf" ]; then
		return
	fi
	
	# find and update all configs in logrotate.d
	if [ -d "$root/etc/logrotate.d" ]; then
		for i in $root/etc/logrotate.d/*; do
			# skip configs that are not updateable
			cat $i | grep -Eq '### skip logrotate-update'
			if [ $? == 0 ]; then
				continue
			fi
			
			# skip configs that does not need updating
			cat $i | grep -Eq "${expression}"
			if [ $? != 0 ]; then
				continue
			fi
			
			echo "Updating $i..."
			
			# update inplace
			sed -i -r "s/${expression}/#\\1/g" $i
		done
	fi
	
	cat >$root/etc/logrotate.conf.tmp <<EOF
daily
rotate 9999
missingok
create
compress
delaycompress
dateext
dateformat .%Y%m%d_%s

include /etc/logrotate.d

/var/log/wtmp {
    create 0664 root utmp
}

/var/log/btmp {
    create 0660 root utmp
}
EOF
	
	checksum=`md5sum "$root/etc/logrotate.conf" | awk '{ print $1; }'`
	
	# replace known default configs
	echo "$checksum" | grep -Eq '^(176edd439a499501372cf3d04e795810|b7398ef6f3da393264e67ff7dbd329fb)$'
	if [ $? == 0 ]; then
		echo "Updating $root/etc/logrotate.conf..."
		
		cat $root/etc/logrotate.conf.tmp > $root/etc/logrotate.conf
	fi
	
	
	# check if config cannot be replaced automatically
	diff -q $root/etc/logrotate.conf $root/etc/logrotate.conf.tmp >/dev/null
	
	if [ $? != 0 ]; then
		echo "Check $root/etc/logrotate.conf.tmp"
	else
		rm $root/etc/logrotate.conf.tmp
	fi
}

run /

if [ -d /jails ]; then
	for i in /jails/*; do
		if [ -d $i ]; then
			run $i
		fi
	done
fi
