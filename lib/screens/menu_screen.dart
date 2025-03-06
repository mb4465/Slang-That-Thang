import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'game_button.dart';
import 'generational_card_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const buttonWidth = 250.0;
  static const buttonHeight = 60.0; // Increased height
  static const skewAngle = 0.15;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        toolbarHeight: 0,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 70),
                const Text(
                  "Menu",
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 150),
                GameButton(
                  text: "How to Play",
                  width: buttonWidth,
                  height: buttonHeight,
                  skewAngle: skewAngle,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                  isBold: true,
                ),
                const SizedBox(height: 16),
                GameButton(
                  text: "Generational Card",
                  width: buttonWidth,
                  height: buttonHeight,
                  skewAngle: skewAngle,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GenerationalCardScreen()),
                    );
                  },
                  isBold: true,
                ),
                const SizedBox(height: 16),
                GameButton(
                  text: "About",
                  width: buttonWidth,
                  height: buttonHeight,
                  skewAngle: skewAngle,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                  isBold: true,
                ),
              ],
            ),
          ),
          // Back arrow button
          Positioned(
            top: 40,  // Matches the title's top padding
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}