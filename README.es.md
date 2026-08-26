# Pasarela LLM y Conmutación por Error (Provider Failover) para Claude Code — Swobu

**Mantén Claude Code en un único endpoint estable. Traslada el enrutamiento y la conmutación por error detrás de él.**

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt-BR.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Українська](README.uk.md)

Swobu conecta Claude Code a un único endpoint local estable. Cambia la capacidad y los proveedores soportados detrás de ese endpoint sin tener que reconfigurar repetidamente Claude Code ni modificar variables de entorno.

## ¿Por qué Swobu?

Al trabajar intensamente con Claude Code, es habitual toparse con límites de peticiones (rate limits), caídas de servicio o la necesidad de redundancia multinube (Anthropic, AWS Bedrock, Google Cloud Vertex AI, Microsoft Foundry). Tradicionalmente esto requería editar `ANTHROPIC_BASE_URL` o cambiar perfiles reiniciando procesos.

Swobu moderniza este flujo: conecta Claude Code una sola vez a Swobu y deja que la pasarela local gestione la selección de rutas, la compatibilidad de protocolos y el failover automático entre proveedores.

## Instalación y Configuración (Install)

Ejecuta los siguientes comandos en Claude Code para añadir e instalar el plugin:

```text
/plugin marketplace add swobuforge/swobu-claude-plugin
/plugin install swobu@swobu
```

A continuación, inicia y conecta:

```text
/swobu:setup
/swobu:connect
```

Si dispones de múltiples espacios de trabajo (workspaces), puedes especificar uno:

```text
/swobu:connect work
```

## Ventajas que aporta Swobu

- **Un único endpoint inalterable**: Claude Code apunta siempre al mismo endpoint local, evitando reconfiguraciones continuas del cliente.
- **Failover automático y ordenado**: Si el proveedor principal falla o alcanza su límite de tasa, Swobu deriva la petición hacia objetivos secundarios (como Bedrock o Vertex AI) de forma transparente.
- **Diseño ligero**: El plugin actúa exclusivamente como un puente delgado entre Claude Code y la CLI local `swobu`, sin duplicar lógica ni consumir recursos innecesarios.

## Límites de Seguridad y Confianza (Trust Invariants)

- **Sin almacenamiento de claves de API**: El plugin no almacena claves de API de ningún proveedor; las credenciales se gestionan exclusivamente en el almacén local de Swobu.
- **Responsabilidad de enrutamiento**: El plugin no ejecuta enrutamiento por sí mismo; Swobu se encarga de todo el enrutamiento, compatibilidad y fallback.
- **Cumplimiento de facturación y acceso**: Este plugin no elude la facturación de Anthropic, los límites de cuenta ni las restricciones geográficas.
- **Límites de compatibilidad de modelos**: Anthropic señala que las pasarelas de terceros no implican soporte oficial de modelos ajenos a Claude en Claude Code; Swobu solo enruta cuando el objetivo configurado puede representar la semántica requerida.

## Recursos y Documentación

- Guía en Español: [https://swobu.com/es/claude-code/llm-gateway/](https://swobu.com/es/claude-code/llm-gateway/)
- Documentación técnica completa en inglés: [English README](README.md) · [https://swobu.com/docs](https://swobu.com/docs)
- Repositorio principal: [https://github.com/swobuforge/swobu](https://github.com/swobuforge/swobu)
- Reporte de incidencias: [https://github.com/swobuforge/swobu-claude-plugin/issues](https://github.com/swobuforge/swobu-claude-plugin/issues)
