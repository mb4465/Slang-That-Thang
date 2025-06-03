// lib/widgets/card_back.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CardBack extends StatelessWidget {
  final String term;
  final String definition;
  final String generation; // Expected format: "Generation Name (YYYY - YYYY)"
  final Image image;
  final Widget nextButton; // Renamed from `button` for clarity
  final Widget? previousButton; // NEW: This is the "Previous" button widget passed from FlipCardWidget
  final GlobalKey? nextButtonKey; // Key for the "Next" button, passed from FlipCardWidget
  final GlobalKey? previousButtonKey; // NEW: Key for the "Previous" button

  const CardBack({
    super.key,
    required this.term,
    required this.definition,
    required this.image,
    required this.generation,
    required this.nextButton, // Renamed
    this.previousButton, // NEW
    this.nextButtonKey,
    this.previousButtonKey, // NEW
  });

  String addNewlineBeforeBracket(String input) {
    final bracketIndex = input.indexOf('(');
    return bracketIndex != -1
        ? '${input.substring(0, bracketIndex).trim()}\n${input.substring(bracketIndex)}'
        : input;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final double termFontSize = screenWidth * 0.08;
        final double definitionFontSize = screenWidth * 0.055;
        final double generationFontSize = screenWidth * 0.045;
        final double topImagePadding = screenHeight * 0.08;
        // Original bottom padding for the button's container
        final double originalBottomButtonPadding = screenHeight * 0.08;
        final double bottomIconPadding = screenHeight * 0.04;
        final double sidePadding = screenWidth * 0.05;
        final double slangIconSize = screenHeight * 0.07;

        // --- MODIFICATION TO ELEVATE THE ENTIRE BUTTONS ROW ---
        // Define an additional upward offset for the button row.
        final double buttonsUpwardOffset = screenHeight * 0.05; // Adjust this factor as needed
        final double totalBottomPaddingForButtons = originalBottomButtonPadding + buttonsUpwardOffset;


        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: topImagePadding),
                  child: SizedBox(
                    key: ValueKey('card-back-image-${image.hashCode}'),
                    width: screenWidth * 0.09,
                    height: screenHeight * 0.095,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: image,
                    ),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: sidePadding * 0.75),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          term,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: termFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Text(
                          definition,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: definitionFontSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // NEW: Row for both buttons at the bottom center
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  // Adjust the bottom padding to include the upward offset
                  padding: EdgeInsets.only(bottom: totalBottomPaddingForButtons),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Keep row as small as its children
                    mainAxisAlignment: MainAxisAlignment.center, // Center the row itself
                    children: [
                      if (previousButton != null) // Only show previous button if provided
                        RepaintBoundary(
                          key: previousButtonKey,
                          child: previousButton!,
                        ),
                      if (previousButton != null) // Add a gap between buttons if both exist
                        SizedBox(width: screenWidth * 0.05), // Adjust spacing as needed
                      RepaintBoundary(
                        key: nextButtonKey, // The key for tutorial is still on this one
                        child: nextButton,
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: sidePadding,
                    right: sidePadding,
                    bottom: bottomIconPadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SvgPicture.asset(
                        'assets/images/slang-icon.svg',
                        height: slangIconSize,
                        width: slangIconSize,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              addNewlineBeforeBracket(generation),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: generationFontSize,
                                color: Colors.white,
                                height: 1.2,
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