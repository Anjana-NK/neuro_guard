import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AppConfig {
  static String getBaseUrl(BuildContext context) {
    if (!kIsWeb && Theme.of(context).platform == TargetPlatform.android) {
      return "http://10.0.2.2:5000";
    }
    return "http://localhost:5000";
  }
}
