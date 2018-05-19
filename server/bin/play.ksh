#!/bin/bash

if [ $# == 1 ] && [ $1 == "-kill" ]
then
	pkill mplayer
else
	pkill mplayer
	unset DISPLAY
	nohup mplayer "$*" &
fi
