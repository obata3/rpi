#! /bin/bash

cd /sys/bus/usb/drivers/usb || exit 99

unset device
for i in 1*; do
  if [ -e "$i"/idVendor ] && [ -e "$i"/idProduct ]; then
    v=$( cat "$i"/idVendor )
    p=$( cat "$i"/idProduct )
    if [ x"$v:$p" == x054c:06c3 ]; then
      device="$i"
      break
    fi
  fi
done 
 
[ x"$device" == x ] && exit 1

sudo sh -c 'echo -n '"$device"' > /sys/bus/usb/drivers/usb/unbind'
sleep 1.0
sudo sh -c 'echo -n '"$device"' > /sys/bus/usb/drivers/usb/bind'

exit 0
