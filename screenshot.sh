#!/bin/bash
set -e

## USER PREFERENCES ##
#MENU="dmenu"
MENU="rofi -i -dmenu -u 6,7,8,9"
RECORDER=wf-recorder
TARGET=$(xdg-user-dir PICTURES)/screenshots
TARGET_VIDEOS=$(xdg-user-dir VIDEOS)/recordings
NOTIFY=$(pidof mako || pidof dunst) || true
FOCUSED=$(swaymsg -t get_tree | jq '.. | ((.nodes? + .floating_nodes?) // empty) | .[] | select(.focused and .pid) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
OUTPUTS=$(swaymsg -t get_outputs | jq -r '.[] | select(.active) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
WINDOWS=$(swaymsg -t get_tree | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
REC_PID=$(pidof $RECORDER) || true

notify() {
    ## if the daemon is not running notify-send will hang indefinitely
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

CHOICE=`$MENU -l 10 -p "How to make a screenshot?" << EOF
Fullscreen
Focused
Select-window
Select-output
Region

Record-focused
Record-select-window
Record-select-output
Record-region
EOF`


mkdir -p $TARGET
mkdir -p $TARGET_VIDEOS
FILENAME="$TARGET/$(date +'%Y-%m-%d_%Hh%Mm%Ss_screenshot.png')"
RECORDING="$TARGET_VIDEOS/$(date +'%Y-%m-%d_%Hh%Mm%Ss_recording.mp4')"

case "$CHOICE" in
    "Fullscreen")
        grim "$FILENAME" ;;
    "Region")
        slurp | grim -g - "$FILENAME" ;;
    "Select-output")
        echo "$OUTPUTS" | slurp | grim -g - "$FILENAME" ;;
    "Select-window")
        echo "$WINDOWS" | slurp | grim -g - "$FILENAME" ;;
    "Focused")
        grim -g "$(eval echo $FOCUSED)" "$FILENAME" ;;
    "Record-select-output")
        $RECORDER -g "$(echo "$OUTPUTS"|slurp)" -f "$RECORDING"
        REC=1 ;;
    "Record-select-window")
        $RECORDER -g "$(echo "$WINDOWS"|slurp)" -f "$RECORDING"
      
      REC=1 ;;
    "Record-region")
        $RECORDER -g "$(slurp)" -f "$RECORDING"
        REC=1 ;;
    "Record-focused")
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
