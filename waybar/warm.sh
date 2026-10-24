#!/bin/sh
WARM=2700        # тёплая температура, K
NORMAL=6500      # обычная температура, K
DURATION=3000    # длительность перехода, мс
START=warm       # состояние после входа: warm или normal

SVC="rs.wl-gammarelay"
OBJ="/"
IFACE="rs.wl.gammarelay"
LABEL=/tmp/warm.label
LOCK=/tmp/warm.lock
THRESH=$(( (WARM + NORMAL) / 2 ))

get_temp() {
  busctl --user get-property $SVC $OBJ $IFACE Temperature | cut -d' ' -f2
}
set_temp() {
  busctl --user set-property $SVC $OBJ $IFACE Temperature q "$1"
}

case "$1" in
  daemon)
    rm -f "$LOCK" "$LABEL"
    wl-gammarelay-rs run &
    pid=$!
    h=$(date +%-H)
    if [ "$h" -ge 20 ] || [ "$h" -lt 7 ]; then t=$WARM; else t=$NORMAL; fi
    for i in $(seq 1 30); do
      set_temp "$t" 2>/dev/null && break
      sleep 0.1
    done
    wait $pid
    ;;
  toggle)
    [ -e "$LOCK" ] && exit 0
    touch "$LOCK"
    from=$(get_temp)
    if [ "$from" -lt "$THRESH" ]; then to=$NORMAL; else to=$WARM; fi
    start=$(( $(date +%s%N) / 1000000 ))
    while :; do
      now=$(( $(date +%s%N) / 1000000 ))
      el=$(( now - start ))
      [ "$el" -ge "$DURATION" ] && break
      n=$(( 3 - el * 3 / DURATION ))
      echo "{\"text\":\"[ WARM: $n ]\",\"class\":\"busy\"}" > "$LABEL"
      set_temp $(( from + (to - from) * el / DURATION ))
      pkill -RTMIN+8 waybar
      sleep 0.05
    done
    set_temp "$to"
    rm -f "$LABEL" "$LOCK"
    pkill -RTMIN+8 waybar
    ;;
  *)
    if [ -e "$LABEL" ]; then
      cat "$LABEL"
    else
      t=$(get_temp 2>/dev/null)
      if [ -n "$t" ] && [ "$t" -lt "$THRESH" ]; then
        echo '{"text":"[ WARM: On ]","class":"on"}'
      else
        echo '{"text":"[ WARM: Off ]","class":"off"}'
      fi
    fi
    ;;
esac
