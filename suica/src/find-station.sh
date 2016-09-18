#! /bin/bash

export LANG=C

dir=../StationCode

mkdir -p "$dir" || exit 99
cd "$dir" || exit 98

if [ -e 0.csv ]; then
  :
else
  wget -O StationCode.xls http://www.denno.net/SFCardFan/sendexcel.php || exit 97
  xlhtml -csv -xp:0 -m StationCode.xls \
    | iconv -f CP932 -t utf-8 > 0.csv || exit 96
fi

grepkey="$( printf "^\"%x\",\"%x\",\"%x\"\n" $(( 0x$1 )) $(( 0x$2 )) $(( 0x$3 )) )"

line="$( grep "$grepkey" cache.csv )"
if [ $? -ne 0 ]; then
  line="$( grep "$grepkey" 0.csv )" || exit 1  # not found
  echo "$line" >> cache.csv
  awk -F , '{ print "st[" '$((0x$1))'"," '$((0x$2))' ","'$((0x$3))'"]=" $6; }' >> cache.awk <<<"$line"
fi

awk -F , '{ print $6; }' <<<"$line" \
  | sed -e 's/^""*//' -e 's/""*$//'

exit 0
