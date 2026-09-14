# Holding Tycoon — repaired source bundle

This bundle contains the complete normalized Dart source set from the supplied files, with the repairs described in `docs/AUDIT_REPORT.md`.

## Integration

1. Copy `lib/`, `assets/translations/`, `pubspec.yaml`, and `pubspec.lock` into the existing Flutter project.
2. Restore the original binary assets, which were shown in screenshots but were not attached:
   - `assets/audio/bgm.mp3`
   - `assets/audio/cash.mp3`
   - `assets/audio/click.mp3`
   - `assets/icon/app_icon.png`
   - `assets/images/logo.png`
   - `assets/images/map.png`
3. Keep the existing Android and iOS folders. They were not part of the upload.
4. Run `flutter pub get`, `dart format lib test`, `flutter analyze`, and `flutter test` using Flutter 3.44 / Dart 3.12 or newer, matching the supplied lockfile.

The app now starts without crashing when audio or map assets are absent: audio failure is isolated, the logo has its existing fallback, and the map retains interactive factory plots on a generated ocean background. The original assets are still required for the intended presentation and launcher icon.

## Release ads

Debug builds use Google's rewarded-ad test units. Release builds deliberately require real rewarded unit IDs:

```text
--dart-define=ADMOB_REWARDED_ANDROID_ID=ca-app-pub-.../...
--dart-define=ADMOB_REWARDED_IOS_ID=ca-app-pub-.../...
```

The native AdMob application IDs must also remain configured in the existing Android/iOS project files.
