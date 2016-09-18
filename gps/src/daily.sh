#! /bin/sh
#
# daily.sh - generate GPS daily archive
#
# Noboru OBATA <obata3@gmail.com>

usage () {
    cat <<EOF
Usage: $0 [OPTION]... GPXFILE

  -d YYYY-MM-DD    extract this date
  -p DISTANCE      extract every DISTANCE (default 6m)
EOF
}

recorded_period () {
    echo $( date -d $( grep '<time>' "$1" | sed -n -e '2s/^.*>\(2.*Z\)<.*/\1/p' ) +"%Y%m%d%H%M%S" )
    echo $( date -d $( grep '<time>' "$1" | sed -n -e '$s/^.*>\(2.*Z\)<.*/\1/p' ) +"%Y%m%d%H%M%S" )

    return 0
} 

DATE=today
DISTANCE=6m

while [ x"$1" != x ]; do
    case $1 in
    -d) DATE=$2; shift; shift; continue;;
    -p) DISTANCE=$2; shift; shift; continue;;
    -h) usage; exit 0;;

    -*) echo $0: Try \`$0 -h\' for more information. 1>&2; exit 1;;
    *) break;;
    esac
done

if [ 0 -eq $# ]; then usage; exit 0; fi

GPXFILES=

while [ 0 -lt $# ]; do
    GPXFILES="$GPXFILES -f \"$1\""
    shift
done

OUTPUTDATE=$( date -d "$DATE" +"%Y%m%d" )
STARTTIME=$( date -d "$( date -d "$DATE" +"%Y-%m-%d 3am JST" ) " -u +"%Y%m%d%H%M%S" )
STOPTIME=$( date -d "$( date -d "$DATE" +"%Y-%m-%d 3am JST" ) + $(( 60 * 60 * 24 - 1 )) seconds " -u +"%Y%m%d%H%M%S" )

eval gpsbabel -t -i gpx $GPXFILES \
    -x track,start=$STARTTIME,stop=$STOPTIME \
    -x position,distance="$DISTANCE" \
    -o gpx -F .$OUTPUTDATE.gpx || exit 1

gpsbabel -t -i gpx -f .$OUTPUTDATE.gpx \
    -x track,move=+9h \
    -o kml -F .$OUTPUTDATE.kml || exit 1

sed -e 's/Time: \(....-..-..\)T\(..:..:..\)Z/Time: \1 \2/' .$OUTPUTDATE.kml \
    | awk '/Altitude:/ { printf "%s %.1f m %s\n", $1, $2 * 0.3048, $4; } !/Altitude:/ { print }' \
    | grep -v 'Longitude:\|Latitude:' \
    | awk '/^<table>$/ { printf "%s", $1; } !/^<table>$/ { print }' \
> $OUTPUTDATE.kml || exit 1

rm -f .$OUTPUTDATE.gpx .$OUTPUTDATE.kml

echo "$( grep TP $OUTPUTDATE.kml | wc -l ) point(s)"

exit 0
