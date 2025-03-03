import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg

class CardFront extends StatelessWidget {
  final String term; // Add a parameter for the text

  const CardFront({super.key, required this.term}); // Make the text required

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Center(
              child: Text(
                // 'this is supposed to be a very long text',
                term, // Use the passed text
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Slang Icon at the bottom left
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SvgPicture.asset(
                'assets/images/slang-icon.svg', // Path to your SVG
                height: 50, // Adjust size as needed
                width: 50,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}