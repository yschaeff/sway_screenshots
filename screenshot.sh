#!/bin/bash
set -e

#MENU="dmenu"
MENU="rofi -dmenu"

NOTIFY=$(pidof mako || pidof dunst) || true

FOCUSED=$(swaymsg -t get_tree | jq '.. | ((.nodes? + .floating_nodes?) // empty) | .[] | select(.focused and .pid) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
OUTPUTS=$(swaymsg -t get_outputs | jq -r '.[] | select(.active) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
WINDOWS=$(swaymsg -t get_tree | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
RECORDER=wf-recorder

REC_PID=$(pidof $RECORDER) || true

notify() {
    if [ $NOTIFY ]; then
        notify-send "$@"
    else
        echo NOTICE: notification daemon not active
        echo "$@"
    fi
}

if [ ! -z $REC_PID ]; then
    echo pid: $REC_PID
    kill -SIGINT $REC_PID
    notify "Screen recorder stopped" -t 2000
    exit 0
fi

CHOICE=`$MENU -u 6,7,8,9 -l 10 -p "How to make a screenshot?" << EOF
fullscreen
focused
select-window
select-output
region

record-focused
record-select-window
record-select-output
record-region
EOF` ||  (notify "Screenshot" "Cancelled" -t 700 && false)


mkdir -p $(xdg-user-dir PICTURES)/screenshots/

FILENAME="$(xdg-user-dir PICTURES)/screenshots/$(date +'%Y-%m-%d-%H%M%S_screenshot.png')"
RECORDING="$(xdg-user-dir PICTURES)/screenshots/$(date +'%Y-%m-%d-%H%M%S_recording.mp4')"

case "$CHOICE" in
    "fullscreen")
        grim "$FILENAME" ;;
    "region")
        slurp | grim -g - "$FILENAME" ;;
    "select-output")
        echo "$OUTPUTS" | slurp | grim -g - "$FILENAME" ;;
    "select-window")
        echo "$WINDOWS" | slurp | grim -g - "$FILENAME" ;;
    "focused")
        grim -g "$(eval echo $FOCUSED)" "$FILENAME" ;;
    "record-select-output")
        $RECORDER -g "$(echo "$OUTPUTS"|slurp)" -f "$RECORDING"
        REC=1 ;;
    "record-select-window")
        $RECORDER -g "$(echo "$WINDOWS"|slurp)" -f "$RECORDING"
        REC=1 ;;
    "record-region")
        $RECORDER -g "$(slurp)" -f "$RECORDING"
        REC=1 ;;
    "record-focused")
        $RECORDER -g "$(eval echo $FOCUSED)" -f "$RECORDING"
        REC=1 ;;
    *)
        grim -g "$(eval echo $CHOICE)" "$FILENAME" ;;
esac


if [ $REC ]; then
    notify "Recording" "Recording stopped: $RECORDING" -t 10000
    wl-copy < $RECORDING
else
    notify "Screenshot" "File saved as $FILENAME\nand copied to clipboard" -t 6000 -i $FILENAME
    wl-copy < $FILENAME
    feh $FILENAME
fi
