<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**Un limpiador de disco para macOS: nativo, privado y asistido por IA.**

Analiza en busca de cachés, registros, duplicados, archivos grandes y aplicaciones sin usar — revísalos con una CLI de IA local — y muévelos de forma segura a la Papelera. Sin cuenta, sin telemetría, sin red.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-black.svg)](#requisitos)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Download](https://img.shields.io/badge/Download-.dmg-blue.svg)](https://github.com/lgqyhm2010/CleanMac/releases/latest)

[English](README.md) ·
[简体中文](README.zh-Hans.md) ·
[繁體中文](README.zh-Hant.md) ·
[日本語](README.ja.md) ·
**Español** ·
[Français](README.fr.md) ·
[العربية](README.ar.md) ·
[हिन्दी](README.hi.md) ·
[Português (BR)](README.pt-BR.md) ·
[Русский](README.ru.md) ·
[বাংলা](README.bn.md)

</div>

---

## ¿Qué es CleanMac?

CleanMac es una aplicación nativa de macOS (SwiftUI) que recupera espacio en disco **de forma segura**. Analiza tu Mac en busca de candidatos a limpieza — cachés, registros, archivos temporales, duplicados, archivos de gran tamaño, datos residuales de aplicaciones — asigna a cada uno un nivel de riesgo y te permite revisarlo todo antes de tocar nada. Los archivos van a la **Papelera**, nunca directamente a la eliminación permanente.

Lo que la hace diferente: puede entregar la lista de eliminación a una **CLI de IA local que ya tienes instalada** (Claude Code, Codex o Gemini CLI) para obtener una segunda opinión sobre qué es seguro eliminar. La IA se ejecuta en tu máquina; no se sube nada.

## Características

- 🧹 **Análisis inteligente** — cachés, registros, archivos temporales, Papelera, restos de desarrollo (datos derivados de Xcode), descargas y archivos «otros» sin clasificar.
- 📦 **Buscador de duplicados** — agrupa los archivos por hash de contenido SHA-256 y conserva la copia más reciente.
- 🐘 **Archivos grandes** — muestra los archivos que superan un umbral configurable (500 MB por defecto).
- 🗑️ **Desinstalador de aplicaciones** — mueve las apps seleccionadas a la Papelera; para evitar pérdidas accidentales, no modifica los datos de soporte del usuario.
- 🤖 **Revisión con IA (local)** — pide a una CLI de IA instalada que clasifique los candidatos en *seguros de eliminar*, *arriesgados* y *requieren revisión*.
- 🛡️ **La seguridad primero** — más de 20 reglas de seguridad y tres niveles de protección impiden la eliminación de datos del sistema, de Mail/Mensajes/Safari y del Llavero.
- 🌍 **11 idiomas** — interfaz totalmente localizada que sigue el idioma de tu sistema o una anulación manual.
- 🔒 **Privado por diseño** — sin llamadas de red, sin telemetría, sin cuenta.

## Revisión con IA (Local)

CleanMac detecta las herramientas de IA de línea de comandos compatibles en tu `PATH` (incluidas las ubicaciones habituales de Homebrew, npm, asdf y volta) y te permite elegir una para revisar un lote de candidatos a limpieza. La aplicación construye un prompt JSON estructurado (ruta, tamaño, fecha de modificación, categoría, riesgo y las reglas de seguridad que aplican), ejecuta la CLI **desde tu directorio de inicio** y analiza la respuesta convirtiéndola en grupos codificados por colores.

| Herramienta | Binario | Modelos que puedes elegir |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

La lista de candidatos y tu prompt se pasan a la CLI a través de stdin/argumentos como un subproceso — **nunca salen de tu máquina**. CleanMac también elimina sus propios marcadores de sesión del entorno del proceso hijo para que una CLI no pueda detectar erróneamente una sesión anidada.

## Privacidad y seguridad

- **Sin red.** CleanMac no realiza ninguna llamada de red. La revisión con IA ocurre localmente a través de las CLI que tú mismo instalaste.
- **Papelera, no `rm`.** Todo se mueve mediante `FileManager.trashItem(at:)`, para que puedas restaurarlo.
- **Niveles de protección.** `allowed` (cachés/registros/temporales) → `requiresReview` (código fuente, almacenamiento en la nube, descargas, datos de desarrollo) → `blocked` (raíz del sistema, datos de aplicaciones, Mail/Mensajes/Safari, datos del navegador, Llavero).
- El **Acceso total al disco** es opcional pero recomendado para que los análisis puedan ver las ubicaciones protegidas de la Biblioteca. CleanMac te guía para concederlo en Ajustes del Sistema.

## Instalación

### Descarga (recomendado)

1. Consigue el último **`CleanMac.dmg`** en la [página de Releases](https://github.com/lgqyhm2010/CleanMac/releases/latest).
2. Abre el DMG y arrastra **CleanMac** a **Aplicaciones**.

> **Primer inicio:** Si macOS dice que la aplicación no puede verificarse (Gatekeeper) en una compilación que aún no está notarizada, haz clic derecho en la aplicación → **Abrir**, o ejecuta:
> ```bash
> xattr -dr com.apple.quarantine /Applications/CleanMac.app
> ```
> Las versiones notarizadas oficialmente se abren con un doble clic normal.

### Requisitos

- macOS **14.0 (Sonoma)** o posterior
- Apple Silicon o Intel

## Compilar desde el código fuente

```bash
git clone https://github.com/lgqyhm2010/CleanMac.git
cd CleanMac

# Compilar y ejecutar el paquete de la app (crea dist/CleanMac.app y lo lanza)
./script/build_and_run.sh

# O simplemente compilar con SwiftPM
swift build --product CleanMac

# Ejecutar las pruebas
swift test
```

**Cadena de herramientas:** Swift 6.0 (Xcode 16+). El paquete expone un target ejecutable `CleanMac` (la app) y un target de biblioteca `CleanMacCore` (lógica, modelos, servicios — mantenidos por separado para facilitar las pruebas).

## Empaquetar un DMG

Un único script compila la aplicación y empaqueta un DMG distribuible de arrastrar para instalar:

```bash
./script/build_dmg.sh          # -> dist/CleanMac.dmg
```

El script **firma y notariza** cuando hay credenciales de Developer ID disponibles y **se degrada con elegancia** (firma ad-hoc) en caso contrario, de modo que siempre produce un DMG. Configura la firma mediante variables de entorno — nunca se codifican secretos de forma fija:

| Variable | Propósito |
|----------|---------|
| `CODESIGN_IDENTITY` | Identidad de firma, p. ej. `Developer ID Application: Name (TEAMID)`. Se detecta automáticamente si no se define. |
| `NOTARY_PROFILE` | Un nombre de perfil de llavero de `notarytool` (consulta [`docs/RELEASING.md`](docs/RELEASING.md)). |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | Credenciales de notarización alternativas (usadas por CI). |

> La distribución real de «descargar y abrir» requiere un certificado de pago **Apple Developer ID Application**. Consulta [`docs/RELEASING.md`](docs/RELEASING.md) para la configuración única. Sin él, el DMG se compila igualmente pero no se notariza.

Cada push a `main` y cada etiqueta reconstruyen y publican automáticamente el DMG mediante GitHub Actions ([`.github/workflows/release-dmg.yml`](.github/workflows/release-dmg.yml)).

## Localización

CleanMac se distribuye en **11 idiomas**: inglés, chino simplificado, chino tradicional, japonés, español, francés, árabe, hindi, portugués (Brasil), ruso y bengalí. La interfaz sigue el idioma de tu sistema por defecto y puede anularse en **Ajustes**.

Las cadenas de texto viven en `Sources/CleanMacCore/Resources/<locale>.lproj/Localizable.strings` detrás de la abstracción `L10n`. Para añadir un idioma, agrega una nueva carpeta `.lproj` con un `Localizable.strings` traducido, añade el caso a `AppLanguage` y recompila.

## Estructura del proyecto

```
Sources/
  CleanMac/          Target de la app — vistas SwiftUI, stores, capa AppKit, menús
  CleanMacCore/      Target de biblioteca — modelos, servicios, reglas de seguridad, localización
Tests/
  CleanMacCoreTests/ Pruebas de la lógica central
  CleanMacUITests/   Pruebas de la app/stores
script/
  build_and_run.sh   Compila el paquete .app y lo lanza
  build_dmg.sh       Compila + empaqueta (y firma/notariza) un DMG
```

## Contribuir

¡Las contribuciones son bienvenidas! Lee [CONTRIBUTING.md](CONTRIBUTING.md) para saber cómo compilar, probar y abrir un pull request. Las correcciones de traducción y los nuevos idiomas se agradecen especialmente.

## Licencia

CleanMac se publica bajo la [Licencia MIT](LICENSE).
