import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // For sound
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg
import 'dart:math'; // For max function
import '../data/globals.dart'; // Adjust path as per your project structure, for getSoundEnabled

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Removed _version and _appName as they are now assumed to be part of the SVG
  // Removed _initPackageInfo as package_info_plus is no longer needed for display

  Future<void> _playUiClickSound() async {
    bool soundEnabled = true;
    try {
      soundEnabled = await getSoundEnabled();
    } catch (e) {
      debugPrint("Error getting sound preference: $e. Sound will be played by default.");
    }

    if (soundEnabled) {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/click.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Dynamic values for back button (consistent with original AboutScreen logic)
    final double backButtonTopPadding = screenHeight * 0.05;
    final double backButtonLeftPadding = screenWidth * 0.05;
    final double backIconSize = screenWidth * 0.075;
    final double backButtonTouchPadding = screenWidth * 0.03;

    // Title properties - matching MenuScreen and original AboutScreen logic
    final double titleFontSize = max(22.0, screenWidth * 0.085);
    final double titleTopPosition = MediaQuery.of(context).padding.top + screenHeight * 0.02;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content Image: about.svg, filling the screen similar to GenerationalCardScreen
          Center(
            child: SvgPicture.asset(
              'assets/images/about.svg', // Your about.svg image
              fit: BoxFit.contain, // Scales the image to fit the screen, preserving aspect ratio
            ),
          ),
          // Positioned "About" Title - replicating MenuScreen's title
          // Positioned(
          //   top: titleTopPosition,
          //   left: 0,
          //   right: 0,
          //   child: SafeArea(
          //     child: Center(
          //       child: Text(
          //         "About",
          //         style: TextStyle(
          //           fontSize: titleFontSize,
          //           fontWeight: FontWeight.bold,
          //           color: Colors.black, // Ensure text is visible on your SVG background
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          // Dynamic Back Button (positioning logic kept from original AboutScreen)
          Positioned(
            top: backButtonTopPadding,
            left: backButtonLeftPadding,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: backIconSize), // Ensure icon is visible
                  padding: EdgeInsets.all(backButtonTouchPadding),
                  splashRadius: backIconSize,
                  tooltip: 'Back',
                  onPressed: () async {
                    await _playUiClickSound();
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ),
          // Slang Icon (positioned at bottom-left, consistent with other screens)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(20.0), // 20px from left and bottom
              child: SvgPicture.asset(
                'assets/images/slang-icons.svg',
                height: screenHeight * 0.08, // 8% of screen height
                width: screenHeight * 0.08,  // 8% of screen height to keep it square
                colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn), // Ensure it's black
              ),
            ),
          ),
        ],
      ),
    );
  }
}