// lib/level_screen.dart
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:test2/data/terms_data.dart';
import 'package:test2/data/globals.dart';
import 'package:test2/widgets/flip_card_widget.dart'; // Ensure this is the latest version

// Helper class for card history
class CardHistoryItem {
  final String term;
  final String definition;
  final String icon;
  final String generation;

  CardHistoryItem({
    required this.term,
    required this.definition,
    required this.icon,
    required this.generation,
  });
}

// Enum to define the animation style
enum CardAnimationStyle { none, next, previous }

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  LevelScreenState createState() => LevelScreenState();
}

class LevelScreenState extends State<LevelScreen> with TickerProviderStateMixin {
  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _cardAnimationController;

  // Card data
  late String _selectedGeneration = '';
  late String _selectedTerm = '';
  late String _selectedDefinition = '';
  late String _selectedIcon = '';

  final List<CardHistoryItem> _cardHistory = []; // For "previous" card functionality
  final List<CardHistoryItem> _displayedCardsLog = []; // For session history
  CardAnimationStyle _cardAnimationStyle = CardAnimationStyle.none;
  bool _isHistoryOverlayVisible = false;

  bool isCardFront = true;

  // Ad state
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _adsRemoved = false;
  int _cardCounter = 0;
  bool isSoundEnabled = true;

