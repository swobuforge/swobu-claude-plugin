# Claude Code LLM Gateway & Provider Failover — Swobu

**Claude Code の接続先を1つのエンドポイントに固定し、プロバイダーのルーティングとフェイルオーバーを背後に集約。**

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt-BR.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Українська](README.uk.md)

Swobu は Claude Code を安定した単一のローカルエンドポイントに接続します。Claude Code の設定や `ANTHROPIC_BASE_URL` を何度も書き換えることなく、その背後で利用可能なプロバイダー容量の切り替えや自動フェイルオーバー（Provider Failover）を実現します。

## なぜ Swobu が必要なのか？

Claude Code を運用する際、レート制限（Rate Limits）、一時的なサービス障害、あるいはマルチクラウド冗長構成（Anthropic、AWS Bedrock、Google Cloud Vertex AI、Microsoft Foundry）の管理が課題になります。従来はプロファイルごとに環境変数を切り替えたり、Claude Code を再起動する必要がありました。

Swobu はこのアプローチを刷新します。Claude Code を Swobu に一度接続するだけで、以後のルーティング、フォールバック、互換性変換はすべて背後のローカルゲートウェイが自動で処理します。

## インストールとセットアップ (Install)

Claude Code 内で次のコマンドを実行してプラグインをインストールします。

```text
/plugin marketplace add swobuforge/swobu-claude-plugin
/plugin install swobu@swobu
```

インストール後、セットアップと接続を実行します。

```text
/swobu:setup
/swobu:connect
```

複数のワークスペースが存在する場合は、ワークスペース名を指定できます。

```text
/swobu:connect work
```

## Swobu がもたらすメリット

- **単一の安定したエンドポイント**: Claude Code は固定のローカルエンドポイントに接続し続けるため、クライアント側の設定変更が不要になります。
- **自動プロバイダーフェイルオーバー**: メインプロバイダーでエラーやレート制限が発生した場合、設定された優先順位に従って代替プロバイダー（AWS Bedrock や Vertex AI など）へシームレスに切り替えます。
- **軽量なプラグイン設計**: プラグイン自身は Claude Code とローカル `swobu` CLI を接続する薄い制御層として機能し、余計なリソースを消費しません。

## セキュリティと利用上の注意 (Trust Invariants)

- **API キーの非保持**: プラグイン自体はいかなるプロバイダー API キーも保存しません。認証情報はローカルの Swobu が管理します。
- **ルーティングの責務**: ルーティングやフォールバック、プロトコル互換性処理はすべてローカルデーモンである Swobu が担当し、プラグイン単体でルーティングを行うわけではありません。
- **利用規約と制限の遵守**: 本プラグインは Anthropic の課金、アカウント制限、または地域制限を回避するものではありません。
- **モデルサポート範囲**: Anthropic はサードパーティ製ゲートウェイ経由であっても、Claude Code における非 Claude モデルの公式サポートを表明していません。Swobu は設定されたターゲットが要求されたセマンティクスを表現可能な場合にのみ互換ルーティングを行います。

## リソースとドキュメント

- 日本語ガイド: [https://swobu.com/ja/claude-code/llm-gateway/](https://swobu.com/ja/claude-code/llm-gateway/)
- 英語公式ドキュメント: [English README](README.md) · [https://swobu.com/docs](https://swobu.com/docs)
- メインリポジトリ: [https://github.com/swobuforge/swobu](https://github.com/swobuforge/swobu)
- Issue 報告: [https://github.com/swobuforge/swobu-claude-plugin/issues](https://github.com/swobuforge/swobu-claude-plugin/issues)
