#!/bin/sh

IP_ADDRESS=$1
TIMEOUT=$2

if [ -z "$TIMEOUT" ]
then
  TIMEOUT=100
fi

ping -c 1 -t 1 "$IP_ADDRESS" > /dev/null

while [ $? -ne 2 ]
do
  ping -c 1 -t 1 -i 0.1 "$IP_ADDRESS" > /dev/null
done

time ping -c 1 -t "$TIMEOUT" "$IP_ADDRESS" > /dev/null
