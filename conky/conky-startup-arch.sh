#!/usr/bin/bash

# sleep 20s
killall conky
cd "/home/phoenix/.conky/Arch"
conky -c "/home/phoenix/.conky/Arch/conkyrc" --daemonize &
