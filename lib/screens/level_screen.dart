import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:test2/data/terms_data.dart';
import 'package:test2/data/icon_mapping.dart';
import 'package:test2/widgets/flip_card_widget.dart';
import 'package:test2/widgets/card_front.dart'; //Import CardFront
import 'package:test2/widgets/card_back.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({Key? key}) : super(key: key);

  @override
  LevelScreenState createState() => LevelScreenState();
}

class LevelScreenState extends State<LevelScreen> {
  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late String _selectedGeneration;
  late String _selectedTerm;
  late String _selectedDefinition;
  late IconData _selectedIcon;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _getRandomTerm();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _getRandomTerm() {
    List<String> generations = termsData.keys.toList();
    _selectedGeneration = generations[_random.nextInt(generations.length)];

    List<Map<String, String>> termList = termsData[_selectedGeneration]!;
    if (termList.isNotEmpty) {
      Map<String, String> randomTerm = termList[_random.nextInt(termList.length)];
      setState(() {
        _selectedTerm = randomTerm["term"]!;
        _selectedDefinition = randomTerm["definition"]!;
        _selectedIcon = generationIcons[_selectedGeneration] ?? Icons.help_outline;
      });
    }
  }

  Future<void> _loadAndPlayAudio() async {
    await _audioPlayer.play(AssetSource('audio/next_card.mp3'));
  }

  void _goToNextCard() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % 100;
      _getRandomTerm();
      _loadAndPlayAudio();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the current card data
    Widget currentCard = FlipCardWidget(
      icon: _selectedIcon,
      term: _selectedTerm,
      definition: _selectedDefinition,
      generation: _selectedGeneration,
    );

    // Determine if the front is currently visible
    bool isCardFront = false;

    if (currentCard is FlipCardWidget) {
      isCardFront = currentCard.key == const ValueKey<bool>(true);
    }

    final arrowColor = isCardFront ? Colors.black : Colors.white;

    return Scaffold(
      body: Stack(
        children: [
          currentCard, // Display the FlipCard
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: arrowColor),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height / 2 - 20,
            child: IconButton(
              icon: Icon(Icons.arrow_right, size: 40, color: arrowColor),
              onPressed: () {
                _goToNextCard();
              },
            ),
          ),
        ],
      ),
    );
  }
}