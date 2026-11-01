#!/bin/sh
# Adapt the pinned image's generated config without changing its startup logic.
# Revisit this adapter whenever the server image/entrypoint is updated.
set -eu

source_entrypoint=/entrypoint.sh
adapted_entrypoint=/tmp/frigate-low-memory-entrypoint.sh

# Fail closed if a future image changes the expected config template.
for section in '[index]' '[scan]' '[server]'; do
    if [ "$(grep -Fxc "$section" "$source_entrypoint")" != 1 ]; then
        echo "Unexpected Frigate entrypoint: missing or duplicate $section" >&2
        exit 1
    fi
done

sed \
    -e '/^\[scan\]$/i cacheSize = "1M"' \
    -e '/^\[server\]$/i dbThreads = 2\nmemoryLimit = "1GB"\nmaxSubscriptions = 5' \
    "$source_entrypoint" > "$adapted_entrypoint"

exec /bin/bash "$adapted_entrypoint" "$@"
