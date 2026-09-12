# Meduz (MDZ)

A private, CryptoNote-based cryptocurrency. Forked from [TurtleCoin](https://github.com/turtlecoin/turtlecoin) (itself CryptoNote/Bytecoin-derived).

## Status

Live test network. Seed and second node both running, mining, and staying in sync
with each other in real time. Wallet-verified balance on the seed. Not yet
public/announced — this is still the development/testing phase.

## Coin parameters

| | |
|---|---|
| Ticker | MDZ |
| Address prefix | `UZMDi...` |
| Total supply | 50,000,000 MDZ |
| Founder allocation | 5,000,000 MDZ (10%), paid at block height 1 — see below |
| Block time | 30 seconds (target) |
| Decimals | 2 |

### Why the founder allocation is at height 1, not in genesis

This fork's wallet sync (`SynchronizationState`) always seeds its "known blocks" list
with the genesis hash before scanning anything (`src/Transfers/SynchronizationState.h`).
That means genesis's own coinbase output is treated as always-already-known and is
**never scanned for wallet ownership** — a genesis premine would be real on-chain but
invisible to every wallet built from this codebase. Rather than patch wallet-sync
internals (higher risk, touches fund-safety-relevant code), the founder allocation is
paid as a bonus on a normal mined block instead (`FOUNDER_BONUS_HEIGHT` /
`FOUNDER_BONUS_AMOUNT` in `CryptoNoteConfig.h`, applied in
`Currency::getBlockReward`) — a block reward works exactly like every other mined
block and wallets scan it correctly. Verified with `tools/test_reward.cpp` and against
a real wallet balance.

## Network

- Seed node: `tokaido.proxy.rlwy.net:26381`
- To connect a new node to the network, no extra flags are needed — the seed above
  is baked into `src/config/CryptoNoteConfig.h` as the default seed.

### Staying synced with only 1-2 nodes

Seed connections in this codebase use `just_take_peerlist=true`
(`NodeServer::connections_maker` in `src/P2p/NetNode.cpp`) — by design, a seed
connection fetches the peer list and disconnects, it isn't meant to be a long-lived
sync connection. On a real network with many peers this is fine (you get a peer list,
then connect to those peers normally). With only one other node to find, there's
nothing else to connect to, so a second node needs `--add-priority-node` for a
maintained connection to the seed.

**Gotcha:** `--add-priority-node`'s parser only accepts a raw IP, not a hostname — it
silently drops anything it can't parse as one (no error, `Priority peers configured: 0`
in the logs is the only sign). Railway's TCP proxy is only reachable by hostname
(`tokaido.proxy.rlwy.net`), so `entrypoint.sh` resolves it to an IP with `getent hosts`
before passing it via `PRIORITY_NODE`. If you point this at a plain IP:port yourself,
skip the resolution step.
node stays caught up.

## Building

```
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

Notes for building with modern GCC (13+): this 2018-era codebase relies on some
headers that used to be included transitively and no longer are. `src/compat_fixes.h`
is force-included into every translation unit (see `CMakeLists.txt`) to paper over this
without touching every file individually.

**If you touch `CryptoNoteCore/Currency.h`:** it has a hand-written move constructor
(`Currency::Currency(Currency&&)`) that lists members individually. Any new member you
add must also be added there, or it silently keeps its default/garbage value after
`CurrencyBuilder::currency()` returns. This cost real debugging time once already.

### Docker

`Dockerfile` builds the daemon, wallet service, and a CPU miner into one image.
`entrypoint.sh` starts the daemon, waits for it to report synced (or a 5-minute
timeout) before starting the miner, and optionally imports/runs a wallet if wallet
keys are provided. Env vars:

| Var | Default | Purpose |
|---|---|---|
| `MINE_ADDRESS` | project address | where mining rewards go |
| `MINE_THREADS` | `1` | set to `0` to disable mining |
| `WALLET_VIEW_KEY` / `WALLET_SPEND_KEY` | unset | if both set, imports and runs a wallet, logging balance every 15s |
| `WALLET_PASSWORD` / `WALLET_RPC_PASSWORD` | `changeme` | set real values in production |
| `LOG_LEVEL` | `2` | raise to `3`/`4` to debug P2P/connection issues |
| `PRIORITY_NODE` | unset | `--add-priority-node` target (see Known issue above) |

Mount a volume at `/data` for the chain (and wallet) to survive redeploys — without
one, every redeploy starts a fresh chain from genesis.

## Backups

**Right now the entire chain exists only on Railway volumes under one account** — if
that account has a payment or ToS issue, everything (including the founder allocation)
is gone with no other copy anywhere. `backup.sh` mitigates this: if `BACKUP_GIT_TOKEN`
is set, `entrypoint.sh` runs it hourly, force-pushing a snapshot of `/data` to a
`chain-backup` branch on this repo (not `main`, to avoid bloating normal history).

This was a genuinely tricky bug hunt worth recording: it failed silently/differently
three separate times before working —
1. No `GIT_TERMINAL_PROMPT=0`: a bad credential could hang forever waiting on a
   prompt that doesn't exist in a container.
2. The runtime Docker stage never had `git` installed at all (only the builder stage
   did) — every git call failed instantly with "command not found".
3. `BACKUP_GIT_TOKEN` / `BACKUP_REPO` were plain shell variables in `entrypoint.sh`,
   not `export`ed — so the separate `backup.sh` process saw `BACKUP_REPO` as empty
   and built a URL like `https://TOKEN@github.com/.git`, which GitHub reports as
   "Not Found" rather than an obviously-empty-variable error.

This is a stopgap, not a real disaster-recovery setup — it's one person's GitHub
account backing up one person's Railway account. A real backup strategy would use an
independent storage provider and probably more than one location.

### If you actually have to restore from this backup

```
git clone -b chain-backup https://github.com/meduztrade-maker/meduzcoin.git restore
# restore/data/ now has everything: blockchain DB, wallet.wallet, logs
```

Verified end-to-end once: cloning the branch and pointing `meduzd --data-dir` at the
restored `data/` folder loads the full chain correctly (right height, no corruption).

**Important:** a restored node started completely alone (every other node lost too —
the actual disaster scenario) can never pass this codebase's `isSynchronized()` check
on its own, since that only flips true after a real peer handshake. Until it finds a
peer, mining and most RPC calls (including what the wallet needs) stay blocked with
"Core is busy" — even though the restored data is perfectly valid. Set
`MEDUZ_FORCE_READY=1` on that node to bypass the check and confirm you're intentionally
trusting the local restored data with no one else to verify against.

## Binaries

- `meduzd` — the daemon / node
- `meduz-wallet` — CLI wallet
- `meduz-service` — wallet RPC service
- `miner` — CPU miner

## License

LGPL / BSD-3-Clause, inherited from the CryptoNote / Bytecoin / TurtleCoin lineage.
See `LICENSE`. Copyright notices of upstream authors are preserved throughout the
codebase as required by these licenses.

## Tools

`tools/gen_address.cpp` — generates a real spend/view keypair + address using this
codebase's own crypto library (useful for premine/team addresses).
`tools/find_address_prefix.py` — brute-force search for a vanity Base58 address prefix
matching this fork's exact encoding scheme.
`tools/test_reward.cpp` — direct unit test of `Currency::getBlockReward` bypassing the
daemon/networking stack entirely; useful for verifying emission/bonus logic changes
before deploying them.
