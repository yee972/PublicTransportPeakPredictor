class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'PASTE_YOUR_SUPABASE_URL_HERE',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE',
  );

  static const String openDataPortal = 'https://data.gov.my/';
  static const String ridershipDatasetUrl =
      'https://api.data.gov.my/data-catalogue?id=ridership_headline';
  static const String openStreetMapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String tileUserAgent = 'com.group3.peak_predictor';

  static const int forecastHorizonDays = 7;
  static const int trendWindowDays = 14;
  static const int baselineWeeks = 8;
  static const int validationHoldOutDays = 28;
  static const int minimumHistoryDays = 60;

  static bool get isConfigured =>
      !supabaseUrl.startsWith('PASTE_') && !supabaseAnonKey.startsWith('PASTE_');
}
