import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GenerationsScreen extends StatelessWidget {
  const GenerationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Generations",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: const [
                      GenerationRow(
                        title: "Silent Generation",
                        years: "1928 - 1945",
                        icon: Icons.mic, // 🎙️
                      ),
                      GenerationRow(
                        title: "Baby Boomers",
                        years: "1946 - 1964",
                        icon: FontAwesomeIcons.peace, // ☮️ (FontAwesome)
                      ),
                      GenerationRow(
                        title: "Gen X",
                        years: "1965 - 1980",
                        icon: Icons.computer, // 💻
                      ),
                      GenerationRow(
                        title: "Millennials",
                        years: "1981 - 1996",
                        icon: Icons.smartphone, // 📱
                      ),
                      GenerationRow(
                        title: "Gen Z",
                        years: "1997 - 2012",
                        icon: Icons.videogame_asset, // 🎮
                      ),
                      GenerationRow(
                        title: "Gen Alpha",
                        years: "2013 - present",
                        icon: FontAwesomeIcons.vrCardboard, // 🕶️ (FontAwesome alternative)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "Slang that Thank",
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Updated GenerationRow widget
class GenerationRow extends StatelessWidget {
  final String title;
  final String years;
  final IconData icon; // Corrected type

  const GenerationRow({
    super.key,
    required this.title,
    required this.years,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "• $years",
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          FaIcon(icon, size: 30), // Using FaIcon for FontAwesome icons
        ],
      ),
    );
  }
}
