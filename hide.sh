#!/bin/bash

# This script hides and shows focused windows with your favorite window manager or DE by using xdo to proceed

_Dependencies() {
    DEPS=( "wmctrl" "xdo" )

    for pkg in "${DEPS[@]}"; do
        [[ -z $(command -v $pkg) ]] \
        && notify-send "$pkg is not installed...exiting" \
        && exit 127
    done
}

TARGET=$(xdo id ${1})
ID_LIST="$XDG_RUNTIME_DIR/scratchpad_hidden.list"
ID_LIST_ALL="$XDG_RUNTIME_DIR/scratchpad_all.list"

case "$1" in
    -h) # Hide the currently focused window and add it to the list
        _Dependencies
        wmctrl -lx | awk '{print $1" "$3}' > "$ID_LIST_ALL"
        # using lowercases will match ids in $ID_LIST_ALL
        echo "$TARGET" | tr [:upper:] [:lower:] >> "$ID_LIST"
        xdo hide "$TARGET"
        notify-send 'Window hidden'
    ;;
    -u) 
        # Check if there are windows in the hidden list
        if [[ -f "$ID_LIST" ]] && [[ $(cat "$ID_LIST" | wc -l) -gt 0 ]]; then
            # Show the first hidden window from the list
            ID=$(head -n 1 "$ID_LIST")
            xdo show "$ID"
            # Remove the window ID from the list
            sed -i '1d' "$ID_LIST"
            notify-send 'Window shown'
        else
            notify-send 'No hidden windows to unhide'
        fi
    ;;
    -r) 
        # Show a list of hidden windows with rofi and allow the user to choose one to unhide
        if [[ -f "$ID_LIST" ]] && [[ $(cat "$ID_LIST" | wc -l) -gt 0 ]]; then
            HIDDEN=$(cat $ID_LIST)

            # Creating a rofi menu
            N=$(for w in $HIDDEN; do
                NAME=$(wmctrl -lx | grep "$w" | awk '{print $3}')
                [[ -n "$NAME" ]] && echo "$w $NAME" || echo "$w"
            done | rofi -dmenu -no-custom -format i -p 'Unhide a window: ')

            if [[ -n "$N" ]]; then
                ID=$(echo "$HIDDEN" | sed -n "$((N+1))p")
                xdo show "$ID"
                # Remove the selected window ID from the list
                sed -i "/${ID}/d" "$ID_LIST"
            fi
        else
            notify-send 'No hidden windows to unhide'
        fi
    ;;
esac
