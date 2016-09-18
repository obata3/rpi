#! /bin/bash

PORT=25

#sudo sh -c 'echo '"$PORT"' > /sys/class/gpio/export'
#sudo sh -c 'echo out > /sys/class/gpio/gpio'"$PORT"'/direction'

beep () {
  echo 1 > /sys/class/gpio/gpio"$1"/value || return 1
  sleep "$2"
  echo 0 > /sys/class/gpio/gpio"$1"/value || return 2
}

beep "$PORT" 0.1 || exit 4
sleep 0.025 || exit 5
beep "$PORT" 0.1 || exit 6

exit 0
