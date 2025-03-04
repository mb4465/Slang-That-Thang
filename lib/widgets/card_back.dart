import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg

class CardBack extends StatelessWidget {
  final String term;
  final String definition;
  final String generation;
  final IconData icon;
  final Transform button;

  const CardBack({
    super.key,
    required this.term,
    required this.definition,
    required this.icon,
    required this.generation,
     required this.button,
  });

  String addNewlineBeforeBracket(String input) {
    int bracketIndex = input.indexOf('(');

    if (bracketIndex != -1) {
      return '${input.substring(0, bracketIndex)}\n${input.substring(bracketIndex)}';
    }

    return input;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: FaIcon(
                icon,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                              // 'this is supposed to be a very long text',
                    term,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Text(
                    definition,
                    // 'this is supposed to be a very long text very long too long to comprehend wow',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Slang Icon and Generation at the bottom left and right respectively
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: button
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space evenly
                crossAxisAlignment: CrossAxisAlignment.end, // Align items to the bottom
                children: [
                  // Slang Icon
                  SvgPicture.asset(
                    'assets/images/slang-icon.svg', // Path to your SVG
                    height: 50, // Adjust size as needed
                    width: 50,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), // Set color to white
                  ),

                  // Generation
                  Text(
                    addNewlineBeforeBracket(generation),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}