// lib/widgets/card_back.dart (or your actual path)
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CardBack extends StatelessWidget {
  final String term;
  final String definition;
  final String generation; // Expected format: "Generation Name (YYYY - YYYY)"
  final Image image;
  final Widget button; // This is the "Next" button widget passed from FlipCardWidget
  final GlobalKey? nextButtonKey; // Key for the "Next" button, passed from FlipCardWidget

  const CardBack({
    super.key,
    required this.term,
    required this.definition,
    required this.image,
    required this.generation,
    required this.button,
    this.nextButtonKey,
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

        final double termFontSize = screenWidth * 0.07;
        final double definitionFontSize = screenWidth * 0.055;
        final double generationFontSize = screenWidth * 0.045;
        final double topImagePadding = screenHeight * 0.08;
        final double bottomButtonPadding = screenHeight * 0.08;
        final double bottomIconPadding = screenHeight * 0.04;
        final double sidePadding = screenWidth * 0.05;
        final double slangIconSize = screenHeight * 0.07;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: topImagePadding),
                  child: SizedBox(
                    key: ValueKey('card-back-image-${image.hashCode}'), // CORRECTED: Use 'image'
                    width: screenWidth * 0.09,
                    height: screenHeight * 0.095,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: image, // CORRECTED: Use 'image'
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
                          term, // CORRECTED: Use 'term'
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
                          definition, // CORRECTED: Use 'definition'
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
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomButtonPadding),
                  child: RepaintBoundary(
                    key: nextButtonKey, // CORRECTED: Use 'nextButtonKey'
                    child: button, // CORRECTED: Use 'button'
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
                              addNewlineBeforeBracket(generation), // CORRECTED: Use 'generation'
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