#!/usr/bin/env sh

input() {
  stty raw
  dd bs=1 count=1 2> /dev/null
  stty -raw
}

record_background() {
  input
  arecord -f S16_LE -r 48000 -D hw:1,0 background.wav &
  pid=$!
  sleep 1
  input
  kill $pid
}

play_layer() {
  play_layer_pid=""
  if [ -e "layer.wav" ]
  then
    aplay layer.wav &
    play_layer_pid=$!
  fi
}

record_layer() {
  record_layer_pid=""
  if $(cat should_record_layer)
  then
    arecord -f S16_LE -r 48000 -D hw:1,0 layer.wav &
    record_layer_pid=$!
    echo false > should_record_layer
  fi
}

main_loop() {
  echo false > should_record_layer
  while true
  do
    play_layer
    record_layer  
    aplay background.wav
    [ $? -ne 0 ] && break
    [ -n $record_layer_pid ] && kill $record_layer_pid
    [ -n $play_layer_pid ] && kill $play_layer_pid
  done
}

rm background.wav layer.wav
record_background
main_loop &
main_loop_pid=$!
input
echo true > should_record_layer
wait $main_loop_pid

