#!/usr/bin/env bash
# Remove build products only; preserve source, evidence, logs and Git history.
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd -P)
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi
unset CARGO_TARGET_DIR
for relative in os/target lab1/target target; do
    candidate="$repo/$relative"
    resolved=$(realpath -m -- "$candidate")
    if [[ -L "$candidate" || "$resolved" != "$candidate" ]]; then
        printf 'Refusing unexpected build-directory path: %s -> %s\n' "$candidate" "$resolved" >&2
        exit 1
    fi
done
printf '$ cargo clean --manifest-path os/Cargo.toml --target-dir os/target\n'
(cd "$repo/os" && cargo clean --color never --target-dir "$repo/os/target")
for relative in lab1/target target; do
    printf '$ rm -rf -- %s\n' "$relative"
    rm -rf -- "$repo/$relative"
done
for relative in os/target lab1/target target; do
    if [[ -e "$repo/$relative" || -L "$repo/$relative" ]]; then
        printf 'FAIL: remaining build directory: %s\n' "$relative" >&2
        exit 1
    fi
    printf 'PASS: %s is absent\n' "$relative"
done
[[ -d "$repo/.git" && -f "$repo/os/src/main.rs" && -d "$repo/lab1/stages" ]]
printf 'CLEAN CHECK PASSED: source files and Git history are preserved.\n'
