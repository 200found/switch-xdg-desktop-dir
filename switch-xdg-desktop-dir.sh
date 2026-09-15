#!/usr/bin/env bash

# change the xdg desktop under kde 6 plasma to another, existing folder. supports a cyclable history and can be used with a virtual desktop switch.

# kde directories for right-click services
# ~/.local/share/kio/servicemenus/
# ~/.local/share/applications/

# dependencies
# freedesktop, bash 4, mapfile, kdialog (kde) or notify-send (linux mint xfce),

# todo
# support more window managers. i started this while using linux mint xfce and now much prefer kde.
# more robust checks for history and input
# make installer and adjacent scripts for more platforms
# make documetation and language more consistent
# localize

# notes
# it's been like 20 years since i last did any serious programming, so there's a lot of good practices i didn't know of when i wrote this. compsci is no longer my career. if you would like to help modernize this, i would welcome input on the matter.


# FUNCTIONS

# notification function; currently supports kde and xfce
notify() {
    local title="$1"
    local message="$2"
    # kde
    if command -v kdialog >/dev/null 2>&1; then
        kdialog --title "$title" --passivepopup "$message" 2
        return
    fi
    # linux mint xfce
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t 2000 "$title" "$message"
        return
    fi
    echo "$title $message"
}

update_history() {
    local skip=0
    if [ "$path" = "$XDG_DESKTOP_DIR" ]; then
        skip=1
    fi
    for item in "${history_array[@]}"; do
        if [ "$item" = "$path" ]; then
            skip=1
            break
        fi
    done
    if [ "$skip" = 0 ]; then
        printf "$path\n" >> "$history_file"
    fi
}


# INIT

mode="$1"
path="$2"
working_dir="$(dirname "$0")"
# load xdg user directory definitions
source "$HOME/.config/user-dirs.dirs"
eval XDG_DESKTOP_DIR="$XDG_DESKTOP_DIR"
history_file="$working_dir/switch-xdg-desktop-dir.history"
history_array=()
# read history file or create a blank one
if [ -f "$history_file" ]; then
    mapfile -t history_array < "$history_file"
else
    printf "$XDG_DESKTOP_DIR\n" > "$history_file"
    mapfile -t history_array < "$history_file"
fi


# MODES

# no args; show docs
if [ -z "$mode" ]; then
    echo 'A means to switch XDG desktop folders on the fly, to make virtual desktops more useful. Can probably be adapted to other window managers.

Usage: switch-xdg-desktop-dir.sh [mode] [[path]]

Commands:
switch /path/to/new/desktop     Switches desktop to the new path and adds to the history. Use as a right-click on folder service.

default                         Revert to ~/Desktop

reset                           Reset XDG history and revert to ~/Desktop

remove /path/to/folder          Remove path from XDG history. Use as a right-click on folder service.

next|prev                       Switch to the next or previous desktop in history. Use with [Meta]+[tab] and [Meta]+[shift]+[tab] keyboard shortcuts and/or chain it with virtual desktop switching.'
    exit 1
fi


# default values mode
if [ "$mode" = "default" ]; then
    xdg-user-dirs-update --set DESKTOP "$HOME/Desktop"
    echo "Desktop Switch: desktop folder is now reset to: $HOME/Desktop."
    notify "Desktop Switched" "Desktop folder is now reset to: $HOME/Desktop"
    exit 0
fi


# clear history mode
if [ "$mode" = "reset" ]; then
    printf "$XDG_DESKTOP_DIR\n" > "$history_file"
    xdg-user-dirs-update --set DESKTOP "$HOME/Desktop"
    echo "Desktop Switch: history cleared and desktop folder is now reset to: $HOME/Desktop."
    notify "Desktop Switched" "History cleared and desktop folder is now reset to: $HOME/Desktop"
    exit 0
fi


