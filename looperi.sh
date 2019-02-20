#!/usr/bin/env sh

input() {
  stty raw
  dd bs=1 count=1 2> /dev/null
  stty -raw
}

input
arecord -f S16_LE -r 48000 -D hw:1,0 out.wav &
pid=$!
sleep 1
input

kill $pid
while true
do
  aplay out.wav
  [ $? -ne 0 ] && break
done
