#!/bin/bash

# Get ID of focused window
focusedWindow=$(yabai -m query --windows | jq '.[] | select(."has-focus" == true) | .id')

# Get IDs of the two monitors
monitor1=$(yabai -m query --displays | jq '.[] | select(.index == 1) | .index')
monitor2=$(yabai -m query --displays | jq '.[] | select(.index == 2) | .index')

# Get the current space index on the first monitor
current_space_monitor1=$(yabai -m query --spaces --display "$monitor1" | jq '.[] | select(."is-visible" == true) | .index')

# Get the current space index on the second monitor
current_space_monitor2=$(yabai -m query --spaces --display "$monitor2" | jq '.[] | select(."is-visible" == true) | .index')

# Get windows on the current space of the first monitor
windows_on_space1=$(yabai -m query --windows | jq --arg space "$current_space_monitor1" '.[] | select(.space == ($space | tonumber)) | .id')

# Get windows on the current space of the second monitor
windows_on_space2=$(yabai -m query --windows | jq --arg space "$current_space_monitor2" '.[] | select(.space == ($space | tonumber)) | .id')

# Move windows from the current space of monitor 1 to the current space of monitor 2
for win in $windows_on_space1; do
  yabai -m window "$win" --display "$monitor2"
done

# Move windows from the current space of monitor 2 to the current space of monitor 1
for win in $windows_on_space2; do
  yabai -m window "$win" --display "$monitor1"
done

# Focus original window
yabai -m window "$focusedWindow" --focus
