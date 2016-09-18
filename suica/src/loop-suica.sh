#! /bin/bash

cd /home/pi/rpi/suica/src

mkdir -p ../debug

while :; do
  t=$( date "+%Y%m%d%H%M%S" )
  bash -x ./suica.sh 2>&1 | tee ../debug/"$t".txt
  if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    sleep 5
  fi
done
