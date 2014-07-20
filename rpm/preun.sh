#!/bin/bash
# preun script for linuxmuster
#
if [ $1 -gt 0 ]; then
    exit 0;
fi

%{stop_on_removal linuxmuster-client boot.linuxmuster-client-early}
[ -e /usr/share/linuxmuster-client/.current ] && rm -f /usr/share/linuxmuster-client/.current
[ -e /etc/pam.d/xdm ] && /usr/sbin/pam-config --service xdm -d --mount
/usr/sbin/pam-config --service login -d --mount
/usr/sbin/pam-config -d --group

# restore kscreenlocker
file=/usr/share/kde4/libexec/kscreenlocker
if [ -e "${file}.disabled" ]; then
    [ -e "${file}" ] && rm -f "${file}"
    mv -f "${file}.disabled" "${file}"
fi
 
exit 0
