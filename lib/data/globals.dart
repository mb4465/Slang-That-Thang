// Map of generation icons using the constants
import 'package:flutter/material.dart';
import 'package:test2/data/terms_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Map<String, IconData> generationIcons = {
  babyBoomers: Icons.history,
  genX: Icons.radio,
  millennials: Icons.wifi,
  genZ: Icons.smartphone,
};


Future<bool> getSoundEnabled() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('sound_enabled') ?? true;
}
