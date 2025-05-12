#!/usr/bin/env bash

# TODO: I want my service managed by systemd.

usage="Usage: ./deploy.sh binary_file
  Deploys binary to remote server, starts process, and switches over
  network traffic to the new http server.
"

if [ ( "$1" = "-h" ) -o ( "$1" = "--help" ) ]; then
  echo "$usage"
  exit 0
fi

SOCKET=~/.ssh/ctrl-%h-%p-%r
CONN="ec2-user@$ip_ec2"

binary="$1"

if [ ! -b "$binary" ]; then
  echo "Error: binary $binary does not exist"
  echo "$usage"
  exit 1
fi

# establish connection for re-use
ssh \
  -o ControlMaster=auto \
  -o ControlPersist=60s \
  -o ControlPath="$SOCKET" \
  "$CONN" true

scp -o ControlPath="$SOCKET" \


ssh -o ControlPath="$SOCKET" \
  "$CONN" \
  <<'EOF'
  # let's do some commands
  # 1. make sure .www folder exists in $HOME
  #    (actually I can parse port from iptables. then get pid from lsof)
  # 2. put binary in .www folder.
  # 3. Serialize log writing using `tee`
  #    ```
  #    mkfifo .www/log.fifo
  #    tee -a .www/log < .www/log.fifo &
  #    ./binary --version=1 > .www/log.fifo 2>&1 &
  #    ./binary --version=2 > .www/log.fifo 2>&1 &
  #    ```
  #    Amazon Linux uses systemd, so I may as well set it up for this.
EOF
