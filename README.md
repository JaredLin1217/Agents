# Jared's AI Team

[![Checkpoint](https://github.com/JaredLin1217/Agents/actions/workflows/checkpoint.yml/badge.svg)](https://github.com/JaredLin1217/Agents/actions/workflows/checkpoint.yml)
[![Public Updates](https://github.com/JaredLin1217/Agents/actions/workflows/public-updates.yml/badge.svg)](https://github.com/JaredLin1217/Agents/actions/workflows/public-updates.yml)

Jared's AI Team 是一套 repo-local AI 工作流核心治理系统。它不是一个独立 SaaS、Dashboard 或长期会话数据库，而是把每个客户专案需要的 AI 协作规则、派工流程、验证标准、部署边界、runtime evidence 与 release 审计，封装成可跟随专案一起版本控制、一起验证、一起部署的标准层。

核心价值很直接：让 Codex 或其他 AI coding session 在进入客户专案时，不必读取大量历史对话，也不必靠人类记忆判断流程。AI 只需要先读取最小路由，再按任务展开指定规则，并把执行证据、风险、验证结果与清理状态写入本机 runtime。这样可以降低 token 消耗、减少上下文爆炸、提高跨视窗恢复能力，也能避免 AI 随意修改业务文件或把本机状态带进 release package。

## 对客户专案的好处

### 1. 低 token 的 AI 工作方式

系统采用 route-first 设计。简单问答只走最小规则；部署、验收、企业派工、协作者视窗、上下文精简、runtime evidence 等任务，才展开对应的规则包。AI 不需要每次都读取完整规范，因此更适合长周期、多人员、多项目的开发工作。

### 2. 跨视窗可恢复

长任务不会依赖完整聊天记录。系统要求保留 run id、事件摘要、验证引用、风险、resume pointer 与 cleanup evidence。新的 Codex 工作阶段接手时，可以读取最小状态摘要继续执行，而不是重新消耗大量上下文。

### 3. 部门领导式派工

主控默认只向部门领导下命令，例如部署、QA、架构、文档、供应商管理。部门内部如何拆分给员工，由部门领导自行处理；主控只整合 department report、collaborator report 或 escalation record。这样可以避免 worker raw chatter 直接进入主线，降低混乱与误判。

### 4. 可验证的 runtime evidence

写入、部署、外部访问、破坏性操作、模型层级升级等高风险动作，需要 approval gate 或 escalation record。每次执行可以记录 step、approval、tool evidence、result、verification ref、risk 与 cleanup evidence，让流程不是口头宣称，而是有可检查证据。

### 5. 更安全的部署到客户专案

部署脚本以 allowlist 更新 Agents file set，并记录目标专案部署前后的 dirty snapshot。若部署造成非 Agents 文件变化，会被视为高风险。既有目标专案的本机 Codex environment 会被保留；只有不存在时，才建立以目标专案命名的环境文件。

### 6. 支援多种部署布局

系统定义 root-layout 与 dot-agents-layout。不同客户专案可以采用不同 Agents 布局，部署脚本会自动选择或按指定 profile 生成正确的入口与规则路径，并验证不能混用两种 canonical path。

### 7. 强制 cleanup 语义

子代理与协作者视窗不能只靠侧边栏昵称宣称已关闭。cleanup 必须使用 exact runtime id 与可验证证据；如果 runtime 工具无法证明硬删除，只能报告 close/archive requested 或 verified inactive，不能宣称 fully deleted。

## 当前版本

目前版本：`2.5.1 Cross-Project Runtime Resilience Patch`

Current Agents workflow version: `2.5.1` (`core-runtime`).

Canonical version source: `docs/agents/version.yaml`

## 功能演进

| 版本 | 新增能力 |
|---|---|
| `2.5.1` | 新增跨专案 runtime 韧性补丁：跨视窗恢复证据、多布局部署 profile、目标 dirty snapshot 保护、批量验证独立 temp/run id、cleanup mandatory gate。 |
| `2.5.0` | 将专案定位为 Core Runtime System：整合核心系统边界、runtime execution、provider adapters、route packs、knowledge footprint、部署与 release blocklist。 |
| `2.3.x` | 新增 Collaborator Window Dispatch：支援命名部门领导工作阶段、create/rename/report/archive/close 生命周期、worker window 阻挡、thread evidence runtime-local 化。 |
| `2.2.1` | 新增 Context Compact Layer：保留 retained facts、dropped details、risk、resume pointer、changed files 与 subagent closeout counts，不保存完整 raw transcript。 |
| `2.2.x` | 新增 Supervised Workflow Artifact Layer：支援 workflow state、leader packet、worker packet、verification packet、escalation packet、approval gate、collect 与 normalized report。 |
| `2.1.0` | 新增 Enterprise Dispatch Layer：建立公司式部门、部门领导派工、模型 tier policy、department report、escalation record 与 clean release package export。 |
| `2.0.0` | 新增公开版本对齐、部署版本提取、Apache-2.0 授权声明、GitHub 公开文件与基础自动更新流程。 |
| Initial | 建立 compact AI runtime route、repo-local project skill、template mirror、部署验证与隔离边界。 |

## 基本使用

验证当前专案：

```powershell
.\scripts\validate.ps1
```

执行完整 release readiness 审计：

```powershell
.\scripts\validate.ps1 -Full
```

部署前 dry-run：

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap -LayoutProfile auto -DryRun
```

写入已授权目标专案：

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap -LayoutProfile auto -Upgrade
```

建立 runtime execution evidence：

```powershell
.\scripts\agents-runtime.ps1 -Action NewRun -RunId "example"
.\scripts\agents-runtime.ps1 -Action AddStep -RunId "example" -Step "read_only"
.\scripts\agents-runtime.ps1 -Action AddResult -RunId "example" -Result "completed" -Summary "read-only example completed"
.\scripts\agents-runtime.ps1 -Action Verify -RunId "example"
.\scripts\agents-runtime.ps1 -Action Cleanup -RunId "example"
```

清理子代理 runtime residue：

```powershell
.\scripts\agents-cleanup.ps1 -Action Verify -RuntimeIds "<runtime-id>" -ParentThreadId "<parent-runtime-id>"
.\scripts\agents-cleanup.ps1 -Action Cleanup -RuntimeIds "<runtime-id>" -ParentThreadId "<parent-runtime-id>" -Force
```

输出 deterministic route pack：

```powershell
.\scripts\export-route-pack.ps1 -RouteId core_system
```

输出 release package：

```powershell
.\scripts\export-release-package.ps1
```

## 使用原则

- 先按任务读取最小 route，再展开指定规则。
- 不把 live thread id、API key、provider session、runtime evidence、本机 Codex config 写入 GitHub、部署包或 release package。
- 高风险操作必须有 approval gate 或 escalation record。
- 部署只允许更新 Agents file set、目标本机 environment bootstrap 与部署报告。
- 子代理或协作者关闭必须有可验证 evidence；不能只凭侧边栏名称宣称完成。
- 跨视窗恢复只保留必要事实、证据引用、风险与 resume pointer，不保存完整聊天记录。

## 适用场景

- 需要让多个专案共享同一套 AI 工作规则。
- 需要让 Codex 工作阶段能在低 token 情况下恢复长任务。
- 需要把 AI 部署、验收、派工、cleanup 与 release 审计标准化。
- 需要避免 AI 修改客户业务文件或泄漏本机 runtime/local 状态。
- 需要用企业部门管理方式组织 AI 子任务与协作者视窗。

## 授权

Copyright 2026 Yu-Jie, Lin.

Licensed under the Apache License, Version 2.0. See `LICENSE` for the full license text and `NOTICE` for the project notice and additional disclaimer.

Unless required by applicable law or agreed to in writing, this repository is provided on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
