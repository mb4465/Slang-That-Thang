import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
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
    with TickerProviderStateMixin {
  static const buttonWidth = 250.0;
  static const buttonHeight = 50.0;
  static const skewAngle = 0.15;

  late AnimationController _screenController;
  late AnimationController _buttonController;
  late List<Animation<Offset>> _buttonAnimations;
  bool _isAnimating = false;

  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderAnimation; // Border thickness animation


  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
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
      begin: 0.4, // Start at small size
      end: 1.0, // End at normal size
    ).animate(CurvedAnimation(
      parent: _screenController,
      curve: Curves.easeIn, // Smooth arrival effect
    ));

    _borderAnimation = Tween<double>(
      begin: 8.0, // Start with a thick border
      end: 3.0, // Shrink to a subtle border
    ).animate(CurvedAnimation(
      parent: _screenController,
      curve: Curves.easeOut, // Smooth transition for a natural feel
    ));

    _screenController.forward();
  }
  @override
  void dispose() {
    _screenController.dispose();
    _buttonController.dispose();
    super.dispose();
  }
  void _animateButtonsAndNavigate(VoidCallback navigate) {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
    });
    _buttonController.forward().then((_) {
      navigate();
    });
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
        color: Colors.white, // Background (table color)
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
                          width: _borderAnimation.value, // Animated border thickness
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
                              _buttonController.reset();
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
