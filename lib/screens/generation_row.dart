import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GenerationRow extends StatelessWidget {
  final String title;
  final String years;
  final IconData icon;

  const GenerationRow({
    super.key,
    required this.title,
    required this.years,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // --- Responsive Sizes ---
    // Adjust these multipliers to achieve your desired visual balance.
    final double titleFontSize = screenWidth * 0.045; // e.g., 18dp on a 400dp screen
    final double yearsFontSize = screenWidth * 0.04;  // e.g., 16dp on a 400dp screen
    final double iconSize = screenWidth * 0.075;     // e.g., 30dp on a 400dp screen

    // Optional: Clamping sizes to prevent them from becoming too small or too large
    // final double clampedTitleFontSize = titleFontSize.clamp(14.0, 24.0);
    // final double clampedYearsFontSize = yearsFontSize.clamp(12.0, 20.0);
    // final double clampedIconSize = iconSize.clamp(24.0, 48.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    // fontSize: clampedTitleFontSize, // Uncomment for clamped size
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "• $years",
                  style: TextStyle(
                    fontSize: yearsFontSize,
                    // fontSize: clampedYearsFontSize, // Uncomment for clamped size
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: FaIcon(
              icon,
              size: iconSize,
              // size: clampedIconSize, // Uncomment for clamped size
              color: Colors.blueGrey[700], // A slightly darker, more distinct color
            ),
          ),
        ],
      ),
    );
  }
}