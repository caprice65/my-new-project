# Creeps 对话上下文（供新对话继续）

> 生成自 Cursor 对话「Creeps」。下次开新对话时可 `@docs/CREEPS_CONTEXT.md` 或让 AI 先读此文件。

**仓库：** `g:\cursor\practce`  
**Godot 工程：** `g:\cursor\practce\dodge_the_creeps`（打开 `project.godot`，不要把仓库根目录当 Godot 项目）  
**远程：** `https://github.com/caprice65/my-new-project.git`（分支 `main`）  
**引擎：** Godot **4.7**，GDScript，Compatibility 渲染

---

## 1. 本对话做了什么（时间线）

1. **调研 / 下载参考**
   - 曾在 GitHub 找贪吃蛇示例并下载到 `refs/`，后来按用户要求**全部删除**。
   - 改用官方 Godot demo：只检出 `dodge_the_creeps`（Godot 4），因直连/稀疏克隆不稳，用 `gh api` 按文件下载。

2. **运行说明**
   - 本机曾无 Node/`gh` 不全；贪吃蛇阶段用 Python `http.server`。Godot 工程用编辑器打开即可。
   - Godot 路径（本机）：`f:\tools\Godot\Godot_v4.7.2-stable_win64.exe`

3. **第一轮优化（已落地）**
   - `Main` 编排 + `MobSpawner` 拆刷怪
   - 状态机、难度随分数、最高分 `user://save.cfg`
   - 玩家：`Input.get_vector`、`_physics_process`、只翻转动画不转碰撞体
   - HUD：`await` 竞态用 `sequence_token` 取消；Theme；Best 分

4. **第二轮优化 1～7（已落地）**
   1. 玩家 → `CharacterBody2D` + `HitArea`（Area2D）检测怪  
   2. 目录重组（后又再次细化，见下）  
   3. 怪物对象池  
   4. 暂停（Esc / P / 按钮）  
   5. 虚拟摇杆 → `GameState.instance.touch_input`  
   6. `AudioManager` Autoload 场景  
   7. `GameState` Autoload + `class_name`

5. **Git**
   - 写了根目录 / 项目 `.gitignore`（忽略 `.godot/`、`.vscode/` 等，**保留 `*.uid`**）
   - 曾把误提交的 `.godot` 从版本库撤掉并 push
   - **结论：`.uid` 应该提交并 push**

6. **Bug：怪刷在屏幕外 / 进不了场景（已修，多次迭代）**
   - 原因：PathFollow 边缘坐标 + 对象池瞬移时 `screen_exited` 误回收；`VisibleOnScreenNotifier2D` **没有** `monitoring` 属性
   - 当前方案：四边显式出生 + 向内 `spawn_inset`；本地 `position`
   - **已取消 RigidBody2D 对象池**（复用时物理变换/信号会导致后半段闪没）；改回 instantiate + `queue_free`
   - 越界回收：mob `_physics_process` bounds 检测；出生：四边显式 + `spawn_inset`

7. **工程整理（当前结构）**
   - 脚本/场景按 `core` / `game` / `ui` / `actors` / `systems` 分子目录
   - 音频改名：`audio/house_in_a_forest_loop.ogg`
   - 文档：根 `README.md`、`dodge_the_creeps/README.md`、本文件
   - `practce.code-workspace`：可同时打开仓库根与 Godot 工程

---

## 2. 当前目录结构

```
practce/
├── README.md
├── docs/CREEPS_CONTEXT.md          ← 本文件
├── practce.code-workspace
├── .gitignore
├── .vscode/settings.json           # Godot 编辑器路径（勿提交依赖本机路径也可）
└── dodge_the_creeps/
    ├── project.godot
    ├── README.md                   # 架构与「改哪里」表
    ├── scenes/
    │   ├── main.tscn
    │   ├── actors/player.tscn, mob.tscn
    │   ├── ui/hud.tscn
    │   └── systems/audio_manager.tscn
    ├── scripts/
    │   ├── core/game_state.gd, audio_manager.gd
    │   ├── game/main.gd, player.gd, mob.gd, mob_spawner.gd
    │   └── ui/hud.gd, virtual_joystick.gd
    ├── art/  audio/  fonts/  screenshots/
    └── ...
```

