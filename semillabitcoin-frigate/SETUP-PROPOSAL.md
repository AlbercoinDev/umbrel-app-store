# Proposal: Frigate setup and configuration dashboard

This document proposes a feature; it does not implement it. The aim is to let
Umbrel users select the historical range and tune resource use without editing
container files, while protecting existing installations and indexes.

## First-run setup

On a new installation, start the dashboard but wait for explicit confirmation
before starting Frigate's initial index. Offer three choices:

1. **Full supported history:** use Frigate's default start height (709632 on
   mainnet, 0 on test networks).
2. **Block height:** enter a specific starting height.
3. **UTC date:** look up a suggested block height using the local Bitcoin Core
   or Electrs instance, then allow the user to review and edit it.

Warn clearly that selecting a later height can omit older Silent Payments and
that this cannot safely be inferred from a wallet's creation date. Confirm the
chosen height before starting; persist the confirmation so restarting the app
does not trigger the wizard again. Existing installations must continue to run
without being treated as new installs or reindexed.

For the date lookup, our implementation queries both local backends in parallel,
returns the first valid result, searches using median block time and applies a
144-block lookback. The result is an approximation, not a guarantee; check
backend synchronization, reject future or unavailable dates, show the selected
block and its time, and report failures without exposing credentials.

## Configuration dashboard

Expose validated settings with explanatory help, including:

| Setting | Purpose | Example |
| --- | --- | --- |
| Start height | Earliest block included in the index | Empty uses upstream default |
| ScriptPubKey cache | Indexing speed versus RAM | `1M` |
| DuckDB memory limit | Limit the DuckDB pool, not total app memory | `1GB` |
| DuckDB threads | Control scan parallelism and CPU load | `2` |
| Compute backend | Select supported compute backend | `CPU`, `AUTO`, `GPU` |
| Max labels / SP subscriptions | Control per-subscription and per-connection limits | `10` / `5` |
| RPC timeout and batch size | Adjust Bitcoin Core requests | `60` seconds / `100` |
| Metrics | Enable or disable aggregate scan metrics | `true` |

Optional GPU batch size can be exposed for installations using a GPU. These
are examples, not universal recommendations: explain that a smaller cache may
slow indexing, DuckDB's pool is not the total RAM used by the app, and tighter
subscription limits can affect wallet compatibility.

Persist settings independently of generated `config.toml`, validate all values
before writing them, and restart Frigate gracefully after a confirmed change.
Changes to the start height are special: warn that they require rebuilding the
index, ask for explicit confirmation, and never delete or rebuild an existing
index silently during an upgrade. Keep credentials private, write config files
with restrictive permissions, and protect state-changing dashboard requests
against unauthorized access and CSRF.

## Status and verification

Display indexing progress, configured start height, current status, connection
details and recent logs. Read only a bounded tail of the log to avoid loading an
unbounded file into memory. Consider an optional indexing performance profile,
but make its higher temporary RAM requirements explicit and allow users to
choose a low-memory profile from the outset.

Before release, test new installs, preservation of existing settings and indexes,
date lookup failure and synchronization cases, restart behavior, invalid
inputs, wallet connectivity and memory use on real Umbrel hardware. In
particular, changing the start height must require explicit consent and an
index rebuild; unrelated configuration changes must not rebuild the index.

## Reference implementation

Albercoin's Frigate app implements a first-run wizard, local date-to-height
lookup, configurable settings, bounded log reads and profile transitions:

- [App documentation](https://github.com/AlbercoinDev/Umbrel-AppStore-Albercoin/blob/master/albercoin-store-frigate/README.md#configuración)
- [Dashboard and Frigate startup code](https://github.com/AlbercoinDev/Umbrel-AppStore-Albercoin/blob/master/albercoin-store-frigate/docker-compose.yml)
- [Offline tests](https://github.com/AlbercoinDev/Umbrel-AppStore-Albercoin/blob/master/albercoin-store-frigate/tests/test_frigate.py)

It is an example of functionality, not a request to replace the Semilla
architecture wholesale. Its optional initial-indexing profile temporarily uses
more memory, so it should not be assumed to suit every Umbrel device.
