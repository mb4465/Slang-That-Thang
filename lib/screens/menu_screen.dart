import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:test2/screens/HowToPlay.dart';
import 'AboutScreen.dart';
import 'game_button.dart';
import 'generational_card_screen.dart';
import 'settings_screen.dart';
import 'package:test2/data/globals.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  static const buttonWidth = 250.0;
  static const buttonHeight = 60.0;
  static const skewAngle = 0.0;
  static const double topPadding = 70.0;
  static const double titleBottomPadding = 150.0;
  static const double buttonVerticalPadding = 16.0;
  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 35,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  int? _selectedButtonIndex;
  final int _buttonCount = 4;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _opacityAnimations;
  static const double slideOffsetFactor = 1.5;
  bool isSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

// Check sound enabled state from your globals
    getSoundEnabled().then((value) {
      setState(() {
        isSoundEnabled = value;
      });
    });

    _slideAnimations = List.generate(_buttonCount, (index) {
      final start = index / _buttonCount;
      final end = (index + 1) / _buttonCount;
      return Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(slideOffsetFactor, 0.0),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });

    _opacityAnimations = List.generate(_buttonCount, (index) {
      final start = index / _buttonCount;
      final end = (index + 1) / _buttonCount;
      return Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeIn),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

// Create a new AudioPlayer instance each time to reliably play the click sound.
  Future<void> _loadAndPlayClickSound() async {
    final player = AudioPlayer();
// Optionally, set release mode to stop to ensure the sound doesn't loop.
    await player.setReleaseMode(ReleaseMode.stop);
    await player.play(AssetSource('audio/click.mp3'));
  }

  void _onButtonPressed(int index, Widget screen) async {
    if (_controller.isAnimating || _selectedButtonIndex != null) return;

    bool shouldPlaySound = await getSoundEnabled();
    if (shouldPlaySound) {
      _loadAndPlayClickSound();
    }

    setState(() => _selectedButtonIndex = index);
    _controller.forward().then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      ).then((_) {
        setState(() => _selectedButtonIndex = null);
        _controller.reset();
      });
    });
  }

  Widget _buildAnimatedButton(int index, String text, Widget screen) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isAnimating = _selectedButtonIndex != null;
        final slideOffset = _slideAnimations[index].value;
        final opacity = _opacityAnimations[index].value;

        return Transform.translate(
          offset: isAnimating
              ? Offset(slideOffset.dx * MediaQuery.of(context).size.width, 0)
              : Offset.zero,
          child: Opacity(
            opacity: isAnimating ? opacity : 1.0,
            child: GameButton(
              text: text,
              width: MenuScreen.buttonWidth,
              height: MenuScreen.buttonHeight,
              skewAngle: MenuScreen.skewAngle,
              onPressed: () => _onButtonPressed(index, screen),
              isBold: true,
            ),
          ),
        );
      },
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
                  const SizedBox(height: MenuScreen.topPadding),
                  const Text(
                    "Menu",
                    style: MenuScreen.titleTextStyle,
                  ),
                  const SizedBox(height: MenuScreen.titleBottomPadding),
                  _buildAnimatedButton(0, "How to Play", const Howtoplay()),
                  const SizedBox(height: MenuScreen.buttonVerticalPadding),
                  _buildAnimatedButton(1, "Generational Card", const GenerationalCardScreen()),
                  const SizedBox(height: MenuScreen.buttonVerticalPadding),
                  _buildAnimatedButton(2, "Settings", const SettingsScreen()),
                  const SizedBox(height: MenuScreen.buttonVerticalPadding),
                  _buildAnimatedButton(3, "About", const AboutScreen()),
                ],
              ),
            ),
          ),
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
