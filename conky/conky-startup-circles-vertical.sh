#!/usr/bin/bash

# sleep 20s
killall conky
conky -c "/home/phoenix/.conky/Conky_Revisited_2/Conky_Circle_Vertical/start_conky_General_VERTICAL_circle" --daemonize &
