#!/bin/sh

temp_json=$(sensors -j)
#pkg0_temp=$(echo $temp_json | jq '.["coretemp-isa-0000"]."Package id 0"."temp1_input"')
cpu0_temp=$(echo $temp_json | jq '.["coretemp-isa-0000"]."Core 0"."temp2_input"')
cpu1_temp=$(echo $temp_json | jq '.["coretemp-isa-0000"]."Core 1"."temp3_input"')
cpu2_temp=$(echo $temp_json | jq '.["coretemp-isa-0000"]."Core 2"."temp4_input"')
cpu3_temp=$(echo $temp_json | jq '.["coretemp-isa-0000"]."Core 3"."temp5_input"')

echo $cpu0_temp $cpu1_temp $cpu2_temp $cpu3_temp
