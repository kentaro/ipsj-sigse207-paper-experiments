#!/bin/sh

set -u

BUILD_METHOD=$1

if [ -z "$BUILD_METHOD" ]
then
  echo "usage: $0 [firmware | firmware.patch]"
  exit 1
fi

IP_ADDRESS=$(ping -c 1 nerves.local | grep 'PING nerves.local' | perl -nle 's/^.+\((\d+\.\d+\.\d+\.\d+)\).+$/$1/; print')
echo "nerves.local is at $IP_ADDRESS"
echo ""

echo "Time to build firmware (mix $BUILD_METHOD)"
echo "======================================"

time mix "$BUILD_METHOD" > /dev/null
echo ""

echo "Time to upload firmware"
echo "======================================"

if [ "$BUILD_METHOD" = "firmware" ]
then
  time mix upload > /dev/null
else
  time mix upload --firmware _build/rpi3_dev/nerves/images/patch.fw > /dev/null
fi
echo ""

echo "Time to reboot"
echo "======================================"
echo ""

START_TIME=$(gdate +"%s.%3N")
ping -c 1 -t 1 "$IP_ADDRESS" > /dev/null

while [ $? -ne 2 ]
do
  ping -c 1 -t 1 -i 0.1 "$IP_ADDRESS" > /dev/null
done

ping -c 1 -t 100 "$IP_ADDRESS" > /dev/null

END_TIME=$(gdate +"%s.%3N")
DURATION=$(echo "scale=1; $END_TIME - $START_TIME" | bc)
echo "time: $DURATION sec."
echo ""
