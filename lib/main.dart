import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:test2/screens/home_screen.dart'; // Make sure this path is correct for your project
import 'package:device_preview/device_preview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Enable DevicePreview only in debug mode
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SLANG THAT THANG!!',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      // Use DevicePreview's builder for MaterialApp
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 7), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 2, // This section takes 2/3 of the vertical space
            child: Align( // Changed from Center to Align
              // Alignment(x, y)
              // x: -1.0 (left) to 1.0 (right)
              // y: -1.0 (top) to 1.0 (bottom)
              // 0.0, 0.0 is center.
              // 0.0, 0.2 moves it slightly down from the vertical center of this Expanded space.
              alignment: const Alignment(0.0, 0.2), // Adjust the Y-coordinate (e.g., 0.1 for less, 0.3 for more)
              child: Image.asset(
                'assets/images/callidora-logo.png',
                fit: BoxFit.contain,
                width: screenWidth * 0.8, // Image width is responsive to screen width
              ),
            ),
          ),
          Expanded(
            flex: 1, // This section takes 1/3 of the vertical space
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Powered by',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedTextKit(
                  key: ValueKey(screenWidth), // Key added here for proper rebuild on screen size changes
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Callidora Global Media',
                      textStyle: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0C2340),
                      ),
                      speed: const Duration(milliseconds: 150),
                    ),
                  ],
                  totalRepeatCount: 1,
                  pause: const Duration(milliseconds: 1000),
                  displayFullTextOnTap: true,
                  stopPauseOnTap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}