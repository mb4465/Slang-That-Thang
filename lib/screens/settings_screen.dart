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

  // Renamed for clarity as AppBar is removed, but functionality is the same
  Future<void> _playBackButtonClickSound() async {
    if (await getSoundEnabled()) {
      final player = AudioPlayer();
      // setReleaseMode is not strictly necessary for short one-off sounds with modern audioplayers
      // await player.setReleaseMode(ReleaseMode.stop); // Can be removed or set to ReleaseMode.release
      await player.play(AssetSource('audio/click.mp3'));
      // Consider player.dispose() if you create many players, or use a shared instance.
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // --- Dynamic sizes similar to AboutScreen ---
    // Back Button (copied from AboutScreen for consistency)
    final double backButtonTopPadding = screenHeight * 0.05;
    final double backButtonLeftPadding = screenWidth * 0.05;
    final double backIconSize = screenWidth * 0.075; // e.g., 30 on 400dp width
    final double backButtonTouchPadding = screenWidth * 0.03; // e.g., 12 on 400dp width

    // Content Padding (similar to AboutScreen)
    final double contentPadding = screenWidth * 0.06; // Approx 24 on 400dp width for all sides

    // "Settings" Title (similar to "About" title in AboutScreen)
    final double settingsTitleFontSize = screenWidth * 0.085; // Approx 34 on 400dp width

    // Spacing (similar to AboutScreen)
    final double spacingBeforeTitle = screenHeight * 0.09; // Equivalent to spacing1 in AboutScreen
    final double spacingAfterTitle = screenHeight * 0.03; // Similar to spacing4 or a bit less than spacing2

    // --- Sizes for ListView items (kept from original SettingsScreen, responsive) ---
    final double settingItemTitleSize = (screenWidth * 0.045).clamp(16.0, 24.0);
    final double settingItemSubtitleSize = settingItemTitleSize * 0.8;
    final double itemHorizontalPadding = screenWidth * 0.05; // Horizontal padding for list items (within the list boundaries)
    final double itemVerticalSpacing = screenHeight * 0.01; // Vertical padding within/between items

    // --- Switch Scale (kept from original SettingsScreen) ---
    final double switchScaleFactor = 1.2;

    return Scaffold(
      backgroundColor: Colors.white, // Consistent with AboutScreen
      body: Stack(
        children: [
          // Main content area (Title and ListView)
          Padding(
            padding: EdgeInsets.all(contentPadding), // Overall padding for the content block
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
                    color: Colors.black, // Consistent with AboutScreen title
                  ),
                ),
                SizedBox(height: spacingAfterTitle),
                Expanded(
                  child: _settingsLoaded
                      ? ListView(
                    // Removed ListView's own vertical padding, now handled by outer Padding and SizedBoxes
                    // padding: EdgeInsets.symmetric(vertical: listVerticalPadding),
                    children: <Widget>[
                      // --- Sound Setting ---
                      Padding(
                        // This padding is for the content *inside* the list item row
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
                                      color: Colors.black, // Ensure text color
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
                                onChanged: (bool value) {
                                  if (!mounted) return;
                                  setState(() {
                                    _soundEnabled = value;
                                  });
                                  if (_soundEnabled) {
                                    final player = AudioPlayer();
                                    // player.setReleaseMode(ReleaseMode.stop); // Optional
                                    player.play(AssetSource('audio/click.mp3'));
                                  }
                                  _saveSoundSetting(value);
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
                        indent: itemHorizontalPadding, // Indent based on item's internal horizontal padding
                        endIndent: itemHorizontalPadding,
                        color: Colors.grey[300], // Softer divider color
                      ),
                      // Add more settings here if needed
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
          // Dynamic Back Button (copied from AboutScreen for consistency)
          Positioned(
            top: backButtonTopPadding,
            left: backButtonLeftPadding,
            child: SafeArea( // Ensures button is not obscured by notches/system UI
              child: Material(
                color: Colors.transparent, // For correct splash effect
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: backIconSize),
                  padding: EdgeInsets.all(backButtonTouchPadding), // Larger touch target
                  splashRadius: backIconSize, // Splash radius related to icon size
                  tooltip: 'Back',
                  onPressed: () async {
                    await _playBackButtonClickSound(); // Use the renamed sound function
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