# Claude Code LLM 网关与服务商故障转移 (Provider Failover) — Swobu

**保持 Claude Code 端点固定，将服务商路由与故障转移移至底层。**

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt-BR.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Українська](README.uk.md)

Swobu 将 Claude Code 连接至单个稳定的本地端点（Local Endpoint）。您无需反复重写 Claude Code 的配置或环境变量，即可在端点背后切换支持的服务商容量、设置自动降级与故障切换。

## 为什么需要 Swobu？

在日常使用 Claude Code 时，开发者常面临 API 速率限制（Rate Limits）、区域服务波动或多云冗余需求（Anthropic、AWS Bedrock、Google Cloud Vertex AI、Microsoft Foundry）。传统方式通常需要频繁修改 `ANTHROPIC_BASE_URL` 或在切换配置时重新启动进程。

Swobu 改变了这一模式：只需将 Claude Code 与 Swobu 连接一次，后续所有的路由选择、多服务商故障转移（Provider Failover）与协议兼容性转换均由底层的本地网关自动完成。

## 安装与配置 (Install)

在 Claude Code 中执行以下命令添加并安装插件：

```text
/plugin marketplace add swobuforge/swobu-claude-plugin
/plugin install swobu@swobu
```

安装完成后，运行初始化与连接命令：

```text
/swobu:setup
/swobu:connect
```

如果您拥有多个工作区（Workspaces），可以指定工作区名称：

```text
/swobu:connect work
```

## Swobu 带来的改变

- **单一稳定端点**：Claude Code 始终指向固定的本地工作区端点，无需频繁修改客户端设置。
- **服务商故障转移与降级**：当主服务商遭遇限流或故障时，Swobu 自动按优先级切换至备用目标（如 AWS Bedrock 或 Vertex AI）。
- **轻量插件架构**：插件本身仅负责连接 Claude Code 与本地 `swobu` CLI，不驻留冗余进程。

## 安全边界与限制说明 (Trust Invariants)

- **无 API 密钥存储**：本插件不存储任何服务商 API 密钥，所有凭据均由本地 Swobu 凭据系统管理。
- **网关归属**：插件本身不实现路由逻辑，所有路由、兼容性与故障转移均由本地运行的 Swobu 守护程序执行。
- **合规与计费**：本插件绝不绕过 Anthropic 官方计费、账户限制或地理区域限制。
- **模型支持边界**：Anthropic 官方明确说明第三方网关并不会使 Claude Code 官方支持非 Claude 模型；Swobu 仅在配置目标具备对应语义表达能力时处理兼容路由。

## 相关资源

- 简体中文网关指南：[https://swobu.com/zh-cn/claude-code/llm-gateway/](https://swobu.com/zh-cn/claude-code/llm-gateway/)
- 完整英文技术文档：[English README](README.md) · [https://swobu.com/docs](https://swobu.com/docs)
- 主项目仓库：[https://github.com/swobuforge/swobu](https://github.com/swobuforge/swobu)
- 问题反馈：[https://github.com/swobuforge/swobu-claude-plugin/issues](https://github.com/swobuforge/swobu-claude-plugin/issues)
