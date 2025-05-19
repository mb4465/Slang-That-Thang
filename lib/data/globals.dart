import 'package:shared_preferences/shared_preferences.dart';

// Generation Constants
const String babyBoomers = "Baby Boomers (1946-1964)";
const String genX = "Generation X (1965-1980)";
const String millennials = "Millennials (1981-1996)";
const String silentGeneration = "Silent Generation (1928-1945)";
const String genAlpha = "Generation Alpha (2013-present)";
const String genZ = "Generation Z (1997-2012)";

// Map of generation icons using the constants
final Map<String, String> generationIcons = {
  silentGeneration: 'assets/images/generations/mic.png',
  babyBoomers: 'assets/images/generations/peace.png',
  genX: 'assets/images/generations/cassette.png',
  millennials: 'assets/images/generations/mobile.png',
  genZ: 'assets/images/generations/selfieStick.png',
  genAlpha: 'assets/images/generations/vrHeadset.png',
};

// --- SharedPreferences Keys ---
const String _kSoundEnabledKey = 'sound_enabled';
const String _kAdsRemovedKey = 'ads_removed';

// Keys for Home Screen Tutorial
const String prefHasSeenGenerationsTutorial = 'hasSeenGenerationsTutorialHomeScreen';
const String prefHasSeenMenuHint = 'hasSeenMenuHintHomeScreen';
// Key for Card Flip Tutorial (from previous step, if you want to keep it global)
const String prefAppHasSeenFirstFlip = 'appHasSeenFirstFlip';


// --- Sound Preferences ---
/// Returns whether sound is enabled (defaults to true).
Future<bool> getSoundEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kSoundEnabledKey) ?? true;
}

/// Persist sound enabled/disabled state.
Future<void> setSoundEnabled(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kSoundEnabledKey, enabled);
}

// --- Ads Preferences ---
/// Returns whether ads have been removed (i.e. user purchased "Remove Ads").
Future<bool> getAdsRemovedStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kAdsRemovedKey) ?? false;
}

/// Persist the "ads removed" purchase state.
Future<void> setAdsRemoved(bool removed) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kAdsRemovedKey, removed);
}

// --- Home Screen Tutorial Preferences ---
/// Returns whether the user has seen the generations tutorial on the Home Screen.
Future<bool> getHasSeenGenerationsTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenGenerationsTutorial) ?? false;
}

/// Persist that the user has seen the generations tutorial on the Home Screen.
Future<void> setHasSeenGenerationsTutorial(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenGenerationsTutorial, value);
}

/// Returns whether the user has seen the menu hint on the Home Screen.
Future<bool> getHasSeenMenuHint() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenMenuHint) ?? false;
}

/// Persist that the user has seen the menu hint on the Home Screen.
Future<void> setHasSeenMenuHint(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenMenuHint, value);
}

// --- Card Flip Tutorial Preference (Global) ---
/// Returns whether the user has flipped any card at least once in the app.
Future<bool> getAppHasSeenFirstFlip() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefAppHasSeenFirstFlip) ?? false;
}

/// Persist that the user has flipped a card for the first time in the app.
Future<void> setAppHasSeenFirstFlip(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefAppHasSeenFirstFlip, value);
}