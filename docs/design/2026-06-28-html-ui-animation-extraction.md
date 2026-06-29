# HTML UI And Animation Extraction

Source: `cleanmac_with_ai.html`

Scope: extract the visual direction for later SwiftUI work. This phase does not change app behavior.

## Design Intent

The HTML direction is a playful desktop utility window: thick ink outlines, warm paper surfaces, offset shadows, rounded-but-irregular cards, colorful feature badges, and small celebratory motion. The SwiftUI app should preserve the existing trust-first cleanup flow while adopting this visual language.

Do not treat every HTML page as a new product surface. Map the visual patterns onto the current app sections first:

- Scan: overview/header, disk/folder setup, permission guidance, scan options.
- Results: cleanup candidate list, safety/risk badges, detail pane, Move to Trash confirmation path.
- App Uninstaller: application scan and uninstall plan list.
- AI Review: local AI configuration, progress, and recommendation output.
- Settings/Permission: appearance/language and Full Disk Access guidance.

## Layout

- App shell: centered macOS-style window, target around `1180 x 760`, minimum height near `620`, with a large `30px` outer corner radius and a subtle 2px app ring.
- Title bar: `48px` high, warm chrome background, traffic-light controls on the left, left-aligned title text, and a small `CleanMac` chip before the current page title.
- Sidebar: custom 250px source column with warm paper/beige background, a raised brand card, section labels, colorful circular feature icons, active rows with paper fill and offset shadow.
- Content pane: warm paper background with very subtle radial color accents and sparse sparkle ornaments. Page content sits above the decorative layer.
- Page header: first element on each page is a raised rounded card with icon, title, subtitle, and trailing status/action summary.
- Cards: use thick `3px` dark border, `28px` radius, warm paper fill, and vertical offset shadow. Metric/action cards can be square-ish with centered feature illustrations.
- Tables/lists: keep desktop density, but wrap headers/lists in the same raised card treatment. Use separated rows with light dividers, not fully nested cards inside cards.
- Mobile HTML collapse is not directly relevant for the macOS app, but the SwiftUI layout should remain robust when the window narrows.

## Color Tokens

Primary light tokens from the HTML:

- Ink/line: `#221E34` / `#241F36`
- Paper: `#FFFDF6`
- Warm pane: `#FBF6EB`
- Chrome: `#EFE7D6`
- Desk background: `#EDF1F4`
- Shadow: `#E7DECD`
- Sidebar: `#F2E8D8`
- Sidebar section text: `#877AA1`
- Secondary text: `#706B82`
- Blue: `#5DAEE7` and legacy accent `#58A7D8`
- Green: `#74C6A6` and legacy accent `#7DC4A8`
- Yellow: `#F6C94E` / `#F2CC5A`
- Purple: `#A685DF` / `#9E70E8`
- Pink: `#EF96B5` / `#E891B0`
- Peach: `#F2A67F` / `#F0A882`

Dark mode keeps the dark ink outline but changes the shell:

- Chrome/sidebar: `#282631` / `#2C2934`
- Warm pane: `#302D35`
- Paper cards stay warm: `#FFF8EA`
- Dark shadow: `rgba(0,0,0,.34)`
- Chrome text: `#FFF7E8`
- Sidebar text: `#F5EFE5`

Implementation note: keep semantic color helpers in `CleanMacTheme`, but replace the current material-heavy neutrals with explicit design tokens so repeated components stay consistent.

## Motion And Animation Cues

HTML motion inventory:

- `float`: feature/brand icons drift up about 5px over 3s.
- `sparkPop`: sparkle glyphs scale in/out with opacity.
- `blink`: mascot eye blink.
- `segIn`: disk usage segments scale in from the left with short delays.
- `slideIn`: page enters with fade + 12px upward movement over 0.25s.
- `spin`: progress indicator rotation.
- `scanBeam`: scanning beam sweep.
- `pulse`: active icons scale from 1.0 to about 1.06.
- `fillBar`: bars fill from zero to target width.
- `fadeIn`: streamed AI lines appear quickly.
- `wiggle` and `bounce`: small celebratory feedback for done states.

SwiftUI guidance:

- Honor `accessibilityReduceMotion` through `CleanMacMotion.allowed`.
- Use looping motion only for active states: scanning, AI review, progress, mascot/sparkle accents.
- Use page transition as fade + slight upward movement rather than the current scale-only transition.
- Buttons should have hover/press feedback: offset shadow grows on hover and compresses on press.
- Animate numeric/text state changes with the existing `.contentTransition(.numericText())` where useful.
- Avoid motion that implies work happened before the app actually changes state.

## Image Assets Needed

The HTML contains no external `<img>` assets; it uses inline SVGs and emoji. The next phase should generate a small reusable asset set instead of one-off screenshots.

Recommended assets:

- `cleanmac-mascot`: friendly rounded desktop-computer face, thick dark outline, pastel blue screen, warm paper body. Needed for brand/sidebar/header.
- `feature-disk-overview`: disk/drive overview icon with blue accent.
- `feature-cleanup-trash`: cleanup/trash or folder icon with green accent.
- `feature-duplicates`: overlapping documents with yellow accent.
- `feature-app-uninstall`: app bundle/document icon with pink accent.
- `feature-ai-review`: local AI headset/sparkle icon with purple accent.
- `feature-permission-shield`: shield/lock for Full Disk Access with amber or green status variants.
- Optional `feature-space-chart`: bar chart/space analysis motif, only if the existing app needs a decorative overview asset later.

Asset style rules:

- Transparent background.
- Thick `#241F36` outline.
- Warm paper fills, pastel feature color, minimal shading.
- Export at least 256px square; 512px preferred for retina scaling.
- Keep decorative sparkles as SwiftUI shapes/glyphs unless the generated mascot includes them.

Resource note: the `CleanMac` executable target currently has no resource declaration in `Package.swift`. A later implementation phase may need to add a `Sources/CleanMac/Resources` folder and process it, or keep the simple icons in SwiftUI vector code.

## SwiftUI Files Likely Affected

- `Sources/CleanMac/Views/DesignSystem.swift`: core color tokens, panel/card style, button style, page background, header, metric tile, status badge, icon/motion helpers.
- `Sources/CleanMac/Views/ContentView.swift`: app shell, split layout styling, page transition, toolbar action placement.
- `Sources/CleanMac/Views/SidebarView.swift`: custom sidebar surface, brand block, section labels, active row treatment, colorful section icons.
- `Sources/CleanMac/Views/SidebarSection.swift`: visual labels/icons may need remapping, but do not add HTML-only sections unless product behavior is intentionally added later.
- `Sources/CleanMac/Views/ScanView.swift`: overview header, metric tiles, permission guide placement, folder and scan option cards.
- `Sources/CleanMac/Views/ResultsView.swift`: cleanup list/table styling, risk/protection badges, detail card, action row.
- `Sources/CleanMac/Views/AppUninstallerView.swift`: application metric cards and uninstall plan rows.
- `Sources/CleanMac/Views/AIReviewView.swift`: local AI configuration card, progress card, streamed/recommendation output treatment.
- `Sources/CleanMac/Views/PermissionGuideView.swift`: shield/status card styling.
- `Sources/CleanMac/Views/SettingsView.swift`: settings cards should match HTML appearance/language card treatment.

## Decisions For Later Phases

- Preserve existing product behavior and safety guarantees; HTML-only demo pages are visual references, not required new navigation.
- Generate a compact reusable illustration set before applying SwiftUI styling.
- Prefer a shared SwiftUI design system over per-view hardcoded colors and shadows.
- Keep motion accessible, state-driven, and tied to actual scanning/review/cleanup states.
