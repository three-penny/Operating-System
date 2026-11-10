#!/usr/bin/env bash
# Run inside the configured openEuler container: bash /mnt/lab1/verify.sh [phase]
set -euo pipefail
export LC_ALL=C
source /root/.cargo/env
repo=$(cd "$(dirname "$0")/.." && pwd)
phase=${1:-all}
cd "$repo"
mkdir -p lab1/logs lab1/target
build_root="$repo/lab1/target"
log_root="$repo/lab1/logs"
ulimit -c 0

run() {
    printf '\n$ '
    printf '%q ' "$@"
    printf '\n'
    "$@"
}

prepare_stage() {
    local label=$1
    local source_file=$2
    stage_dir="$build_root/$label"
    mkdir -p "$stage_dir/src" "$stage_dir/.cargo"
    printf '[package]\nname = "os"\nversion = "0.1.0"\nedition = "2021"\n\n[dependencies]\n' > "$stage_dir/Cargo.toml"
    cp "$repo/lab1/stages/$source_file" "$stage_dir/src/main.rs"
    if [[ "$label" != standard ]]; then
        cp "$repo/os/.cargo/config.toml" "$stage_dir/.cargo/config.toml"
    fi
    cd "$stage_dir"
    run cargo build --color never
}

environment() {
    run cat /etc/os-release
    run rustc --version
    run cargo --version
    run rustup target list --installed
    run rustup component list --installed
    run qemu-system-riscv64 --version
    run qemu-riscv64 --version
}

standard() {
    prepare_stage standard 00-standard.rs
    run cargo run --color never
}

no_entry() {
    prepare_stage no-entry 01-no-entry.rs
    local binary=target/riscv64gc-unknown-none-elf/debug/os
    run file "$binary"
    run rust-readobj -h "$binary"
    run rust-objdump -S "$binary"
    run rust-size "$binary"
}

loop_stage() {
    prepare_stage loop 02-loop.rs
    printf '\n$ timeout 2s qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os\n'
    local result=0
    timeout 2s qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os || result=$?
    printf 'Observed status: %s (124 means timeout stopped the infinite loop)\n' "$result"
    [[ "$result" == 124 ]]
}

return_stage() {
    prepare_stage return 03-return.rs
    printf '\n$ timeout 2s qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os\n'
    local result=0
    timeout 2s qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os || result=$?
    printf 'Observed status: %s (139 means SIGSEGV)\n' "$result"
    [[ "$result" == 139 ]]
}

exit_stage() {
    prepare_stage exit9 04-exit9.rs
    printf '\n$ qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os\n'
    local result=0
    qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os || result=$?
    printf 'Observed exit status: %s\n' "$result"
    [[ "$result" == 9 ]]
}

final_stage() {
    cd "$repo/os"
    run cargo build --color never
    run file target/riscv64gc-unknown-none-elf/debug/os
    run rust-readobj -h target/riscv64gc-unknown-none-elf/debug/os
    rust-objdump -S target/riscv64gc-unknown-none-elf/debug/os > "$log_root/final-disassembly.txt" 2>&1
    run rust-objdump -d --disassemble-symbols=_start target/riscv64gc-unknown-none-elf/debug/os
    printf '\n$ qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os\n'
    local result=0
    qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os > "$log_root/final-stdout.txt" || result=$?
    cat "$log_root/final-stdout.txt"
    printf 'Observed exit status: %s\n' "$result"
    [[ "$result" == 0 ]]
    [[ "$(cat "$log_root/final-stdout.txt")" == 'Hello, world!' ]]
    printf '\n$ qemu-riscv64 -strace target/riscv64gc-unknown-none-elf/debug/os\n'
    qemu-riscv64 -strace target/riscv64gc-unknown-none-elf/debug/os
}

formatting() {
    local stage_dir="$build_root/formatting"
    mkdir -p "$stage_dir/src" "$stage_dir/.cargo"
    cp "$repo/os/Cargo.toml" "$stage_dir/Cargo.toml"
    cp "$repo/os/.cargo/config.toml" "$stage_dir/.cargo/config.toml"
    sed 's/println!("Hello, world!");/print!("value={} ", 42); println!("hex={:x}", 42); println!();/' "$repo/os/src/main.rs" > "$stage_dir/src/main.rs"
    cd "$stage_dir"
    run cargo build --color never
    printf '\n$ qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os\n'
    qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os > "$log_root/formatting-stdout.txt"
    cat "$log_root/formatting-stdout.txt"
    [[ "$(cat "$log_root/formatting-stdout.txt")" == 'value=42 hex=2a' ]]
}

case "$phase" in
    environment|standard|no_entry|loop_stage|return_stage|exit_stage|final_stage|formatting)
        "$phase" 2>&1 | tee "$log_root/$phase.txt"
        ;;
    all)
        for step in environment standard no_entry loop_stage return_stage exit_stage final_stage formatting; do
            printf '\n=== %s ===\n' "$step"
            ("$step") 2>&1 | tee "$log_root/$step.txt"
        done
        printf '\nALL EXPERIMENT CHECKS PASSED\n'
        ;;
    *) printf 'Unknown phase: %s\n' "$phase" >&2; exit 2 ;;
esac
