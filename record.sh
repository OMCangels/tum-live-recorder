#!/bin/bash
# by Max-Joseph Krempl (krempl@in.tum.de)

DIR="$(dirname "$0")"
saveStream="$DIR/_saveStream.sh"
getStreamURL="$DIR/_getStreamURL.sh"

OUTPUT_DIR="$DIR/saved" # Folder where recordings are saved to

error() {
  echo -e "$@"
  exit 1
}

date=$(which gdate)
[[ -z "$date" ]] && date="date" # Use gdate if it's installed (required on macOS/BSD)

[ ! -d "$OUTPUT_DIR" ] && mkdir "$OUTPUT_DIR" # Create output directory if it doesn't exist

[ ! -f "$saveStream" ] && error "Couldn't find script \"$saveStream\""
[ ! -f "$getStreamURL" ] && error "Couldn't find script \"$getStreamURL\""

# first argument is always start time
if [ $# -le 1 ]; then
  CMD="$(basename "$0")"
  echo "Usage:     $CMD {time/date} [file name] {TUM Live URL}"
  echo "Or:        $CMD {time/date} [file name] \"True\" {stream URL (--> TUM Live -> copy HLS URL)}"
  echo ""
  echo "Examples:  $CMD now https://live.rbg.tum.de/w/set/21876"
  echo "           $CMD 13:15 https://live.rbg.tum.de/w/set/21876"
  echo "           $CMD \"tomorrow 08:15\" https://live.rbg.tum.de/w/set/21876"
  echo "           $CMD \"wed 08:15\" https://live.rbg.tum.de/w/set/21876"
  echo "           $CMD 08:15 SET https://live.rbg.tum.de/w/set/21876"
  echo "Or:        $CMD 08:15 SET True https://stream.lrz.de/vod/_definst_/mp4:tum/RBG/set_2022_10_13_11_00COMB.mp4/playlist.m3u8"
  exit 1
fi

# Prevents computer from sleeping while script is running, if caffeinate is installed (macOS/BSD)
[[ -n "$(which caffeinate)" ]] && caffeinate -imsw $$ &

TARGET_TIME=$($date -d "$1" +%s) || exit 1
echo "Recording starts on:  $($date -d "$1")"

# countdown until recording starts
CURRENT_TIME=$(date +%s)
while [[ $CURRENT_TIME -lt $TARGET_TIME ]]; do
  DELTA_TIME=$((TARGET_TIME - CURRENT_TIME - 1))
  COUNTDOWN="$($date -ud "@$DELTA_TIME" +%H:%M:%S)"
  [ $DELTA_TIME -ge 86400 ] && COUNTDOWN="$((DELTA_TIME / 86400)) day(s) and $COUNTDOWN"
  echo -ne "\r$COUNTDOWN\033[0K" 1>&2
  sleep 1
  CURRENT_TIME=$(date +%s)
done
echo -e "\n" 1>&2

# default file name
FILE_NAME="$(date +%Y-%m-%d)"

# get Stream URL to record
STREAM_URL=""
if [ $# -eq 2 ]; then
  # time + TUM Live URL --> use curl to get stream url
  STREAM_URL=$($getStreamURL "$2")
  [[ "$STREAM_URL" = "" ]] && error "No stream url found. ($2)
  Stream currently not live? Or login required to access course?"

elif [ $# -eq 3 ] && [ "$2" != "True" ]; then
  # time + file name + TUM Live URL --> use curl to get stream url
  FILE_NAME="$2"
  STREAM_URL=$($getStreamURL "$3")
  [[ "$STREAM_URL" = "" ]] && error "No stream url found. ($3)
  Stream currently not live? Or login required to access course?"

elif [ $# -eq 3 ] && [ "$2" = "True" ]; then
  # time + "True" + HLS URL given in 3rd arg, no curl needed
  STREAM_URL="$3"

elif [ $# -eq 4 ] && [ "$3" = "True" ]; then
  # time + file name in 2nd arg + "True" + HLS URL in 3rd arg, no curl needed
  FILE_NAME="$2"
  STREAM_URL="$4"
else
  error "Args:" "$@"
fi

# start recording
$saveStream "$OUTPUT_DIR" "$FILE_NAME" "$STREAM_URL"
