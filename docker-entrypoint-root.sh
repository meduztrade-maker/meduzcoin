#!/bin/bash
set -e

# Runs as root only long enough to make sure the mounted volume is writable
# by the unprivileged user, then drops privileges permanently. The daemon,
# miner, and wallet service never run as root.
mkdir -p /data
chown -R meduz:meduz /data

exec gosu meduz /usr/local/bin/entrypoint.sh
