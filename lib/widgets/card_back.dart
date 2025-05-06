import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Ensure this is imported
// Import your generation data file
import '../screens/generation_data.dart';

class CardBack extends StatelessWidget {
  final String term;
  final String definition;
  final String generation; // Expected format: "Generation Name (YYYY - YYYY)"
  final Image image;
  final Transform button;

  const CardBack({
    super.key,
    required this.term,
    required this.definition,
    required this.image,
    required this.generation,
    required this.button,
  });

  String addNewlineBeforeBracket(String input) {
    final bracketIndex = input.indexOf('(');
    return bracketIndex != -1
        ? '${input.substring(0, bracketIndex).trim()}\n${input.substring(bracketIndex)}' // Trim before newline
        : input;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Get the icon for the current generation
        // The 'generation' string passed to CardBack must match the format expected by getIconForGeneration
        // e.g., "Gen Z (1997 - 2012)"
        final IconData? generationIcon = getIconForGeneration(generation);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.08), // Responsive top padding
                  child: Container(
                      key: ValueKey('image-container-$screenWidth-$screenHeight'),
                      width: screenWidth * 0.09,
                      height: screenHeight * 0.095,
                      // Added FittedBox here as discussed in previous answers for the main image
                      child: FittedBox(
                        fit: BoxFit.contain, // Or BoxFit.scaleDown
                        child: image,
                      )
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView( // Added SingleChildScrollView for long terms/definitions
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15), // Reduced from 30
                        child: Text(
                          term,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.07, // Slightly smaller for potentially long terms
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0), // No extra padding, outer padding handles it
                        child: Text(
                          definition,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045, // Adjusted for definition length
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: screenHeight * 0.08), // Responsive bottom padding
                  child: button,
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  // Responsive padding for bottom left content
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.05,
                    right: screenWidth * 0.05,
                    bottom: screenHeight * 0.04,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SvgPicture.asset(
                        'assets/images/slang-icon.svg',
                        height: screenHeight * 0.07, // Adjusted size
                        width: screenHeight * 0.07,  // Adjusted size
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      Flexible( // Allow generation info to take space but not overflow
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end, // Align to the right
                          children: [
                            if (generationIcon != null)
                              FaIcon(
                                generationIcon,
                                size: screenWidth * 0.065, // Responsive icon size
                                color: Colors.white70,
                              ),
                            if (generationIcon != null) const SizedBox(height: 4),
                            Text(
                              addNewlineBeforeBracket(generation),
                              textAlign: TextAlign.right, // Align text to the right
                              style: TextStyle(
                                fontSize: screenWidth * 0.035, // Adjusted size
                                color: Colors.white,
                                height: 1.2, // Line height for multi-line text
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}