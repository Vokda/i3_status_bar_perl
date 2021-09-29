#!/bin/sh

out=$(setxkbmap -query | sed -En "s/layout:\s+(..)/\1/p") 
echo $out
