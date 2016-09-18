#! /bin/sh
#
# gengpx.sh - generate GPX format data from GPS device or file
#
# Noboru OBATA <obata3@gmail.com>

usage () {
    cat <<EOF
Usage: $0 [OPTION]... [DUMPFILE]

  -n     do not erace device data
  -p     just show the recorded period and exit
EOF
}

recorded_period () {
    echo $( date -d $( grep '<time>' "$1" | sed -n -e '2s/^.*>\(2.*Z\)<.*/\1/p' ) +"%Y%m%d%H%M%S" )
    echo $( date -d $( grep '<time>' "$1" | sed -n -e '$s/^.*>\(2.*Z\)<.*/\1/p' ) +"%Y%m%d%H%M%S" )

    return 0
} 

dump_read () {
    gpsbabel -i skytraq,erase=$2,baud=38400,initbaud=38400,no-output=0,dump-file=$1 -f /dev/ttyACM0 || return 1

    return 0
}

dump_to_gpx () {
    gpsbabel -t -i skytraq-bin -f "$1" -o gpx -F "$2" || return 1

    return 0
}


ERACE=1

while [ x"$1" != x ]; do
    case $1 in
    -n) ERACE=0; shift; continue;;
    -p) PERIODONLY=y; shift; continue;;
    -h) usage; exit 0;;

    -*) echo $0: Try \`$0 -h\' for more information. 1>&2; exit 1;;
    *) break;;
    esac
done

[ -e /dev/ttyACM0 ] || { echo $0: /dev/ttyACM0: No such file or directory 1>&2; exit 1; }

F=$( date +"%Y%m%d%H%M%S" )
if [ x"$PERIODONLY" = xy ]; then
    mkdir -p backup
    F=backup/"$F"
fi

DUMPFILE=

if [ 0 -eq $# ]; then
    dump_read $F.dump $ERACE || exit 1
    DUMPFILE=$F.dump
    GPXFILE=$F.gpx
elif [ 1 -eq $# ]; then
    DUMPFILE="$1"
    GPXFILE="${1%.*}.gpx"
fi

dump_to_gpx "$DUMPFILE" "$GPXFILE" || exit 1
BS=$( recorded_period "$GPXFILE" | head -1 ) || exit 1
ES=$( recorded_period "$GPXFILE" | tail -1 ) || exit 1
if [ x"$PERIODONLY" = xy ]; then
    echo "$BS"-"$ES"

    rm -f "$GPXFILE"
    exit 0
fi

mv "$GPXFILE" "$BS"-"$ES".gpx
echo $0: generated "$BS"-"$ES".gpx

exit 0

#gpsbabel -t -i skytraq-bin -f $F.dump -o gpx -F $F.gpx
#gpsbabel -t -i gpx -f $F.gpx -o kml -F $F.kml

#BZ=$( grep '<begin>\|<end>' $F.kml | head -2 | sed -e 's/^.*>2/2/' -e 's/Z<.*/Z/' | head -1 )
#EZ=$( grep '<begin>\|<end>' $F.kml | head -2 | sed -e 's/^.*>2/2/' -e 's/Z<.*/Z/' | tail -1 )

#BN=$( date -d "$BZ" +"%Y%m%d%H" )
#EN=$( date -d "$EZ" +"%Y%m%d%H" )

#i=0; while :; do N=$( date -d "$BZ + $(( i * 60 )) minutes" +"%Y%m%d%H" ); NS="$N"0000; NE="$N"5959; echo $NS - $NE; [ x"$N" = x"$EN" ] && break; i=$(( i + 1 )); done

#sed -e 's/Time: \(....-..-..\)T\(..:..:..\)Z/Time: \1 \2/' gps-160515-182950-6m.kml | awk '/Altitude:/ { printf "%s %.1f m %s\n", $1, $2 * 0.3048, $4; } !/Altitude:/ { print }' | grep -v 'Longitude:\|Latitude:' | awk '/^<table>$/ { printf "%s", $1; } !/^<table>$/ { print }' > gps-160515-182950-6m-JST.kml
