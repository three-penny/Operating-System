# 实验二：裸机执行环境与最小化内核

## 实验目标

将实验一依赖 Linux 用户态系统调用的 RISC-V 程序改造成由 OpenSBI 启动的裸机内核。内核固定加载到 `0x80200000`，自行设置启动栈、清理 BSS，通过 SBI 控制台输出，并在 panic 后请求关机。

## 环境准备

在课程配置好的 `gardeneros` 容器中运行，进入容器后加载 Rust 环境：

```bash
source /root/.cargo/env
cd /mnt
```

请优先使用老师提供的 `opensbi.bin`，放在仓库根目录的 `bootloader/opensbi.bin`。本次未取得课程固件，因此用 OpenSBI 官方 v1.9 generic `fw_jump.bin` 完成验证；来源和 SHA-256 记录于 `lab2/logs/opensbi-source.txt`。如课程固件与此版本不同，应换成老师版本并重新执行验证。仓库不分发固件。需要 Rust 的 `riscv64gc-unknown-none-elf` target、`rust-objcopy`/`rust-readobj`（由 cargo-binutils 提供）以及 `qemu-system-riscv64`。

## 构建与运行

```bash
cd /mnt/os
make env       # 初次准备 Rust target、组件和 cargo-binutils
make build     # 编译 release ELF 并生成 os.bin
make verify    # 检查 ELF 入口、镜像并在 QEMU 启动
make run       # 单独运行 QEMU
make clean     # 删除 target 和生成的 os.bin
```

也可按实验文档逐条执行：

```bash
cargo build --release
rust-readobj -h target/riscv64gc-unknown-none-elf/release/os
rust-objcopy --binary-architecture=riscv64 target/riscv64gc-unknown-none-elf/release/os --strip-all -O binary target/riscv64gc-unknown-none-elf/release/os.bin
qemu-system-riscv64 -machine virt -nographic -bios ../bootloader/opensbi.bin -device loader,file=target/riscv64gc-unknown-none-elf/release/os.bin,addr=0x80200000
```

成功时应看到 ELF entry 为 `0x80200000`、各节地址、`Hello, world!` 和 panic 信息，随后由 SBI 关闭 QEMU 虚拟机。若初始实验版本卡住，先检查 ELF 的 Entry；默认链接布局不保证位于 OpenSBI 约定的加载地址。

## 代码结构

- `os/src/linker.ld` 固定内核入口地址并排列 `.text`、`.rodata`、`.data`、栈和 `.bss`，同时导出边界符号。
- `os/src/entry.asm` 是最先执行的入口，切换到内核栈后调用 Rust 函数。
- `os/src/sbi.rs` 使用 `ecall` 调用 OpenSBI 的 legacy console 和 shutdown 服务。
- `os/src/console.rs` 将 `core::fmt::Write` 接到 SBI 字符输出，并提供格式化宏。
- `os/src/lang_items.rs` 实现 `no_std` 程序必须提供的 panic handler。
- `os/src/main.rs` 清零 BSS，显示链接段边界，并触发 panic 以验证诊断与关机路径。

## 报告与 Git

实验报告位于 `lab2/report/24301048_余欣泽_实验2_裸机执行环境与最小化内核.docx`。本实验使用独立的 `lab2` 分支，起点为实验一固定提交；功能按启动布局、SBI 与异常处理、运行材料和报告分成多次提交。查看完整树：

```bash
git log --graph --oneline --decorate lab2
git log --format=fuller --stat lab2
```

固定版本标签为 `lab2-v1.0`，指向包含最终报告和真实 QEMU 验证日志的提交。清理构建文件不会改变源码或 Git 历史。
