class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  static AppConfig fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || key.isEmpty) {
      throw StateError(
        'Defina SUPABASE_URL e SUPABASE_ANON_KEY via --dart-define ou .vscode/launch.json',
      );
    }

    return AppConfig(supabaseUrl: url, supabaseAnonKey: key);
  }
}
