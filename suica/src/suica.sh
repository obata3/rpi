#! /bin/bash

atexit() {
  [ x"${tmpdir}" != x ] && rm -rf "${tmpdir}"
}

trap atexit EXIT
trap 'trap - EXIT; atexit; exit 130' INT
trap 'trap - EXIT; atexit; exit 141' PIPE
trap 'trap - EXIT; atexit; exit 143' TERM

tmpdir="$( mktemp -d "/tmp/.${0##*/}.tmp.XXXXXX" )"
tmpdatafile="$tmpdir"/data.txt
tmpidfile="$tmpdir"/id.txt

cd /home/pi/rpi/suica/src || exit 100

lsusb -d 054c:06c3 > /dev/null || exit 99

echo -n "Touch Suica: " 1>&2

t=$( date "+%Y%m%d%H%M%S.%N" )

./read-suica.py >"$tmpdatafile" 2>"$tmpidfile" &
pypid=$!

# Wait until read-suica.py closes its stdout after reading the card.
while [ -e /proc/"$pypid"/fd/1 ]; do
  # Wait until file events such as begin written or deleted.
  which inotifywait >/dev/null \
    && inotifywait -qq /proc/"$pypid"/fd/1
  sleep 0.2
done

wcdata=$( wc <"$tmpdatafile" | sed -e 's/[ \t][ \t]*/ /g' -e 's/^  *//' )
wcid=$( wc -l <"$tmpidfile" | sed -e 's/[ \t][ \t]*/ /g' -e 's/^  *//' )

if [ x"$wcdata" != "x20 20 660" ]; then
  ./beep-error.sh
  cat "$tmpidfile" 1>&2
  cat "$tmpdatafile" 1>&2
  ./clear-reader.sh
  exit 98
elif [ x"$wcid" != "x1" ]; then
  ./beep-error.sh
  cat "$tmpidfile" 1>&2
  ./clear-reader.sh
  exit 97
else
  ./beep-suica.sh
fi
  
id=$( sed -e 's/.* ID[^=]*=\([^ ][^ ]*\) .*/\1/' "$tmpidfile" | tr '[:upper:]' '[:lower:]' )

mkdir -p "../data/$id"

datafile="../data/$id/$t.090f.hex"
mailto="obata3+suica-admin@gmail.com"

if [ -e "../data/$id/address" ]; then
  mailto="$( cat ../data/$id/address )"
else
  echo "put email address to data/$id/address"
fi

cp "$tmpdatafile" "$datafile"

new=$( diff -c $( find ../data/"$id" -type f -name '*.090f.hex' | sort -r | head -n 2 ) | grep '^\+' | wc -l )

output="$( sed -e 's/\(..\)/\1 /g' "$datafile" \
  | awk -i <( echo "BEGIN { "; cat ../StationCode/cache.awk; echo "}"; ) -f format.awk \
  | cat -n \
  | sort -rn \
  | awk '{ if (NR == 1) { printf "%6d\t%s %s %s ??? %s\n", $1, $2, $3, $4, yen($5) } else { if (NF == 5) { printf "%6d\t%s %s %s %s %s\n", $1, $2, $3, $4, yen($5 - r,1), yen($5); } else { printf "%6d\t%s %s %s %s %s #%s\n", $1, $2, $3, $4, yen($5 - r,1), yen($5), $6 } } r = $5 } function yen(y,z, s) { if(y>0&&z>0){s="+";}if(y<0){s="-";y=-y} if(y>1000) { return sprintf("\\%s%d,%03d",s,int(y/1000),y%1000) } else { return sprintf("\\%s%d",s,y) }}' \
  | sort -n \
  | sed -e 's/^.......//' \
  | sed -e 's/\\/\xC2\xA5/g' \
  | awk "BEGIN { n = "$new" } "'{ if (n-- > 0) { printf "%s  NEW!\n", $0 } else { print } }' )"

#echo "$output"

balance=$( cat "$datafile" | awk 'NR == 1 { b = strtonum("0x" substr($0, 23, 2) substr($0, 21, 2)); if (b > 1000) { printf "\\%d,%03d\n", int(b / 1000), b % 1000; } else { printf "\\%d\n", b;} exit; }' | sed -e 's/\\/\xC2\xA5/g' )

if [ x"$mailto" = x ]; then
  :
else
  echo -n "Sending to $mailto: " 1>&2
  echo "$output" | mutt -s "Suica残高 ""${balance}" "$mailto"
  echo 1>&2
fi

cd "../data/$id" && ../../src/erase-dup.sh

wait "$pypid"

exit 0
