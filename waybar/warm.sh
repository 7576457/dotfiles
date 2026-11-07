#!/bin/sh
B="busctl --user"
P="rs.wl-gammarelay / rs.wl.gammarelay Temperature"
t=$($B get-property $P | cut -d' ' -f2)

if [ "$1" = toggle ]; then
  [ "$t" -lt 4600 ] && n=6500 || n=2700
  $B set-property $P q $n
  pkill -RTMIN+8 waybar
elif [ "$t" -lt 4600 ]; then
  echo '{"text":"[ WARM: On ]","class":"on"}'
else
  echo '{"text":"[ WARM: Off ]","class":"off"}'
fi
