import 'dart:math'; // Still needed for min if you use it elsewhere, but not for padding here

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/globals.dart';

class GenerationalCardScreen extends StatelessWidget {
  const GenerationalCardScreen({super.key});

  Future<void> _playUiClickSound() async {
    if (await getSoundEnabled()) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource('audio/click.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Consistent padding and icon size values (like in Howtoplay)
    final double topSafeAreaPadding = MediaQuery.of(context).padding.top;
    final double consistentTopOffset = screenHeight * 0.02;
    final double consistentHorizontalPadding = screenWidth * 0.05;
    final double consistentIconSize = screenHeight * 0.05; // Match Howtoplay's iconSize

    // Back button specific touch padding (can remain if desired for larger touch target)
    final double backButtonTouchPadding = screenWidth * 0.03;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content Image - Remove outer Padding to match Howtoplay
          Center( // This will center the SvgPicture in the available space
            child: SvgPicture.asset(
              'assets/images/generations.svg',
              fit: BoxFit.contain,
              // If you still want some horizontal padding for the image but not top/bottom affecting centering:
              // You could wrap SvgPicture with a Padding(padding: EdgeInsets.symmetric(horizontal: consistentHorizontalPadding))
              // But for exact vertical centering match, no vertical padding here.
            ),
          ),

          // Back Button - Adjusted to match Howtoplay's positioning
          Positioned(
            top: topSafeAreaPadding + consistentTopOffset, // Accounts for status bar + small offset
            left: consistentHorizontalPadding,
            child: Material( // SafeArea removed from here, top positioning handles it
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black, size: consistentIconSize), // Use consistent icon size
                padding: EdgeInsets.all(backButtonTouchPadding),
                splashRadius: consistentIconSize, // Match splash to icon size
                tooltip: 'Back',
                onPressed: () async {
                  await _playUiClickSound();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}