# switch to specified directory
if [ "$mode" = "switch" ]; then

    # if the path is empty, break
    if [ -z "$path" ]; then
        echo "Desktop Switch: no path specified."
        exit 1
    fi

    # if the folder doesn't exist, break
    if [ ! -d "$path" ]; then
        echo "Desktop Switch: folder $path does not exist."
        notify "Desktop Switch Failed" "Folder does not exist: $path"
        exit 1
    fi

    # if the path specified is already set to the current desktop folder, there's nothing to do
    if [ "$path" = "$XDG_DESKTOP_DIR" ]; then
        echo "Desktop Switch: path is already set to $path."
        exit 0
    fi

    # update xdg user dirs
    xdg-user-dirs-update --set DESKTOP "$path"
    echo "Desktop Switch: desktop is now: $path."
    notify "Desktop Switched" "Desktop is now: $path"
    update_history
    exit 0
fi


# if next then cycle next desktop
if [ "$mode" = "next" ]; then
    current="$XDG_DESKTOP_DIR"
    index=-1

    # find current index
    i=0
    for item in "${history_array[@]}"; do
        if [ "$item" = "$current" ]; then
            index=$i
            break
        fi
        i=$((i+1))
    done

    # if not found, default to first entry
    if [ "$index" -lt 0 ]; then
        index=0
    fi

    # compute next index (wrap around)
    next_index=$(( (index + 1) % ${#history_array[@]} ))
    next_dir="${history_array[$next_index]}"

    if [ ! -d "$next_dir" ]; then
        xdg-user-dirs-update --set DESKTOP "$XDG_DESKTOP_DIR"
        notify "Desktop Switch Failed" "Folder does not exist: $next_dir\nDesktop is now: $XDG_DESKTOP_DIR"
    else
        xdg-user-dirs-update --set DESKTOP "$next_dir"
        notify "Desktop Switched" "Desktop is now: $next_dir"
    fi
    exit 0
fi


# if prev then cycle prev desktop
if [ "$mode" = "prev" ]; then
    current="$XDG_DESKTOP_DIR"
    index=-1

    # find current index
    i=0
    for item in "${history_array[@]}"; do
        if [ "$item" = "$current" ]; then
            index=$i
            break
        fi
        i=$((i+1))
    done

    # if not found, default to first entry
    if [ "$index" -lt 0 ]; then
        index=0
    fi

    # compute previous index (wrap around)
    prev_index=$(( (index - 1 + ${#history_array[@]}) % ${#history_array[@]} ))
    prev_dir="${history_array[$prev_index]}"

    if [ ! -d "$prev_dir" ]; then
        xdg-user-dirs-update --set DESKTOP "$XDG_DESKTOP_DIR"
        notify "Desktop Switch Failed" "Folder does not exist: $prev_dir\nDesktop is now: $XDG_DESKTOP_DIR"
    else
        xdg-user-dirs-update --set DESKTOP "$prev_dir"
        notify "Desktop Switched" "Desktop is now: $prev_dir"
    fi
    exit 0
fi


# remove the specified path from history
# assumes a valid history array
if [ "$mode" = "remove" ]; then
    if [ "$path" = "$XDG_DESKTOP_DIR" ]; then
        echo "Desktop Switch: will not remove current desktop folder from history."
        notify "Desktop History Removal Failed" "Will not remove current desktop folder."
        exit 1
    fi
    if [ ! -d "$path" ]; then
        echo "Desktop Switch: cannot remove a folder from history that does not exist."
        notify "Desktop History Removal Failed" "Cannot remove a folder from history that does not exist."
        exit 1
    fi
    printf "" > "$history_file"
    for item in "${history_array[@]}"; do
        if [ "$item" != "$path" ]; then
            printf "$item\n" >> "$history_file"
        else
            echo "Desktop history removed: $path."
            notify "Desktop History Removed" "$path removed."
        fi
    done
    echo "Desktop history updated."
    exit 0
fi


# if no mode matched, break
echo "Desktop Switch: unknown mode '$mode'"
exit 1
