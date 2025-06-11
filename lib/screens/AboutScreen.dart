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
              'assets/images/about-without-logo.svg', // Your about.svg image
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
                'assets/images/slang-icon.svg', // <-- Changed from 'slang-icons.svg' to 'slang-icon.svg'
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

// GenerationalCardScreen (remains unchanged, provided for context)
/*
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
              'assets/images/generations-without-icon.svg',
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

          // Slang Icon (positioned at bottom-left, consistent with other screens)
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
*/