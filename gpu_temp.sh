#!/bin/sh

nvidia-smi -d TEMPERATURE -q | grep "GPU Current" | awk '{print $5}'
