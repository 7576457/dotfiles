#!/usr/bin/env bash

src="$HOME/dotfiles"
dst="$HOME/.config"

for item in "$src"/*; do
    name=$(basename "$item")
    [ $name = "install.sh" ] && continue
    if [ $name = "vscode" ]; then
        vscode_dst="$dst/Code/User"
        mkdir -p "$vscode_dst"

        printf "%-23s -> %s\n" "vscode/settings.json" "$vscode_dst/settings.json"
        ln -sfn "$item/settings.json" "$vscode_dst/settings.json"

        printf "%-23s -> %s\n" "vscode/keybindings.json" "$vscode_dst/keybindings.json"
        ln -sfn "$item/keybindings.json" "$vscode_dst/keybindings.json"

        continue
    fi

    # echo "$item -> $dst/$name"
    printf "%-9s -> %s\n" "$name" "$dst/$name"
    ln -sfn "$item" "$dst/$name"   
done

