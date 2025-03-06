// Map of generation icons using the constants
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:test2/data/terms_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String babyBoomers = "Baby Boomers (1946-1964)";
const String genX = "Generation X (1965-1980)";
const String millennials = "Millennials (1981-1996)";
const String silentGeneration = "Silent Generation (1928-1945)";
const String genAlpha = "Generation Alpha (2013-present)";
const String genZ = "Generation Z (1997-2012)";

final Map<String, IconData> generationIcons = {
  babyBoomers: FontAwesomeIcons.peace,
  genX: FontAwesomeIcons.moneyBill,//cassette icon needed here only in pro version
  millennials: FontAwesomeIcons.mobileScreenButton,
  silentGeneration: FontAwesomeIcons.microphoneLines,
  genAlpha: FontAwesomeIcons.solidMessage, // vr headset icon needed here-> not availble in faicon
  genZ: Icons.camera_alt, // selfie stick needed here -> same prob as above
};


Future<bool> getSoundEnabled() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('sound_enabled') ?? true;
}
