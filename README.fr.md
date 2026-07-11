<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**Un nettoyeur de disque natif, privé et assisté par IA pour macOS.**

Recherchez les caches, journaux, doublons, fichiers volumineux et applications inutilisées — passez-les en revue avec une CLI d'IA locale — et déplacez-les en toute sécurité vers la Corbeille. Aucun compte, aucune télémétrie, aucun réseau.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-black.svg)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Download](https://img.shields.io/badge/Download-.dmg-blue.svg)](https://github.com/lgqyhm2010/CleanMac/releases/latest)

[English](README.md) ·
[简体中文](README.zh-Hans.md) ·
[繁體中文](README.zh-Hant.md) ·
[日本語](README.ja.md) ·
[Español](README.es.md) ·
**Français** ·
[العربية](README.ar.md) ·
[हिन्दी](README.hi.md) ·
[Português (BR)](README.pt-BR.md) ·
[Русский](README.ru.md) ·
[বাংলা](README.bn.md)

</div>

---

## Qu'est-ce que CleanMac ?

CleanMac est une application macOS native (SwiftUI) qui récupère de l'espace disque **en toute sécurité**. Elle analyse votre Mac à la recherche de candidats au nettoyage — caches, journaux, fichiers temporaires, doublons, fichiers surdimensionnés, données d'applications résiduelles — attribue à chacun un niveau de risque et vous permet de tout examiner avant que quoi que ce soit ne soit touché. Les fichiers vont dans la **Corbeille**, jamais directement vers une suppression définitive.

Ce qui la distingue : elle peut confier la liste de suppression à une **CLI d'IA locale que vous avez déjà installée** (Claude Code, Codex ou Gemini CLI) pour obtenir un second avis sur ce qui peut être supprimé sans danger. L'IA s'exécute sur votre machine ; rien n'est envoyé en ligne.

## Fonctionnalités

- 🧹 **Analyse intelligente** — caches, journaux, fichiers temporaires, Corbeille, déchets de développement (données dérivées de Xcode), téléchargements et fichiers « autres » non classés.
- 📦 **Détecteur de doublons** — regroupe les fichiers par empreinte de contenu SHA-256 et conserve la copie la plus récente.
- 🐘 **Fichiers volumineux** — fait remonter les fichiers dépassant un seuil configurable (500 Mo par défaut).
- 🗑️ **Désinstalleur d'applications** — déplace les apps sélectionnées vers la Corbeille ; les données de support utilisateur restent intactes pour éviter toute perte accidentelle.
- 🤖 **Revue IA (locale)** — demandez à une CLI d'IA installée de classer les candidats en *suppression sûre*, *risqué* et *à examiner*.
- 🛡️ **La sécurité avant tout** — plus de 20 règles de sécurité et trois niveaux de protection empêchent la suppression des données système, de Mail/Messages/Safari et du Trousseau.
- 🌍 **11 langues** — interface entièrement localisée qui suit la langue de votre système ou un choix manuel.
- 🔒 **Privé par conception** — aucun appel réseau, aucune télémétrie, aucun compte.

## Revue IA (locale)

CleanMac détecte les outils d'IA en ligne de commande pris en charge sur votre `PATH` (y compris les emplacements courants de Homebrew, npm, asdf et volta) et vous laisse en choisir un pour examiner un lot de candidats au nettoyage. L'application construit une invite JSON structurée (chemin, taille, date de modification, catégorie, risque et les règles de sécurité applicables), exécute la CLI **depuis votre répertoire personnel** et analyse la réponse pour la reconvertir en groupes à code couleur.

| Outil | Binaire | Modèles disponibles |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

La liste des candidats et votre invite sont transmises à la CLI via stdin/arguments en tant que sous-processus — **elles ne quittent jamais votre machine**. CleanMac supprime également ses propres marqueurs de session de l'environnement enfant afin qu'une CLI ne puisse pas confondre cela avec une session imbriquée.

## Confidentialité et sécurité

