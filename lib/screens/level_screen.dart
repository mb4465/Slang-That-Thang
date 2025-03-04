import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:test2/data/terms_data.dart';
import 'package:test2/data/globals.dart';
import 'package:test2/widgets/flip_card_widget.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  LevelScreenState createState() => LevelScreenState();
}

class LevelScreenState extends State<LevelScreen> {
  final Random _random = Random();
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late String _selectedGeneration;
  late String _selectedTerm;
  late String _selectedDefinition;
  late IconData _selectedIcon;
  bool isNextCard = true; // can the user go to the next card? to fix audio sync
  bool isCardFront = true;
  bool isSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _getRandomTerm();
    getSoundEnabled().then((value) {
      isSoundEnabled = value;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
    // Stop any currently playing audio
    await _audioPlayer.stop();
    // Play the new audio
    await _audioPlayer.play(AssetSource('audio/next_card.mp3'));
  }

  void _onPageChanged(int index) async {
    _getRandomTerm();
  }
//
  void _goToNextCard() {

    Duration duration = Duration(milliseconds: 150);
    isNextCard = false; // Set isNextCard to false initially
    isCardFront = true;
    // Play the audio
    isSoundEnabled?_loadAndPlayAudio():null;
    _pageController.nextPage(
      duration: duration,
      curve: Curves.easeInCubic,
    );
    // Set isNextCard to true after the duration
    Future.delayed(duration + Duration(milliseconds: 200), () {
      setState(() {
        isNextCard = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return FlipCardWidget(
                onNextButtonPressed: _goToNextCard,
                icon: _selectedIcon,
                term: _selectedTerm,
                definition: _selectedDefinition,
                generation: _selectedGeneration,
                onFlip: (isFront) {
                  // print('isFront =  $isFront');
                  setState(() {
                    isCardFront = isFront; // Update the state in LevelScreenState
                  });
                },
              );
            },
          ),
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: isCardFront? Colors.black: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),

        ],
      ),
    );
  }
}