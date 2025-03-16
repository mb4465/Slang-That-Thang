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
    'assets/images/about-1.svg',
    'assets/images/about-2.svg',
    'assets/images/about-3.svg',
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAndPlayClickSound() async {
    if (_isSoundPlaying) return; // Don't play if already playing
    _isSoundPlaying = true;
    bool shouldPlaySound = await getSoundEnabled();
    if (shouldPlaySound) {
      await _audioPlayer.stop(); // Stop any current playback
      await _audioPlayer.play(AssetSource('audio/rules.mp3'));
    }
    _audioPlayer.onPlayerComplete.listen((event) {
      // Reset _isSoundPlaying when sound finishes
      _isSoundPlaying = false;
    });

  }

  void _previousImage() async {
    await _loadAndPlayClickSound();
    setState(() {
      _currentImageIndex = (_currentImageIndex - 1) % _imagePaths.length;
      if (_currentImageIndex < 0) {
        _currentImageIndex = _imagePaths.length - 1;
      }
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
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Center(
              child: SvgPicture.asset(
                _imagePaths[_currentImageIndex],
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Navigation Buttons
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousImage,
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    size: 40,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: _nextImage,
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 40,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Back Button
          Positioned(
            top: 20, // Adjust top position as needed
            left: 20, // Adjust left position as needed
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context); // Navigate back
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}