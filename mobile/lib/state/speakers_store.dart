import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/speaker.dart';
import '../services/discovery_service.dart';

class SpeakersStore extends ChangeNotifier {
  static const _prefsKey = 'opensoundtouch.speakers';

  final DiscoveryService _discovery = DiscoveryService();
  final List<Speaker> _speakers = <Speaker>[];
  bool _discovering = false;

  List<Speaker> get speakers => List.unmodifiable(_speakers);
  bool get isDiscovering => _discovering;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final List<dynamic> parsed = json.decode(raw) as List<dynamic>;
    _speakers
      ..clear()
      ..addAll(parsed.map((e) => Speaker.fromJson(e as Map<String, dynamic>)));
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(_speakers.map((s) => s.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  Future<void> addManual(Speaker speaker) async {
    if (!_speakers.contains(speaker)) {
      _speakers.add(speaker);
      await _persist();
      notifyListeners();
    }
  }

  Future<void> remove(Speaker speaker) async {
    _speakers.remove(speaker);
    await _persist();
    notifyListeners();
  }

  Future<void> discover() async {
    if (_discovering) return;
    _discovering = true;
    notifyListeners();
    try {
      final found = await _discovery.discover();
      for (final s in found) {
        if (!_speakers.contains(s)) {
          _speakers.add(s);
        }
      }
      await _persist();
    } finally {
      _discovering = false;
      notifyListeners();
    }
  }
}
