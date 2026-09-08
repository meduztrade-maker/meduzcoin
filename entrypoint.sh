#!/bin/bash
set -e

MINE_ADDRESS="${MINE_ADDRESS:-UZMDiFLE4ThJaWeBYZvtfL7FphcnYMobUhXMddMnoTnYevj3sRiLUPoHoNfHVs6Aoccw6sZvinipmfNe9pQmMC2PJQ9uSUbhCj1}"
MINE_THREADS="${MINE_THREADS:-1}"

/usr/local/bin/meduzd --data-dir /data --no-console --rpc-bind-ip 0.0.0.0 --p2p-bind-ip 0.0.0.0 &
DAEMON_PID=$!

echo "[entrypoint] waiting for daemon RPC to come up..."
for i in $(seq 1 60); do
  if curl -s -m 2 -X POST http://127.0.0.1:27898/getinfo -o /tmp/getinfo.json 2>/dev/null && [ -s /tmp/getinfo.json ]; then
    echo "[entrypoint] daemon RPC is up after ${i}s"
    break
  fi
  sleep 1
done

echo "[entrypoint] starting miner -> ${MINE_ADDRESS} (${MINE_THREADS} thread(s))"
/usr/local/bin/miner --daemon-address 127.0.0.1:27898 --address "$MINE_ADDRESS" --threads "$MINE_THREADS" &
MINER_PID=$!

wait $DAEMON_PID
