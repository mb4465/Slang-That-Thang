import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:test2/data/terms_data.dart';
import 'package:test2/data/globals.dart';
import 'package:test2/widgets/flip_card_widget.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  LevelScreenState createState() => LevelScreenState();
}

class LevelScreenState extends State<LevelScreen> with TickerProviderStateMixin {
  final Random _random = Random();
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late String _selectedGeneration;
  late String _selectedTerm;
  late String _selectedDefinition;
  late String _selectedIcon;
  bool isNextCard = true;
  bool isCardFront = true;
  bool isSoundEnabled = true;
  late AnimationController _cardAnimationController;
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  int _cardCounter = 0; // counts the number of cards shown


  @override
  void initState() {
    super.initState();
    _getRandomTerm();
    getSoundEnabled().then((value) {
      isSoundEnabled = value;
    });
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Load the interstitial ad
    _createInterstitialAd();
  }


  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.dispose();
    _cardAnimationController.dispose();
    _interstitialAd?.dispose();
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
        _selectedIcon = generationIcons[_selectedGeneration] ?? '';
      });
    }
  }

  Future<void> _loadAndPlayAudio() async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audio/next_card.mp3'));
  }

  void _onPageChanged(int index) async {
    _getRandomTerm();
  }

  void _goToNextCard() {
    if (!isNextCard) return;

    setState(() {
      isNextCard = false;
      isCardFront = true;
    });

    if (isSoundEnabled) _loadAndPlayAudio();

    // Increase the card counter
    _cardCounter++;

    // Check if it’s time to show an interstitial ad
    if (_cardCounter >= 20 && _isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createInterstitialAd(); // Reload a new ad for future use
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createInterstitialAd(); // Reload a new ad if it fails to show
        },
      );
      _interstitialAd!.show();
      _cardCounter = 0; // Reset the counter after showing the ad
    }

    _cardAnimationController.forward().then((_) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      ).then((_) {
        _cardAnimationController.reset();
        setState(() => isNextCard = true);
      });
    });
  }


  Widget _buildAnimatedCard(Widget child) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Next Card Entrance
            Positioned.fill(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0)
                    .animate(_cardAnimationController),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _cardAnimationController,
                    curve: Curves.easeInOut,
                  )),
                  child: child,
                ),
              ),
            ),

            // Current Card Exit
            Positioned.fill(
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0)
                    .animate(_cardAnimationController),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(0.0, -0.5),
                  ).animate(CurvedAnimation(
                    parent: _cardAnimationController,
                    curve: Curves.easeInOut,
                  )),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return _buildAnimatedCard(
                FlipCardWidget(
                  onNextButtonPressed: _goToNextCard,
                  image: Image.asset(_selectedIcon),
                  term: _selectedTerm,
                  definition: _selectedDefinition,
                  generation: _selectedGeneration,
                  onFlip: (isFront) {
                    setState(() => isCardFront = isFront);
                  },
                ),
              );
            },
          ),
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: isCardFront ? Colors.black : Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Ads
  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-2326982552327072/8228863861', // Use the test ad unit ID during development
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

}
