import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cities.dart';

/// The cities the user follows, in their order. The device's own time is
/// always shown first and isn't part of this list.
class WorldPrefs {
  static const key = 'world_cities';
  static const _defaults = [
    'America/New_York',
    'Europe/London',
    'Asia/Tokyo',
  ];

  static final cities = ValueNotifier<List<String>>(List.of(_defaults));

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(key);
    cities.value = stored == null
        ? List.of(_defaults)
        : stored.where((id) => cityById(id) != null).toList();
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, cities.value);
  }

  static Future<void> add(String tz) async {
    if (cities.value.contains(tz)) return;
    cities.value = [...cities.value, tz];
    await _save();
  }

  static Future<void> remove(String tz) async {
    cities.value = cities.value.where((c) => c != tz).toList();
    await _save();
  }

  static Future<void> reorder(int from, int to) async {
    final next = List.of(cities.value);
    next.insert(to, next.removeAt(from));
    cities.value = next;
    await _save();
  }
}
