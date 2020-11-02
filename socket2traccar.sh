#!/bin/bash
# 02.11.2020 KerZol
# testing script

set -x

if [ -e config ]
then
	. config
else
	echo "[-] missing config file"
	exit 1
fi

echo "[*] Daemon started $(date +"%F %T")"

while true;
do

REPLY=$(websocat -1 -E "$HOST")

PORT=$(echo "$REPLY" | awk -F "," '{print $6}' | awk -F ":" '{print $2}')
DATA=$(echo "$REPLY" | awk -F "," '{print $15}' | awk -F ":" '{print $2}' | awk -F "\"" '{print $2}')
ID=$(echo $REPLY | awk -F "," '{print $3}' | awk -F ":" '{print $2}' | sed 's/"//g' | tail -c 7)

case "$PORT" in

	200)
    echo 'a message sent on cold starts, content is equivalent with port 208 msg $(date +"%F %T")'
    ;;
    
    203)
    echo 'message sent when device is in motion, and GPS is disabled $(date +"%F %T")'
    ;;

	204)
    echo '[*] GPS coordinates message'
    LATITUDE_DECIMAL=$(echo $((16#$(echo "$DATA" | awk '{print substr($1,1,6)}'))))
    LATITUDE=$(awk "BEGIN {print ($LATITUDE_DECIMAL/8388606)*90}")
    LONGITUDE_DECIMAL=$(echo $((16#$(echo "$DATA" | awk '{print substr($1,7,6)}'))))
    LONGITUDE=$(awk "BEGIN {print ($LONGITUDE_DECIMAL/8388606)*180}")
    ALTITUDE=$(echo $((16#$(echo "$DATA" | awk '{print substr($1,13,4)}'))))
    ;;

	205)
    echo '[*] Motion sensor activated, no GPS coordinates message $(date +"%F %T")'
    #temperature
    TEMP_SIGN=$(echo "$DATA"| awk '{print substr($1,1,1)}')
	TEMP_INTEGER=$(echo "$DATA" | awk '{print substr($1,2,2)}')
    TEMP_FRACTIONAL=$(echo "$DATA" | awk '{print substr($1,4,1)}')
    if [ "$TEMP_SIGN" -eq 0 ]
		then
        TEMP_SIGN="+"
	else
        TEMP_SIGN="-"
	fi
    TEMPERATURE="$TEMP_SIGN$TEMP_INTEGER.$TEMP_FRACTIONAL $(date +"%F %T")"
	#battery
    BATTERY=$(echo "$DATA" | awk '{print substr($1,5,2)}')
    ;;

	207)
    echo "[*] Keepalive message $(date +"%F %T")"
    #temperature
    TEMP_SIGN=$(echo "$DATA"| awk '{print substr($1,1,1)}')
	TEMP_INTEGER=$(echo "$DATA" | awk '{print substr($1,2,2)}')
    TEMP_FRACTIONAL=$(echo "$DATA" | awk '{print substr($1,4,1)}')
    if [ "$TEMP_SIGN" -eq 0 ]
		then
        TEMP_SIGN="+"
	else
        TEMP_SIGN="-"
	fi
    TEMPERATURE="$TEMP_SIGN$TEMP_INTEGER.$TEMP_FRACTIONAL $(date +"%F %T")"
	#battery
    BATTERY=$(echo "$DATA" | awk '{print substr($1,5,2)}')
    ;;
    
    208)
    echo 'configuration status package, only sent on request'
    ;;
esac

#http://demo.traccar.org:5055/?id=123456&lat={0}&lon={1}&timestamp={2}&hdop={3}&altitude={4}&speed={5}
TIME=$(date +"%F %T")

curl --data "id=$ID&lat=$LATITUDE&lon=$LONGITUDE&altitude=$ALTITUDE&timestamp=$TIME&temperature=$TEMPERATURE&battery=$BATTERY" http://"$TRACCAR_IP":"$TRACCAR_PORT"
done
