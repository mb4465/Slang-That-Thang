import 'package:flutter/material.dart';
import '../screens/AboutScreen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true; // Example setting

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: ListView(
        children: <Widget>[
          SwitchListTile(
            title: Text("Sound Effects"),
            value: _soundEnabled,
            onChanged: (bool value) {
              setState(() {
                _soundEnabled = value;
                // Logic to update sound settings goes here (e.g., save to shared preferences).
              });
            },
          ),
          ListTile(
            title: Text("About"),
            onTap: () {
              // Navigate to an "About" screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutScreen()), // Replace AboutScreen()
              );
            },
          ),
        ],
      ),
    );
  }
}