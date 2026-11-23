
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Backend host depends on the runtime platform.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator access to the host computer.
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';

  static const String assets = '/api/assets/';
}
