import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
// Adjust path as per your project structure
import '../data/globals.dart';

class GenerationalCardScreen extends StatelessWidget {
  const GenerationalCardScreen({super.key});

  // Consistent helper function name
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
    final double svgDimension = min(screenWidth * 0.90, screenHeight * 0.90); // As per previous adjustment
    final double backButtonTopPadding = screenHeight * 0.05;
    final double backButtonLeftPadding = screenWidth * 0.05;
    final double backIconSize = screenWidth * 0.075;
    final double backButtonTouchPadding = screenWidth * 0.03;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.all(min(screenWidth, screenHeight) * 0.05),
              child: SvgPicture.asset(
                'assets/images/generations.svg',
                width: svgDimension,
                height: svgDimension,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: backButtonTopPadding,
            left: backButtonLeftPadding,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: backIconSize),
                  padding: EdgeInsets.all(backButtonTouchPadding),
                  splashRadius: backIconSize,
                  tooltip: 'Back',
                  onPressed: () async { // Make async for sound
                    await _playUiClickSound();
                    // No need to check mounted here as this is a StatelessWidget's build method context
                    // and Navigator.pop itself handles context.
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}