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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation; // New Scale Animation

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _positionAnimation = Tween<Offset>(
      begin: const Offset(0, 2),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    ));

    _rotationAnimation = Tween<double>(
      begin: 5 * pi,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.4, // Start at half size
      end: 1.0, // End at normal size
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn, // Slight overshoot for natural feel
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFB68D40), // Background (table color)
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: _positionAnimation.value * MediaQuery.of(context).size.height / 3,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Transform.scale( // Apply scaling
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black26, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container( // Keeps full-screen content inside
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
                          GameButton(
                            text: "Start Game",
                            width: 250,
                            height: 50,
                            skewAngle: 0.15,
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
                            width: 250,
                            height: 50,
                            skewAngle: 0.15,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MenuScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
