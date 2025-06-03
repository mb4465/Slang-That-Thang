import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:test2/data/globals.dart'; // Ensure this path is correct for globals.dart

import 'home_screen.dart'; // Import HomeScreen

class Howtoplay extends StatefulWidget {
  const Howtoplay({super.key});

  @override
  State<Howtoplay> createState() => _HowToPlayState();
}

class _HowToPlayState extends State<Howtoplay> {
  int _currentImageIndex = 0;
  final List<String> _imagePaths = [
    'assets/images/basics-objectives-without-logo.svg',
    'assets/images/how-to-play-without-logo.svg',
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.onPlayerComplete.listen((event) {
      _isSoundPlaying = false;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAndPlayClickSound() async {
    if (_isSoundPlaying) return;
    bool shouldPlaySound = await getSoundEnabled();

    if (shouldPlaySound) {
      _isSoundPlaying = true;
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource('audio/rules.mp3'));
      } finally {
        Future.delayed(const Duration(seconds: 3), () {
          _isSoundPlaying = false;
        });
      }
    }
  }

  void _previousImage() async {
    await _loadAndPlayClickSound();
    setState(() {
      _currentImageIndex = (_currentImageIndex - 1 + _imagePaths.length) % _imagePaths.length;
    });
  }

  void _nextImage() async {
    await _loadAndPlayClickSound();
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % _imagePaths.length;
    });
  }

  Future<void> _startHomeTutorial() async {
    // Reset all home screen tutorial preferences to false
    await setHasSeenWelcomeTutorial(false);
    await setHasSeenBasicsTutorial(false);
    await setHasSeenHowToPlayTutorial(false);
    await setHasSeenStartGameButtonTutorial(false);
    await setHasSeenMenuButtonTutorial(false);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenHeight * 0.05; // ~40 on 800px height
    final padding = screenWidth * 0.05;   // ~20 on 400px width

    // Define the style for the new tutorial button, mimicking HomeScreen's "Next" button
    final ButtonStyle tutorialButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015), // Adjusted padding for smaller button
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.black, width: 1.5),
      ),
      textStyle: TextStyle(fontSize: screenHeight * 0.02, fontWeight: FontWeight.bold), // Adjusted font size
      minimumSize: Size(screenWidth * 0.25, screenHeight * 0.05), // Ensure a minimum size
    );

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Center(
              child: SvgPicture.asset(
                _imagePaths[_currentImageIndex],
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Navigation Buttons (Previous/Next Image)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: padding),
                  child: IconButton(
                    onPressed: _previousImage,
                    icon: Icon(Icons.arrow_back_ios, size: iconSize, color: Colors.black),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: padding),
                  child: IconButton(
                    onPressed: _nextImage,
                    icon: Icon(Icons.arrow_forward_ios, size: iconSize, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),

          // Back Button (top-left) - RESTORED TO ORIGINAL POSITIONING
          Positioned(
            top: MediaQuery.of(context).padding.top + screenHeight * 0.02, // ~20
            left: padding,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black, size: iconSize),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Go back',
            ),
          ),

          // NEW: Tutorial Button (top-right corner)
          Positioned(
            top: MediaQuery.of(context).padding.top + screenHeight * 0.02,
            right: padding, // Anchored to the right
            child: ElevatedButton(
              style: tutorialButtonStyle,
              onPressed: _startHomeTutorial,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Tutorial"),
                  SizedBox(width: 8),
                  Icon(Icons.school, size: screenHeight * 0.025), // Using a 'school' icon for tutorial
                ],
              ),
            ),
          ),

          // Slang Icon (positioned at bottom-left)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(20.0), // 20px from left and bottom
              child: SvgPicture.asset(
                'assets/images/slang-icon.svg',
                height: MediaQuery.of(context).size.height * 0.08, // 8% of screen height
                width: MediaQuery.of(context).size.height * 0.08,  // 8% of screen height
                colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn), // Ensure it's black
              ),
            ),
          ),
        ],
      ),
    );
  }
}