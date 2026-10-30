# nekocal

Public project/package name: `nekocal`. The app bundle, display name, bundle identifier and signing credentials retain the existing KawaiiCal identity.

Personal Apple Silicon fork of [Itsycal](https://github.com/sfsam/Itsycal), based on 1a31050555a97e3b7aac5470ec147abfe7aa0d6a (0.27.3).

KawaiiCal has its own version series, starting at **0.1.0 (build 1)**. The upstream version above records source provenance only.

Requires Xcode 27 and macOS 27+. Existing calendar UI and EventKit behavior are retained. App identity is `ing.miel.KawaiiCal`; date links use `kawaiical://date/now`. Settings are separate from upstream; calendar events are shared through macOS Calendar. Upstream software update checks are disabled; rebuild to update. Original MIT license and attribution are retained.

## Build

Run `./scripts/build.sh`. Output is `outputs/KawaiiCal.app`, locally signed. Build details are in `outputs/build.log`. Quit the installed app and run `./scripts/install.sh`, then open `/Applications/KawaiiCal.app`. The installer verifies identity and signatures and keeps the previous app in `outputs/installed-backups/`. Allow Calendar access when prompted to display and create events.

## Sign and notarize

Create a Developer ID Application certificate in Xcode > Settings > Apple Accounts > team > Manage Certificates > +. A paid developer team and appropriate permissions are required.

Store notarization credentials interactively in Terminal with `xcrun notarytool store-credentials kawaii-cal`. Do not put passwords in this repository or chat.

To sign without submitting, run `SIGNING_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)' ./scripts/sign.sh` after building.

Run `SIGNING_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)' NOTARY_PROFILE=kawaii-cal ./scripts/notarize.sh`.

This rebuilds, signs nested code and the app with hardened runtime and timestamp, submits to Apple, checks acceptance, staples the ticket, validates Gatekeeper, and writes `outputs/KawaiiCal.zip`. Apple notarization is pending until these steps pass. Existing upstream notarization does not apply to the fork.

The upstream release packaging script is retained for reference; use the scripts above for this fork.

After successful notarization, quit the running app and use `./scripts/install.sh` again to install the notarized copy.

## Release validation

The local 0.1.0 build passed Developer ID signature verification, Apple notarization, stapled-ticket validation and Gatekeeper assessment. These checks apply to that built artifact; anyone rebuilding must sign and notarize with their own credentials. Live calendar create/delete operations were not exercised against personal data.

Public source repository: [ynifamily3/nekocal](https://github.com/ynifamily3/nekocal). The original source is retained as the `upstream` remote.

## Korean date/time audit

Date headers, relative day names, interval/detail/copy/delete formatting, date pickers, recurrence labels, menu-bar date patterns, and alert labels were inspected. Korean app language now also selects Korean date/day/time language when the system language differs, while retaining region, time zone, and 12/24-hour preferences. A spanning event uses `오후 3:00 종료`; the repeat-end option reads `종료 없음`. User-defined menu-bar patterns remain intact.

The production locale helper and interval-locale workaround were exercised in a synthetic Foundation bundle with Korean app language plus English-region 12-hour and 24-hour settings, Korean/Korea settings, and English settings. All checks passed; no personal calendar events were changed.

## Emoji and kaomoji rotation

Open Settings > Appearance > 이모티콘 관리…. Enter one expression per line, choose a 1–1440 minute interval, enable automatic rotation, and press 적용. The menu-bar pattern field defaults to `{emoji} HH:mm`; place `{emoji}` wherever the expression should appear. Apply saves all settings. 지금 바꾸기 chooses from the saved list; edits must be applied first. Turning automatic rotation off freezes the current expression. 이전 형식 복원 restores the menu-bar pattern saved before first applying this feature.

CSV import replaces the editor contents for review; it does not save until Apply. Use UTF-8, one expression per row. A header named `emoji`, `emoticon`, `이모티콘` or `카오모지` chooses that column; without a header the first column is used. Standard CSV quoting allows commas and double quotes. Empty entries and duplicates are removed. Imports are limited to 1MB, and saved lists to 500 expressions of at most 200 UTF-16 units each. See `examples/emoji.csv`.

Rotation excludes the current expression when two or more unique entries exist. A dedicated timer updates emoji-only displays too; after sleep, it chooses once when overdue. Rendering substitutes the expression after date formatting so emoji, Latin letters and apostrophes are not interpreted as time-format instructions. Existing patterns without `{emoji}` are unchanged.

Run the Foundation regression checks with:

```sh
xcrun clang -fobjc-arc -framework Foundation -I Itsycal tests/emoji-rotation.m Itsycal/EmojiRotation.m -o work/emoji-rotation-check
work/emoji-rotation-check
```

## Weekend and holiday colors

Saturday uses system blue; Sunday and dates covered by flagged holiday calendars use system red. Red takes priority when a holiday falls on Saturday. Calendar weekday headings and agenda date headings use the same convention; adjacent-month dates and empty agenda days remain dimmed. Today/selection outlines and event dots retain their existing behavior.

In Settings > Events, each calendar has an independent `이 캘린더의 일정은 공휴일` checkbox. Check it on a South Korea holiday calendar already available through macOS Calendar. This does not subscribe to or compute national holidays: it uses events in the calendars you designate, including observed holidays present in those feeds. Marked calendars color dates even if their agenda-display checkbox is off. Flags are persisted by calendar identifier. Multi-day events color each covered date, excluding the event's end date when it ends at midnight.

The synthetic holiday regression check uses fake calendars/store data and does not read or modify personal events. It tests light/dark weekend colors, holiday priority, dimming, clearing reused cell colors, multi-day end boundaries, hidden calendar flags, and immediate on/off refresh.

## Popup material and agenda spacing

The main popup uses AppKit's popover material with behind-window blending and a 55% theme-colored tint behind its content to reduce wallpaper bleed. The tint does not intercept input or change foreground opacity. The calendar no longer paints an opaque background over it. Sticky agenda date headings use header material with within-window blending so scrolled rows do not directly compete with heading text. Native scrollbars replace the previously painted scrollbar track. AppKit controls material appearance and accessibility behavior.

Agenda titles and date headings are 1pt larger than the existing text-size setting; event titles use medium weight. Time/location text retains the existing size. Event rows use 4pt top/bottom padding and 2pt internal spacing; date headings use 7pt top and 3pt bottom padding. Event dots are realigned to the title. Calendar cell sizes and selection outlines are preserved.

The AppKit material-layout harness verifies the actual production views: material/blending configuration, transparent window/calendar, sticky heading material, and fitting/font sizes across all three text-size settings in light/dark appearances. It does not exercise personal events or visually measure the live desktop backdrop.

## Settings presentation

The four settings tabs share a 480pt minimum content width and system window material. Settings and emoji-editor windows use opaque system window backgrounds and nontransparent titlebars; material blending is limited to within-window content to prevent unblurred windows behind the toolbar from showing through. Related controls are grouped into rounded, subtly bordered sections with 16pt inner padding and 24pt page margins. Toolbar icons use SF Symbols. General groups launch/alerts and shortcut/position controls; Events separates calendar selection (including holiday flags) from agenda options; Appearance separates theme/text size, menu-bar settings and calendar options. The unavailable upstream-update checkbox is removed from General. All active bindings are retained. About shows only the app name and version; the emoji editor uses the same window material.

A resource-backed AppKit test checked every tab in light/dark appearances: General 480×295, Events 480×515, Appearance 480×572, About was later simplified to a compact app-name/version-only view. It verified section counts and fitting sizes without requesting calendar access or changing personal settings.

The settings regression test also constructs a titled panel with a preference toolbar and asserts an opaque window, a fully opaque background color, nontransparent titlebar, and within-window-only material blending.

## Korean shortcut-recorder messages

The bundled MASShortcut framework now includes Korean translations for all 16 English resource-table messages: idle/recording prompts, cancel/keep-existing actions, delete/help text, conflict alerts, Space-key naming, and VoiceOver announcements. A small MASShortcutView subclass localizes the framework's otherwise hard-coded `Empty` accessibility-label prefix without changing key capture, validation, or defaults binding. Existing settings-tab localization keys were checked for missing Korean entries; none were missing. The modified framework is re-signed with the user's Developer ID during release signing.

An isolated resource-backed test verified Korean resource selection, recorder recording/cancel state transitions, Korean accessibility labels/help and conflict-message formatting. Test input was not bound to the installed app's shortcut preference.

## App icon

The app icon is a simple, vector-style cat-face emoji illustration. Its transparent 1024px raster asset is `Itsycal/AppIcon.icon/Assets/KawaiiCal-Cat-Simple.png`; Icon Composer supplies native light/dark backgrounds and icon sizes. The built-in image generation prompt is preserved in `Design/KawaiiCal-Cat-Simple.prompt.txt`. The compiled 256px icon was visually inspected before installation.

## Menu bar cat icon

The fourth menu-bar icon is a simple monochrome cat outline with ears, eyes, a smiling mouth and whiskers. Its canonical 21×16pt artwork is generated by `swift Design/MenuBarCat.swift` into a vector PDF. The asset catalog preserves its vector representation and marks it as a template so macOS supplies the appropriate menu-bar foreground color. The previous face bitmaps are retained in `Design/LegacyMenuBarFace*.png`. The Korean picker label is `고양이 아이콘`.

The compiled asset was checked for its 21×16pt size and template flag, and rendered on light/dark backgrounds for visual review. Existing menu-bar text and emoji rotation remain independent of this icon.
