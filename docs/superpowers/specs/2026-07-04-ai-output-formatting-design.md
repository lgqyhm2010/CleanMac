# AI Review Output Formatting — Design

Date: 2026-07-04
Status: Approved (user confirmed via brainstorming session)

## Goal

Stop dumping the AI CLI's raw text into the results panel. Parse the JSON the
prompt already requests and render a structured, color-coded result view; fall
back to the current raw-text view whenever parsing fails, so the feature can
never be worse than today.

## Prompt tightening (AIReviewService.makePrompt)

Replace the loose "Answer in concise JSON with keys …" instruction with an
explicit schema and a no-fences rule:

```
Respond with JSON only — no markdown fences, no prose outside the JSON.
Schema:
{"summary": "<one-paragraph overall assessment>",
 "safe_to_delete": [{"path": "<absolute path>", "reason": "<short reason>"}],
 "risky": [{"path": "...", "reason": "..."}],
 "needs_user_review": [{"path": "...", "reason": "..."}]}
```

## Parser (new: Sources/CleanMacCore/Services/AIReviewOutputParser.swift)

```swift
public struct AIReviewItem: Equatable, Sendable, Identifiable {
    public var id: String { path + (reason ?? "") }
    public let path: String
    public let reason: String?
}

public struct AIReviewSummary: Equatable, Sendable {
    public let summary: String?
    public let safeToDelete: [AIReviewItem]
    public let risky: [AIReviewItem]
    public let needsUserReview: [AIReviewItem]
}

public enum AIReviewOutputParser {
    public static func parse(_ raw: String) -> AIReviewSummary?
}
```

Tolerant parsing pipeline:

1. Strip markdown code fences (```json … ``` or ``` … ```).
2. Extract the substring from the first `{` to the last `}` (models often wrap
   JSON in prose).
3. `JSONSerialization` decode; map keys `summary` (String) and the three arrays.
4. Array elements accept BOTH shapes: a plain String (→ path, reason nil) or a
   dictionary (path from `path`/`file`/`url`, reason from `reason`/`note`/`why`).
5. Return nil when decoding fails or when everything is empty (nil summary and
   all three arrays empty) — nil means "show raw text".

## Store (CleaningStore)

- `@Published var aiReviewSummary: AIReviewSummary?`
- `askAI()` clears it when starting and sets
  `aiReviewSummary = AIReviewOutputParser.parse(review.output)` on success.
- `aiOutput` keeps the raw text (fallback view + user copying).

## UI (AIReviewView.aiOutputContent)

- `aiReviewSummary != nil` → ScrollView with:
  - summary paragraph (when present),
  - three groups in fixed order — safe to delete (green), risky (danger red),
    needs user review (orange) — each a CleanMacSectionHeader-style title with
    count, rows showing the path (middle-truncated) and the reason as secondary
    text. Empty groups are hidden.
- `aiReviewSummary == nil` → the existing monospaced raw TextEditor, unchanged.
- Colors come from the existing CleanMacTheme palette (reuse its
  success/danger/warning tints; add a constant only if one is missing).

## Localization

Four new L10n keys × 11 languages:

| Key | zh-Hans | en |
|---|---|---|
| `aiSummary` | 总结 | Summary |
| `safeToDelete` | 可安全删除 | Safe to delete |
| `riskyItems` | 有风险 | Risky |
| `needsUserReview` | 需人工确认 | Needs your review |

Other languages follow the existing translation table conventions.

## Testing

- Parser: clean JSON; fenced JSON; JSON embedded in prose; string-array
  elements; object-array elements with alternate keys; pure prose → nil.
- Prompt: makePrompt contains the schema line and the no-fences rule.
- Store: successful review populates aiReviewSummary; new run clears it.
- Localization: existing coverage tests pick up the new keys.
- Real-sample check: run the actual codex CLI output through the parser once
  during verification.

## Out of scope

- Acting on the parsed result (e.g. auto-adjusting the selection to match
  safe_to_delete) — display only for now.
- Markdown rendering.
