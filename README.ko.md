# Claude Code LLM 게이트웨이 및 프로바이더 장애 조치 (Provider Failover) — Swobu

**Claude Code 엔드포인트를 하나로 고정하고, 라우팅과 페일오버를 그 뒤로 이동시키세요.**

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt-BR.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Українська](README.uk.md)

Swobu는 Claude Code를 안정적인 단일 로컬 엔드포인트에 연결합니다. Claude Code 설정이나 `ANTHROPIC_BASE_URL`을 반복해서 수정하지 않고도, 엔드포인트 뒤에서 지원되는 프로바이더 용량 변경 및 장애 조치(Provider Failover)를 처리할 수 있습니다.

## 왜 Swobu가 필요한가요?

Claude Code를 사용할 때 API 속도 제한(Rate Limits), 일시적 장애, 또는 멀티클라우드 이중화(Anthropic, AWS Bedrock, Google Cloud Vertex AI, Microsoft Foundry)가 자주 요구됩니다. 기존 방식은 프로필을 변경하거나 환경 변수를 바꾸고 프로세스를 재시작해야 했습니다.

Swobu는 이러한 번거로움을 해결합니다. Claude Code를 Swobu에 한 번만 연결하면, 이후의 모든 경로 선택, 프로토콜 호환성 변환, 자동 장애 조치는 로컬 게이트웨이가 자동으로 수행합니다.

## 설치 및 설정 (Install)

Claude Code에서 아래 명령어를 실행하여 플러그인을 설치합니다.

```text
/plugin marketplace add swobuforge/swobu-claude-plugin
/plugin install swobu@swobu
```

설치 후 초기 설정 및 연결을 진행합니다.

```text
/swobu:setup
/swobu:connect
```

여러 워크스페이스가 구성된 경우 워크스페이스 이름을 지정할 수 있습니다.

```text
/swobu:connect work
```

## Swobu의 핵심 가치

- **단일 고정 엔드포인트**: Claude Code 클라이언트는 고정된 로컬 엔드포인트를 계속 가리키므로 클라이언트 설정 변경이 불필요합니다.
- **자동 프로바이더 페일오버**: 기본 프로바이더에 장애나 속도 제한이 발생하면 백업 타깃(AWS Bedrock, Vertex AI 등)으로 자동 전환됩니다.
- **가벼운 플러그인 구조**: 플러그인은 Claude Code와 로컬 `swobu` CLI를 연결하는 얇은 인터페이스 역할만 수행하며 불필요한 리소스를 차지하지 않습니다.

## 보안 및 신뢰 원칙 (Trust Invariants)

- **API 키 미저장**: 본 플러그인은 어떠한 프로바이더 API 키도 저장하지 않습니다. 모든 인증 정보는 로컬 Swobu 자격 증명 시스템이 안전하게 관리합니다.
- **라우팅 책임**: 플러그인 자체가 라우팅을 수행하지 않으며, 모든 라우팅, 호환성 및 폴백은 로컬 데몬인 Swobu가 전담합니다.
- **과금 및 정책 준수**: 본 플러그인은 Anthropic의 결제, 계정 한도 또는 지역 제한을 우회하지 않습니다.
- **모델 지원 경계**: Anthropic은 타사 게이트웨이를 사용하더라도 비 Claude 모델이 Claude Code에서 공식 지원되는 것은 아님을 명시합니다. Swobu는 구성된 타깃이 요청된 의미 구조를 표현할 수 있는 경우에만 호환 라우팅을 수행합니다.

## 참고 자료

- 한국어 가이드: [https://swobu.com/ko/claude-code/llm-gateway/](https://swobu.com/ko/claude-code/llm-gateway/)
- 공식 영문 기술 문서: [English README](README.md) · [https://swobu.com/docs](https://swobu.com/docs)
- 메인 저장소: [https://github.com/swobuforge/swobu](https://github.com/swobuforge/swobu)
- 이슈 보고: [https://github.com/swobuforge/swobu-claude-plugin/issues](https://github.com/swobuforge/swobu-claude-plugin/issues)
