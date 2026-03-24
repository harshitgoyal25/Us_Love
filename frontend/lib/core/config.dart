import 'dart:io';
import 'package:flutter/foundation.dart';

/// ─────────────────────────────────────────────────────────────────────
/// SERVER CONFIGURATION
///
/// Set SERVER_HOST to your PC's local IP when running on a physical
/// Android device.  Leave it as 'localhost' for web / desktop.
///
/// How to find your PC's IP:  run  ipconfig  in PowerShell, look for
/// "IPv4 Address" under your Wi-Fi adapter (e.g. 192.168.0.102).
///
/// Make sure your phone and PC are on the same Wi-Fi network.
/// ─────────────────────────────────────────────────────────────────────
const String _serverHost = String.fromEnvironment(
  'SERVER_HOST',
  defaultValue: 'localhost',
);

const bool _useHttps = bool.fromEnvironment(
  'USE_HTTPS',
  defaultValue: false,
);

class AppConfig {
  AppConfig._();

  static String get host {
    // --dart-define=SERVER_HOST=<ip>  takes priority over everything
    if (_serverHost != 'localhost') return _serverHost;
    if (kIsWeb) return 'localhost';
    if (!kIsWeb && Platform.isAndroid) {
      // On physical device without a dart-define, point to loopback
      // (will timeout — remind developer to set SERVER_HOST).
      debugPrint(
        '⚠️  Running on Android without SERVER_HOST set.\n'
        '   Run with:  flutter run --dart-define=SERVER_HOST=<your-PC-LAN-IP>',
      );
    }
    return 'localhost';
  }

  static String get httpBase {
    if (_useHttps) return 'https://$host';
    return 'http://$host:8080';
  }

  static String get wsBase {
    if (_useHttps) return 'wss://$host';
    return 'ws://$host:8080';
  }
}
