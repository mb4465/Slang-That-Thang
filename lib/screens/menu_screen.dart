import 'package:flutter/material.dart';
import 'package:test2/screens/HowToPlay.dart';
import 'AboutScreen.dart';
import 'game_button.dart';
import 'generational_card_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  static const buttonWidth = 250.0;
  static const buttonHeight = 60.0;
  static const skewAngle = 0.0;

  late AnimationController _controller;
  late List<Animation<Offset>> _buttonAnimations;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    // Total duration is 875ms: each button's flight lasts 500ms, with a 125ms delay for each subsequent button.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 875),
      vsync: this,
    );

    const int buttonAnimationDelay = 125; // ms delay between starts
    const int buttonAnimationDuration = 500; // ms for each button's flight

    // For each button, the start and end fractions are computed as follows:
    // start = (i * delay) / totalDuration
    // end = ((i * delay) + buttonAnimationDuration) / totalDuration
    _buttonAnimations = List.generate(4, (i) {
      double start = (i * buttonAnimationDelay) / 875;
      double end = ((i * buttonAnimationDelay) + buttonAnimationDuration) / 875;
      return Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(2.0, 0.0),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
  }

  void _animateButtonsAndNavigate(VoidCallback navigate) {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
    });
    _controller.forward().then((_) {
      navigate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedButton(String text, VoidCallback onPressed, int index) {
    return SlideTransition(
      position: _buttonAnimations[index],
      child: GameButton(
        text: text,
        width: buttonWidth,
        height: buttonHeight,
        skewAngle: skewAngle,
        onPressed: _isAnimating ? () {} : onPressed,
        isBold: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Center(
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
                  _buildAnimatedButton("How to Play", () {
                    _animateButtonsAndNavigate(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Howtoplay()),
                      ).then((_) {
                        _controller.reset();
                        setState(() {
                          _isAnimating = false;
                        });
                      });
                    });
                  }, 0),
                  const SizedBox(height: 16),
                  _buildAnimatedButton("Generational Card", () {
                    _animateButtonsAndNavigate(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GenerationalCardScreen()),
                      ).then((_) {
                        _controller.reset();
                        setState(() {
                          _isAnimating = false;
                        });
                      });
                    });
                  }, 1),
                  const SizedBox(height: 16),
                  _buildAnimatedButton("Settings", () {
                    _animateButtonsAndNavigate(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      ).then((_) {
                        _controller.reset();
                        setState(() {
                          _isAnimating = false;
                        });
                      });
                    });
                  }, 2),
                  const SizedBox(height: 16),
                  _buildAnimatedButton("About", () {
                    _animateButtonsAndNavigate(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutScreen()),
                      ).then((_) {
                        _controller.reset();
                        setState(() {
                          _isAnimating = false;
                        });
                      });
                    });
                  }, 3),
                ],
              ),
            ),
          ),
          // Back arrow button remains outside the animation.
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
