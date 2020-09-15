#!/usr/bin/bash

# sleep 20s
killall conky
cd "/home/phoenix/.conky/blackPantherOS/Conky-lua 2011 next generation/Arch"
conky -c "/home/phoenix/.conky/blackPantherOS/Conky-lua 2011 next generation/Arch/conkyrc" &
