# Run in the configured Linux container after loading ~/.cargo/env.
SHELL := /bin/bash
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
.DEFAULT_GOAL := build
.PHONY: help build run verify clean env
help:
	@printf '%s\n' 'make build  - build Experiment 2 kernel and raw image' 'make run    - build and run with OpenSBI' 'make verify - verify ELF and QEMU output' 'make clean  - remove generated build files' 'make env    - prepare the Rust target and tools'
env:
	$(MAKE) -C "$(ROOT)/os" env
build:
	$(MAKE) -C "$(ROOT)/os" build
run: build
	$(MAKE) -C "$(ROOT)/os" run
verify:
	$(MAKE) -C "$(ROOT)/os" verify
clean:
	$(MAKE) -C "$(ROOT)/os" clean
