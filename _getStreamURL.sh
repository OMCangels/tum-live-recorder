#!/bin/bash
# by Max-Joseph Krempl (krempl@in.tum.de)

EXT="m3u8"

if [ $# -ge 1 ]; then
  curl -s "$1" | grep -m1 ".$EXT" | sed "s|.*\(http.*\.${EXT}\).*|\1|g"
else
  echo "Usage:  $(basename "$0") {live.rbg.tum.de url}, course must not require login"
  exit 1
fi
