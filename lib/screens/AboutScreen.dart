import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Import package_info_plus
import 'package:audioplayers/audioplayers.dart'; // For sound
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

  // Consistent helper function name (from GenerationalCardScreen)
  Future<void> _playUiClickSound() async {
    // Assuming getSoundEnabled is available from globals.dart
    // You might need to adjust this part based on your actual sound settings logic
    bool soundEnabled = true; // Default to true or handle error if getSoundEnabled is not found
    try {
      soundEnabled = await getSoundEnabled();
    } catch (e) {
      // Handle cases where getSoundEnabled might not be available or throws an error
      // For example, if globals.dart or the function is not correctly set up
      debugPrint("Error getting sound preference: $e. Sound will be played by default.");
    }

    if (soundEnabled) {
      final player = AudioPlayer();
      // According to new audioplayers versions, setReleaseMode(ReleaseMode.stop) is often not needed
      // if you are playing a short sound and not looping.
      // player.setReleaseMode(ReleaseMode.stop); // This can be ReleaseMode.release
      await player.play(AssetSource('audio/click.mp3'));
      // It's good practice to release the player after use for short sounds if you create it each time
      // However, if you play many sounds, consider a shared player instance.
      // For simplicity and consistency with the example, we'll keep it like this.
      // await player.dispose(); // Or use ReleaseMode.release
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Dynamic values for back button (consistent with GenerationalCardScreen)
    final double backButtonTopPadding = screenHeight * 0.05;
    final double backButtonLeftPadding = screenWidth * 0.05;
    final double backIconSize = screenWidth * 0.075; // e.g., 30 on 400dp width
    final double backButtonTouchPadding = screenWidth * 0.03; // e.g., 12 on 400dp width

    // Dynamic values for content
    final double contentPadding = screenWidth * 0.06; // Approx 24 on 400dp width

    final double titleFontSize = screenWidth * 0.085; // Approx 34 on 400dp width (Original: 35)
    final double appNameFontSize = screenWidth * 0.06;  // Approx 24 on 400dp width (Original: 24)
    final double versionFontSize = screenWidth * 0.04;  // Approx 16 on 400dp width (Original: 16)
    final double descriptionFontSize = screenWidth * 0.045; // Approx 18 on 400dp width (Original: 18)
    final double copyrightFontSize = screenWidth * 0.035; // Approx 14 on 400dp width (Original: 14)

    // Dynamic SizedBox heights (already percentage-based in original, keeping them)
    final double spacing1 = screenHeight * 0.09; // Original: ~70
    final double spacing2 = screenHeight * 0.06; // Original: ~50
    final double spacing3 = screenHeight * 0.015; // Original: ~12
    final double spacing4 = screenHeight * 0.03; // Original: ~24
    final double spacing5 = screenHeight * 0.04; // Original: ~32

    return Scaffold(
      backgroundColor: Colors.white, // Explicitly set background color for the Scaffold
      body: Stack(
        children: [
          // Main content area
          Container(
            color: Colors.white, // Ensure background for the Center content
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(contentPadding),
                child: SingleChildScrollView( // Added for very small screens or large text
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, // Align to top
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: spacing1),
                      Text(
                        "About",
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: spacing2),
                      Text(
                        _appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: appNameFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: spacing3),
                      Text(
                        'Version: $_version',
                        style: TextStyle(
                          fontSize: versionFontSize,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: spacing4),
                      Text(
                        'SLANG THAT THANG!! is an educational and entertaining game designed to bridge the gap between generations by exploring the evolution of slang. Test your knowledge of slang terms from different eras and see how well you understand the language of each generation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: descriptionFontSize,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: spacing5),
                      Text(
                        '© 2024 Callidora Global Media. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: copyrightFontSize,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02), // Extra padding at the bottom if needed
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Dynamic Back Button (consistent with GenerationalCardScreen)
          Positioned(
            top: backButtonTopPadding,
            left: backButtonLeftPadding,
            child: SafeArea( // Ensures button is not obscured by notches/system UI
              child: Material(
                color: Colors.transparent, // For correct splash effect
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: backIconSize),
                  padding: EdgeInsets.all(backButtonTouchPadding), // Larger touch target
                  splashRadius: backIconSize, // Splash radius related to icon size
                  tooltip: 'Back',
                  onPressed: () async {
                    await _playUiClickSound();
                    if (mounted) { // Good practice to check mounted before Navigator.pop
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