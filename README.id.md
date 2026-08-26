# Claude Code LLM Gateway & Provider Failover — Swobu

**Pertahankan Claude Code pada satu endpoint stabil. Pindahkan routing dan failover ke belakangnya.**

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt-BR.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Українська](README.uk.md)

Swobu menghubungkan Claude Code ke satu endpoint lokal yang stabil. Ubah kapasitas dan penyedia (provider) yang didukung di balik endpoint tersebut tanpa harus terus-menerus mengubah konfigurasi Claude Code atau variabel lingkungan.

## Mengapa Membutuhkan Swobu?

Saat menggunakan Claude Code untuk alur kerja intensif, pengembang sering menghadapi batas tarif (rate limits), gangguan penyedia, atau kebutuhan failover lintas cloud (Anthropic, AWS Bedrock, Google Cloud Vertex AI, Microsoft Foundry). Cara lama mengharuskan pengubahan `ANTHROPIC_BASE_URL` atau pergantian profil berulang kali.

Swobu mengubah pola ini: hubungkan Claude Code sekali ke Swobu, dan biarkan gateway lokal menangani pemilihan rute, kompatibilitas protokol, serta failover otomatis antar penyedia.

## Instalasi dan Pengaturan (Install)

Jalankan perintah berikut di dalam Claude Code untuk menambahkan dan memasang plugin:

```text
/plugin marketplace add swobuforge/swobu-claude-plugin
/plugin install swobu@swobu
```

Setelah terpasang, jalankan perintah setup dan koneksi:

```text
/swobu:setup
/swobu:connect
```

Jika Anda memiliki beberapa workspace Swobu, tentukan workspace secara eksplisit:

```text
/swobu:connect work
```

## Keunggulan Swobu

- **Satu Endpoint Tetap**: Claude Code selalu terhubung ke endpoint lokal yang sama, menghilangkan kebutuhan pengubahan konfigurasi klien berulang kali.
- **Failover Otomatis**: Jika penyedia utama mengalami gangguan atau rate limit, Swobu secara otomatis mengalihkan beban kerja ke target cadangan (seperti AWS Bedrock atau Vertex AI).
- **Arsitektur Plugin Ringan**: Plugin ini hanya berfungsi sebagai penghubung tipis antara Claude Code dan CLI `swobu` lokal, tanpa membebani memori atau proses tambahan.

## Batasan Keamanan dan Kepercayaan (Trust Invariants)

- **Tidak Menyimpan Kunci API**: Plugin ini sama sekali tidak menyimpan kunci API penyedia; seluruh kredensial dikelola oleh sistem kredensial lokal Swobu.
- **Kepemilikan Routing**: Plugin ini tidak melakukan routing sendiri; Swobu bertanggung jawab penuh atas routing, kompatibilitas, dan fallback.
- **Kepatuhan Penagihan dan Akses**: Plugin ini tidak melewati penagihan langganan Anthropic, batas kuota akun, atau pembatasan geografis.
- **Batasan Dukungan Model**: Anthropic menegaskan bahwa gateway pihak ketiga tidak membuat model non-Claude didukung secara resmi di Claude Code; Swobu hanya merutekan beban kerja jika target yang dikonfigurasi mampu merepresentasikan semantik yang diperlukan.

## Sumber Daya & Dokumentasi

- Panduan Bahasa Indonesia: [https://swobu.com/id/claude-code/llm-gateway/](https://swobu.com/id/claude-code/llm-gateway/)
- Dokumentasi teknis lengkap (Bahasa Inggris): [English README](README.md) · [https://swobu.com/docs](https://swobu.com/docs)
- Repositori Utama: [https://github.com/swobuforge/swobu](https://github.com/swobuforge/swobu)
- Laporan Masalah (Issues): [https://github.com/swobuforge/swobu-claude-plugin/issues](https://github.com/swobuforge/swobu-claude-plugin/issues)
