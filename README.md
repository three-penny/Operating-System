# 操作系统实验

余欣泽 · 24301048

本仓库包含实验 0 的环境配置记录，以及实验 1 的 RISC-V 无标准库可执行程序和各阶段验证材料。

## 实验环境

- Windows 主机通过 Docker Desktop 运行 openEuler 24.03 LTS SP4。
- 容器名称为 `gardeneros`；本地 `C:\Users\yxzdt\GardenerOS` 挂载到容器 `/mnt`。
- Rust 固定为 `nightly-2026-05-08`，编译目标为 `riscv64gc-unknown-none-elf`。
- QEMU 11.0.0 源码构建目标为 `riscv64-softmmu,riscv64-linux-user`。
- 已保存环境镜像 `myopeneuler:oslab`。挂载的项目文件独立于该镜像，需要由本仓库提供。

## 运行最终程序

在 Windows PowerShell 中运行：

```powershell
docker start gardeneros
docker exec -it gardeneros bash
```

进入容器后运行：

```bash
source /root/.cargo/env
cd /mnt/os
cargo build
qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os
echo $?
```

预期输出 `Hello, world!`，退出码为 `0`。最终程序通过 Linux `write`（64）和 `exit`（93）系统调用完成输出与退出。

## 验证全部阶段

```powershell
docker exec gardeneros bash /mnt/lab1/verify.sh all
```

脚本在 `lab1/target/` 下创建各阶段的临时 Cargo 项目，不改写 `os/src/main.rs`。运行日志保存在 `lab1/logs/`。

| 阶段 | 实测结果 |
| --- | --- |
| 标准 Rust 程序 | 主机目标上 `cargo run` 输出 `Hello, world!` |
| `no_std`、`no_main`，无 `_start` | 链接器警告找不到入口，ELF 入口为 0，text/data/bss 均为 0 |
| `_start` 中死循环 | 无输出；脚本在 2 秒后终止，timeout 状态为 124 |
| `_start` 直接返回 | 缺少合法返回目标，SIGSEGV，状态为 139 |
| `exit(9)` | QEMU 退出码为 9 |
| 最终输出程序 | `Hello, world!`；退出码为 0；跟踪可见 write 与 exit |
| 格式化宏 | `value=42 hex=2a`，同时验证无参数换行 |

`124` 是验证工具 `timeout` 的状态；`139` 是被信号终止的状态，均不表示成功返回。`exit(9)` 的状态是实验主动指定的返回值。

## 实现与说明材料的差异

1. `os/.cargo/config.toml` 使用当前 Cargo 推荐的文件名，内容仍指定课程要求的 RISC-V 目标。
2. 项目保持 edition 2021；入口写为 `#[unsafe(no_mangle)]`，显式声明符号导出的安全约束。
3. 修正示例打印宏中的模块路径和参数问题：当前项目没有 `console` 模块，`print` 接收 `fmt::Arguments`；宏统一通过 `format_args!` 转发。
4. `a0` 同时为系统调用的第一个参数和返回值，内联汇编通过 `inlateout("a0")` 表达该约定；`a1/a2` 传入其余参数，`a7` 传入系统调用号。
5. 课程给出的 USTC Git 索引路径返回 404，Cargo 改用清华 TUNA sparse 镜像：

```toml
[source.crates-io]
replace-with = "tuna"

[source.tuna]
registry = "sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"
```

## 独立性的边界

最终程序不依赖 `std`、libc 或常规 Rust 程序入口，但仍使用 `core` 和 Linux 系统调用 ABI。`qemu-riscv64` 为它提供 Linux 用户态执行环境，因此它还不是可通过 `qemu-system-riscv64` 直接启动的操作系统内核。

实验材料中的 Windows 路径与容器路径只对应本次环境；在其他电脑上应按实际位置重新挂载。
