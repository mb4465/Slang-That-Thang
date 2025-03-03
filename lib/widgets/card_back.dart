import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg

class CardBack extends StatelessWidget {
  final String term;
  final String definition;
  final String generation;
  final IconData icon;

  const CardBack({
    Key? key,
    required this.term,
    required this.definition,
    required this.icon,
    required this.generation,
  }) : super(key: key);

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
                Text(
                  term,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  definition,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Slang Icon and Generation at the bottom left and right respectively
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