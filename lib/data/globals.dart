// Map of generation icons using the constants
import 'package:shared_preferences/shared_preferences.dart';

const String babyBoomers = "Baby Boomers (1946-1964)";
const String genX = "Generation X (1965-1980)";
const String millennials = "Millennials (1981-1996)";
const String silentGeneration = "Silent Generation (1928-1945)";
const String genAlpha = "Generation Alpha (2013-present)";
const String genZ = "Generation Z (1997-2012)";

final Map<String, String> generationIcons = {
  silentGeneration: 'assets/images/generations/mic.png', //micrphone
  babyBoomers: 'assets/images/generations/peace.png',//peace
  genX: 'assets/images/generations/cassette.png',//cassette icon needed here only in pro version
  millennials: 'assets/images/generations/mobile.png', //mobile
  genZ: 'assets/images/generations/selfieStick.png', // selfie stick needed here -> same prob as above
  genAlpha: 'assets/images/generations/vrHeadset.png', // vr headset icon needed here-> not availble in faicon
};


Future<bool> getSoundEnabled() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('sound_enabled') ?? true;
}
