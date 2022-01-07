#!/usr/bin/env bash
#
# Change headphones audio to audio sink https://gist.github.com/egelev/2e6b57d5a8ba62cf6df6fff2878c3fd4
# The headphones have to be already connected!
#
# Copy connect-headphones.desktop to ~/.local/share/applications/ for app launcher to appear in the list of your apps
#

function get_headphones_index() {
  echo $(pacmd list-cards | grep bluez_card -B1 | grep index | awk '{print $2}')
}

function get_headphones_mac_address() {
  local temp=$(pacmd list-cards | grep bluez_card -C20 | grep 'device.string' | cut -d' ' -f 3)
  temp="${temp%\"}"
  temp="${temp#\"}"
  echo "${temp}"
}

function _control_bluethoot_headphones() {
  local op=${1}
  local hp_mac=${2}
  echo -e "${op} ${hp_mac}\n quit" | bluetoothctl
}

function disconnect_bluetooth_headphones() {
  local hp_mac=${1}
  _control_bluethoot_headphones "disconnect" ${hp_mac}
}

function connect_bluetooth_headphones() {
  local hp_mac=${1}
  _control_bluethoot_headphones "connect" ${hp_mac}
}

function _set_headphones_profile() {
  local profile=${1}
  pacmd set-card-profile $(get_headphones_index) ${profile}
}

function set_headphones_profile_a2dp_sink() {
  _set_headphones_profile "a2dp_sink"
  echo "Bluethooth headphones a2dp_sink"
}

function set_headphones_profile_off() {
  _set_headphones_profile "off"
  echo "Bluethooth headphones profile off"
}

# Set headphones as default audio channel https://askubuntu.com/questions/1038490/how-do-you-set-a-default-audio-output-device-in-ubuntu-18-04
function set_headphones_def_audio_a2dp() {
  local hp_name=$(pactl list short sinks | grep "bluez_sink." | cut -f2)
  pactl set-default-sink $hp_name
}

function main() {
  local hp_mac=$(get_headphones_mac_address)
  if [ "$hp_mac" == "" ]; then # Checks if hp are connected and connects them if regular bt connect doesn't work
    ./connect-audio.py
  fi
  set_headphones_profile_off
  sleep 2s
  disconnect_bluetooth_headphones ${hp_mac}
  sleep 6s
  connect_bluetooth_headphones ${hp_mac}
  sleep 3s
  set_headphones_profile_a2dp_sink
  sleep 3s
  set_headphones_def_audio_a2dp
}

main
