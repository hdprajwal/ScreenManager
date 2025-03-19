#!/bin/bash

# ===========================================================================
# Screen Manager
# ===========================================================================
# Author: Prajwal HD (hdprajwal)
# GitHub: https://github.com/hdprajwal/ScreenManager
# Description:  A dynamic script to manage multiple display configurations in i3wm
#               with support for rotation, resolution, and custom layouts.
# ===========================================================================

# Set up logging - create log directory if it doesn't exist
LOG_DIR="$HOME/.local/share/screenmanager"
LOG_FILE="$LOG_DIR/screenmanager.log"
mkdir -p "$LOG_DIR"

# Redirect all output to log file and suppress console output
{
    # Get connected displays
    disconnected_displays=($(xrandr | grep " disconnected" | awk '{print $1}'))
    connected_displays=$(xrandr | grep " connected" | awk '{print $1}')
    displays=($connected_displays)
    display_count=${#displays[@]}

    echo "$(date): Script started"
    echo "$(date): Detected $display_count connected displays: ${displays[*]}"
    echo "$(date): Detected disconnected displays: ${disconnected_displays[*]}"

    # Function to restart i3
    restart_i3() {
        echo "$(date): Restarting i3"
        i3-msg restart
    }

    # Function to turn off disconnected displays
    turn_off_disconnected() {
        for disp in "${disconnected_displays[@]}"; do
            echo "$(date): Turning off disconnected display: $disp"
            xrandr --output "$disp" --off
        done
    }

    # Function to create dynamic options based on display count
    create_options() {
        local options=()

        # Always add extend option if multiple displays
        if [ "$display_count" -gt 1 ]; then
            options+=("Extend displays")
        fi

        # Always add mirror option if multiple displays
        if [ "$display_count" -gt 1 ]; then
            options+=("Mirror displays")
        fi

        # Add individual display options
        for ((i = 0; i < display_count; i++)); do
            options+=("Show only ${displays[$i]}")
        done

        # Add custom layout options
        if [ "$display_count" -gt 1 ]; then
            options+=("Custom layout")
        fi

        # Add rotation options for each display
        for ((i = 0; i < display_count; i++)); do
            options+=("Rotate ${displays[$i]} (normal/left/right/inverted)")
        done

        # Add resolution options for each display
        for ((i = 0; i < display_count; i++)); do
            options+=("Set resolution for ${displays[$i]}")
        done

        # Return options as newline-separated string
        printf '%s\n' "${options[@]}"
    }

    # Function to get available resolutions for a display
    get_resolutions() {
        local display=$1
        xrandr --query | grep -A 20 "^$display connected" | grep -oP '\d+x\d+' | sort -u
    }

    # Function to execute commands based on selected option
    run_cmd() {
        local option=$1
        local selected=$2

        echo "$(date): Selected option: $option"

        case "$option" in
        "Extend displays")
            local primary=${displays[0]}
            local cmd="xrandr --output \"$primary\" --auto --primary"

            local position="right-of"
            for ((i = 1; i < display_count; i++)); do
                cmd+=" --output \"${displays[$i]}\" --auto --$position \"$primary\""
                primary=${displays[$i]}
                # Alternate between right-of and below
                if [ "$position" = "right-of" ]; then
                    position="below"
                else
                    position="right-of"
                fi
            done
            echo "$(date): Running command: $cmd"
            eval "$cmd"
            ;;

        "Mirror displays")
            local primary=${displays[0]}
            local cmd="xrandr --output \"$primary\" --auto --primary"

            for ((i = 1; i < display_count; i++)); do
                cmd+=" --output \"${displays[$i]}\" --auto --same-as \"$primary\""
            done
            echo "$(date): Running command: $cmd"
            eval "$cmd"
            ;;

        "Show only"*)
            # Extract the display name from the option
            local selected_display=$(echo "$option" | sed 's/Show only //g')

            # Set the selected display as primary and turn off others
            local cmd="xrandr --output \"$selected_display\" --auto --primary"

            for disp in "${displays[@]}"; do
                if [ "$disp" != "$selected_display" ]; then
                    cmd+=" --output \"$disp\" --off"
                fi
            done
            echo "$(date): Running command: $cmd"
            eval "$cmd"
            ;;

        "Rotate"*)
            # Extract the display name from the option
            local selected_display=$(echo "$option" | sed 's/Rotate \(.*\) (normal.*)/\1/')

            # Ask for rotation type using rofi
            local rotation=$(echo -e "normal\nleft\nright\ninverted" | rofi -dmenu -p "Select rotation for $selected_display")

            if [ -n "$rotation" ]; then
                echo "$(date): Rotating $selected_display to $rotation"
                xrandr --output "$selected_display" --rotate "$rotation"
            fi
            ;;

        "Set resolution for"*)
            # Extract the display name from the option
            local selected_display=$(echo "$option" | sed 's/Set resolution for //g')

            # Get available resolutions
            local resolutions=$(get_resolutions "$selected_display")

            # Ask for resolution using rofi
            local resolution=$(echo -e "$resolutions" | rofi -dmenu -p "Select resolution for $selected_display")

            if [ -n "$resolution" ]; then
                echo "$(date): Setting resolution of $selected_display to $resolution"
                xrandr --output "$selected_display" --mode "$resolution"
            fi
            ;;

        "Custom layout")
            # More complex layout setup using a multi-step approach
            local primary=$(echo "${displays[@]}" | tr ' ' '\n' | rofi -dmenu -p "Select primary display")

            if [ -n "$primary" ]; then
                local cmd="xrandr --output \"$primary\" --auto --primary"
                echo "$(date): Selected primary display: $primary"

                for disp in "${displays[@]}"; do
                    if [ "$disp" != "$primary" ]; then
                        local position=$(echo -e "right-of\nleft-of\nabove\nbelow\nsame-as\noff" | rofi -dmenu -p "Position for $disp relative to $primary")

                        if [ "$position" = "off" ]; then
                            cmd+=" --output \"$disp\" --off"
                        elif [ -n "$position" ]; then
                            cmd+=" --output \"$disp\" --auto --$position \"$primary\""
                        fi
                        echo "$(date): Positioning $disp $position $primary"
                    fi
                done
                echo "$(date): Running command: $cmd"
                eval "$cmd"
            fi
            ;;
        esac

        # Turn off disconnected displays
        turn_off_disconnected

        # Restart i3
        restart_i3
    }

    # Single display case
    if [ "$display_count" -eq 1 ]; then
        echo "$(date): Only one display detected: ${displays[0]}"
        xrandr --output "${displays[0]}" --auto --primary

        # Turn off disconnected displays
        turn_off_disconnected

        restart_i3
    else
        # Multiple display case
        prompt="Display Settings"
        mesg="Select a display configuration:"
        win_width='500px'

        # Generate dynamic options
        options=$(create_options)
        echo "$(date): Generated options: "
        echo "$options" | while read -r line; do echo "$(date): - $line"; done

        # Rofi command
        chosen=$(echo -e "$options" | rofi -theme-str "window {width: $win_width;}" \
            -theme-str "listview {lines: $(echo "$options" | wc -l);}" \
            -theme-str 'textbox-prompt-colon {str: "";}' \
            -dmenu \
            -p "$prompt" \
            -mesg "$mesg" \
            -markup-rows)

        # Run the command if an option was selected
        if [ -n "$chosen" ]; then
            run_cmd "$chosen"
        else
            echo "$(date): No option selected."
        fi
    fi

    echo "$(date): Script completed successfully"
} >"$LOG_FILE" 2>&1
