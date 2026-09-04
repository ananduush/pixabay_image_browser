/// Compile-time environment configuration.
///
/// Every value is injected at build time and never committed:
/// `flutter run --dart-define=PIXABAY_API_KEY=YOUR_KEY ...`
/// or `flutter run --dart-define-from-file=env.json` (keys listed in
/// `env.example.json`).
abstract final class Env {
  static const String pixabayApiKey = String.fromEnvironment('PIXABAY_API_KEY');

  /// Supabase project URL, `https://<ref>.supabase.co`.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase *publishable* key (`sb_publishable_…`) — the only Supabase key
  /// the app may ever hold. Never a service-role or secret key.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
}
