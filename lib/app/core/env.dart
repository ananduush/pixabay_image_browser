/// Compile-time environment configuration.
///
/// The Pixabay API key is injected at build time and is never committed:
/// `flutter run --dart-define-from-file=env.json`
abstract final class Env {
  static const String pixabayApiKey = String.fromEnvironment('PIXABAY_API_KEY');
}
