#!/bin/sh

setxkbmap -query | sed -En "s/layout:\s+(..)/\1/p"
