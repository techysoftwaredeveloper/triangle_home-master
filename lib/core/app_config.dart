enum Environment { dev, staging, prod }

class AppConfig {
  static Environment environment = Environment.dev;

  static bool get isDev => environment == Environment.dev;
  static bool get isStaging => environment == Environment.staging;
  static bool get isProd => environment == Environment.prod;

  static String get apiBaseUrl {
    switch (environment) {
      case Environment.dev:
        // Use local IP to support both physical devices and emulators
        return 'http://192.168.31.25:5000';
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
