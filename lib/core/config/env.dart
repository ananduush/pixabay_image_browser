/// Compile-time environment configuration.
///
abstract final class Env {
  static const String pixabayApiKey = String.fromEnvironment('PIXABAY_API_KEY');

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
}
