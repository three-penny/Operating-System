# Run in the configured Linux container after loading ~/.cargo/env.
SHELL := /bin/bash
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
.DEFAULT_GOAL := help
.PHONY: help build run verify clean
help:
	@printf '%s\n' 'make build  - build the final RISC-V program' 'make run    - build and run the final program' 'make verify - verify all experiment stages' 'make clean  - remove generated build directories, keep sources/logs/.git'
build:
	cd "$(ROOT)/os" && cargo build --color never
run: build
	cd "$(ROOT)/os" && qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os
verify:
	bash "$(ROOT)/lab1/verify.sh" all
clean:
	bash "$(ROOT)/lab1/clean.sh"
