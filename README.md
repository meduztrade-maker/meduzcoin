# Meduz (MDZ)

A private, CryptoNote-based cryptocurrency. Forked from [TurtleCoin](https://github.com/turtlecoin/turtlecoin) (itself CryptoNote/Bytecoin-derived).

## Status

Live test network. A seed node is running, mining, and holding a real, wallet-verified
balance. A second node exists but does not yet stay persistently synced (see Known
issues). Not yet public/announced — this is still the development/testing phase.

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

### Known issue: staying synced with only 1-2 nodes

Seed connections in this codebase use `just_take_peerlist=true`
(`NodeServer::connections_maker` in `src/P2p/NetNode.cpp`) — by design, a seed
connection fetches the peer list and disconnects, it isn't meant to be a long-lived
sync connection. On a real network with many peers this is fine (you get a peer list,
then connect to those peers normally). With only one other node to find, there's
nothing else to connect to. `--add-priority-node` (wired up via the `PRIORITY_NODE`
env var, see Docker section) was tried as a fix and did not resolve it — the
connection still cycles handshake-then-close. Not yet root-caused further. Doesn't
affect the seed's own ability to mine and hold balance; it affects whether a second
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
