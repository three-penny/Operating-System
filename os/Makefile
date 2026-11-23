TARGET := riscv64gc-unknown-none-elf
MODE := release
KERNEL_ELF := target/$(TARGET)/$(MODE)/os
KERNEL_BIN := $(KERNEL_ELF).bin
BOOTLOADER := ../bootloader/opensbi.bin
KERNEL_ENTRY_PA := 0x80200000
OBJDUMP := rust-objdump --arch-name=riscv64
OBJCOPY := rust-objcopy --binary-architecture=riscv64

.DEFAULT_GOAL := build
.PHONY: help build env kernel clean disasm run verify

help:
	@printf '%s\n' 'make build   - build ELF and raw kernel binary' \
	              'make kernel  - build the release ELF' \
	              'make run     - build and launch with OpenSBI in QEMU' \
	              'make verify  - check ELF entry, binary, and boot output' \
	              'make disasm  - show RISC-V disassembly' \
	              'make clean   - remove generated build files'

env:
	@rustup target list --installed | grep -qx '$(TARGET)' || rustup target add $(TARGET)
	@rustup component list --installed | grep -q '^rust-src ' || rustup component add rust-src
	@rustup component list --installed | grep -q '^llvm-tools ' || rustup component add llvm-tools-preview
	@command -v rust-objcopy >/dev/null || cargo install cargo-binutils

kernel:
	cargo build --release

build: kernel
	$(OBJCOPY) $(KERNEL_ELF) --strip-all -O binary $(KERNEL_BIN)

run: build
	@test -f $(BOOTLOADER) || { echo 'Missing teacher-provided ../bootloader/opensbi.bin' >&2; exit 2; }
	qemu-system-riscv64 -machine virt -nographic -bios $(BOOTLOADER) \
		-device loader,file=$(KERNEL_BIN),addr=$(KERNEL_ENTRY_PA)

verify: build
	@rust-readobj -h $(KERNEL_ELF) | tee target/$(TARGET)/$(MODE)/elf-header.txt
	@grep -Eiq 'Entry:[[:space:]]*0x0*80200000' target/$(TARGET)/$(MODE)/elf-header.txt
	@test -s $(KERNEL_BIN)
	@test -f $(BOOTLOADER) || { echo 'Missing teacher-provided ../bootloader/opensbi.bin; QEMU check skipped' >&2; exit 2; }
	@set -o pipefail; timeout 30s qemu-system-riscv64 -machine virt -nographic -bios $(BOOTLOADER) \
		-device loader,file=$(KERNEL_BIN),addr=$(KERNEL_ENTRY_PA) 2>&1 | tee target/$(TARGET)/$(MODE)/qemu-output.txt
	@grep -q 'Hello, world!' target/$(TARGET)/$(MODE)/qemu-output.txt
	@grep -q 'Panicked at' target/$(TARGET)/$(MODE)/qemu-output.txt
	@echo 'EXPERIMENT 2 CHECKS PASSED'

disasm: kernel
	$(OBJDUMP) -d $(KERNEL_ELF)

clean:
	cargo clean
	rm -f $(KERNEL_BIN)
