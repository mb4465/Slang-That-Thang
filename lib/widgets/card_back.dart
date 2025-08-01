import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/globals.dart'; // Ensure this path is correct

class CardBack extends StatefulWidget {
  final String term;
  final String definition;
  final String generation;
  final String imagePath;
  final Widget nextButton;
  final Widget? previousButton;
  final GlobalKey? nextButtonKey;
  final GlobalKey? previousButtonKey;
  final double iconSize;
  final double topImageYOffset; // NEW: Add topImageYOffset parameter

  const CardBack({
    super.key,
    required this.term,
    required this.definition,
    required this.imagePath,
    required this.generation,
    required this.nextButton,
    this.previousButton,
    this.nextButtonKey,
    this.previousButtonKey,
    required this.iconSize,
    required this.topImageYOffset, // NEW: Require topImageYOffset
  });

  @override
  State<CardBack> createState() => _CardBackState();
}

class _CardBackState extends State<CardBack> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playStandardClickSound() async {
    if (await getSoundEnabled()) {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/click.mp3'));
      player.onPlayerComplete.first.then((_) => player.dispose());
    }
  }

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
        final double originalBottomButtonPadding = screenHeight * 0.08;
        final double bottomIconPadding = screenHeight * 0.04;
        final double sidePadding = screenWidth * 0.05;
        final double slangIconSize = screenHeight * 0.07;
        final double buttonsUpwardOffset = screenHeight * 0.05;
        final double totalBottomPaddingForButtons = originalBottomButtonPadding + buttonsUpwardOffset;

        // Calculate the space taken by the image and a small buffer below it.
        // This will be used to push the text content down.
        final double imageAreaHeight = widget.iconSize + screenHeight * 0.03;


        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Position the image at the exact topYOffset received
              Positioned(
                top: widget.topImageYOffset,
                left: (screenWidth - widget.iconSize) / 2, // Center horizontally
                child: SizedBox(
                  width: widget.iconSize,
                  height: widget.iconSize,
                  child: Image.asset(
                    widget.imagePath,
                    key: ValueKey('card-back-image-${widget.imagePath}'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Main content (term, definition) - adjust its top padding
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: sidePadding * 0.75),
                  child: Padding(
                    // Add top padding dynamically based on image size and desired spacing
                    padding: EdgeInsets.only(top: imageAreaHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            widget.term,
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
                            widget.definition,
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
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: totalBottomPaddingForButtons),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.previousButton != null)
                        RepaintBoundary(
                          key: widget.previousButtonKey,
                          child: widget.previousButton!,
                        ),
                      if (widget.previousButton != null)
                        SizedBox(width: screenWidth * 0.05),
                      RepaintBoundary(
                        key: widget.nextButtonKey,
                        child: widget.nextButton,
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
                              addNewlineBeforeBracket(widget.generation),
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