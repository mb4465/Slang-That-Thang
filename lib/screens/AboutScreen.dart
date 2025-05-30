import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Import package_info_plus
import 'package:audioplayers/audioplayers.dart'; // For sound
import 'dart:math'; // For max function
import '../data/globals.dart'; // Adjust path as per your project structure, for getSoundEnabled

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0'; // Default version
  String _appName = 'SLANG THAT THANG!!'; // App name as per original code

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) { // Check if the widget is still in the tree
      setState(() {
        _version = packageInfo.version;
        // _appName = packageInfo.appName; // Original code had this commented out
      });
    }
  }

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

    // Dynamic values for back button (consistent with GenerationalCardScreen logic, but positions may differ from MenuScreen)
    final double backButtonTopPadding = screenHeight * 0.05;
    final double backButtonLeftPadding = screenWidth * 0.05;
    final double backIconSize = screenWidth * 0.075;
    final double backButtonTouchPadding = screenWidth * 0.03;

    // Content padding for the main scrollable area
    final double contentHorizontalPadding = screenWidth * 0.06;

    // Title properties - matching MenuScreen
    final double titleFontSize = max(22.0, screenWidth * 0.085); // Matched MenuScreen
    final double titleTopPosition = MediaQuery.of(context).padding.top + screenHeight * 0.02; // Matched MenuScreen

    // Font sizes for other text elements
    final double appNameFontSize = screenWidth * 0.06;
    final double versionFontSize = screenWidth * 0.04;
    final double descriptionFontSize = screenWidth * 0.045;
    final double copyrightFontSize = screenWidth * 0.035;

    // Spacing for the content within the Column
    // This SizedBox pushes the content of the Column down to clear the absolutely positioned title.
    // It includes space for the title, its top offset, and padding below it.
    final double contentStartPaddingInColumn = titleTopPosition + titleFontSize + (screenHeight * 0.05); // Adjusted to match MenuScreen's content logic

    // Spacings for items within the column, after the initial padding
    final double spacingAfterAppName = screenHeight * 0.015; // Original spacing3
    final double spacingAfterVersion = screenHeight * 0.03;  // Original spacing4
    final double spacingAfterDescription = screenHeight * 0.04; // Original spacing5
    final double bottomContentPadding = screenHeight * 0.02; // Extra padding at the bottom

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content area
          Center( // Center the Padded SingleChildScrollView
            child: Padding(
              // Symmetrical horizontal padding for the content block
              padding: EdgeInsets.symmetric(horizontal: contentHorizontalPadding),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // This SizedBox pushes content down to account for the absolutely positioned title
                    SizedBox(height: contentStartPaddingInColumn),
                    // SizedBox(height: screenHeight * 0.06), // This was spacing2, now incorporated into contentStartPaddingInColumn logic
                    Text(
                      _appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: appNameFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: spacingAfterAppName),
                    Text(
                      'Version: $_version',
                      style: TextStyle(
                        fontSize: versionFontSize,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: spacingAfterVersion),
                    Text(
                      'SLANG THAT THANG!! is an educational and entertaining game designed to bridge the gap between generations by exploring the evolution of slang. Test your knowledge of slang terms from different eras and see how well you understand the language of each generation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: descriptionFontSize,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: spacingAfterDescription),
                    Text(
                      '© 2024 Callidora Global Media. All rights reserved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: copyrightFontSize,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: bottomContentPadding),
                  ],
                ),
              ),
            ),
          ),
          // Positioned "About" Title - replicating MenuScreen's title
          Positioned(
            top: titleTopPosition,
            left: 0,
            right: 0,
            child: SafeArea( // Using SafeArea as in MenuScreen title
              // top: false, bottom: false, // Potentially if titleTopPosition already fully accounts for safe area
              child: Center(
                child: Text(
                  "About",
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          // Dynamic Back Button (positioning logic kept from original AboutScreen, may differ from MenuScreen's back button)
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
        ],
      ),
    );
  }
}