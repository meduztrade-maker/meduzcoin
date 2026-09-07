# Meduz (MDZ)

A private, CryptoNote-based cryptocurrency. Forked from [TurtleCoin](https://github.com/turtlecoin/turtlecoin) (itself CryptoNote/Bytecoin-derived).

## Status

Early development. Builds and runs a working single-node chain (genesis + premine verified). Not yet networked — no seed nodes are running publicly yet.

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
