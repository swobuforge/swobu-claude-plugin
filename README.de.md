# Claude Code LLM Gateway & Provider Failover — Swobu

**Halten Sie Claude Code auf einem stabilen Endpunkt. Verlagern Sie Routing und Failover dahinter.**

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt-BR.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Українська](README.uk.md)

Swobu verbindet Claude Code mit einem einzigen, stabilen lokalen Endpunkt. Ändern Sie unterstützte Provider-Kapazitäten und Redundanzen hinter diesem Endpunkt, ohne Claude Code-Konfigurationen oder Umgebungsvariablen ständig neu anpassen zu müssen.

## Warum Swobu?

Beim intensiven Einsatz von Claude Code stoßen Entwickler häufig auf Ratenbegrenzungen (Rate Limits), Ausfälle oder die Notwendigkeit von Multi-Cloud-Redundanz (Anthropic, AWS Bedrock, Google Cloud Vertex AI, Microsoft Foundry). Herkömmliche Ansätze erfordern das manuelle Anpassen von `ANTHROPIC_BASE_URL` oder das Umschalten von Profilen mit Neustarts.

Swobu vereinfacht dies: Verbinden Sie Claude Code einmalig mit Swobu, und das lokale Gateway übernimmt die Routenwahl, Protokollkompatibilität und automatische Ausfallsicherung (Failover) im Hintergrund.

## Installation und Einrichtung (Install)

Führen Sie die folgenden Befehle in Claude Code aus, um das Plugin zu installieren:

```text
/plugin marketplace add swobuforge/swobu-claude-plugin
/plugin install swobu@swobu
```

Führen Sie anschließend die Einrichtung und Verbindung durch:

```text
/swobu:setup
/swobu:connect
```

Falls mehrere Workspaces konfiguriert sind, können Sie den gewünschten Workspace angeben:

```text
/swobu:connect work
```

## Was Swobu bietet

- **Ein stabiler lokaler Endpunkt**: Claude Code bleibt dauerhaft mit demselben lokalen Endpunkt verbunden; keine wiederkehrenden Client-Konfigurationsänderungen.
- **Automatisches Provider-Failover**: Bei Ratenlimits oder Fehlern des Hauptanbieters schaltet Swobu Anfragen transparent auf Backup-Ziele (wie AWS Bedrock oder Vertex AI) um.
- **Schlanke Plugin-Architektur**: Das Plugin fungiert ausschließlich als direkte Brücke zwischen Claude Code und der lokalen `swobu` CLI, ohne zusätzlichen Ressourcen-Overhead.

## Sicherheits- und Vertrauensgrenzen (Trust Invariants)

- **Keine Speicherung von API-Schlüsseln**: Das Plugin speichert keine Provider-API-Schlüssel; Zugangsdaten verbleiben sicher im lokalen Swobu-Tresor.
- **Routing-Zuständigkeit**: Das Plugin führt kein eigenes Routing durch; Swobu verantwortet Routing, Protokollanpassung und Fallback vollständig.
- **Abrechnungs- und Richtlinienkonformität**: Das Plugin umgeht weder die Abrechnung noch Kontolimits oder geografische Beschränkungen von Anthropic.
- **Modell-Unterstützungsgrenzen**: Anthropic weist darauf hin, dass Gateways von Drittanbietern Nicht-Claude-Modelle in Claude Code nicht offiziell unterstützen; Swobu leitet nur weiter, wenn das Ziel die geforderte Semantik abbilden kann.

## Ressourcen & Dokumentation

- Deutscher Leitfaden: [https://swobu.com/de/claude-code/llm-gateway/](https://swobu.com/de/claude-code/llm-gateway/)
- Vollständige englische Dokumentation: [English README](README.md) · [https://swobu.com/docs](https://swobu.com/docs)
- Haupt-Repository: [https://github.com/swobuforge/swobu](https://github.com/swobuforge/swobu)
- Problem melden: [https://github.com/swobuforge/swobu-claude-plugin/issues](https://github.com/swobuforge/swobu-claude-plugin/issues)
