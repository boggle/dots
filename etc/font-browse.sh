#!/bin/bash

# Get list of fonts into an array
fonts=($(ls /usr/share/kbd/consolefonts/*.psfu.gz))
i=0
num_fonts=${#fonts[@]}

while true; do
    current_font=${fonts[$i]}
    
    # Clear screen and apply font
    clear
    setfont "$current_font"
    
    echo "--- TTY Font Browser ---"
    echo "Font [$((i+1))/$num_fonts]: $(basename "$current_font")"
    echo "-------------------------------------------------------"
    echo "ABCDEFGHIJKLM NOPQRSTUVWXYZ"
    echo "abcdefghijklm nopqrstuvwxyz"
    echo "0123456789 !@#$%^&*()_+-="
    echo "The quick brown fox jumps over the lazy dog."
    echo "-------------------------------------------------------"
    echo "Controls: [n] Next  [p] Prev  [q] Quit"

    # Wait for user input (1 character)
    read -n 1 -s char
    case "$char" in
        n) ((i=(i+1)%num_fonts)) ;;
        p) ((i=(i-1+num_fonts)%num_fonts)) ;;
        q) echo -e "\nExiting..."; break ;;
    esac
done
