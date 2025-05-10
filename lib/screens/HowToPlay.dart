import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:test2/data/globals.dart';

class Howtoplay extends StatefulWidget {
  const Howtoplay({super.key});

  @override
  State<Howtoplay> createState() => _HowToPlayState();
}

class _HowToPlayState extends State<Howtoplay> {
  int _currentImageIndex = 0;
  final List<String> _imagePaths = [
    'assets/images/basics.svg',
    'assets/images/objective.svg',
    'assets/images/how-to-play.svg',
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
              child: SvgPicture.asset(
              // child: Image.asset(
                _imagePaths[_currentImageIndex],
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Navigation Buttons
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
