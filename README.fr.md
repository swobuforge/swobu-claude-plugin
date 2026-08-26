# Passerelle LLM et Basculement de Fournisseurs (Provider Failover) pour Claude Code — Swobu

**Conservez Claude Code sur un point de terminaison unique et stable. Déplacez le routage et le basculement en arrière-plan.**

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt-BR.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Українська](README.uk.md)

Swobu connecte Claude Code à un point de terminaison local (local endpoint) stable. Modifiez la capacité des fournisseurs pris en charge derrière ce point de terminaison sans reconfigurer continuellement Claude Code ni modifier vos variables d'environnement.

## Pourquoi utiliser Swobu ?

Lors de l'utilisation intensive de Claude Code, les développeurs rencontrent régulièrement des limites de débit (rate limits), des pannes temporaires ou des besoins de redondance multi-cloud (Anthropic, AWS Bedrock, Google Cloud Vertex AI, Microsoft Foundry). La méthode classique impose de modifier `ANTHROPIC_BASE_URL` ou de changer de profil en redémarrant le processus.

Swobu transforme cette approche : connectez Claude Code une seule fois à Swobu et laissez la passerelle locale gérer la sélection des routes, la compatibilité des protocoles et le basculement automatique entre fournisseurs.

## Installation et Configuration (Install)

Exécutez les commandes suivantes dans Claude Code pour ajouter et installer le plugin :

```text
/plugin marketplace add swobuforge/swobu-claude-plugin
/plugin install swobu@swobu
```

Ensuite, lancez la configuration et la connexion :

```text
/swobu:setup
/swobu:connect
```

Si plusieurs espaces de travail (workspaces) sont configurés, spécifiez le nom de l'espace souhaité :

```text
/swobu:connect work
```

## Les apports de Swobu

- **Point de terminaison unique et fixe** : Claude Code pointe en permanence vers le même endpoint local sans nécessiter de modification client.
- **Basculement automatique ordonné** : En cas d'erreur ou de limite de débit chez le fournisseur principal, Swobu bascule les requêtes vers des cibles de secours (comme AWS Bedrock ou Vertex AI) en toute transparence.
- **Architecture ultra-légère** : Le plugin agit uniquement comme une passerelle mince entre Claude Code et la CLI locale `swobu`, sans consommer de mémoire inutile.

## Limites de Sécurité et de Confiance (Trust Invariants)

- **Aucun stockage de clés API** : Le plugin ne stocke aucune clé API de fournisseur ; les identifiants restent protégés dans le coffre local de Swobu.
- **Responsabilité du routage** : Le plugin n'exécute aucun routage direct ; Swobu assure l'intégralité du routage, de la compatibilité et du fallback.
- **Respect de la facturation et des politiques** : Ce plugin ne contourne pas la facturation d'Anthropic, les quotas de compte ou les restrictions géographiques.
- **Périmètre des modèles pris en charge** : Anthropic précise que les passerelles tierces ne rendent pas les modèles non-Claude officiellement pris en charge dans Claude Code ; Swobu n'achemine les requêtes que lorsque la cible configurée peut restituer la sémantique requise.

## Ressources et Documentation

- Guide en Français : [https://swobu.com/fr/claude-code/llm-gateway/](https://swobu.com/fr/claude-code/llm-gateway/)
- Documentation technique complète en anglais : [English README](README.md) · [https://swobu.com/docs](https://swobu.com/docs)
- Dépôt principal : [https://github.com/swobuforge/swobu](https://github.com/swobuforge/swobu)
- Signaler un problème : [https://github.com/swobuforge/swobu-claude-plugin/issues](https://github.com/swobuforge/swobu-claude-plugin/issues)
