// lib/widgets/card_back.dart
import 'package:audioplayers/audioplayers.dart'; // ADDED
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/globals.dart'; // ADDED for getSoundEnabled

class CardBack extends StatefulWidget { // MODIFIED to StatefulWidget
  final String term;
  final String definition;
  final String generation; // Expected format: "Generation Name (YYYY - YYYY)"
  final Image image;
  final Widget nextButton;
  final Widget? previousButton;
  final GlobalKey? nextButtonKey;
  final GlobalKey? previousButtonKey;
  final VoidCallback? onHistoryIconPressed; // New callback

  const CardBack({
    super.key,
    required this.term,
    required this.definition,
    required this.image,
    required this.generation,
    required this.nextButton,
    this.previousButton,
    this.nextButtonKey,
    this.previousButtonKey,
    this.onHistoryIconPressed, // New callback
  });

  @override
  State<CardBack> createState() => _CardBackState(); // ADDED createState
}

class _CardBackState extends State<CardBack> { // ADDED State class
  bool _showGenerationsOverlay = false; // ADDED state for overlay
  final AudioPlayer _audioPlayer = AudioPlayer(); // ADDED AudioPlayer

  @override
  void dispose() {
    _audioPlayer.dispose(); // ADDED dispose for audio player
    super.dispose();
  }

  Future<void> _playStandardClickSound() async { // ADDED sound method
    if (await getSoundEnabled()) {
      // Create a new player instance for short sounds to avoid issues with ongoing playback.
      final player = AudioPlayer(); 
      await player.play(AssetSource('audio/click.mp3'));
      // Release the player resources once playback is complete.
      player.onPlayerComplete.first.then((_) => player.dispose());
    }
  }
  
  Future<void> _playHistoryButtonSound() async {
    if (await getSoundEnabled()) {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/click.mp3')); // CHANGED to click.mp3
      player.onPlayerComplete.first.then((_) => player.dispose());
    }
  }

  String addNewlineBeforeBracket(String input) {
    final bracketIndex = input.indexOf('(');
    return bracketIndex != -1
        ? '${input.substring(0, bracketIndex).trim()}\n${input.substring(bracketIndex)}'
        : input;
  }

  Widget _buildGenerationsOverlayWidget(BuildContext context) { // ADDED overlay widget builder
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final overlayWidth = screenWidth * 0.85; // Similar to CardFront
    final overlayMaxHeight = screenHeight * 0.7; // Similar to CardFront

    return Center(
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(16.0),
        color: Colors.transparent, // To ensure rounded corners from Container are visible
        child: Container(
          width: overlayWidth,
          constraints: BoxConstraints(maxHeight: overlayMaxHeight, minWidth: 280),
          decoration: BoxDecoration(
            color: Colors.white, // White background for the overlay content
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25), // Darker shadow for better visibility on black card back
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    tooltip: 'Close',
                    onPressed: () async {
                      await _playStandardClickSound();
                      if (mounted) {
                        setState(() {
                          _showGenerationsOverlay = false;
                        });
                      }
                    },
                  ),
                ),
              ),
              Expanded( // Ensure SVG takes available space and can be centered
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Padding around SVG
                  child: SvgPicture.asset(
                    'assets/images/generations-without-icon.svg',
                    fit: BoxFit.contain, // Ensure SVG scales down to fit
                    colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn), // Ensure it's black
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final statusBarHeight = MediaQuery.of(context).padding.top;
        final double generationLogoSize = screenWidth * 0.085;
        final double historyIconSize = screenWidth * 0.075; // Consistent with CardFront

        final double termFontSize = screenWidth * 0.08;
        final double definitionFontSize = screenWidth * 0.055;
        final double generationFontSize = screenWidth * 0.045;
        final double topImagePadding = screenHeight * 0.08;
        final double originalBottomButtonPadding = screenHeight * 0.08;
        final double bottomIconPadding = screenHeight * 0.04;
        final double sidePadding = screenWidth * 0.05;
        final double slangIconSize = screenHeight * 0.07;
        final double buttonsUpwardOffset = screenHeight * 0.05;
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
                    key: ValueKey('card-back-image-${widget.image.hashCode}'), // Access image via widget.image
                    width: screenWidth * 0.09,
                    height: screenHeight * 0.095,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: widget.image, // Access image via widget.image
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
                          widget.term, // Access term via widget.term
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
                          widget.definition, // Access definition via widget.definition
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
                  padding: EdgeInsets.only(bottom: totalBottomPaddingForButtons),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.previousButton != null)
                        RepaintBoundary(
                          key: widget.previousButtonKey, // Access previousButtonKey via widget.previousButtonKey
                          child: widget.previousButton!, // Access previousButton via widget.previousButton
                        ),
                      if (widget.previousButton != null)
                        SizedBox(width: screenWidth * 0.05),
                      RepaintBoundary(
                        key: widget.nextButtonKey, // Access nextButtonKey via widget.nextButtonKey
                        child: widget.nextButton, // Access nextButton via widget.nextButton
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
                              addNewlineBeforeBracket(widget.generation), // Access generation via widget.generation
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
              Positioned(
                top: statusBarHeight + 16.0,
                right: 16.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () async {
                        await _playStandardClickSound();
                        if (mounted) {
                          setState(() {
                            _showGenerationsOverlay = true;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(generationLogoSize / 2), // For ripple effect
                      child: SvgPicture.asset(
                        'assets/images/generation-icon.svg',
                        height: generationLogoSize,
                        width: generationLogoSize,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    ),
                    const SizedBox(height: 8.0), // Spacing between icons
                    IconButton(
                      icon: Icon(Icons.history, color: Colors.white, size: historyIconSize), // White icon for dark background
                      tooltip: 'View Card History',
                      onPressed: () async {
                        await _playHistoryButtonSound();
                        widget.onHistoryIconPressed?.call();
                      },
                    ),
                  ],
                ),
              ),
              // Removed the old Positioned History Icon Button as it's now in the Column
              if (_showGenerationsOverlay) _buildGenerationsOverlayWidget(context), // ADDED conditional overlay
            ],
          ),
        );
      },
    );
  }
}
