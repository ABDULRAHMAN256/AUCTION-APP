import 'package:flutter/foundation.dart';

/// Where your FastAPI server lives.
/// - Chrome / iOS simulator: localhost
/// - Android emulator: 10.0.2.2 (the emulator's name for your PC)
/// - Real phone: use your PC's WiFi IP, e.g. 'http://192.168.1.5:3000'
String get baseUrl {
  if (kIsWeb) return 'http://localhost:3000';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}