---

## 3. 架构要点（必读）

### Autoload（`project.godot`）

| Autoload 节点名 | 资源 | 代码访问 |
|-----------------|------|----------|
| `GameStateAutoload` | `scripts/core/game_state.gd` | **`GameState.instance`**，枚举 **`GameState.State`** |
| `AudioManagerAutoload` | `scenes/systems/audio_manager.tscn` | **`AudioManager.instance`** |

**不要**再写裸的 `GameState.begin_playing()`（除非再改成静态门面）。  
原因：仓库根不是 Godot 项目根，IDE 读不到 Autoload 全局名；用 `class_name` + `instance` 避免「Identifier GameState not declared」。

### 状态机 `GameState.State`

`IDLE` → `READY`（Get Ready）→ `PLAYING` → `GAME_OVER`；另有 `PAUSED`（仅从 PLAYING 进入）。

### 职责划分

| 模块 | 文件 | 职责 |
|------|------|------|
| 编排 | `scripts/game/main.gd` | 开局/结束接线、计时器、调 spawner / HUD / Audio |
| 状态 | `scripts/core/game_state.gd` | 分数、最高分、暂停、`touch_input` |
| 玩家 | `scripts/game/player.gd` | `CharacterBody2D`，键盘+摇杆，HitArea 碰怪发 `hit` |
| 刷怪 | `scripts/game/mob_spawner.gd` | Path2D 边缘出生、难度、对象池 |
| 怪 | `scripts/game/mob.gd` | 池化 activate/deactivate，出屏 `recycled` |
| UI | `scripts/ui/hud.gd` 等 | 分数、暂停层、摇杆、Game Over 流程 |

### 碰撞约定

- 怪：`RigidBody2D`，`collision_layer = 1`，`mask = 0`
- 玩家身体：layer/mask = 0（不物理撞怪）
- 玩家 `HitArea`：`mask = 1`，用 `body_entered` 检测怪

### 存档

- 路径：`user://save.cfg`
- section/key：`score` / `high`

---

## 4. Git / 忽略规则

- **忽略：** `.godot/`、`.vscode/`（根 gitignore）、导出配置、系统垃圾文件  
- **要提交：** 源码、场景、`*.import`、`*.uid`、`art/`、`audio/`、文档  
- 推 `main` 可能需审批（受保护分支）

未提交内容可能仍包括：目录重组、刷怪修复、本上下文文档——新对话里先 `git status` 确认。

---

## 5. 已知注意点 / 坑

1. **必须打开** `dodge_the_creeps/project.godot`，不要把 `practce/` 当 Godot 项目。  
2. 访问状态/音频一律 **`GameState.instance` / `AudioManager.instance`**。  
3. 刷怪路径按 **480×720** project 设置，勿再随意用未就绪的 viewport 尺寸重建。  
4. 对象池瞬移时先关 `VisibleOnScreenNotifier2D.monitoring`，就位后再 deferred 打开。  
5. HUD Game Over 有异步 `await`，开新局要走 `cancel_game_over_sequence()`。  
6. 本机曾无 `gh`；GitHub 直连不稳时可用 API/镜像（历史问题）。  
7. 对话标题可在 Cursor 历史里手动改名（AI 改不了）。

---

## 6. 尚未做 / 可后续加（可选）

- 难度档位、音量/设置页  
- 受击闪白、震屏等反馈  
- 更完善的移动端安全区  
- 把仓库根与 Godot 工程关系写进 CI（若需要）

---

## 7. 新对话建议开场

可复制：

```text
请先阅读 @docs/CREEPS_CONTEXT.md 和 @dodge_the_creeps/README.md。
当前 Godot 工程在 dodge_the_creeps/，继续在此基础上修改。
```

然后说明本次具体任务即可。
