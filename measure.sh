#!/bin/sh

BUILD_METHOD=$1
PORT=$2

if [ -z "$BUILD_METHOD" ]
then
  echo "usage: $0 [firmware | firmware.patch | upload.hotswap]"
  exit 1
fi

if [ -z "$PORT" ]
then
  PORT=9849
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

# firmwareアップデートの場合デバイスの再起動でpingが通らなくなる
# upload.hotswapでは再起動はないためpingは通る
# そのため、firmwareアップデートの時のみpingで再起動判定する
if [ "$BUILD_METHOD" = "firmware" -o "$BUILD_METHOD" = "firmware.patch" ]
then
  echo "Time to reboot"
  echo "======================================"
  echo ""

  START_TIME=$(gdate +"%s.%3N")

  # 再起動に入るまでしばらく時間がかかる。
  # その間はpingは通るので、通らなくなるまでpingし続ける。
  ping -c 1 -t 1 "$IP_ADDRESS" > /dev/null

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
fi

echo "Time to accept"
echo "======================================"
echo ""

START_TIME=$(gdate +"%s.%3N")
TIMEOUT_COUNT=0

# acceptされるまで短い期間で接続を試み続ける
ncat -z -w 1ms "$IP_ADDRESS" "$PORT" > /dev/null
while [ $? -ne 0 ] 
do
  TIMEOUT_COUNT=$(( TIMEOUT_COUNT + 1 ))
  ncat -z -w 1ms "$IP_ADDRESS" "$PORT" > /dev/null
done

END_TIME=$(gdate +"%s.%3N")
DURATION=$(echo "scale=1; $END_TIME - $START_TIME" | bc)
echo "time: $DURATION sec. (timeout: $TIMEOUT_COUNT)"
echo ""
