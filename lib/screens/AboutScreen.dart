import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _currentImageIndex = 0;
  final List<String> _imagePaths = [
    'assets/images/about-1.svg',
    'assets/images/about-2.svg',
    'assets/images/about-3.svg',
  ];

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

          //Navigation Buttons
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
            child: SafeArea( //Added safe area
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black), // Style the button
                onPressed: () {
                  Navigator.pop(context);  // Navigate back
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousImage() {
    setState(() {
      _currentImageIndex = (_currentImageIndex - 1) % _imagePaths.length;
      if (_currentImageIndex < 0) {
        _currentImageIndex = _imagePaths.length - 1;
      }
    });
  }

  void _nextImage() {
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % _imagePaths.length;
    });
  }
}