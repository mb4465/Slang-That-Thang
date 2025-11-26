import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:slang_that_thang/data/globals.dart'; // Corrected path

// HomeScreen import is no longer needed here as the tutorial button is moved
// import 'home_screen.dart'; // This line is removed

class Howtoplay extends StatefulWidget {
  const Howtoplay({super.key});

  @override
  State<Howtoplay> createState() => _HowToPlayState();
}

class _HowToPlayState extends State<Howtoplay> {
  int _currentImageIndex = 0;
  final List<String> _imagePaths = [
    'assets/images/basics-objectives-without-logo.png',
    'assets/images/how-to-play-without-logo.png',
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
        // Resetting _isSoundPlaying sooner if play() errors or completes quickly.
        // The original 3-second delay might be too long if sound is shorter or fails.
        // A more robust approach might be to reset it in onPlayerComplete,
        // but for a simple click, this should be fine.
        // If sounds are very short, the delay might prevent rapid clicks.
        // For now, keeping it as is, but it's a point of potential refinement.
        Future.delayed(const Duration(milliseconds: 500), () { // Reduced delay
          if(mounted) { // Check if widget is still mounted
            _isSoundPlaying = false;
          }
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

  // --- The _startHomeTutorial method is REMOVED from here ---
  // --- The tutorialButtonStyle definition is REMOVED from here ---

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenHeight * 0.05; // ~40 on 800px height
    final padding = screenWidth * 0.05;   // ~20 on 400px width

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Center(
              child: Image.asset(
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

          // Back Button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + screenHeight * 0.02, // ~20
            left: padding,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black, size: iconSize),
              onPressed: () async {
                await _loadAndPlayClickSound();
                if (mounted) Navigator.pop(context);
              },
              tooltip: 'Go back',
            ),
          ),

          // --- The Tutorial Button (top-right corner) is REMOVED from here ---

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