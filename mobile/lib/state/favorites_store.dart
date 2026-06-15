import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radio_station.dart';

/// App-side preset/favorite stations, persisted locally per speaker.
///
/// The SoundTouch hardware presets (buttons 1-6) can no longer be programmed
/// since Bose shut down the cloud, so we keep our own 1-6 slot mapping here.
/// Slots are numbered 1..6 so they line up with the physical buttons for the
/// WebSocket button-listener.
class FavoritesStore extends ChangeNotifier {
  static const _prefsKey = 'opensoundtouch.favorites';
  static const int slotCount = 6;

  /// host -> (slot 1..6 -> station)
  final Map<String, Map<int, RadioStation>> _byHost = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final Map<String, dynamic> parsed = json.decode(raw) as Map<String, dynamic>;
    _byHost.clear();
    parsed.forEach((host, slots) {
      final map = <int, RadioStation>{};
      (slots as Map<String, dynamic>).forEach((slot, station) {
        final id = int.tryParse(slot);
        if (id != null) {
          map[id] = RadioStation.fromJson(station as Map<String, dynamic>);
        }
      });
      _byHost[host] = map;
    });
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final out = _byHost.map((host, slots) => MapEntry(
        host, slots.map((slot, s) => MapEntry('$slot', s.toJson()))));
    await prefs.setString(_prefsKey, json.encode(out));
  }

  /// Station assigned to [slot] (1..6) on [host], or null if empty.
  RadioStation? stationFor(String host, int slot) => _byHost[host]?[slot];

  Map<int, RadioStation> slotsFor(String host) =>
      Map.unmodifiable(_byHost[host] ?? const {});

  Future<void> assign(String host, int slot, RadioStation station) async {
    if (slot < 1 || slot > slotCount) {
      throw ArgumentError('Slot must be 1..$slotCount');
    }
    (_byHost[host] ??= {})[slot] = station;
    await _persist();
    notifyListeners();
  }

  Future<void> clear(String host, int slot) async {
    _byHost[host]?.remove(slot);
    await _persist();
    notifyListeners();
  }
}
