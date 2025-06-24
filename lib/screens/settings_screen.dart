import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/globals.dart'; // Adjust path as needed

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _settingsLoaded = false;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Shared AudioPlayer instance

  @override
  void initState() {
    super.initState();
    _loadSoundSetting();
  }

  Future<void> _loadSoundSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _settingsLoaded = true;
    });
  }

  Future<void> _saveSoundSetting(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
  }

  // Renamed from _playBackButtonClickSound
  Future<void> _playBackNavigationSound() async {
    if (await getSoundEnabled()) {
      await _audioPlayer.play(AssetSource('audio/rules.mp3')); // Path is correct
    }
  }

  // Renamed from _playUiClickSound
  Future<void> _playUiInteractionSound() async {
    if (await getSoundEnabled()) {
      await _audioPlayer.play(AssetSource('audio/click.mp3')); // Path is correct
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Dispose of the shared AudioPlayer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double backButtonTopPadding = screenHeight * 0.05;
    final double backButtonLeftPadding = screenWidth * 0.05;
    final double backIconSize = screenWidth * 0.075;
    final double backButtonTouchPadding = screenWidth * 0.03;
    final double contentPadding = screenWidth * 0.06;
    final double settingsTitleFontSize = screenWidth * 0.085;
    final double spacingBeforeTitle = screenHeight * 0.09;
    final double spacingAfterTitle = screenHeight * 0.03;
    final double settingItemTitleSize = (screenWidth * 0.045).clamp(16.0, 24.0);
    final double settingItemSubtitleSize = settingItemTitleSize * 0.8;
    final double itemHorizontalPadding = screenWidth * 0.05;
    final double itemVerticalSpacing = screenHeight * 0.01;
    final double switchScaleFactor = 1.2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(contentPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: spacingBeforeTitle),
                Text(
                  "Settings",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: settingsTitleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: spacingAfterTitle),
                Expanded(
                  child: _settingsLoaded
                      ? ListView(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: itemHorizontalPadding, vertical: itemVerticalSpacing),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Sound",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: settingItemTitleSize,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Text(
                                          _soundEnabled ? "Sound effects are ON" : "Sound effects are OFF",
                                          style: TextStyle(
                                            fontSize: settingItemSubtitleSize,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: switchScaleFactor,
                                    alignment: Alignment.centerRight,
                                    child: Switch(
                                      value: _soundEnabled,
                                      onChanged: (bool value) async {
                                        if (!mounted) return;
                                        setState(() {
                                          _soundEnabled = value;
                                        });
                                        if (_soundEnabled) {
                                          // Use renamed method
                                          await _playUiInteractionSound();
                                        }
                                        await _saveSoundSetting(value);
                                      },
                                      activeColor: Colors.black,
                                      activeTrackColor: Colors.grey.shade400,
                                      inactiveThumbColor: Colors.grey.shade400,
                                      inactiveTrackColor: Colors.grey.shade200,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              indent: itemHorizontalPadding,
                              endIndent: itemHorizontalPadding,
                              color: Colors.grey[300],
                            ),
                          ],
                        )
                      : Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            top: backButtonTopPadding,
            left: backButtonLeftPadding,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: backIconSize),
                  padding: EdgeInsets.all(backButtonTouchPadding),
                  splashRadius: backIconSize,
                  tooltip: 'Back',
                  onPressed: () async {
                    // Use renamed method
                    await _playBackNavigationSound();
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
