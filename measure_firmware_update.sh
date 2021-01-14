#!/bin/sh

BUILD_METHOD=$1

if [ -z "$BUILD_METHOD" ]
then
  echo "usage: $0 [firmware | firmware.patch | upload.hotswap]"
  exit 1
fi

set -u

IP_ADDRESS=$(ping -c 1 nerves.local | grep 'PING nerves.local' | perl -nle 's/^.+\((\d+\.\d+\.\d+\.\d+)\).+$/$1/; print')
echo "nerves.local is at $IP_ADDRESS"
echo ""

if [ "$BUILD_METHOD" = "firmware" -o "$BUILD_METHOD" = "firmware.patch" ]
then
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
else
  echo "Time to hotswap (mix upload.hotswap)"
  echo "======================================"
  time mix upload.hotswap > /dev/null
fi
echo ""

echo "Time to reboot"
echo "======================================"
echo ""

START_TIME=$(gdate +"%s.%3N")

# 再起動に入るまでしばらく時間がかかる。
# その間はpingは通るので、通らなくなるまでpingし続ける。
ping -c 1 -t 1 "$IP_ADDRESS" > /dev/null

# pingが通らなくなったら終了ステータスが2になる
while [ $? -ne 2 ] 
do
  ping -c 1 -t 1 -i 0.1 "$IP_ADDRESS" > /dev/null
done

# pingが通らなくなったら再起動中ということなので、
# あらためてタイムアウトを長く設定してpingする
ping -c 1 -t 100 "$IP_ADDRESS" > /dev/null

END_TIME=$(gdate +"%s.%3N")
DURATION=$(echo "scale=1; $END_TIME - $START_TIME" | bc)
echo "time: $DURATION sec."
echo ""
