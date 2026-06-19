import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  static void _init() {
    if (_isInitialized) return;
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
    _isInitialized = true;
  }

  static Future<void> speak(String text, String language) async {
    _init();
    
    // Map language choices to standard locales
    String langCode = "en-US";
    if (language == "Malayalam") {
      langCode = "ml-IN";
    } else if (language == "Hindi") {
      langCode = "hi-IN";
    } else if (language == "Tamil") {
      langCode = "ta-IN";
    }
    
    try {
      await _flutterTts.setLanguage(langCode);
      await _flutterTts.speak(text);
    } catch (e) {
      print("TTS playback failure: $e");
    }
  }

  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print("TTS stop failure: $e");
    }
  }
}
