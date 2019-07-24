#!/bin/bash

DUNST=`pidof dunst`

FOCUSED=$(swaymsg -t get_tree | jq '.. | (.nodes? // empty)[] | select(.focused and .pid) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
OUTPUTS=$(swaymsg -t get_outputs | jq -r '.[] | select(.active) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
WINDOWS=$(swaymsg -t get_tree | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')

CHOICE=`dmenu -l 10 -p "How to make a screenshot?" << EOF
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

EOF`


FILENAME="$(xdg-user-dir PICTURES)/screenshots/$(date +'%Y-%m-%d-%H%M%S_screenshot.png')"
RECORDING="$(xdg-user-dir PICTURES)/screenshots/$(date +'%Y-%m-%d-%H%M%S_recording.mp4')"

if [ "$CHOICE" = fullscreen ]
then
    grim "$FILENAME"
elif [ "$CHOICE" = region ]
then
    slurp | grim -g - "$FILENAME"
elif [ "$CHOICE" = select-output ]
then
    echo $OUTPUTS | slurp | grim -g - "$FILENAME"
elif [ "$CHOICE" = select-window ]
then
    echo $WINDOWS | slurp | grim -g - "$FILENAME"
elif [ "$CHOICE" = focused ]
then
    grim -g "$(eval echo $FOCUSED)" "$FILENAME"
elif [ "$CHOICE" = 'record-builtin' ]
then
    /home/yuri/repo/third-party/wf-recorder/build/wf-recorder -o eDP-1 -f "$RECORDING"
    REC=1
elif [ "$CHOICE" = 'record-external' ]
then
    /home/yuri/repo/third-party/wf-recorder/build/wf-recorder -o DP-1 -f "$RECORDING"
    REC=1
elif [ "$CHOICE" = 'record-region' ]
then
    /home/yuri/repo/third-party/wf-recorder/build/wf-recorder -g "$(slurp)" -f "$RECORDING"
    REC=1
elif [ "$CHOICE" = 'record-focused' ]
then
    /home/yuri/repo/third-party/wf-recorder/build/wf-recorder -g "$(eval echo $FOCUSED)" -f "$RECORDING"
    REC=1
elif [ "$CHOICE" = 'record-stop' ]
then
    killall -SIGINT wf-recorder
    if [ $DUNST ]; then
        notify-send "Killing screen recorder" -t 2000
    fi
    exit
elif [ -z "$CHOICE" ]
then
    if [ $DUNST ]; then
        notify-send "Screenshot" "Cancelled" -t 1000
    fi
    exit 0
else
    grim -g "$(eval echo $CHOICE)" "$FILENAME"
fi

if [ $REC ]; then
    notify-send "Recording" "Recording stopped: $RECORDING" -t 10000
else
    if [ $DUNST ]; then
        notify-send "Screenshot" "File saved as $FILENAME\nand copied to clipboard" -t 6000 -i $FILENAME
    fi
    wl-copy < $FILENAME
    feh $FILENAME
fi
