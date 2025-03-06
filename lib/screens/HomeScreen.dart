import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// Import for math functions
import '../screens/GenerationalCardScreen.dart';
import 'AboutScreen.dart';
import 'GameButton.dart';
import 'MenuScreen.dart';
import 'SettingsScreen.dart';
import 'level_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const buttonWidth = 250.0;
  static const buttonHeight = 50.0;
  static const skewAngle = 0.15; // Adjust for desired slant

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        toolbarHeight: 0,
      ),
      backgroundColor: Colors.white,
      body: Column(
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
                GameButton(
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
                GameButton(
                  text: "Menu",
                  width: buttonWidth,
                  height: buttonHeight,
                  skewAngle: skewAngle,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MenuScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                GameButton(
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
    );
  }
}

class ParallelogramButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final double skewAngle;

  const ParallelogramButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.width,
    required this.height,
    required this.skewAngle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.skewX(skewAngle),
      alignment: Alignment.center,
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          onPressed: onPressed,
          child: Transform(  // Counter-skew the text
            transform: Matrix4.skewX(-skewAngle),
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}