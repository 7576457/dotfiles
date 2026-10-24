#!/bin/bash

CFG="$HOME/.config/niri/binds.kdl"

[ -f "$CFG" ] || {
    notify-send "Niri" "Файл биндов не найден: $CFG"
    exit 1
}

declare -a labels
declare -a actions

while IFS='|' read -r key title action; do
    [ -z "$key" ] && continue

    labels+=("$(printf '%-28s %s' "$key" "$title")")
    actions+=("$action")
done < <(
    awk '
    /^binds[[:space:]]*\{/ { inb=1; next }
    inb && /^\}/ { inb=0; next }
    !inb || /^[[:space:]]*\/\// { next }

    /\{.*\}/ {
        key=$1
        title=""
        if (match($0, /hotkey-overlay-title="[^"]*"/)) {
            title=substr($0, RSTART+22, RLENGTH-23)
        }

        action=$0
        sub(/^[^{]*\{[[:space:]]*/, "", action)
        sub(/[[:space:]]*;?[[:space:]]*\}.*/, "", action)

        if (title == "") title=action
        print key "|" title "|" action
    }
    ' "$CFG"
)

[ ${#labels[@]} -eq 0 ] && exit 1

selected=$(
    printf '%s\n' "${labels[@]}" |
        fuzzel --dmenu --prompt "Binds: " --width 70 --lines 20
) || exit 0

for i in "${!labels[@]}"; do
    if [[ "${labels[$i]}" == "$selected" ]]; then
        action="${actions[$i]}"
        break
    fi
done

[ -z "${action:-}" ] && exit 0

# Выполняем действие
if [[ "$action" == spawn-sh\ * ]]; then
    cmd="${action#spawn-sh }"
    eval "$cmd"
elif [[ "$action" == spawn\ * ]]; then
    cmd="${action#spawn }"
    eval "$cmd" &
else
    name="${action%% *}"
    args="${action#"$name"}"
    args="${args# }"

    # Преобразуем имена действий KDL в CLI Niri
    name="${name//-/_}"

    case "$name" in
        focus_workspace|move_column_to_workspace)
            niri msg action "${name//_/-}" "$args"
            ;;
        *)
            niri msg action "${name//_/-}"
            ;;
    esac
fi
