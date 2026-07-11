<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**Um limpador de disco nativo, privado e assistido por IA para macOS.**

Faça a varredura de caches, logs, duplicatas, arquivos grandes e apps não utilizados, revise metadados omitidos com uma CLI de IA instalada e mova-os com segurança para o Lixo. O CleanMac não exige conta nem inclui telemetria; a CLI de IA pode usar o serviço de rede do provedor.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-black.svg)](#requisitos)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Download](https://img.shields.io/badge/Download-.dmg-blue.svg)](https://github.com/lgqyhm2010/CleanMac/releases/latest)

[English](README.md) ·
[简体中文](README.zh-Hans.md) ·
[繁體中文](README.zh-Hant.md) ·
[日本語](README.ja.md) ·
[Español](README.es.md) ·
[Français](README.fr.md) ·
[العربية](README.ar.md) ·
[हिन्दी](README.hi.md) ·
**Português (BR)** ·
[Русский](README.ru.md) ·
[বাংলা](README.bn.md)

</div>

---

## O que é o CleanMac?

O CleanMac é um app nativo do macOS (SwiftUI) que recupera espaço em disco **com segurança**. Ele varre o seu Mac em busca de candidatos à limpeza — caches, logs, arquivos temporários, duplicatas, arquivos gigantes, dados residuais de apps —, atribui um nível de risco a cada um e permite que você revise tudo antes que qualquer coisa seja tocada. Os arquivos vão para o **Lixo**, nunca direto para a exclusão permanente.

O que o torna diferente: ele pode entregar **metadados omitidos e limitados** dos itens selecionados a uma CLI de IA instalada (Claude Code, Codex ou Gemini CLI) para obter uma segunda opinião. Sua pergunta é enviada como foi digitada; o CleanMac não adiciona conteúdo de arquivos nem caminhos completos, e a CLI pode contatar o provedor configurado.

## Recursos

- 🧹 **Varredura inteligente** — caches, logs, arquivos temporários, Lixo, entulho de desenvolvedor (dados derivados do Xcode), downloads e arquivos “outros” não classificados.
- 📦 **Localizador de duplicatas** — agrupa arquivos por hash de conteúdo SHA-256 e mantém a cópia mais recente.
- 🐘 **Arquivos grandes** — revela arquivos acima de um limite configurável (padrão de 500 MB).
- 🗑️ **Desinstalador de apps** — move os apps selecionados para o Lixo; para evitar perda acidental, os dados de suporte do usuário não são alterados.
- 🤖 **Revisão por IA (local)** — peça a uma CLI de IA instalada para classificar os candidatos em *seguro para excluir*, *arriscado* e *precisa de revisão*.
- 🛡️ **Segurança em primeiro lugar** — mais de 20 regras de segurança e três níveis de proteção impedem que dados do sistema, do Mail/Mensagens/Safari e do Keychain sejam excluídos.
- 🌍 **11 idiomas** — interface totalmente localizada que segue o idioma do seu sistema ou uma substituição manual.
- 🔒 **Limite de privacidade explícito** — sem telemetria ou conta do CleanMac; a entrega à IA é omitida e informada claramente.

## Revisão por IA (Local)

O CleanMac detecta ferramentas de IA compatíveis no seu `PATH` e permite revisar até 80 candidatos. Ele envia sua pergunta e metadados anônimos estruturados (ID, tamanho, data, categoria, risco e IDs de regras), executa a CLI em um diretório temporário vazio e exclusivo com limite de 120 segundos e só aceita a resposta se cada item for classificado exatamente uma vez.

| Ferramenta | Binário | Modelos que você pode escolher |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

A lista de candidatos e o seu prompt são passados para a CLI via stdin/argumentos como um subprocesso — **eles nunca saem da sua máquina**. O CleanMac também remove seus próprios marcadores de sessão do ambiente do processo filho para que uma CLI não detecte por engano uma sessão aninhada.

## Privacidade e Segurança

- **Aviso de rede da IA.** O CleanMac não inclui telemetria, mas uma CLI de IA instalada pode contatar o provedor. A revisão envia sua pergunta como digitada, IDs anônimos e metadados limitados; nunca o conteúdo dos arquivos ou caminhos completos coletados automaticamente.
- **Lixo, não `rm`.** Tudo é movido via `FileManager.trashItem(at:)`, então você pode restaurar.
- **Níveis de proteção.** `allowed` (caches/logs/temp) → `requiresReview` (código-fonte, armazenamento em nuvem, downloads, dados de desenvolvimento) → `blocked` (raiz do sistema, dados de apps, Mail/Mensagens/Safari, dados de navegadores, Keychain).
- **Full Disk Access** é opcional, mas recomendado para que as varreduras possam ver os locais protegidos da Library. O CleanMac orienta você a concedê-lo nas Ajustes do Sistema.

## Instalação

### Download (recomendado)

1. Baixe o **`CleanMac.dmg`** mais recente na [página de Releases](https://github.com/lgqyhm2010/CleanMac/releases/latest).
2. Abra o DMG e arraste o **CleanMac** para **Aplicativos**.

> Downloads oficiais são assinados e notarizados. Se o Gatekeeper não conseguir verificar um deles, não desative a quarentena; apague-o e baixe-o novamente na página oficial de Releases.

### Requisitos

- macOS **14.0 (Sonoma)** ou posterior
- Apple Silicon ou Intel

## Compilar a partir do código-fonte

```bash
git clone https://github.com/lgqyhm2010/CleanMac.git
cd CleanMac

# Compile e execute o pacote do app (cria dist/CleanMac.app e o inicia)
./script/build_and_run.sh

# Ou apenas compile com o SwiftPM
swift build --product CleanMac

# Execute os testes
swift test
```

**Toolchain:** Swift 6.0 (Xcode 16+). O pacote expõe um alvo executável `CleanMac` (o app) e um alvo de biblioteca `CleanMacCore` (lógica, modelos, serviços — mantidos separados para facilitar os testes).

## Empacotando um DMG

Um único script compila o app e empacota um DMG distribuível, do tipo arrastar-para-instalar:

```bash
# Prévia local, não distribuível
./script/build_dmg.sh --unsigned

# Release formal; requer Developer ID e credenciais de notarização
CLEANMAC_VERSION=1.0.0 CLEANMAC_BUILD_NUMBER=1 \
  NOTARY_PROFILE=CleanMacNotary ./script/build_dmg.sh --release
```

Releases formais falham de forma fechada: qualquer erro de credencial, versão, arquitetura, assinatura, notarização, stapling ou Gatekeeper interrompe o build. A configuração usa variáveis de ambiente e nenhum segredo é fixado no código:

| Variável | Finalidade |
|----------|---------|
| `CODESIGN_IDENTITY` | Identidade de assinatura, por exemplo, `Developer ID Application: Name (TEAMID)`. Detectada automaticamente se não for definida. |
| `CLEANMAC_VERSION` / `CLEANMAC_BUILD_NUMBER` | Versão do release e número de build numérico. |
| `NOTARY_PROFILE` | Um nome de perfil de keychain do `notarytool` (veja [`docs/RELEASING.md`](docs/RELEASING.md)). |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | Credenciais de notarização alternativas (usadas pela CI). |

> `--unsigned` serve apenas para validação local/PR e nunca é publicado como release. Veja [`docs/RELEASING.md`](docs/RELEASING.md).

PRs e pushes para `main` só criam uma prévia sem assinatura e de leitura. Apenas uma tag `v*` publica após todas as verificações ([workflow](.github/workflows/release-dmg.yml)).

## Localização

O CleanMac vem em **11 idiomas**: inglês, chinês simplificado, chinês tradicional, japonês, espanhol, francês, árabe, hindi, português (Brasil), russo e bengali. A interface segue o idioma do seu sistema por padrão e pode ser substituída em **Ajustes**.

As strings ficam em `Sources/CleanMacCore/Resources/<locale>.lproj/Localizable.strings`, por trás da abstração `L10n`. Para adicionar um idioma, adicione uma nova pasta `.lproj` com um `Localizable.strings` traduzido, adicione o caso ao `AppLanguage` e recompile.

## Estrutura do projeto

```
Sources/
  CleanMac/          Alvo do app — views SwiftUI, stores, shell AppKit, menus
  CleanMacCore/      Alvo de biblioteca — modelos, serviços, regras de segurança, localização
Tests/
  CleanMacCoreTests/ Testes da lógica central
  CleanMacUITests/   Testes do app/store
script/
  build_and_run.sh   Compila o pacote .app e o inicia
  build_dmg.sh       Compila + empacota (e assina/notariza) um DMG
```

## Contribuindo

Contribuições são bem-vindas! Leia o [CONTRIBUTING.md](CONTRIBUTING.md) para saber como compilar, testar e abrir um pull request. Correções de tradução e novos idiomas são especialmente apreciados.

## Licença

O CleanMac é distribuído sob a [Licença MIT](LICENSE).
