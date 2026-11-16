# 实验源码提交说明

学号：24301048
姓名：余欣泽
远程仓库：https://github.com/three-penny/Operating-System.git
分支：master

## 清理后的代码

2026年11月16日在配置好的 openEuler 容器中重新执行 `make build`、`make run`、`make verify`，全部阶段验证通过。随后执行 `make clean`，并复核 `make -C os clean` 入口；最终提交时不存在 `os/target/`、`lab1/target/` 和根目录 `target/`。

- 最终源码：`os/src/main.rs`。
- 阶段源码：`lab1/stages/00-standard.rs` 至 `04-exit9.rs`。
- 全部复验输出：`lab1/logs/submission-verify.txt`。
- 实际清理输出：`lab1/logs/make-clean.txt`。
- 完整终端窗口截图：`lab1/evidence/clean.png`。
- 清理不会删除 Cargo.lock、源码、日志、截图或 Git 历史。

## 完整 Git 信息

仓库保留各阶段源码和真实的多次提交，不压缩为单次提交，不改写作者或历史时间。提交说明包含学号；每条提交均可查看完整哈希、作者姓名与邮箱、作者日期、提交者日期、说明及文件差异。

```bash
git log --graph --oneline --decorate --all
git log --format=fuller --stat
git show <commit-hash>
git remote -v
git status --short --branch
```

源码提交包包含隐藏目录 `.git/`，解压后进入 `GardenerOS` 即可运行上述命令。包内另外提供完整文本历史和提交元数据，避免隐藏目录未显示时误以为没有历史。请使用保留隐藏文件的解压工具，不要只提交 GitHub 的 Download ZIP 或 `git archive` 生成的无历史快照。

## 复现和再次清理

在已安装固定 Rust 工具链与 QEMU 的 Linux 环境中：

```bash
source /root/.cargo/env
cd /mnt
make build
make run
make verify
make clean
```

本实验最终程序通过 `qemu-riscv64` 运行。Windows 主机可使用已配置的 `gardeneros` 容器；其他电脑需先按实验0报告配置环境，并将解压后的仓库挂载到容器 `/mnt`。清理后的包不携带预编译程序，运行前需要重新构建。
