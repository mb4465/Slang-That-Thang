import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:audioplayers/audioplayers.dart'; // Add this import
import 'package:test2/data/globals.dart';
import 'package:test2/widgets/card_back.dart';
import 'package:test2/widgets/card_front.dart';

class FlipCardWidget extends StatefulWidget {
  const FlipCardWidget({
    super.key,
    required this.term,
    required this.definition,
    required this.image,
    required this.generation,
    required this.onNextButtonPressed,
    this.onFlip,
  });

  final VoidCallback onNextButtonPressed;
  final Image image;
  final String generation;
  final String term; // Parameter for the term
  final String definition; // Parameter for the definition
  final Function(bool isFront)? onFlip;

  @override
  FlipCardWidgetState createState() => FlipCardWidgetState();
}

class FlipCardWidgetState extends State<FlipCardWidget> {
  final FlipCardController con = FlipCardController();
  final _flipDuration = Duration(milliseconds: 400);
  bool _isFront = true; // Track the current side of the card
  bool _isFlipping = false; // Track whether the card is currently flipping
  bool isSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    getSoundEnabled().then((value) {
      isSoundEnabled = value;
    });
  }

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
    widget.onFlip?.call(_isFront);
    // Play the flip sound after the animation completes
    isSoundEnabled ? _playFlipSound() : null;
    // Wait for the flip animation to complete
    await Future.delayed(_flipDuration);

    _isFlipping = false; // Reset flipping state
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Updated next button: wrapped in a Transform to match the required type
    final nextButton = Transform(
      transform: Matrix4.identity(), // No skew transformation, just to match the expected type
      alignment: Alignment.center,
      child: SizedBox(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFront ? Colors.white : Colors.black,
            foregroundColor: _isFront ? Colors.black : Colors.white,
            side: BorderSide(color: _isFront ? Colors.black : Colors.white, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Curved corners
            ),
          ),
          onPressed: widget.onNextButtonPressed,
          child: Icon(
            Icons.arrow_forward,
            color: _isFront ? Colors.black : Colors.white,
          ),
        ),
      ),
    );

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
                child: CardFront(term: widget.term, button: nextButton),
              ),
              backWidget: SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: CardBack(
                  image: widget.image,
                  term: widget.term,
                  definition: widget.definition,
                  generation: widget.generation,
                  button: nextButton,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