- **Aucun réseau.** CleanMac n'effectue aucun appel réseau. La revue IA se déroule localement via les CLI que vous avez installées vous-même.
- **Corbeille, pas `rm`.** Tout est déplacé via `FileManager.trashItem(at:)`, ce qui vous permet de le restaurer.
- **Niveaux de protection.** `allowed` (caches/journaux/temporaires) → `requiresReview` (code source, stockage cloud, téléchargements, données de développement) → `blocked` (racine système, données d'applications, Mail/Messages/Safari, données de navigateur, Trousseau).
- **L'accès complet au disque (Full Disk Access)** est facultatif mais recommandé afin que les analyses puissent voir les emplacements protégés de la bibliothèque. CleanMac vous guide pour l'accorder dans Réglages Système.

## Installation

### Téléchargement (recommandé)

1. Récupérez le dernier **`CleanMac.dmg`** depuis la [page des versions](https://github.com/lgqyhm2010/CleanMac/releases/latest).
2. Ouvrez le DMG et faites glisser **CleanMac** dans **Applications**.

> **Premier lancement :** Si macOS indique que l'application ne peut pas être vérifiée (Gatekeeper) sur une version qui n'est pas encore notarisée, faites un clic droit sur l'application → **Ouvrir**, ou exécutez :
> ```bash
> xattr -dr com.apple.quarantine /Applications/CleanMac.app
> ```
> Les versions officiellement notarisées s'ouvrent d'un simple double-clic.

### Prérequis

- macOS **14.0 (Sonoma)** ou une version ultérieure
- Apple Silicon ou Intel

## Compilation depuis les sources

```bash
git clone https://github.com/lgqyhm2010/CleanMac.git
cd CleanMac

# Compiler et exécuter le bundle de l'application (crée dist/CleanMac.app et le lance)
./script/build_and_run.sh

# Ou simplement compiler avec SwiftPM
swift build --product CleanMac

# Exécuter les tests
swift test
```

**Chaîne d'outils :** Swift 6.0 (Xcode 16+). Le paquet expose une cible exécutable `CleanMac` (l'application) et une cible bibliothèque `CleanMacCore` (logique, modèles, services — maintenue séparément pour la testabilité).

## Création d'un DMG

Un seul script compile l'application et l'empaquette dans un DMG distribuable, à glisser pour installer :

```bash
./script/build_dmg.sh          # -> dist/CleanMac.dmg
```

Le script **signe et notarise** lorsque des identifiants Developer ID sont disponibles et **se dégrade avec élégance** (signature ad-hoc) sinon, de sorte qu'il produit toujours un DMG. Configurez la signature via des variables d'environnement — aucun secret n'est jamais codé en dur :

| Variable | Rôle |
|----------|---------|
| `CODESIGN_IDENTITY` | Identité de signature, par exemple `Developer ID Application: Name (TEAMID)`. Détectée automatiquement si non définie. |
| `NOTARY_PROFILE` | Un nom de profil de trousseau `notarytool` (voir [`docs/RELEASING.md`](docs/RELEASING.md)). |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | Identifiants de notarisation alternatifs (utilisés par la CI). |

> Une véritable distribution de type « télécharger et ouvrir » nécessite un certificat payant **Apple Developer ID Application**. Consultez [`docs/RELEASING.md`](docs/RELEASING.md) pour la configuration initiale. Sans cela, le DMG est tout de même créé mais n'est pas notarisé.

Chaque push vers `main` et chaque tag recompile et publie automatiquement le DMG via GitHub Actions ([`.github/workflows/release-dmg.yml`](.github/workflows/release-dmg.yml)).

## Localisation

CleanMac est disponible en **11 langues** : anglais, chinois simplifié, chinois traditionnel, japonais, espagnol, français, arabe, hindi, portugais (Brésil), russe et bengali. L'interface suit la langue de votre système par défaut et peut être remplacée dans les **Réglages**.

Les chaînes se trouvent dans `Sources/CleanMacCore/Resources/<locale>.lproj/Localizable.strings` derrière l'abstraction `L10n`. Pour ajouter une langue, ajoutez un nouveau dossier `.lproj` avec un `Localizable.strings` traduit, ajoutez le cas correspondant à `AppLanguage`, puis recompilez.

## Structure du projet

```
Sources/
  CleanMac/          Cible application — vues SwiftUI, stores, coque AppKit, menus
  CleanMacCore/      Cible bibliothèque — modèles, services, règles de sécurité, localisation
Tests/
  CleanMacCoreTests/ Tests de la logique du cœur
  CleanMacUITests/   Tests de l'application/des stores
script/
  build_and_run.sh   Compile le bundle .app et le lance
  build_dmg.sh       Compile + empaquette (et signe/notarise) un DMG
```

## Contribuer

Les contributions sont les bienvenues ! Veuillez lire [CONTRIBUTING.md](CONTRIBUTING.md) pour savoir comment compiler, tester et ouvrir une pull request. Les corrections de traduction et les nouvelles langues sont particulièrement appréciées.

## Licence

CleanMac est distribué sous la [licence MIT](LICENSE).
