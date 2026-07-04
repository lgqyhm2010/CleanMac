# AI Review Per-Tool Model Selection — Design

Date: 2026-07-04
Status: Approved (user confirmed via brainstorming session)

## Goal

Let the user pick which model each detected AI CLI (Claude Code / Codex / Gemini CLI)
uses for the AI review, from a curated preset list per tool. "Default" (no flag) is
always the first option so the CLI's own default model is used unless overridden.

No CLI offers a "list models" command, so presets are hardcoded per tool profile and
updated with the app.

## Data layer (CleanMacCore)

New type in `AIToolDetector.swift` (alongside `AIToolProfile`):

```swift
public struct AIModelOption: Identifiable, Equatable, Sendable {
    public let id: String          // stable, e.g. "default", "fable", "gpt-5.1-codex"
    public let displayName: String // shown on the pill; raw model names stay raw
    public let flagValue: String?  // nil = default → no model flag appended
}
```

`AIToolProfile` gains:

- `modelFlag: String` — `"--model"` for claude, `"-m"` for codex/gemini.
- `modelOptions: [AIModelOption]` — first entry is always Default (`flagValue: nil`).

Presets (revised 2026-07-04 after verifying official docs — prefer auto-upgrading
aliases over pinned IDs so lists stay current without app updates):

| Tool | Options (flag value) |
|---|---|
| Claude Code | Default / Fable (`fable`) / Opus (`opus`) / Sonnet (`sonnet`) / Haiku (`haiku`) — official aliases, auto-upgrade |
| Codex | Default / `gpt-5.5` / `gpt-5.4` / `gpt-5.4-mini` — no alias mechanism, pinned IDs (developers.openai.com/codex/models) |
| Gemini CLI | Default / Pro (`pro`) / Flash (`flash`) — official aliases, auto-upgrade (geminicli.com/docs/cli/model) |

## Command construction (AIReviewService)

`review(candidates:userQuestion:)` gains a `model: AIModelOption?` parameter
(default `nil`). Argument order: base arguments, then `[modelFlag, flagValue]`
when `flagValue != nil`, then the prompt for `.argument` delivery tools:

- claude: `-p --model fable` (prompt via stdin)
- codex: `exec -m gpt-5.1` (prompt via stdin)
- gemini: `-m gemini-2.5-pro -p <prompt>`

An invalid/retired model name makes the CLI exit non-zero; the existing error
surfacing (merged stderr+stdout tail) shows the CLI's own message. No extra
validation in the app.

## State (CleaningStore)

- `selectedModelIDsByTool: [String: String]` (toolID → modelOption id), persisted
  in UserDefaults under `"aiModelPreferenceByTool"` — mirrors the existing
  `aiToolPreferenceKey` pattern.
- `selectModel(_ modelID: String, for toolID: String)` writes state + UserDefaults.
- `selectedModelOption(for toolID:)` resolves the persisted id against the tool's
  `modelOptions`; unknown/missing ids fall back to the first (Default) option, so
  removed presets degrade gracefully.
- `askAI()` passes the resolved option to `AIReviewService.review`.

## UI (AIReviewView)

Below the existing tool pills, a "模型 / Model" row shows the selected tool's
`modelOptions` as pills (same interaction style as tool pills). Switching tools
swaps the row's options and highlights that tool's remembered selection.

Localization: new L10n key for the "Model" section label (zh: 模型, en: Model,
plus the other supported languages following the existing table).

## Testing

- Profile: each known profile exposes a Default-first `modelOptions` list and the
  right `modelFlag`.
- Service: `review(model:)` appends `[flag, value]` before the prompt argument;
  no flag appended for Default/nil.
- Store: selection persists per tool; unknown persisted id falls back to Default.
- Localization: existing key-coverage tests pick up the new label key.

## Out of scope

- Custom free-text model input (user chose presets-only).
- Dynamic model discovery (no CLI supports it).
- Per-model pricing/capability hints.
