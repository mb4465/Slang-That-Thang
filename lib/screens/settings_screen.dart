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
    await Future.delayed(Duration(seconds: 2));

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
            title: const Text("Sound"),
            value: _soundEnabled,
            onChanged: (bool value) {
              setState(() {
                _soundEnabled = value;
              });
              _saveSoundSetting(value);
            },
            activeColor: Colors.black, // Set active color to white
            activeTrackColor: Colors.grey.shade300, // Set active track color (light grey for boundary effect)
            inactiveThumbColor: Colors.white, //Set inactive thumb color
            inactiveTrackColor: Colors.grey.shade300,

          ),
          // ListTile(
          //   title: const Text("About"),
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => AboutScreen()),
          //     );
          //   },
          // ),
        ],
      )
          : const Center(child: CircularProgressIndicator()), // Show loader while settings load
    );
  }
}