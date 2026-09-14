# Holding Tycoon source audit

## Outcome

The supplied 16 Dart files and both dependency files were reviewed as one Flutter application. The repaired bundle preserves the existing sky-blue, white, black-outline, gold, green, and red palette and retains every existing screen and gameplay entry point.

## Critical fixes

- **Startup and dependencies:** `pubspec.yaml` claimed Dart 3.5 while the supplied lockfile requires Dart 3.12 and Flutter 3.44. The declared SDK now matches the resolved dependency graph. AdMob is initialized during startup and an ads failure no longer prevents the game from launching.
- **Root rebuild storm:** the root `MaterialApp` previously listened to the entire `GameState`, so the one-second economy tick rebuilt the full app and navigator. It now selects only first-launch state.
- **Save integrity:** simultaneous fire-and-forget saves could finish out of order and overwrite newer progress. Saves are serialized and coalesced. Invalid JSON, invalid dates, non-finite balances, malformed list lengths, out-of-range levels, and invalid stock values are sanitized. Device-clock rollback no longer creates negative offline time.
- **State lifecycle:** the global economy timer is canceled in `GameState.dispose`. Expired boosts, tax bonuses, and events are removed during loading.
- **Reward validation:** task, achievement, prestige, research, stock, starter-sector, and numeric mutations validate their rules in `GameState`; UI buttons are no longer the only protection against invalid rewards or upgrades.
- **Rewarded ads:** only one ad can load/show at a time, a reward callback is accepted once, loading UI is closed safely, audio is resumed after dismissal/failure, and a fresh ad is preloaded. Debug uses test IDs; release requires supplied production IDs.
- **Audio races:** music pause/resume is reason-based, so app lifecycle events cannot incorrectly resume music over an ad. Rapid click/cash effects use independent players and no longer cut each other off. Temporary players and subscriptions are cleaned up.
- **Map failure:** missing or corrupt `map.png` previously removed the entire interactive map because factory plots were created inside the image-load `try` block. Factory plots and navigation now remain available with the fallback ocean scene.
- **Build side effects:** random event consumption and bag spawning were moved out of the widget build phase and into one guarded post-frame operation.
- **Reset safety:** starting a new holding previously called `SharedPreferences.clear()`, deleting audio and unrelated preferences, and committed a half-reset game before setup was complete. Only game/holding keys are removed; the actual reset happens after setup confirmation.

## Gameplay and economy corrections

- Prestige remains locked until total turnover reaches `100 Qi` (`1e20`) and is now enforced in state. Outstanding tax blocks prestige unless the automatic-amnesty research is unlocked.
- Research parent requirements are enforced in state. Factory-specific income research, passive/product research, upgrade and land discounts, office research, tax research, stock commission/cashback/trend/dividend research, opportunity/crisis research, boost research, prestige research, rank research, and apex multipliers now affect gameplay instead of being descriptive-only purchases.
- Research-driven discounts are capped so costs cannot become zero or negative.
- Tax timing and foreclosure now match their research descriptions more closely: hourly late interest and a 72-hour base foreclosure window replace the previous 2% every 15 minutes and one-hour foreclosure.
- Repeated boost rewards extend the active boost rather than discarding remaining time.
- New games reset stock prices/history and offline-session diagnostics as well as holdings.
- Task cards now display their real reward type: the wheel and stock tasks grant RP, not the cash amounts previously shown.
- Stock inputs reject NaN, infinity, zero, and negative values. Dialog text controllers are disposed. Research cashback, dip buying, commission reduction, dividends, and profitable-sale apex bonuses are applied consistently.
- The wheel cannot be closed while its ad request is pending, eliminating disposed-widget callbacks and lost rewards. Wheel research now affects reward size, premium-result chance, and tax amnesty.

## UI, responsiveness, and animation

- Async `setState` and navigation paths now check that their widget/context is still mounted.
- Settings persistence is debounced so dragging a volume slider no longer writes preferences dozens of times per second. The language row can shrink on narrow devices.
- Side actions are vertically scrollable between the top panel and bottom navigation on short phones.
- Only three toast-style notifications render simultaneously, preventing a large achievement queue from overflowing the map.
- Notification exit animations are single-shot and do not call state after disposal.
- Live prestige turnover/progress updates while the dialog is open.
- The company name is trimmed, newline-free, and limited to 24 characters.

## File-by-file review

| File | Result |
| --- | --- |
| `lib/main.dart` | Fixed ad initialization, lifecycle audio arbitration, and whole-app rebuilds. |
| `lib/providers/game_state.dart` | Repaired persistence, validation, timer disposal, economy rules, research effects, prestige, tax, stock, offline, and reset behavior. |
| `lib/screens/main_menu_screen.dart` | Fixed destructive preference clearing, interrupted setup behavior, name validation, and async flow. |
| `lib/screens/map_screen.dart` | Fixed build-time mutations, missing-map failure, async lifecycle checks, notification overflow, and short-screen action overflow. |
| `lib/screens/office_screen.dart` | UI and state now use the same research-adjusted staff cost. Animation controllers were verified as disposed. |
| `lib/screens/research_screen.dart` | Existing responsive tree and controller disposal retained; state now independently enforces parent locks and costs. |
| `lib/screens/settings_screen.dart` | Fixed post-dispose updates, slider write storms, narrow-layout overflow, and language-switch lifecycle. |
| `lib/screens/stock_screen.dart` | Fixed controller leak; state validates all amounts and consistently applies research effects. |
| `lib/services/admob_service.dart` | Rebuilt ad lifecycle and reward safety; added release configuration. |
| `lib/services/audio_service.dart` | Rebuilt concurrent SFX lifecycle and reason-based BGM control. |
| `lib/services/translation_service.dart` | Added supported-language validation, stale-load protection, safe JSON/fallback handling, and non-string protection. |
| `lib/theme/app_theme.dart` | Palette intentionally unchanged. No breaking theme migration introduced. |
| `lib/widgets/achievements.dart` | Reward UI retained; claim index/progress validation is now enforced by state. |
| `lib/widgets/prestige_dialog.dart` | Uses live turnover and authoritative state eligibility. |
| `lib/widgets/tasks.dart` | Corrected reward labels to match actual cash/RP grants. |
| `lib/widgets/wheel.dart` | Fixed ad/disposal race and connected wheel research effects. |
| `pubspec.yaml` / `pubspec.lock` | SDK constraint aligned; lockfile retained unchanged. |

## Validation performed

- All 16 Dart files passed a lexical delimiter/string/comment balance scan after editing.
- All six translation JSON files parse successfully and contain every translation key referenced with `.tr()`.
- Import targets and declared project paths were checked after normalizing filenames into the intended directory structure.
- Reward, save, reset, map fallback, ad, audio, and lifecycle flows were traced across callers rather than reviewed only within individual files.

The current execution environment does not contain the Flutter/Dart SDK, so `flutter analyze`, device rendering, and platform ad integration could not be executed here. Run the four commands in the README after restoring the binary assets and native platform folders.

## Inputs not supplied

The two attached PNG files are screenshots of the folder tree, not the game assets. Audio, logo, map, launcher icon, and Android/iOS native project files were therefore not available for visual, waveform, manifest, safe-area-on-device, or release-build verification.
