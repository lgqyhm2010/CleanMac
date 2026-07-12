<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**Un nettoyeur de disque natif, privé et assisté par IA pour macOS.**

Recherchez les caches, journaux, doublons, fichiers volumineux et applications inutilisées, faites examiner leurs métadonnées expurgées par un CLI d’IA installé, puis déplacez-les vers la Corbeille. CleanMac ne demande aucun compte et n’intègre aucune télémétrie ; le CLI d’IA peut utiliser le service réseau de son fournisseur.

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

Ce qui la distingue : elle peut confier des **métadonnées expurgées et limitées** des éléments sélectionnés à un CLI d’IA installé (Claude Code, Codex ou Gemini CLI) pour obtenir un second avis. Votre question est envoyée telle quelle ; CleanMac n’ajoute ni contenu de fichier ni chemin complet, et le CLI peut contacter son fournisseur configuré.

## Fonctionnalités

- 🧹 **Analyse intelligente** — caches, journaux, fichiers temporaires, Corbeille, déchets de développement (données dérivées de Xcode), téléchargements et fichiers « autres » non classés.
- 📦 **Détecteur de doublons** — regroupe les fichiers par empreinte de contenu SHA-256 et conserve la copie la plus récente.
- 🐘 **Fichiers volumineux** — fait remonter les fichiers dépassant un seuil configurable (500 Mo par défaut).
- 🗑️ **Désinstalleur d'applications** — déplace les apps sélectionnées vers la Corbeille ; les données de support utilisateur restent intactes pour éviter toute perte accidentelle.
- 🤖 **Revue IA (locale)** — demandez à une CLI d'IA installée de classer les candidats en *suppression sûre*, *risqué* et *à examiner*.
- 🛡️ **La sécurité avant tout** — plus de 20 règles de sécurité et trois niveaux de protection empêchent la suppression des données système, de Mail/Messages/Safari et du Trousseau.
- 🌍 **11 langues** — interface entièrement localisée qui suit la langue de votre système ou un choix manuel.
- 🔒 **Limite de confidentialité explicite** — aucun compte ni télémétrie CleanMac ; le transfert vers l’IA est expurgé et clairement signalé.

## Revue IA (locale)

CleanMac détecte les outils d’IA compatibles sur votre `PATH` et permet d’examiner jusqu’à 80 candidats. Il envoie votre question et des métadonnées anonymes structurées (ID, taille, date, catégorie, risque et ID de règles), exécute le CLI depuis un répertoire temporaire vide et unique avec un délai de 120 secondes, puis n’accepte la réponse que si chaque élément est classé exactement une fois.

| Outil | Binaire | Modèles disponibles |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

La liste des candidats et votre invite sont transmises à la CLI via stdin/arguments en tant que sous-processus — **elles ne quittent jamais votre machine**. CleanMac supprime également ses propres marqueurs de session de l'environnement enfant afin qu'une CLI ne puisse pas confondre cela avec une session imbriquée.

## Confidentialité et sécurité

- **Information réseau de l’IA.** CleanMac n’intègre aucune télémétrie, mais un CLI d’IA installé peut contacter son fournisseur. La revue envoie votre question telle quelle, des ID anonymes et des métadonnées limitées, jamais le contenu des fichiers ni les chemins complets collectés automatiquement.
- **Corbeille, pas `rm`.** Tout est déplacé via `FileManager.trashItem(at:)`, ce qui vous permet de le restaurer.
- **Niveaux de protection.** `allowed` (caches/journaux/temporaires) → `requiresReview` (code source, stockage cloud, téléchargements, données de développement) → `blocked` (racine système, données d'applications, Mail/Messages/Safari, données de navigateur, Trousseau).
- **L'accès complet au disque (Full Disk Access)** est facultatif mais recommandé afin que les analyses puissent voir les emplacements protégés de la bibliothèque. CleanMac vous guide pour l'accorder dans Réglages Système.

## Installation

### Téléchargement (recommandé)

1. Récupérez le dernier **`CleanMac.dmg`** depuis la [page des versions](https://github.com/lgqyhm2010/CleanMac/releases/latest).
2. Ouvrez le DMG et faites glisser **CleanMac** dans **Applications**.

> Les téléchargements officiels sont signés et notarisés. Si Gatekeeper ne peut pas en vérifier un, ne désactivez pas la quarantaine ; supprimez-le et retéléchargez-le depuis la page Releases officielle.

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
# Aperçu local non distribuable
./script/build_dmg.sh --unsigned

# Release formelle ; Developer ID et identifiants de notarisation requis
CLEANMAC_VERSION=1.0.0 CLEANMAC_BUILD_NUMBER=1 \
  NOTARY_PROFILE=CleanMacNotary ./script/build_dmg.sh --release
```

Une release formelle échoue immédiatement si les identifiants, la version, l'architecture, la signature, la notarisation, l'agrafage ou Gatekeeper échouent. La configuration passe par des variables d'environnement et aucun secret n'est codé en dur :

| Variable | Rôle |
|----------|---------|
| `CODESIGN_IDENTITY` | Identité de signature, par exemple `Developer ID Application: Name (TEAMID)`. Détectée automatiquement si non définie. |
| `CLEANMAC_VERSION` / `CLEANMAC_BUILD_NUMBER` | Version de release et numéro de build numérique. |
| `NOTARY_PROFILE` | Un nom de profil de trousseau `notarytool` (voir [`docs/RELEASING.md`](docs/RELEASING.md)). |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | Identifiants de notarisation alternatifs (utilisés par la CI). |

> `--unsigned` sert uniquement à la validation locale/PR et n'est jamais publié comme release. Consultez [`docs/RELEASING.md`](docs/RELEASING.md).

Les PR et pushes vers `main` ne créent qu'un aperçu non signé en lecture seule. Seul un tag `v*` publie après toutes les vérifications ([workflow](.github/workflows/release-dmg.yml)).

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
