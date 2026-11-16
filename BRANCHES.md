# 操作系统实验分支管理

余欣泽 · 24301048

## 分支约定

- `master`：仓库说明与稳定入口；当前保留实验一源码，后续实验的代码在对应分支开发。
- `lab1`：已经完成的实验一，包含最终程序、阶段源码、验证日志、截图和全部8次原有提交。
- `lab2`：实验二的工作分支，目前待开展，基于实验一完成版本初始化。
- `lab3`：实验三的预留分支，目前待开展，基于实验一完成版本初始化；若课程要求承接实验二，开始前先合入实验二完成版本。
- `lab1-v1.0`：实验一完成版本的附注标签，固定指向 `162fcca5091c2e46f5f6c48d04907da41c3c4a47`，用于准确复现，不移动该标签。

实验二、三当前的分支存在并不表示实验已经完成。它们暂时与实验一具有相同源码和历史，没有为凑数创建空提交。后续开发实验二、三时，应将修改提交到各自分支，保留实验一的可复现版本。

## 拉取指定实验

```bash
# 实验一：完整仓库和提交历史
git clone --branch lab1 https://github.com/three-penny/Operating-System.git GardenerOS-lab1

# 实验二：目前是待开展的起始版本
git clone --branch lab2 https://github.com/three-penny/Operating-System.git GardenerOS-lab2

# 实验三：目前是待开展的起始版本
git clone --branch lab3 https://github.com/three-penny/Operating-System.git GardenerOS-lab3
```

上述克隆不会限制历史深度。每个目录都保留 `.git` 和完整提交信息，且可继续获取其他实验分支。

## 在已有仓库中切换

先查看 `git status --short`。如果有未提交修改，先在所属实验分支保存并提交；然后执行：

```bash
git fetch origin
git switch lab1
git pull --ff-only
```

将 `lab1` 换成 `lab2` 或 `lab3` 即可切换。不要将尚未提交的实验二修改带到实验一分支。若本地尚无同名分支且Git不能自动建立跟踪，可使用 `git switch --track origin/lab2`。

## 开展实验二

```bash
git fetch origin
git switch lab2
git pull --ff-only
# 按实验二文档实现、构建和验证
# git add 后按真实阶段提交，提交说明包含学号24301048
git push origin lab2
```

实验二完成后，在 `lab2` 上执行该实验对应的清理命令、检查工作区和验证记录，再创建新的版本标签（例如 `lab2-v1.0`）。保留各阶段提交；不要将历史压成单次提交，也不要把实验二代码合入 `lab1`。

## 实验三承接实验二

仅当实验二已完成、实验三分支仍未开展修改且课程要求承接实验二时，执行：

```bash
git fetch origin
git switch lab2
git pull --ff-only
git switch lab3
git merge --ff-only lab2
git push origin lab3
```

`--ff-only` 会在不能直接承接时停止，保留现有提交。此时先检查分支差异并按实际情况合并；不要通过强制推送或重置覆盖已有实验三工作。如果课程提供独立的实验三起始代码，应以课程要求为准。

## 准确复现实验一提交版本

```bash
git clone --branch lab1 https://github.com/three-penny/Operating-System.git GardenerOS-reproduce
cd GardenerOS-reproduce
git switch --detach lab1-v1.0
git log -1 --format=fuller
```

此时处于固定版本的查看状态。将该目录挂载到已经配置好的容器 `/mnt` 后，在容器中执行：

```bash
source /root/.cargo/env
cd /mnt
make build
make run
make verify
make clean
```

如要修改该固定版本，先创建自己的工作分支，再进行提交。

## 查看和提交Git信息

```bash
git branch -avv
git log --graph --oneline --decorate --all
git log --format=fuller --stat
git remote -v
git status --short --branch
```

原有实验一交付包和报告对应 `lab1-v1.0` 的8次提交。此次只在 `master` 增加分支管理说明，实验一源码和原提交版本继续保留。后续提交源码时仍需执行该实验的清理步骤，并保留 `.git` 或完整历史备份，以及作者、邮箱、日期、完整哈希和变更记录。GitHub的Download ZIP不包含 `.git`，不能替代带完整历史的提交包。
