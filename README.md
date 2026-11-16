# 操作系统实验

余欣泽 · 24301048

本仓库包含实验 0 的环境配置记录，以及实验 1 的 RISC-V 无标准库可执行程序和各阶段验证材料。

## 实验分支导航

| 分支 | 用途 | 当前状态 |
| --- | --- | --- |
| `master` | 仓库总览、稳定入口和分支使用说明 | 当前源码仍对应实验一；后续实验在各自分支开发 |
| [`lab1`](https://github.com/three-penny/Operating-System/tree/lab1) | 实验一 独立的可执行程序 | 已完成，保留全部8次阶段与验证提交 |
| [`lab2`](https://github.com/three-penny/Operating-System/tree/lab2) | 实验二 | 待开展，暂以实验一完成版本初始化 |
| [`lab3`](https://github.com/three-penny/Operating-System/tree/lab3) | 实验三 | 待开展，暂以实验一完成版本初始化 |

实验一完成版本标签为 [`lab1-v1.0`](https://github.com/three-penny/Operating-System/tree/lab1-v1.0)，对应提交 `162fcca5091c2e46f5f6c48d04907da41c3c4a47`。标签用于准确复现该次提交；`lab2`、`lab3` 目前尚未实现对应实验。

单独拉取实验一，并保留完整Git历史：

```bash
git clone --branch lab1 https://github.com/three-penny/Operating-System.git GardenerOS-lab1
cd GardenerOS-lab1
git log --format=fuller --stat
```

在现有仓库切换实验：先用 `git status --short` 确认没有未提交修改，再执行 `git fetch origin`、`git switch lab2` 和 `git pull --ff-only`。实验三如需承接实验二，应在实验二完成且实验三尚未开始修改时快进合入实验二；完整操作见 [BRANCHES.md](BRANCHES.md)。

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

## Make 构建与提交前清理

在已配置好的 openEuler 容器中执行：

```bash
source /root/.cargo/env
cd /mnt
make build
make run
make verify
make clean
```

`make clean` 通过 Cargo 清理最终程序的 `os/target/`，并移除阶段验证产生的 `lab1/target/` 和根目录 `target/`。清理过程会检查目录边界，保留源码、Cargo.lock、日志、截图和 `.git/`；也支持进入 `os/` 后执行 `make clean`。清理后如需运行，应重新执行 `make build`。

提交的源码必须为清理后的版本，不能包含 target 目录、编译出的 ELF、对象文件或 core dump。Git 历史应同时保留；普通 GitHub Download ZIP 或 `git archive` 不包含 `.git/`，因此不能单独作为带 Git 记录的提交材料。
