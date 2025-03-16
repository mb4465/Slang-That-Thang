import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = false;
  bool _settingsLoaded = false; // Track if settings have been loaded

  @override
  initState() {
    super.initState();
    _loadSoundSetting();
  }

  // Load sound setting from SharedPreferences
  Future<void> _loadSoundSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _settingsLoaded = true; // Indicate that settings have been loaded
    });
    await Future.delayed(const Duration(seconds: 2));
  }

  // Save sound setting to SharedPreferences
  Future<void> _saveSoundSetting(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: _settingsLoaded
          ? ListView(
        children: <Widget>[
          SwitchListTile(
            title: Text(
              "Sound",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18, // You can adjust the font size as needed
                color: Theme.of(context).textTheme.bodyLarge?.color, // Inherit text color or specify one
              ),
            ),
            value: _soundEnabled,
            onChanged: (bool value) {
              setState(() {
                _soundEnabled = value;
              });
              _saveSoundSetting(value);
            },
            activeColor: Colors.black,
            activeTrackColor: Colors.grey.shade300,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()), // Show loader while settings load
    );
  }
}