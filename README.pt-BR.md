# Gateway LLM e Failover de Provedores para Claude Code — Swobu

**Mantenha o Claude Code em um único endpoint estável. Mova o roteamento e o failover para trás dele.**

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt-BR.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Українська](README.uk.md)

O Swobu conecta o Claude Code a um único endpoint local estável. Altere a capacidade e os provedores suportados por trás desse endpoint sem precisar reconfigurar o Claude Code ou variáveis de ambiente repetidamente.

## Por que usar o Swobu?

Ao utilizar o Claude Code em produção ou desenvolvimento intenso, desenvolvedores frequentemente enfrentam limites de taxa (rate limits), instabilidades temporárias ou necessidade de redundância multinuvem (Anthropic, AWS Bedrock, Google Cloud Vertex AI, Microsoft Foundry). A abordagem tradicional exige alterar `ANTHROPIC_BASE_URL` ou alternar perfis reiniciando processos.

O Swobu resolve esse problema: conecte o Claude Code uma única vez ao Swobu e deixe que o gateway local gerencie a seleção de rotas, a compatibilidade e o failover automático entre provedores.

## Instalação e Configuração (Install)

No Claude Code, execute os comandos abaixo para adicionar e instalar o plugin:

```text
/plugin marketplace add swobuforge/swobu-claude-plugin
/plugin install swobu@swobu
```

Em seguida, inicialize e conecte:

```text
/swobu:setup
/swobu:connect
```

Se você possuir múltiplos workspaces configurados, especifique o nome desejado:

```text
/swobu:connect work
```

## O que o Swobu transforma

- **Endpoint local único e fixo**: O Claude Code permanece conectado a um endereço estável local sem alterações contínuas nas configurações do cliente.
- **Failover automático e ordenado**: Caso o provedor principal retorne erro ou atinja limites de taxa, o Swobu redireciona a requisição para alvos secundários (como Bedrock ou Vertex AI) de forma transparente.
- **Plugin leve**: O plugin funciona apenas como uma ponte fina entre o Claude Code e a CLI local `swobu`, sem duplicar lógica de roteamento nem consumir memória desnecessária.

## Limites de Segurança e Confiança (Trust Invariants)

- **Sem armazenamento de chaves de API**: O plugin não armazena nenhuma chave de API de provedor; as credenciais permanecem sob controle do cofre local do Swobu.
- **Propriedade do roteamento**: O plugin não executa roteamento próprio; o Swobu é o único responsável por roteamento, compatibilidade e fallback.
- **Conformidade de faturamento e acesso**: Este plugin não contorna faturamento da Anthropic, limites de taxa de conta ou restrições geográficas.
- **Fronteira de suporte a modelos**: A Anthropic destaca que gateways de terceiros não tornam modelos não-Claude oficialmente suportados no Claude Code; o Swobu apenas roteia onde o alvo configurado suporta a semântica necessária.

## Recursos e Documentação

- Guia em Português: [https://swobu.com/pt-br/claude-code/llm-gateway/](https://swobu.com/pt-br/claude-code/llm-gateway/)
- Documentação técnica completa em inglês: [English README](README.md) · [https://swobu.com/docs](https://swobu.com/docs)
- Repositório principal: [https://github.com/swobuforge/swobu](https://github.com/swobuforge/swobu)
- Relatar problemas: [https://github.com/swobuforge/swobu-claude-plugin/issues](https://github.com/swobuforge/swobu-claude-plugin/issues)
