#! /bin/bash

mkdir -p md5

for i in *.090f.hex; do
  md5=$( md5sum "$i" ) || exit 1
  md5=$( echo "$md5" | awk '{ print $1 }' ) || exit 1
  len=$( echo "$md5" | awk '{ printf "%s", $1 }' | wc -c ) || exit 1
  [ $len -eq 32 ] || exit 1

  if [ -h "md5/$md5" ]; then
    a=$( readlink -e "$i" ) || exit 1
    b=$( readlink -e "md5/$md5" ) || exit 1
    if [ x"$a" == x"$b" ]; then
      :
    else
      rm -f "$i"
    fi
  else
    ln -s ../"$i" "md5/$md5" || exit 1
  fi
done
