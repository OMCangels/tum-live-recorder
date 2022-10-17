#!/bin/bash
# by Sebastian Steiner (sebastian.steiner@tum.de)
# mostly copied from Max-Joseph Krempl (krempl@in.tum.de)

RECORD_TIMEOUT="03:00:00" # Maximum recording length

CURRENT_DIR="$(dirname "$0")"

error() {
  echo -e "$@"
  exit 1
}

echo "$0"
echo "$1"
echo "$2"
echo "$3"

if [ $# -ge 3 ]; then
  SAVE_DIR=$1
  FILE_NAME="$2"
  STREAM_URL="$3"
else
  error "Usage:  $(basename "$0") {save directory} {file name} {stream url}"
fi

# determine output file (avoid overwrite)
FILE="$SAVE_DIR/$FILE_NAME.mp4"
i=2
while [ -f "$FILE" ]; do
  FILE="$SAVE_DIR/${FILE_NAME}_$i.mp4"
  ((i += 1))
done

# save stream to output file
FFMPEG_INPUT="$CURRENT_DIR/.ffmpeg_input"
echo "" >"$FFMPEG_INPUT"
ffmpeg <"$FFMPEG_INPUT" -hide_banner -loglevel info -stats -i "$STREAM_URL" -t $RECORD_TIMEOUT -c copy -n "$FILE" & #-progress "$FFMPEG_OUTPUT"
FFMPEG_PID=$!
echo "-" >"$FFMPEG_INPUT" # decrease ffmpeg's loglevel verbosity to "warning" (after info was printed)

sleep 2
echo -e "\n\033[0;31m⬤\033[1m Recording\033[0m '$URL' stream to '$FILE'... ($(date +%H:%M:%S))\n(CRL-C to stop recording)\n"

interrupt_handler() {
  [[ $INTERRUPTED -eq 1 ]] && return 0
  INTERRUPTED=1
  echo -e "\n\n\033[1m◼︎ Stopping recording...\033[0m ($(date +%H:%M:%S))"
  #kill -INT $FFMPEG_PID
  echo "q" >"$FFMPEG_INPUT" # tell ffmpeg to quit
  wait $FFMPEG_PID
  rm "$FFMPEG_INPUT"
}
INTERRUPTED=0
trap interrupt_handler SIGINT && wait $FFMPEG_PID

interrupt_handler # if ffmpeg quits naturally, also use interrupt_handler to perform cleanup
