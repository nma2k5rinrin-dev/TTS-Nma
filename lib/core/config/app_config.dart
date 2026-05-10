class AppConfig {
  static const String appName = 'TTS Nma';
  static const String appVersion = '1.0.0';

  // Supabase - sẽ được cấu hình qua .env hoặc sadmin
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Default pricing (xu per unit) - sadmin có thể thay đổi
  static const int ttsBasicPricePer100Chars = 1;
  static const int ttsPremiumPricePer100Chars = 3;
  static const int voiceClonePrice = 5000;
  static const int voiceCloneUsagePer100Chars = 5;
  static const int sttPricePerMinute = 50;

  // Limits
  static const int maxTtsChars = 2500;
  static const int maxSttDurationMinutes = 30;
  static const int maxCloneSampleSeconds = 60;
}
