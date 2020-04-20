#!/bin/bash

set -e

#MENU="dmenu"
MENU="rofi -dmenu"

NOTIFY=$(pidof mako || pidof dunst)

FOCUSED=$(swaymsg -t get_tree | jq '.. | ((.nodes? + .floating_nodes?) // empty) | .[] | select(.focused and .pid) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
OUTPUTS=$(swaymsg -t get_outputs | jq -r '.[] | select(.active) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
WINDOWS=$(swaymsg -t get_tree | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
RECORDER=wf-recorder

CHOICE=`$MENU -l 11 -p "How to make a screenshot?" << EOF
fullscreen
region
focused
select-output
select-window

record-builtin
record-external
record-region
record-focused
record-stop
EOF` ||  (notify-send "Screenshot" "Cancelled" -t 700 && false)


mkdir -p $(xdg-user-dir PICTURES)/screenshots/

FILENAME="$(xdg-user-dir PICTURES)/screenshots/$(date +'%Y-%m-%d-%H%M%S_screenshot.png')"
RECORDING="$(xdg-user-dir PICTURES)/screenshots/$(date +'%Y-%m-%d-%H%M%S_recording.mp4')"

case "$CHOICE" in
    "fullscreen")
        grim "$FILENAME"
        ;;
    "region")
        slurp | grim -g - "$FILENAME"
        ;;
    "select-output")
        echo $OUTPUTS | slurp | grim -g - "$FILENAME"
        ;;
    "select-window")
        echo $WINDOWS | slurp | grim -g - "$FILENAME"
        ;;
    "focused")
        grim -g "$(eval echo $FOCUSED)" "$FILENAME"
        ;;
    "record-builtin")
        $RECORDER -o eDP-1 -f "$RECORDING"
        REC=1
        ;;
    "record-external")
        $RECORDER -o DP-1 -f "$RECORDING"
        REC=1
        ;;
    "record-region")
        $RECORDER -g "$(slurp)" -f "$RECORDING"
        REC=1
        ;;
    "record-focused")
        $RECORDER -g "$(eval echo $FOCUSED)" -f "$RECORDING"
        REC=1
        ;;
    "record-stop")
        killall -SIGINT wf-recorder
        if [ $NOTIFY ]; then
            notify-send "Killing screen recorder" -t 2000
        fi
        exit
        ;;
    *)
        grim -g "$(eval echo $CHOICE)" "$FILENAME"
        ;;
esac


if [ $REC ]; then
    notify-send "Recording" "Recording stopped: $RECORDING" -t 10000
else
    if [ $NOTIFY ]; then
        notify-send "Screenshot" "File saved as $FILENAME\nand copied to clipboard" -t 6000 -i $FILENAME
    fi
    wl-copy < $FILENAME
    feh $FILENAME
fi
