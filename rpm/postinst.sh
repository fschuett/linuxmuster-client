#! /bin/bash
# postinst script for linuxmuster
#
# Thomas Schmitt <schmitt@lmz-bw.de>
# 18.12.2009
# modified for openSUSE Linux by Frank Schütte <fschuett@gymnasium-himmelsthuer.de>
# 2011
# see: dh_installdeb(1)
set -e

%{fillup_and_insserv -y boot.linuxmuster-client-early}

# read default variables
. /usr/share/linuxmuster-client/config || exit 1
. ${USERCONFIG} || exit 1

# adding administrator to sudoers
if [ -e /etc/sudoers ]; then
	if ! grep -q ^$ADMINISTRATOR /etc/sudoers; then
		echo "Adding $ADMINISTRATOR to sudoers ..."
		echo >> /etc/sudoers
		echo "# linuxmuster: $ADMINISTRATOR may gain root privileges" >> /etc/sudoers
		echo "$ADMINISTRATOR ALL=(ALL) ALL" >> /etc/sudoers
	fi
fi
# adding printoperators group to cups system groups
if [ -e /etc/cups/cupsd.conf ]; then
	if grep -q ^SystemGroup /etc/cups/cupsd.conf; then
		if ! grep ^SystemGroup /etc/cups/cupsd.conf | grep -q $PRINTERADMINS; then
			echo "Adding group $PRINTERADMINS to cupsd system groups ..."
			cp /etc/cups/cupsd.conf /etc/cups/cupsd.conf.old
			sed -e "s/^SystemGroup.*/SystemGroup sys root $PRINTERADMINS/" /etc/cups/cupsd.conf.old > /etc/cups/cupsd.conf
			if [ 0%{suse_version} -gt 1230 ]; then
			    systemctl restart cups.service
			else
			    /etc/init.d/cups restart
			fi
		fi
	fi
fi

	# remove hal's obsolete mountpolicies
cfile=/etc/hal/fdi/policy/mountpolicies.fdi
if [ -e "$cfile" ]; then
	mv $cfile ${cfile}.dpkg-old
	[ -e /etc/init.d/dbus ] && /etc/init.d/dbus restart
fi
	# remove ivman from Xsession.options
cfile=/etc/X11/Xsession.options
if [ -s "$cfile" ]; then
	if grep -q use-session-ivman $cfile; then
		cp $cfile ${cfile}.dpkg-old
		grep -v use-session-ivman ${cfile}.dpkg-old > $cfile
	fi
fi

	# remove ivman's default
cfile=/etc/default/ivman
[ -e "$cfile" ] && mv $cfile ${cfile}.dpkg-old
	# remove ivman script from dapper
cfile=/etc/X11/ivman-xsession
[ -e "$cfile" ] && mv $cfile ${cfile}.dpkg-old

# install start script
%{fillup_and_insserv -f -y linuxmuster-client}

# configure PAM
echo "Configure PAM ..."
[ -e /etc/pam.d/xdm ] && /usr/sbin/pam-config --service xdm -a --mount
/usr/sbin/pam-config --service login -a --mount
/usr/sbin/pam-config -a --group

# patch config files
TIMESTAMP=/usr/share/linuxmuster-client/.current
[ -e $TIMESTAMP ] && rm -f $TIMESTAMP
if [ -e /usr/share/linuxmuster-client/update-client-config ]; then
    /usr/share/linuxmuster-client/update-client-config
fi

echo "Note: You have to reboot the client if you have installed the package for the first time!"

exit 0
