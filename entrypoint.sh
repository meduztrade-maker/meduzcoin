#!/bin/bash
set -e

MINE_ADDRESS="${MINE_ADDRESS:-UZMDiFLE4ThJaWeBYZvtfL7FphcnYMobUhXMddMnoTnYevj3sRiLUPoHoNfHVs6Aoccw6sZvinipmfNe9pQmMC2PJQ9uSUbhCj1}"
MINE_THREADS="${MINE_THREADS:-1}"
WALLET_VIEW_KEY="${WALLET_VIEW_KEY:-}"
WALLET_SPEND_KEY="${WALLET_SPEND_KEY:-}"
WALLET_PASSWORD="${WALLET_PASSWORD:-changeme}"
WALLET_RPC_PASSWORD="${WALLET_RPC_PASSWORD:-changeme}"
LOG_LEVEL="${LOG_LEVEL:-2}"
PRIORITY_NODE="${PRIORITY_NODE:-}"
export BACKUP_GIT_TOKEN="${BACKUP_GIT_TOKEN:-}"
export BACKUP_REPO="${BACKUP_REPO:-meduztrade-maker/meduzcoin}"
BACKUP_INTERVAL_SECONDS="${BACKUP_INTERVAL_SECONDS:-3600}"

PRIORITY_ARGS=()
if [ -n "$PRIORITY_NODE" ]; then
  PRIORITY_HOST="${PRIORITY_NODE%%:*}"
  PRIORITY_PORT="${PRIORITY_NODE##*:}"
  RESOLVED_IP=$(getent hosts "$PRIORITY_HOST" | awk '{print $1}' | head -1)
  if [ -n "$RESOLVED_IP" ]; then
    PRIORITY_ARGS=(--add-priority-node "${RESOLVED_IP}:${PRIORITY_PORT}")
  else
    echo "[entrypoint] WARNING: could not resolve ${PRIORITY_HOST}, skipping priority node"
  fi
fi
echo "[entrypoint] PRIORITY_ARGS: ${PRIORITY_ARGS[@]}"

/usr/local/bin/meduzd --data-dir /data --no-console --rpc-bind-ip 0.0.0.0 --p2p-bind-ip 0.0.0.0 --log-level "$LOG_LEVEL" --log-file /data/meduzd.log "${PRIORITY_ARGS[@]}" &
DAEMON_PID=$!

echo "[entrypoint] waiting for daemon RPC to come up..."
for i in $(seq 1 60); do
  if curl -s -m 2 -X POST http://127.0.0.1:27898/getinfo -o /tmp/getinfo.json 2>/dev/null && [ -s /tmp/getinfo.json ]; then
    echo "[entrypoint] daemon RPC is up after ${i}s"
    break
  fi
  sleep 1
done

if [ "$MINE_THREADS" -gt 0 ] 2>/dev/null; then
  echo "[entrypoint] waiting for daemon to report synced before starting miner (avoids spamming retries against a busy core)..."
  for i in $(seq 1 300); do
    SYNCED=$(curl -s -m 2 -X POST http://127.0.0.1:27898/getinfo 2>/dev/null | grep -o '"synced":[a-z]*' | cut -d: -f2)
    if [ "$SYNCED" = "true" ]; then
      echo "[entrypoint] daemon reports synced after ${i}s"
      break
    fi
    sleep 1
  done

  echo "[entrypoint] starting miner -> ${MINE_ADDRESS} (${MINE_THREADS} thread(s))"
  /usr/local/bin/miner --daemon-address 127.0.0.1:27898 --address "$MINE_ADDRESS" --threads "$MINE_THREADS" &
  MINER_PID=$!
else
  echo "[entrypoint] MINE_THREADS=0, not starting miner"
fi

if [ -n "$WALLET_VIEW_KEY" ] && [ -n "$WALLET_SPEND_KEY" ]; then
  if [ ! -f /data/wallet.wallet ]; then
    echo "[entrypoint] no wallet container yet, importing from keys..."
    /usr/local/bin/meduz-service -g -w /data/wallet.wallet -p "$WALLET_PASSWORD" \
      --view-key "$WALLET_VIEW_KEY" --spend-key "$WALLET_SPEND_KEY" \
      --log-file /data/wallet-service-import.log \
      --rpc-password "$WALLET_RPC_PASSWORD" --SYNC_FROM_ZERO || true
  fi

  echo "[entrypoint] starting wallet service..."
  /usr/local/bin/meduz-service -w /data/wallet.wallet -p "$WALLET_PASSWORD" \
    --bind-address 127.0.0.1 --bind-port 28070 \
    --log-file /data/wallet-service.log \
    --rpc-password "$WALLET_RPC_PASSWORD" &
  WALLET_PID=$!

  (
    for i in $(seq 1 40); do
      sleep 15
      BAL=$(curl -s -m 3 -X POST http://127.0.0.1:28070/json_rpc -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"0\",\"password\":\"${WALLET_RPC_PASSWORD}\",\"method\":\"getBalance\"}" 2>/dev/null)
      echo "[wallet-balance-check] ${BAL}"
    done
  ) &
fi

(
  sleep 30
  echo "[entrypoint] diag: /data size: $(du -sh /data 2>/dev/null | cut -f1)"
) &

if [ -n "$BACKUP_GIT_TOKEN" ]; then
  (
    sleep 60
    while true; do
      echo "[backup] running (max 120s)..."
      if timeout 120 /usr/local/bin/backup.sh > /tmp/backup_run.log 2>&1; then
        echo "[backup] OK: $(tail -1 /tmp/backup_run.log)"
      else
        echo "[backup] FAILED or timed out. Last output: $(tail -5 /tmp/backup_run.log)"
      fi
      sleep "$BACKUP_INTERVAL_SECONDS"
    done
  ) &
else
  echo "[entrypoint] BACKUP_GIT_TOKEN not set, automated chain backup disabled"
fi

wait $DAEMON_PID
