#!/bin/bash

# Install nala
apt install nala -y

# Get the username of the user with UID 1000
username=$(id -u -n 1000)

# Define paths
usenala="/usr/local/share/use-nala"
rusenala="/root/.use-nala"
ubashrc="/etc/bash.bashrc"
rbashrc="/root/.bashrc"

# Create wrapper script for regular user if not exists
if [ ! -f "$usenala" ]; then
  cat << 'EOF' > "$usenala"
apt() {
  command nala "$@"
}
sudo() {
  if [ "$1" = "apt" ] || [ "$1" = "apt-get" ]; then
    shift
    command sudo nala "$@"
  else
    command sudo "$@"
  fi
}
EOF

  # Append sourcing line to system bashrc
  echo 'if [ -f "/usr/local/share/use-nala" ]; then . "/usr/local/share/use-nala"; fi' >> "$ubashrc"
fi

# Create wrapper for root user if not exists
if [ ! -f "$rusenala" ]; then
  cat << 'EOF' > "$rusenala"
apt() {
  command nala "$@"
}
EOF

  # Append sourcing line to root's bashrc
  echo 'if [ -f "/root/.use-nala" ]; then . "/root/.use-nala"; fi' >> "$rbashrc"
fi
