#!/usr/bin/env sh

input() {
  stty raw
  key=$(dd bs=1 count=1 2> /dev/null)
  rc=$?
  [ $rc -ne 0 ] && return $rc
  stty -raw
  return 0
}

record_background() {
  input
  arecord -f S16_LE -r 48000 -D hw:1,0 background.wav &
  pid=$!
  sleep 1
  input
  kill $pid
}

play_layers() {
  play_layer_pids=""
  for i in $(seq $layer_number)
  do
    aplay layer$i.wav &
    play_layer_pids="$! $play_layer_pids"
  done
}

record_layer() {
  record_layer_pid=""
  if $(cat should_record_layer)
  then
    layer_number=$[ $layer_number + 1 ]
    arecord -f S16_LE -r 48000 -D hw:1,0 layer${layer_number}.wav &
    record_layer_pid=$!
    echo false > should_record_layer
  fi
}

remove_layer() {
  record_layer_pid=""
  if $(cat should_remove_layer)
  then
    layer_number=$[ $layer_number - 1 ]
    echo false > should_remove_layer
  fi
}

main_loop() {
  echo false > should_record_layer
  echo false > should_remove_layer
  layer_number=0
  while true
  do
    remove_layer
    play_layers
    record_layer
    aplay background.wav
    [ $? -ne 0 ] && break
    [ -n "$record_layer_pid" ] && kill $record_layer_pid
    [ -n "$play_layer_pids" ] && kill $play_layer_pids
  done
}

input_loop() {
  while true
  do
    input
    [ "$key" = $'\003' ] && break
    if [ "$key" = "a" ]
    then
      echo true > should_remove_layer
    else
      echo true > should_record_layer
    fi
    sleep 1
  done
}

rm background.wav layer*.wav
record_background
main_loop &
main_loop_pid=$!
input_loop
wait $main_loop_pid
