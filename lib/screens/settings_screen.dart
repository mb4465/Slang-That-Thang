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

  Future<void> _playAppBarBackClick() async {
    if (await getSoundEnabled()) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource('audio/click.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // --- Responsive Sizes ---
    // AppBar
    final double appBarTitleSize = (screenWidth * 0.055).clamp(18.0, 30.0); // Clamp for readability
    final double appBarIconSize = appBarTitleSize * 0.9; // Icon slightly smaller than title

    // SwitchListTile content (text, subtitle)
    final double settingTitleSize = (screenWidth * 0.045).clamp(16.0, 24.0);
    final double settingSubtitleSize = settingTitleSize * 0.8;

    // Spacing
    final double listVerticalPadding = screenHeight * 0.02;
    final double itemHorizontalPadding = screenWidth * 0.05; // Horizontal padding for list items
    final double itemVerticalSpacing = screenHeight * 0.01; // Vertical padding within/between items

    // --- Switch Scale ---
    final double switchScaleFactor = 1.2; // How much to scale the switch visually

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            fontSize: appBarTitleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: appBarIconSize),
          onPressed: () {
            _playAppBarBackClick();
            Navigator.of(context).pop();
          },
          tooltip: "Back", // Accessibility
        ),
        elevation: 1.0,
        toolbarHeight: appBarTitleSize * 2.5, // Adjust AppBar height based on title size
      ),
      body: _settingsLoaded
          ? ListView(
        padding: EdgeInsets.symmetric(vertical: listVerticalPadding),
        children: <Widget>[
          // --- Sound Setting ---
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
                          fontSize: settingTitleSize,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        _soundEnabled ? "Sound effects are ON" : "Sound effects are OFF",
                        style: TextStyle(
                          fontSize: settingSubtitleSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: switchScaleFactor,
                  alignment: Alignment.centerRight, // Align scaled switch to the right
                  child: Switch(
                    value: _soundEnabled,
                    onChanged: (bool value) {
                      if (!mounted) return;
                      setState(() {
                        _soundEnabled = value;
                      });
                      if (_soundEnabled) { // Play sound if toggled ON
                        final player = AudioPlayer();
                        player.setReleaseMode(ReleaseMode.stop);
                        player.play(AssetSource('audio/click.mp3'));
                      }
                      _saveSoundSetting(value);
                    },
                    activeColor: Colors.black,
                    activeTrackColor: Colors.grey.shade400,
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade200,
                    // MaterialTapTargetSize.shrinkWrap can reduce extra padding around the switch
                    // but scaling might make this less predictable. Test this.
                    // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          Divider(indent: itemHorizontalPadding, endIndent: itemHorizontalPadding),

          // Add more settings here using a similar Row structure or ListTile if scaling isn't needed for them
          // Example:
          // ListTile(
          //   contentPadding: EdgeInsets.symmetric(horizontal: itemHorizontalPadding, vertical: itemVerticalSpacing * 1.5),
          //   title: Text("About", style: TextStyle(fontSize: settingTitleSize)),
          //   trailing: Icon(Icons.arrow_forward_ios, size: settingTitleSize * 0.8, color: Colors.grey),
          //   onTap: () { /* Navigate to About Screen */ },
          // ),
        ],
      )
          : const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3.0,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
        ),
      ),
    );
  }
}