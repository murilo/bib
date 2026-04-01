# 📖 bib.muitos.com

Leitor bíblico minimalista, offline-first, com busca por voz via IA.

**Demo:** [bib.muitos.com](https://bib.muitos.com)

## Features

### 🎤 Busca por Voz com IA
Grave um áudio dizendo "João 3:16" ou "Salmo 23" — o app usa Gemini Flash para interpretar e navegar direto ao versículo. Funciona com linguagem natural em PT-BR e EN.

### ✝️ Red Letter Edition
Palavras de Jesus destacadas em vermelho (tema claro) ou branco bold (tema escuro). Dataset próprio de marcação red-letter para cada tradução.

### 📅 Devocional Diário
Imagem gerada por AI + reflexão diária, com botão de compartilhar nativo (WhatsApp, etc).

### 🔊 TTS — Leitura em Voz Alta
Narração do capítulo inteiro com controle de velocidade (0.5x–2x) e seleção de voz do sistema.

### 🔍 Busca Inteligente
Aceita múltiplos formatos: "João 3:16", "Jo 3:16", "Sl 23", "Genesis 1", "Gn 1". Autocomplete inline com lista de livros.

### 🌙 Temas & Tipografia
- Dark mode (azul noturno) e Light mode (sépia)
- 3 fontes serifadas otimizadas para leitura: Literata, Lora, Source Serif 4
- Largura de conteúdo ajustável

### 📱 PWA + Offline
Instala como app nativo. Após o primeiro acesso, funciona 100% offline via Service Worker (cache-first para assets, network-first para dados).

### 📚 13 Traduções
ACF (Almeida Corrigida Fiel), ARA (Almeida Revista e Atualizada), ARC, KJA, KJV, A Mensagem, The Message, NAA, NIV, NTLH, NVI, NVT, RV1960.

Dados em JSON comprimido (gzip), carregados sob demanda.

## Arquitetura

```
index.html          ← App inteiro (single-file, ~2100 linhas)
sw.js               ← Service Worker (PWA + offline)
manifest.json       ← PWA manifest
gemini-proxy.php    ← Proxy server-side para API Gemini (voz)
log.php             ← Analytics append-only (JSONL)
data/               ← Traduções bíblicas (JSON.gz)
data/red-letter/    ← Marcação das palavras de Jesus
devotional/         ← Devocional diário (imagem + JSON)
icons/              ← SVG icons para PWA
```

**Zero frameworks.** Vanilla JS + Tailwind CDN. Sem build step.

## Setup

1. Clone o repo
2. Sirva com qualquer servidor PHP (para o proxy Gemini) ou servidor estático (sem voice search)
3. Opcional: crie `.env` com `GEMINI_API_KEY=sua_chave` para voice search server-side

```bash
# Desenvolvimento local
php -S localhost:8080

# Ou com qualquer servidor estático (voice search usa chave do usuário)
python3 -m http.server 8080
```

## Licença

MIT — use, copie, modifique à vontade. Se fizer algo legal com isso, me conta! 🖖

