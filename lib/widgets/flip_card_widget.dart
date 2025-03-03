import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audioplayers/audioplayers.dart'; // Add this import
import 'package:test2/widgets/card_back.dart';
import 'package:test2/widgets/card_front.dart';

class FlipCardWidget extends StatefulWidget {
  const FlipCardWidget({
    super.key,
    required this.term,
    required this.definition,
    required this.icon,
    required this.generation,
  });

  final IconData icon;
  final String generation;
  final String term; // Parameter for the term
  final String definition; // Parameter for the definition

  @override
  FlipCardWidgetState createState() => FlipCardWidgetState();
}

class FlipCardWidgetState extends State<FlipCardWidget> {
  final FlipCardController con = FlipCardController();
  final _flipDuration = Duration(milliseconds: 400);
  bool _isFront = true; // Track the current side of the card
  bool _isFlipping = false; // Track whether the card is currently flipping

  @override
  void dispose() {
    super.dispose();
  }

  // Function to play flip sound
  void _playFlipSound() async {
    AudioPlayer audioPlayer = AudioPlayer(); // Create a new instance for each sound
    await audioPlayer.play(AssetSource('audio/card_flip.mp3')); // Play sound from assets
  }

  // Function to handle card flip
  void _handleFlip() async {
    if (_isFlipping) return; // Exit if the card is already flipping

    _isFlipping = true; // Set flipping state to true
    con.flipcard(); // Flip the card
    setState(() {
      _isFront = !_isFront; // Update the card's side
    });

    // Play the flip sound after the animation completes
    _playFlipSound();

    // Wait for the flip animation to complete
    await Future.delayed(_flipDuration);

    _isFlipping = false; // Reset flipping state
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: _handleFlip, // Flip the card on tap
      child: Stack(
        children: [
          Material(
            child: FlipCard(
              animationDuration: _flipDuration,
              rotateSide: RotateSide.right,
              disableSplashEffect: false,
              splashColor: Colors.orange,
              onTapFlipping: false, // Disable default tap flipping
              axis: FlipAxis.vertical,
              controller: con,
              frontWidget: SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: CardFront(term: widget.term),
              ),
              backWidget: SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: CardBack(
                  icon: widget.icon,
                  term: widget.term,
                  definition: widget.definition,
                  generation: widget.generation,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}