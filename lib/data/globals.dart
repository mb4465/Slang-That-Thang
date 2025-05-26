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

// General App Preferences
const String _kSoundEnabledKey = 'sound_enabled';
const String _kAdsRemovedKey = 'ads_removed';

// Home Screen Tutorial Keys (Image-based steps)
const String prefHasSeenWelcomeTutorial = 'hasSeenWelcomeTutorialHomeScreen';
const String prefHasSeenBasicsTutorial = 'hasSeenBasicsTutorialHomeScreen';
const String prefHasSeenHowToPlayTutorial = 'hasSeenHowToPlayTutorialHomeScreen';

// Home Screen Tutorial Keys (Button highlight steps)
const String prefHasSeenStartGameButtonTutorial = 'hasSeenStartGameButtonTutorialHomeScreen';
const String prefHasSeenMenuButtonTutorial = 'hasSeenMenuButtonTutorialHomeScreen';

// Menu Screen Tutorial Key
const String prefHasSeenMenuScreenTutorial = 'hasSeenMenuScreenTutorial';

// Optional: Card Flip Tutorial Key (if used globally)
const String prefAppHasSeenFirstFlip = 'appHasSeenFirstFlip';

const String prefHasSeenCardFrontTermTutorial = 'hasSeenCardFrontTermTutorial';
const String prefHasSeenCardFrontGenerationTutorial = 'hasSeenCardFrontGenerationTutorial';
const String prefHasSeenCardFrontTapToFlipTutorial = 'hasSeenCardFrontTapToFlipTutorial';
const String prefHasSeenCardBackNextButtonTutorial = 'hasSeenCardBackNextButtonTutorial';


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

// Welcome Tutorial (Image-based)
Future<bool> getHasSeenWelcomeTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenWelcomeTutorial) ?? false;
}
Future<void> setHasSeenWelcomeTutorial(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenWelcomeTutorial, value);
}

// Basics/Objectives Tutorial (Image-based)
Future<bool> getHasSeenBasicsTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenBasicsTutorial) ?? false;
}
Future<void> setHasSeenBasicsTutorial(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenBasicsTutorial, value);
}

// How To Play Tutorial (Image-based)
Future<bool> getHasSeenHowToPlayTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenHowToPlayTutorial) ?? false;
}
Future<void> setHasSeenHowToPlayTutorial(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenHowToPlayTutorial, value);
}

// Start Game Button Tutorial (Button highlight)
Future<bool> getHasSeenStartGameButtonTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenStartGameButtonTutorial) ?? false;
}
Future<void> setHasSeenStartGameButtonTutorial(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenStartGameButtonTutorial, value);
}

// Menu Button Tutorial (Button highlight - replaces old "Menu Hint")
Future<bool> getHasSeenMenuButtonTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenMenuButtonTutorial) ?? false;
}
Future<void> setHasSeenMenuButtonTutorial(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenMenuButtonTutorial, value);
}

// --- Menu Screen Tutorial Preference ---
Future<bool> getHasSeenMenuScreenTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenMenuScreenTutorial) ?? false;
}

Future<void> setHasSeenMenuScreenTutorial(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenMenuScreenTutorial, value);
}


// --- Optional: Card Flip Tutorial Preference (Global) ---
// If you still use this, keep it. Otherwise, you can remove it.

Future<bool> getAppHasSeenFirstFlip() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefAppHasSeenFirstFlip) ?? false;
}

Future<void> setAppHasSeenFirstFlip(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefAppHasSeenFirstFlip, value);
}

// Card Front - Term Hint
Future<bool> getHasSeenCardFrontTermTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenCardFrontTermTutorial) ?? false;
}
Future<void> setHasSeenCardFrontTermTutorial(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenCardFrontTermTutorial, value);
}

// Card Front - Generation Icon Hint
Future<bool> getHasSeenCardFrontGenerationTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenCardFrontGenerationTutorial) ?? false;
}
Future<void> setHasSeenCardFrontGenerationTutorial(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenCardFrontGenerationTutorial, value);
}

// Card Front - Tap to Flip Hint
Future<bool> getHasSeenCardFrontTapToFlipTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenCardFrontTapToFlipTutorial) ?? false;
}
Future<void> setHasSeenCardFrontTapToFlipTutorial(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenCardFrontTapToFlipTutorial, value);
}

// Card Back - Next Button Hint
Future<bool> getHasSeenCardBackNextButtonTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenCardBackNextButtonTutorial) ?? false;
}
Future<void> setHasSeenCardBackNextButtonTutorial(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenCardBackNextButtonTutorial, value);
}


// --- REMOVED OLD/REPLACED Home Screen Tutorial Keys/Functions ---
// const String prefHasSeenGenerationsTutorial = 'hasSeenGenerationsTutorialHomeScreen'; // Replaced by more granular steps or deemed obsolete
// const String prefHasSeenMenuHint = 'hasSeenMenuHintHomeScreen'; // Functionality replaced by prefHasSeenMenuButtonTutorial

/* // Old functions - remove if not used elsewhere or if functionality is fully replaced
Future<bool> getHasSeenGenerationsTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenGenerationsTutorial) ?? false;
}
Future<void> setHasSeenGenerationsTutorial(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenGenerationsTutorial, value);
}

Future<bool> getHasSeenMenuHint() async { // This was for the old menu hint
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(prefHasSeenMenuHint) ?? false;
}
Future<void> setHasSeenMenuHint(bool value) async { // This was for the old menu hint
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(prefHasSeenMenuHint, value);
}
*/