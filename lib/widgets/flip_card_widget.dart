import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:audioplayers/audioplayers.dart';
// Adjust the import path to your globals.dart file
import '../data/globals.dart'; // Or your actual path
import 'package:test2/widgets/card_back.dart'; // Assuming test2/widgets path
import 'package:test2/widgets/card_front.dart'; // Assuming test2/widgets path

class FlipCardWidget extends StatefulWidget {
  // static bool _appHasSeenFirstFlip = false; // REMOVED

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
  final String term;
  final String definition;
  final Function(bool isFront)? onFlip;

  @override
  FlipCardWidgetState createState() => FlipCardWidgetState();
}

class FlipCardWidgetState extends State<FlipCardWidget> {
  final FlipCardController con = FlipCardController();
  final _flipDuration = Duration(milliseconds: 400);
  bool _isFront = true;
  bool _isFlipping = false;
  bool isSoundEnabled = true;
  bool _currentAppHasSeenFirstFlip = false; // Local state to reflect global pref
  bool _prefsLoaded = false;


  @override
  void initState() {
    super.initState();
    _loadInitialPrefs();
  }

  Future<void> _loadInitialPrefs() async {
    bool sound = await getSoundEnabled();
    bool seenFlip = await getAppHasSeenFirstFlip();
    if (!mounted) return;
    setState(() {
      isSoundEnabled = sound;
      _currentAppHasSeenFirstFlip = seenFlip;
      _prefsLoaded = true;
    });
  }


  @override
  void dispose() {
    super.dispose();
  }

  void _playFlipSound() async {
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(AssetSource('audio/card_flip.mp3'));
  }

  void _handleFlip() async {
    if (_isFlipping) return;
    if (!_prefsLoaded) return; // Don't allow flip if prefs not loaded

    _isFlipping = true;

    bool initialFlipState = _currentAppHasSeenFirstFlip;

    if (!_currentAppHasSeenFirstFlip) {
      await setAppHasSeenFirstFlip(true); // Persist the change
      if (mounted) {
        setState(() {
          _currentAppHasSeenFirstFlip = true; // Update local state immediately
        });
      }
    }

    con.flipcard();
    // This setState is primarily for _isFront, but also ensures rebuild if _currentAppHasSeenFirstFlip changed
    if (mounted) {
      setState(() {
        _isFront = !_isFront;
      });
    }


    widget.onFlip?.call(_isFront);
    isSoundEnabled ? _playFlipSound() : null;
    await Future.delayed(_flipDuration);
    _isFlipping = false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const Center(child: CircularProgressIndicator()); // Or some placeholder
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double buttonWidth = screenWidth * 0.3;
    final double buttonHeight = screenHeight * 0.06;
    final double iconSize = min(screenWidth, screenHeight) * 0.04;

    final nextButton = Transform(
      transform: Matrix4.identity(),
      alignment: Alignment.center,
      child: SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFront ? Colors.white : Colors.black,
            foregroundColor: _isFront ? Colors.black : Colors.white,
            side: BorderSide(color: _isFront ? Colors.black : Colors.white, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.zero,
            alignment: Alignment.center,
          ),
          onPressed: widget.onNextButtonPressed,
          child: Icon(
            Icons.arrow_forward,
            size: iconSize,
            color: _isFront ? Colors.black : Colors.white,
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: _handleFlip,
      child: Stack(
        children: [
          Material(
            child: FlipCard(
              animationDuration: _flipDuration,
              rotateSide: RotateSide.right,
              disableSplashEffect: false,
              splashColor: Colors.orange,
              onTapFlipping: false,
              axis: FlipAxis.vertical,
              controller: con,
              frontWidget: SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: CardFront(
                  term: widget.term,
                  showInitialFlipHint: !_currentAppHasSeenFirstFlip,
                ),
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