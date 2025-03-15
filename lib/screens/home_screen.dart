import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'game_button.dart';
import 'menu_screen.dart';
import 'settings_screen.dart';
import 'level_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const buttonWidth = 250.0;
  static const buttonHeight = 50.0;
  static const skewAngle = 0.15;

  late AnimationController _controller;
  late List<Animation<Offset>> _buttonAnimations;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    // Total duration covers all button animations.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 625), // adjust the duration according to number of button
      vsync: this,
    );

    // Create 2 staggered animations for the buttons.
    _buttonAnimations = List.generate(2, (i) {
      double start = 0.0;
      double end = 0.5;

      // for the first button, set the default value
      if (i == 0) {
        start = i * 0.5;
        end = start + 0.5;
      } else {
        // other than first button, overlap is needed
        start = (i - 1) * 0.5 + 0.25; // Start halfway through the previous button's animation
        end = start + 0.5;
      }
      return Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(2.0, 0.0), // Adjust the offset as needed
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
        // Disable button presses while animating
        onPressed: _isAnimating ? () {} : onPressed,
        isBold: true,
      ),
    );
  }

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
                'assets/images/main_icon_crop.svg',
                height: 400,
                width: 400,
              ),
            ),
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  _buildAnimatedButton("Start Game", () {
                    _animateButtonsAndNavigate(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LevelScreen()),
                      ).then((_) {
                        // Reset the animation when returning to the menu
                        _controller.reset();
                        setState(() {
                          _isAnimating = false;
                        });
                      });
                    });
                  }, 0),
                  const SizedBox(height: 16),
                  _buildAnimatedButton("Menu", () {
                    _animateButtonsAndNavigate(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MenuScreen()),
                      ).then((_) {
                        _controller.reset();
                        setState(() {
                          _isAnimating = false;
                        });
                      });
                    });
                  }, 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}