  String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9195859305045271/9115537722';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9195859305045271/6991937266';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _initializeFirstTerm();
    getSoundEnabled().then((v) => isSoundEnabled = v);
    getAdsRemovedStatus().then((v) {
      _adsRemoved = v;
      if (!_adsRemoved && _adUnitId.isNotEmpty) {
        _createInterstitialAd();
      }
    });
  }

  void _initializeFirstTerm() {
    _displayedCardsLog.clear(); // Clear history for new session

    final generations = termsData.keys.toList();
    _selectedGeneration = generations[_random.nextInt(generations.length)];
    final termList = termsData[_selectedGeneration]!;
    final termEntry = termList[_random.nextInt(termList.length)];
    _selectedTerm = termEntry['term']!;
    _selectedDefinition = termEntry['definition']!;
    _selectedIcon = generationIcons[_selectedGeneration] ?? '';

    // Log the first card
    _displayedCardsLog.add(CardHistoryItem(
      term: _selectedTerm,
      definition: _selectedDefinition,
      icon: _selectedIcon,
      generation: _selectedGeneration,
    ));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _cardAnimationController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String assetPath) async {
    if (!isSoundEnabled) return;
    await _audioPlayer.stop(); // Stop any currently playing sound
    await _audioPlayer.play(AssetSource(assetPath));
  }

  void _goToNextCard() {
    _playAudio('audio/next_card.mp3');
    _cardCounter++;

    if (!_adsRemoved && _cardCounter >= 20 && _isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) { ad.dispose(); _createInterstitialAd(); },
        onAdFailedToShowFullScreenContent: (ad, err) { ad.dispose(); _createInterstitialAd(); },
      );
      _interstitialAd!.show();
      _cardCounter = 0;
    }

    setState(() {
      _cardAnimationStyle = CardAnimationStyle.next;
      if (_selectedTerm.isNotEmpty) { // For "previous" card functionality
        _cardHistory.add(CardHistoryItem(
          term: _selectedTerm,
          definition: _selectedDefinition,
          icon: _selectedIcon,
          generation: _selectedGeneration,
        ));
      }
      final generations = termsData.keys.toList();
      final newSelectedGeneration = generations[_random.nextInt(generations.length)];
      final termList = termsData[newSelectedGeneration]!;
      final termEntry = termList[_random.nextInt(termList.length)];
      _selectedGeneration = newSelectedGeneration;
      _selectedTerm = termEntry['term']!;
      _selectedDefinition = termEntry['definition']!;
      _selectedIcon = generationIcons[newSelectedGeneration] ?? '';

      // Log the new card
      _displayedCardsLog.add(CardHistoryItem(
        term: _selectedTerm,
        definition: _selectedDefinition,
        icon: _selectedIcon,
        generation: _selectedGeneration,
      ));
    });

    _cardAnimationController.forward(from: 0.0).then((_) {
      if (mounted) {
        _cardAnimationController.reset();
      }
    });
  }

  void _goToPreviousCard() {
    if (_cardHistory.isNotEmpty) {
      _playAudio('audio/previous_card.mp3');

      final previousCardData = _cardHistory.removeLast();

      setState(() {
        _cardAnimationStyle = CardAnimationStyle.previous;
        _selectedTerm = previousCardData.term;
        _selectedDefinition = previousCardData.definition;
        _selectedIcon = previousCardData.icon;
        _selectedGeneration = previousCardData.generation;
        // Note: We don't remove from _displayedCardsLog here as it's a log of all viewed cards.
      });

      _cardAnimationController.forward(from: 0.0).then((_) {
        if (mounted) {
          _cardAnimationController.reset();
        }
      });
    } else {
      print("No previous card in history.");
    }
  }

  void _toggleHistoryOverlay() {
    _playAudio('audio/click.mp3'); // Generic click sound
    setState(() {
      _isHistoryOverlayVisible = !_isHistoryOverlayVisible;
    });
  }

  Widget _buildHistoryOverlayWidget() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: _toggleHistoryOverlay, // Close overlay by tapping outside the content
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Material( // To prevent the inner tap from closing the overlay
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {}, // Trap taps on the content area
              child: Container(
                width: screenWidth * 0.85,
                height: screenHeight * 0.7,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Cards History",
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: _toggleHistoryOverlay,
                          tooltip: "Close History",
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: _displayedCardsLog.isEmpty
                          ? const Center(
                              child: Text(
                                "No terms viewed yet in this session.",
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _displayedCardsLog.length,
                              itemBuilder: (context, index) {
                                // Display in reverse chronological order
                                final item = _displayedCardsLog[_displayedCardsLog.length - 1 - index];
                                return ListTile(
                                  title: Text(
                                    item.term,
                                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                                  ),
                                  // You could add subtitle: Text(item.generation) or item.definition here
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAnimatedCard(Widget cardContent) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      child: cardContent,
      builder: (context, child) {
        if (_cardAnimationStyle == CardAnimationStyle.none) {
          return child!;
        }

        Offset oldCardOutEndOffset;
        Offset newCardInBeginOffset;

        if (_cardAnimationStyle == CardAnimationStyle.next) {
          oldCardOutEndOffset = const Offset(0, -0.75);
          newCardInBeginOffset = const Offset(0, 1.0);
        } else {
          oldCardOutEndOffset = const Offset(0, 0.75);
          newCardInBeginOffset = const Offset(0, -1.0);
        }

        final outCurve = CurvedAnimation(
          parent: _cardAnimationController,
          curve: Curves.easeInCubic,
        );
        final inCurve = CurvedAnimation(
          parent: _cardAnimationController,
          curve: const Interval(
            0.2,
            1.0,
            curve: Curves.easeOutCubic,
          ),
        );

        return Stack(
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0).animate(outCurve),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: oldCardOutEndOffset,
                ).animate(outCurve),
                child: child,
              ),
            ),
            FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(inCurve),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: newCardInBeginOffset,
                  end: Offset.zero,
                ).animate(inCurve),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenHeight * 0.04;
    final padding = screenWidth * 0.05;

    Widget currentCard = FlipCardWidget(
      key: ValueKey(_selectedTerm + _selectedGeneration),
      onNextButtonPressed: _goToNextCard,
      onPreviousButtonPressed: _cardHistory.isNotEmpty ? _goToPreviousCard : null,
      onHistoryIconPressed: _toggleHistoryOverlay, // Pass the callback
      image: Image.asset(_selectedIcon.isNotEmpty ? _selectedIcon : 'assets/images/default_icon.png'),
      term: _selectedTerm,
      definition: _selectedDefinition,
      generation: _selectedGeneration,
      onFlip: (isFront) {
        setState(() => isCardFront = isFront);
      },
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildAnimatedCard(currentCard),
          Positioned(
            top: MediaQuery.of(context).padding.top + screenHeight * 0.02,
            left: padding,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  Icons.home, // Changed from Icons.arrow_back
                  color: isCardFront ? Colors.black : Colors.white,
                  size: iconSize,
                ),
                onPressed: () {
                  // Play the sound when the home icon is pressed
                  _playAudio('audio/rules.mp3');
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          if (_isHistoryOverlayVisible) _buildHistoryOverlayWidget(), // Display history overlay
        ],
      ),
    );
  }

  void _createInterstitialAd() {
    if (_adUnitId.isEmpty || _adsRemoved) return;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) { _interstitialAd = ad; _isAdLoaded = true; },
        onAdFailedToLoad: (error) { debugPrint('Ad load failed: $error'); },
      ),
    );
  }
}
