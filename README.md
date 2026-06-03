# Jared's AI Team

[![Checkpoint](https://github.com/JaredLin1217/Agents/actions/workflows/checkpoint.yml/badge.svg)](https://github.com/JaredLin1217/Agents/actions/workflows/checkpoint.yml)
[![Public Updates](https://github.com/JaredLin1217/Agents/actions/workflows/public-updates.yml/badge.svg)](https://github.com/JaredLin1217/Agents/actions/workflows/public-updates.yml)

Jared's AI Team 是一套 **repo-local AI 核心治理与 runtime 系统**。它的目标不是替客户项目增加一个新的应用框架，而是把 AI 协作时最容易失控的部分变成项目内部可读取、可验证、可部署、可恢复的工作规则。

当它部署到客户项目后，Codex 或其他 AI coding session 可以先读取项目本地规则，再依照当前任务只展开必要的治理文件、执行最小验证、记录 runtime evidence，并在结束时留下清楚的状态与风险。客户项目因此不需要依赖隐藏对话记忆、个人机器习惯或一次性的人工口头约定，也可以避免 AI 在长任务、多窗口、多员工派工、部署与发布流程中不断重复读取大量上下文。

## 它为客户项目带来的核心价值

### 1. 项目规则留在项目内

每个客户项目都可以拥有自己的 AI 工作规则。AI 不需要猜测这个项目该怎么编辑、怎么部署、怎么验证、怎么交接，而是先读取 repo-local 规则，再按任务路由执行。

这会带来三个直接好处：

- 新的 Codex 工作阶段可以快速理解项目工作方式。
- 不同项目之间不会因为全局记忆或个人偏好互相污染。
- 项目交给其他人、其他机器或其他窗口时，规则仍然跟着 repo 走。

### 2. 降低 token 与上下文消耗

本系统采用 route-first 的读取方式。AI 不会每次都读取整套说明，而是先判断任务类型，再只展开该任务必要的最小文件集合。

对客户项目的实际帮助是：

- 简单问题不会触发大型规则读取。
- 编辑、部署、派工、发布各自有独立读取路径。
- 长任务可以用 compact summary 与 knowledge footprint 接续，不需要保留完整原始对话。
- 多员工任务只整合部门报告，不把所有 worker chatter 都塞回主线。

### 3. 把 AI 动作变成可验证流程

AI 最危险的不是不会做事，而是做完后无法证明自己做对了什么。Jared's AI Team 把验证放进流程本身：编辑有编辑验证，部署有部署验证，发布有发布验证，runtime 执行有 evidence，异常有 escalation record。

客户项目可以得到：

- 明确的验证入口，而不是只听 AI 口头保证。
- 每次部署、发布、派工都能留下结果摘要。
- 高风险写入、部署、外部访问、模型升级必须经过 approval 或 escalation。
- 失败时可以知道是规则失败、验证失败、权限失败还是 cleanup 失败。

### 4. 支持多员工与企业式派工

本系统把「主线 controller」和「部门领导」分开。主线默认只派任务给部门领导，部门领导可以自行决定是否拆给内部员工，最后只回报一个部门报告。

这种模式适合客户项目中的复杂工作，例如：

- 部署部门负责多项目部署。
- QA 部门负责验收部署完整性。
- 架构部门负责分析项目结构与风险。
- 文档部门负责 README、runbook、公开说明。
- Provider Management 负责模型等级、供应商与能力边界。

好处是主线不会被大量子代理讯息淹没，也可以更容易追踪谁负责、谁验证、谁汇总、谁需要升级处理。

### 5. 支持可恢复的协作者窗口

协作者窗口可以把一个 Codex 工作阶段定义成可命名、可恢复的部门领导窗口。它适合长任务、跨窗口交接、主线上下文需要保持轻量的场景。

客户项目可以用这种方式做到：

- 新增一个协作者负责特定目标。
- 把协作者窗口命名成业务上可理解的部门。
- 让其他工作阶段透过共享状态、报告摘要与 evidence 接手。
- 不需要把完整对话历史复制给每一个窗口。

### 6. 让部署与发布更干净

部署到客户项目时，本系统使用 allowlist 复制规则，只部署 AI workflow 需要的内容，并保护目标项目自己的 `.git`、`.codex`、runtime state、secrets、local environment、应用源码和目标专属记忆。

这能降低两个常见风险：

- 把本机运行状态、thread id、API key 或历史 evidence 误发布到 GitHub。
- 覆盖客户项目本来就存在的本地配置或项目专属流程。

## 适合的使用场景

Jared's AI Team 适合这些客户项目：

- 需要长期和 Codex 或多 AI agent 协作的代码库。
- 需要把 AI 编辑、验证、部署、发布流程标准化的团队。
- 需要多窗口、多员工、多部门派工，但又不想让主线上下文爆炸的项目。
- 需要部署同一套 AI workflow 到多个项目，并保留各项目本地差异的工作室。
- 需要公开 repo 说明、版本记录、授权声明和 release package 审计的项目。

它不试图取代完整 SaaS、dashboard、数据库、provider gateway 或云端 agent 平台。它更像是项目内部的 AI runtime contract：把 AI 应该如何工作、如何证明、如何部署、如何交接写进 repo。

## 核心能力

| 能力 | 对客户项目的帮助 |
|---|---|
| Repo-local governance | 每个项目拥有自己的 AI 行为规则，减少全局习惯和隐藏记忆依赖。 |
| Route-first runtime | AI 只读取当前任务必要规则，降低 token、上下文和误触发成本。 |
| Runtime execution evidence | 记录 run、step、approval、tool evidence、result、cleanup，让动作可追溯。 |
| Enterprise dispatch | 主线只对部门领导下令，部门内部自行拆工，最终回报部门报告。 |
| Collaborator windows | 把 Codex 工作阶段变成可命名、可恢复、可封存的协作者窗口。 |
| Context compact | 保留最新目标、变更、验证、风险和下一步，不保存完整原始对话。 |
| Workflow artifacts | 用本地 runtime artifact 支撑派工、验证、收集与报告。 |
| Provider adapters | 用模型 tier 管理能力边界，不把流程写死到单一模型名称。 |
| Route packs | 产生 deterministic minimal read pack，方便低 token、可缓存的规则读取。 |
| Clean deployment | 按 allowlist 部署 workflow，保护客户项目本地状态与既有配置。 |
| Clean release export | 导出不含 runtime、secret、thread id、local config 的 release package。 |
| Validation gates | 用脚本验证版本、模板、部署、发布、runtime、派工与安全边界。 |

## 版本功能说明

目前版本：`2.5.0 Core Runtime System`

Current Agents workflow version: `2.5.0` (`core-runtime`).

Canonical version source：`docs/agents/version.yaml`

| 版本 | 新增功能 |
|---|---|
| `2.5.0` | 将项目定位升级为 Core Runtime System；整合 core system、runtime execution、provider adapters、route packs、knowledge footprint；强化 runtime blocklist、部署/发布审计、旧机制残留检查与版本对齐。 |
| `2.3.0` | 新增 Collaborator Window Dispatch Layer；支持命名部门领导工作阶段、create/rename/report/archive/close 生命周期、worker window 阻挡、thread evidence runtime-local 化。 |
| `2.2.1` | 新增 Context Compact Layer；记录 retained facts、dropped details、risk、resume pointer、changed files、subagent closeout counts，并排除 raw transcript。 |
| `2.2.0` | 新增 Supervised Workflow Artifact Layer；支持本地 workflow state、department leader packet、worker packet、verification packet、escalation packet、approval gate、collect 与 normalized report。 |
| `2.1.0` | 新增 Enterprise Dispatch Layer；定义组织部门、部门领导、允许员工角色、leader-only controller integration、model tier policy、escalation record 与 clean release package export。 |
| `2.0.0` | 新增公开 workflow 版本源、README 版本对齐、部署时版本提取、Apache-2.0 授权声明、GitHub issue/PR template 与 public update automation。 |
| Initial release | 建立 compact AI runtime route、repo-local project skill、template mirror、基础验证与部署规则。 |

## 基本使用方法

### 验证当前项目

```powershell
.\scripts\validate.ps1
```

部署、发布或大范围规则修改前执行完整审计：

```powershell
.\scripts\validate.ps1 -Full
```

### 在 Codex 工作阶段中使用

建议工作顺序：

1. 读取 `AGENTS.md`。
2. 读取 `docs/agents/ai-runtime.yaml`。
3. 依照 route 只展开必要规则。
4. 按 `docs/agents/verify.yaml` 的最小 profile 验证。
5. 结束时回报 isolation、验证结果、风险与 cleanup 状态。

常用请求范例：

```text
请用最小验证流程帮我完成这个 scoped edit。
```

```text
请派 QA 部门领导验收这次部署，并只回报一份 department report。
```

```text
请将本 Agents workflow 部署到 D:\target\repo，先 dry-run，再执行并验证。
```

### 部署到客户项目

先 dry-run：

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode template_provider_mode -DryRun
```

确认计划后部署：

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode template_provider_mode -Upgrade
```

部署原则：

- 只复制 allowlist 中的 workflow 内容。
- 保护目标项目自己的 `.git`、`.codex`、runtime state、secret、local environment 与目标专属记忆。
- 如果目标项目已有本地 environment 配置，保留目标原状；不存在时才按目标项目名称建立。
- 部署完成后必须验证版本、route、schema、script、template mirror 与 blocklist。

### 记录 runtime execution evidence

```powershell
.\scripts\agents-runtime.ps1 -Action NewRun -RunId "example"
.\scripts\agents-runtime.ps1 -Action AddStep -RunId "example" -Step "read_only"
.\scripts\agents-runtime.ps1 -Action AddResult -RunId "example" -Result "completed" -Summary "read-only example completed"
.\scripts\agents-runtime.ps1 -Action Verify -RunId "example"
.\scripts\agents-runtime.ps1 -Action Cleanup -RunId "example"
```

Runtime evidence 属于本机运行状态，不进入正式源码、部署包或 release package。

### 产生 route pack

```powershell
.\scripts\export-route-pack.ps1 -RouteId core_system
```

Route pack 用于输出 deterministic minimal read manifest，帮助 AI 在相同 route 下重复读取更少、更稳定的上下文。

### 导出干净 release package

```powershell
.\scripts\export-release-package.ps1
```

Release package 会排除 `.git/`、`.codex/`、`.agents/runtime/`、`.workflow/`、local environment、thread id、runtime evidence、secrets 与本机状态，并记录 version、commit、file list、file hashes 与 package hash。

## 项目边界与安全原则

- Global Memory 默认不使用，除非使用者明确要求。
- Global/system skills 默认不使用。
- Project-local skills 是项目内容的一部分，不等同全局技能。
- 不把 live runtime state、thread id、API key、provider session、本机部署历史或 Codex local config 放入部署或 release。
- 不宣称硬隔离，除非当前 runtime、工具、OS、账号或云端环境真的提供并已验证隔离证据。
- 高风险写入、部署、外部访问、破坏性操作、模型 tier upgrade 需要 approval gate 或 escalation record。
- 员工与协作者结束时必须留下 closeout evidence；无法验证硬删除时，只能声明 archive/close requested 或已关闭，不宣称完全删除。

## 对外公开资讯

- Update log：`docs/github-updates.md`
- Contribution guide：`CONTRIBUTING.md`
- Security policy：`SECURITY.md`
- Code of conduct：`CODE_OF_CONDUCT.md`

## 授权

Copyright 2026 Yu-Jie, Lin.

Licensed under the Apache License, Version 2.0. See `LICENSE` for the full license text and `NOTICE` for the project notice and additional disclaimer.

Unless required by applicable law or agreed to in writing, this repository is provided on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
