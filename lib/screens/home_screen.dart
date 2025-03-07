import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// Import for math functions
import 'game_button.dart';
import 'menu_screen.dart';
import 'settings_screen.dart';
import 'level_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const buttonWidth = 250.0;
  static const buttonHeight = 50.0;
  static const skewAngle = 0.15; // Keep skewAngle for potential future use

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 40),
            Center(
              child: SvgPicture.asset(
                'assets/images/slang-icon.svg',
                height: 280,
                width: 280,
              ),
            ),
            const SizedBox(height: 88),
            Center(
              child: Column(
                children: [
                  GameButton( // Using GameButton
                    text: "Start Game",
                    width: buttonWidth,
                    height: buttonHeight,
                    skewAngle: skewAngle,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LevelScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  GameButton( // Using GameButton
                    text: "Menu",
                    width: buttonWidth,
                    height: buttonHeight,
                    skewAngle: skewAngle,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MenuScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  GameButton( // Using GameButton
                    text: "Settings",
                    width: buttonWidth,
                    height: buttonHeight,
                    skewAngle: skewAngle,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}