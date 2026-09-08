# Meduz (MDZ)

A private, CryptoNote-based cryptocurrency. Forked from [TurtleCoin](https://github.com/turtlecoin/turtlecoin) (itself CryptoNote/Bytecoin-derived).

## Status

Live test network. A seed node and a second peer node are running, syncing, and mining
in real time. Not yet public/announced — this is still the development/testing phase.

## Coin parameters

| | |
|---|---|
| Ticker | MDZ |
| Address prefix | `UZMDi...` |
| Total supply | 50,000,000 MDZ |
| Block time | 30 seconds (target) |
| Decimals | 2 |

## Network

- Seed node: `tokaido.proxy.rlwy.net:26381`
- To connect a new node to the network, no extra flags are needed — the seed above
  is baked into `src/config/CryptoNoteConfig.h` as the default seed.

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

### Docker

`Dockerfile` builds the daemon and a CPU miner into one image. The container starts
the daemon, waits for its RPC, then attaches the miner (`MINE_ADDRESS` / `MINE_THREADS`
env vars override the defaults). Mount a volume at `/data` for the chain to survive
redeploys.

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
