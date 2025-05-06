import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game_button.dart';
import 'menu_screen.dart';
// import 'settings_screen.dart'; // Not directly used for navigation from home
import 'level_screen.dart';
// Corrected path assuming globals.dart is in 'project_root/lib/data/globals.dart'
// and home_screen.dart is in 'project_root/lib/screens/home_screen.dart' or similar.
// Adjust the path '..' as necessary based on your actual project structure.
import '../data/globals.dart'; // Or your correct path to globals.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _screenController;
  late AnimationController _buttonController;
  late List<Animation<Offset>> _buttonAnimations;
  bool _isAnimating = false;

  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderAnimation;
  late Animation<double> _shadowBlurAnimation;
  late Animation<double> _shadowSpreadAnimation;
  late Animation<Offset> _shadowOffsetAnimation;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 625),
      vsync: this,
    );

    _buttonAnimations = List.generate(2, (i) {
      double start = 0.0;
      double end = 0.5;
      if (i == 0) {
        start = i * 0.5;
        end = start + 0.5;
      } else {
        start = (i - 1) * 0.5 + 0.25;
        end = start + 0.5;
      }
      return Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(2.0, 0.0),
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

    // Border and Shadow animations initialized in didChangeDependencies
    _screenController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final smallestDimension = min(screenWidth, screenHeight);

    _borderAnimation = Tween<double>(
      begin: smallestDimension * 0.02,
      end: smallestDimension * 0.0075,
    ).animate(CurvedAnimation(
      parent: _screenController,
      curve: Curves.easeOut,
    ));

    _shadowBlurAnimation = Tween<double>(
      begin: smallestDimension * 0.05,
      end: smallestDimension * 0.0375,
    ).animate(CurvedAnimation(parent: _screenController, curve: Curves.easeOut));

    _shadowSpreadAnimation = Tween<double>(
      begin: smallestDimension * 0.02,
      end: smallestDimension * 0.0125,
    ).animate(CurvedAnimation(parent: _screenController, curve: Curves.easeOut));

    _shadowOffsetAnimation = Tween<Offset>(
      begin: Offset(0, smallestDimension * 0.035),
      end: Offset(0, smallestDimension * 0.025),
    ).animate(CurvedAnimation(parent: _screenController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _screenController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _animateButtonsAndNavigate(VoidCallback navigate) {
    if (_isAnimating) return;
    if (!mounted) return;
    setState(() {
      _isAnimating = true;
    });
    _buttonController.forward().then((_) {
      if (mounted) {
        navigate();
      }
    });
  }

  // Renamed to be more generic for UI clicks
  Future<void> _playUiClickSound() async {
    if (await getSoundEnabled()) { // Check global sound setting
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource('audio/click.mp3'));
      // No need to call player.dispose() for short one-off sounds with ReleaseMode.stop
    }
  }

  void _onHomeButtonPressed(VoidCallback navigate) async {
    await _playUiClickSound(); // Play sound first
    _animateButtonsAndNavigate(navigate); // Then animate and navigate
  }

  Widget _buildAnimatedButton(String text, VoidCallback onPressed, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const maxButtonWidth = 400.0;
    final buttonWidth = min(screenWidth * 0.7, maxButtonWidth);
    final buttonHeight = screenHeight * 0.075;
    final double fontSize = buttonHeight * 0.3;

    return SlideTransition(
      position: _buttonAnimations[index],
      child: GameButton(
        text: text,
        width: buttonWidth,
        height: buttonHeight,
        onPressed: _isAnimating ? null : onPressed,
        isBold: true,
        fontSize: fontSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final svgHeight = screenHeight * 0.50; // Adjusted from previous step
    final topSpacerHeight = screenHeight * 0.05;
    final midSpacerHeight = screenHeight * 0.10; // Adjusted from previous step
    final buttonSpacerHeight = screenHeight * 0.02;

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_screenController, _borderAnimation, _shadowBlurAnimation, _shadowSpreadAnimation, _shadowOffsetAnimation]),
            builder: (context, child) {
              return Transform.translate(
                offset: _positionAnimation.value * screenHeight / 3,
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
                            blurRadius: _shadowBlurAnimation.value,
                            spreadRadius: _shadowSpreadAnimation.value,
                            offset: _shadowOffsetAnimation.value,
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
                  SizedBox(height: topSpacerHeight),
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/main_icon_crop.svg',
                      height: svgHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: midSpacerHeight),
                  Center(
                    child: Column(
                      children: [
                        _buildAnimatedButton("Start Game", () {
                          _onHomeButtonPressed(() { // This now calls _playUiClickSound
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => LevelScreen()),
                              ).then((_) {
                                if (mounted) {
                                  _buttonController.reset();
                                  setState(() {
                                    _isAnimating = false;
                                  });
                                }
                              });
                            }
                          });
                        }, 0),
                        SizedBox(height: buttonSpacerHeight),
                        _buildAnimatedButton("Menu", () {
                          _onHomeButtonPressed(() { // This now calls _playUiClickSound
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MenuScreen()),
                              ).then((_) {
                                if (mounted) {
                                  _buttonController.reset();
                                  setState(() {
                                    _isAnimating = false;
                                  });
                                }
                              });
                            }
                          });
                        }, 1),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}