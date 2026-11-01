# Frigate resource profile

The pinned Frigate image generates its own `config.toml` at startup. The
`low-memory-entrypoint.sh` adapter adds the following settings to that generated
configuration while retaining the image's existing startup and authentication:

```toml
[index]
cacheSize = "1M"

[scan]
dbThreads = 2
memoryLimit = "1GB"
maxSubscriptions = 5
```

This profile applies during initial indexing as well as normal operation. A
smaller cache can make indexing substantially slower, and the subscription
limit may need revisiting for clients with many Silent Payments subscriptions.
The DuckDB pool limit is **not** a total RAM limit: Java, the scriptPubKey
cache, native allocations, Bitcoin Core, Electrs and other apps also need RAM.
No Docker memory limit is imposed. The existing index and start height are not
changed. Test peak memory and indexing time on representative hardware.

The adapter checks the expected template sections before starting. When the
image is updated, verify its entrypoint remains compatible or replace the
adapter with native resource options in the image.
