import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game_button.dart';
import 'menu_screen.dart';
import 'settings_screen.dart';
import 'level_screen.dart';
import 'package:test2/data/globals.dart'; // Assumes getSoundEnabled() is defined here

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const buttonWidthFactor = 0.7;   // 70% of screen width
  static const buttonHeightFactor = 0.08; // 8% of screen height
  static const skewAngle = 0.15;

  late AnimationController _screenController;
  late AnimationController _buttonController;
  late List<Animation<Offset>> _buttonAnimations;
  bool _isAnimating = false;

  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderAnimation; // Animated border thickness

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 625),
      vsync: this,
    );

    // Create 2 staggered animations for the buttons.
    _buttonAnimations = List.generate(2, (i) {
      double start = 0.0;
      double end = 0.5;
      if (i == 0) {
        start = i * 0.5;
        end = start + 0.5;
      } else {
        // Overlap the second button's animation halfway through the first.
        start = (i - 1) * 0.5 + 0.25;
        end = start + 0.5;
      }
      return Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(2.0, 0.0), // Adjust as needed.
      ).animate(
        CurvedAnimation(
          parent: _buttonController,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });

    _screenController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _positionAnimation = Tween<Offset>(
      begin: const Offset(0, 2),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _screenController,
      curve: Curves.decelerate,
    ));

    _rotationAnimation = Tween<double>(
      begin: 5 * pi,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _screenController,
      curve: Curves.decelerate,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _screenController,
      curve: Curves.easeIn,
    ));

    _borderAnimation = Tween<double>(
      begin: 8.0,
      end: 3.0,
    ).animate(CurvedAnimation(
      parent: _screenController,
      curve: Curves.easeOut,
    ));

    _screenController.forward();
  }

  @override
  void dispose() {
    _screenController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  // Animate buttons and then navigate.
  void _animateButtonsAndNavigate(VoidCallback navigate) {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
    });
    _buttonController.forward().then((_) {
      navigate();
    });
  }

  // Create a new AudioPlayer instance each time to reliably play the click sound.
  Future<void> _loadAndPlayClickSound() async {
    final player = AudioPlayer();
    // Set release mode to stop to avoid looping.
    await player.setReleaseMode(ReleaseMode.stop);
    await player.play(AssetSource('audio/click.mp3'));
  }

  // Check if sound is enabled; if so, play the click sound, then animate and navigate.
  void _onHomeButtonPressed(VoidCallback navigate) async {
    bool shouldPlaySound = await getSoundEnabled();
    if (shouldPlaySound) {
      await _loadAndPlayClickSound();
    }
    _animateButtonsAndNavigate(navigate);
  }

  Widget _buildAnimatedButton(String text, VoidCallback onPressed, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    const maxButtonWidth = 400.0;
    const heightFactor = 0.075;

    final buttonWidth = min(screenWidth * 0.7, maxButtonWidth);
    final buttonHeight = MediaQuery.of(context).size.height * heightFactor;

    return SlideTransition(
      position: _buttonAnimations[index],
      child: GameButton(
        text: text,
        width: buttonWidth,
        height: buttonHeight,
        onPressed: _isAnimating ? null : onPressed,
        isBold: true,
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white, // Background color.
        child: Center(
          child: AnimatedBuilder(
            animation: _screenController,
            builder: (context, child) {
              return Transform.translate(
                offset: _positionAnimation.value * MediaQuery.of(context).size.height / 3,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(
                          color: Colors.black,
                          width: _borderAnimation.value,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // const SizedBox(height: 40),
                  // SizedBox(height: screenHeight * 0.05), // instead of 40
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/main_icon_crop.svg',
                      height: 400,
                      width: 400,
                    ),
                  ),
                  // const SizedBox(height: 100),
                  // SizedBox(height: screenHeight * 0.12), // instead of 100
                  SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                  Center(
                    child: Column(
                      children: [
                        _buildAnimatedButton("Start Game", () {
                          _onHomeButtonPressed(() {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LevelScreen()),
                            ).then((_) {
                              _buttonController.reset();
                              setState(() {
                                _isAnimating = false;
                              });
                            });
                          });
                        }, 0),
                        // const SizedBox(height: 16),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        _buildAnimatedButton("Menu", () {
                          _onHomeButtonPressed(() {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MenuScreen()),
                            ).then((_) {
                              _buttonController.reset();
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
          ),
        ),
      ),
    );
  }
}
