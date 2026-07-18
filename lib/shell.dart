/// Entry point de l'UI Reel (TikTok-style feed).
///
/// Quand watchtower importe ce package via git dep, il instancie [ReelShell]
/// dans son switcher d'UI (`lib/ui/ui_shell.dart`).
///
/// ReelShell utilise les providers et la DB fournis par watchtower —
/// aucune duplication de cache, Isar, ou réseau.
library reel;

export 'features/feed/feed_screen.dart' show FeedScreen;
export 'app.dart' show ReelApp;
