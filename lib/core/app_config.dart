enum Environment { dev, staging, prod }

class AppConfig {
  static Environment environment = Environment.dev;

  static bool get isDev => environment == Environment.dev;
  static bool get isStaging => environment == Environment.staging;
  static bool get isProd => environment == Environment.prod;

  static String get apiBaseUrl {
    switch (environment) {
      case Environment.dev:
        // Use 10.0.2.2 for Android Emulator to connect to localhost
        return 'http://10.0.2.2:3000';
      case Environment.staging:
        return 'https://staging.api.trianglehomes.com';
      case Environment.prod:
        return 'https://api.trianglehomes.com';
    }
  }

  static void initialize({required Environment env}) {
    environment = env;
  }
}
