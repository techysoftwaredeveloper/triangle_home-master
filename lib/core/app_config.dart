enum Environment { dev, staging, prod }

class AppConfig {
  static Environment environment = Environment.dev;

  static bool get isDev => environment == Environment.dev;
  static bool get isStaging => environment == Environment.staging;
  static bool get isProd => environment == Environment.prod;

  static String get apiBaseUrl {
    // Check if we should override the environment (e.g., via a constant for quick testing)
    const bool useProdForDev = false; // Set to true to hit production even in debug mode

    switch (environment) {
      case Environment.dev:
        if (useProdForDev) return 'https://api.trianglehomes.com';
        // Use local IP to support both physical devices and emulators
        return 'http://192.168.31.25:5000';
      case Environment.staging:
        return 'https://staging.api.trianglehomes.com';
      case Environment.prod:
        return 'https://api.trianglehomes.com';
    }
  }

  static String get razorpayKey {
    if (isProd) return 'rzp_live_YourLiveKeyHere';
    return 'rzp_test_YourTestKeyHere';
  }

  static void initialize({required Environment env}) {
    environment = env;
  }
}
