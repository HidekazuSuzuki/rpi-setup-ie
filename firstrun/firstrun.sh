#!/bin/bash

set +e

CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_hostname rpi4-xxx
else
   echo rpi4-xxx >/etc/hostname
   sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\trpi4-xxx/g" /etc/hosts
fi
FIRSTUSER=`getent passwd 1000 | cut -d: -f1`
FIRSTUSERHOME=`getent passwd 1000 | cut -d: -f6`
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom enable_ssh
else
   systemctl enable ssh
fi
if [ -f /usr/lib/userconf-pi/userconf ]; then
   /usr/lib/userconf-pi/userconf 'ie-user' '$5$6QPxmcGbbd$1/CtRMdtM2sKhLmk4BqZySAEAOB4wFeM3S96rSBkS27'
else
   echo "$FIRSTUSER:"'$5$6QPxmcGbbd$1/CtRMdtM2sKhLmk4BqZySAEAOB4wFeM3S96rSBkS27' | chpasswd -e
   if [ "$FIRSTUSER" != "ie-user" ]; then
      usermod -l "ie-user" "$FIRSTUSER"
      usermod -m -d "/home/ie-user" "ie-user"
      groupmod -n "ie-user" "$FIRSTUSER"
      if grep -q "^autologin-user=" /etc/lightdm/lightdm.conf ; then
         sed /etc/lightdm/lightdm.conf -i -e "s/^autologin-user=.*/autologin-user=ie-user/"
      fi
      if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
         sed /etc/systemd/system/getty@tty1.service.d/autologin.conf -i -e "s/$FIRSTUSER/ie-user/"
      fi
      if [ -f /etc/sudoers.d/010_pi-nopasswd ]; then
         sed -i "s/^$FIRSTUSER /ie-user /" /etc/sudoers.d/010_pi-nopasswd
      fi
   fi
fi
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_wlan 'UCLab' '{PSK_VALUE}' 'JP'
   cp /boot/firmware/nmprofiles/*.nmconnection /etc/NetworkManager/system-connections/
   chmod 600 /etc/NetworkManager/system-connections/*.nmconnection
else
cat >/etc/wpa_supplicant/wpa_supplicant.conf <<'WPAEOF'
country=JP
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
ap_scan=1

update_config=1
network={
	ssid="UCLab"
	psk={PSK_VALUE}
   priority=10
}
network={
   ssid="innovation-hub-IoT"
   psk={PSK_VALUE}
   priority=0
}
network={
   ssid="innovation-hub-IoT5"
   psk={PSK_VALUE}
   priority=10
}
network={
   ssid="ComputerLab-IoT"
   psk={PSK_VALUE}
   priority=0
}
network={
   ssid="ComputerLab-IoT5"
   psk={PSK_VALUE}
   priority=10
}
network={
   ssid="SeminarRoom-A-IoT"
   psk={PSK_VALUE}
   priority=0
}
network={
   ssid="SeminarRoom-A-IoT5"
   psk={PSK_VALUE}
   priority=10
}

WPAEOF
   chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
   rfkill unblock wifi
   for filename in /var/lib/systemd/rfkill/*:wlan ; do
       echo 0 > $filename
   done
fi
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_keymap 'jp'
   /usr/lib/raspberrypi-sys-mods/imager_custom set_timezone 'Asia/Tokyo'
else
   rm -f /etc/localtime
   echo "Asia/Tokyo" >/etc/timezone
   dpkg-reconfigure -f noninteractive tzdata
cat >/etc/default/keyboard <<'KBEOF'
XKBMODEL="pc105"
XKBLAYOUT="jp"
XKBVARIANT=""
XKBOPTIONS=""

KBEOF
   dpkg-reconfigure -f noninteractive keyboard-configuration
fi
rm -f /boot/firstrun.sh
sed -i 's| systemd.run.*||g' /boot/cmdline.txt
exit 0
