import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = 'Unknown';
  String _appName = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _appName = packageInfo.appName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust base size depending on width (you can tweak these numbers as needed)
    double scale(double base) => base * (screenWidth / 375).clamp(0.8, 1.4);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("About"),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(scale(24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _appName,
                style: TextStyle(
                  fontSize: scale(24),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: scale(12)),
              Text(
                'Version: $_version',
                style: TextStyle(
                  fontSize: scale(16),
                  color: Colors.black,
                ),
              ),
              SizedBox(height: scale(24)),
              Text(
                'Slang That Thang!! is an educational and entertaining game designed to bridge the gap between generations by exploring the evolution of slang. Test your knowledge of slang terms from different eras and see how well you understand the language of each generation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: scale(18),
                  color: Colors.black,
                ),
              ),
              SizedBox(height: scale(32)),
              Text(
                '© 2024 Your Company Name. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: scale(14),
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
