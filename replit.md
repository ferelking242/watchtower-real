# Reel (watchtower-real)

Application Flutter UI TikTok-style qui consomme le SDK Watchtower. Feed vertical, recherche, live, inbox, profil.

## Build & CI

- Builds via GitHub Actions CI (pas de toolchain local nécessaire).
- Flutter `3.38.x` / Dart `^3.10.0`.
- APK : arm64-v8a release.
- IPA : TrollStore (no codesign).

## Structure

- Code Flutter à la racine du repo (`lib/`, `android/`, `pubspec.yaml`).
- Pas de Rust, pas de Go — UI pure + client HTTP SDK Watchtower.

## User preferences

- Utilisateur francophone — strings UI en français.
- CI-first : push → Actions → télécharger l'APK/IPA.
