#!/bin/bash

DUNST=`pidof dunst`

WINDOWS=`swaymsg -t get_tree | jq '.. | (.nodes? // empty)[] | select(.visible and .pid) | .rect | "\(.x),\(.y) \(.width)x\(.height)"'`
FOCUSED=`swaymsg -t get_tree | jq '.. | (.nodes? // empty)[] | select(.focused and .pid) | .rect | "\(.x),\(.y) \(.width)x\(.height)"'`

CHOICE=`dmenu -l 10 -p "How to make a screenshot?" << EOF
fullscreen
region
focused
$WINDOWS
EOF`


FILENAME="$(xdg-user-dir PICTURES)/screenshots/$(date +'%Y-%m-%d-%H%M%S_screenshot.png')"

if [ "$CHOICE" = fullscreen ]
then
    grim "$FILENAME"
elif [ "$CHOICE" = region ]
then
    grim -g "$(slurp)" "$FILENAME"
elif [ "$CHOICE" = focused ]
then
    grim -g "$(eval echo $FOCUSED)" "$FILENAME"
elif [ -z "$CHOICE" ]
then
    if [ $DUNST ]; then
        notify-send "Screenshot" "Cancelled" -t 1000
    fi
    exit 0
else
    grim -g "$(eval echo $CHOICE)" "$FILENAME"
fi

wl-copy < $FILENAME
feh $FILENAME
if [ $DUNST ]; then
    notify-send "Screenshot" "File saved as $FILENAME\nand copied to clipboard" -t 6000 -i $FILENAME
fi

