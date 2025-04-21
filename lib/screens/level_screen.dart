import 'dart:io';
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
  // Randomizer & controllers
  final Random _random = Random();
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _cardAnimationController;

  // Card data
  late String _selectedGeneration;
  late String _selectedTerm;
  late String _selectedDefinition;
  late String _selectedIcon;

  bool isNextCard = true;
  bool isCardFront = true;

  // Ad state
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _adsRemoved = false;
  int _cardCounter = 0;

  // Sound
  bool isSoundEnabled = true;

  /// Returns correct Ad Unit ID per platform
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
    _getRandomTerm();
    // load prefs
    getSoundEnabled().then((v) => isSoundEnabled = v);
    getAdsRemovedStatus().then((v) {
      _adsRemoved = v;
      if (!_adsRemoved && _adUnitId.isNotEmpty) {
        _createInterstitialAd();
      }
    });
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
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
    final generations = termsData.keys.toList();
    _selectedGeneration = generations[_random.nextInt(generations.length)];
    final termList = termsData[_selectedGeneration]!;
    final term = termList[_random.nextInt(termList.length)];
    setState(() {
      _selectedTerm = term['term']!;
      _selectedDefinition = term['definition']!;
      _selectedIcon = generationIcons[_selectedGeneration] ?? '';
    });
  }

  Future<void> _loadAndPlayAudio() async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audio/next_card.mp3'));
  }

  void _onPageChanged(int index) {
    _getRandomTerm();
  }

  void _goToNextCard() {
    if (isSoundEnabled) _loadAndPlayAudio();
    _cardCounter++;

    // Show ad every 20 cards if not removed
    if (!_adsRemoved && _cardCounter >= 20 && _isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _createInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _cardCounter = 0;
    }

    _cardAnimationController.forward().then((_) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 1),
          curve: Curves.linear,
        ).then((_) {
          _cardAnimationController.reset();
          if (mounted) setState(() {});
        });
      }
    });
  }

  Widget _buildAnimatedCard(Widget child) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(_cardAnimationController),
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0,1), end: Offset.zero)
                      .animate(CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeInOut)),
                  child: child,
                ),
              ),
            ),
            Positioned.fill(
              child: FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0).animate(_cardAnimationController),
                child: SlideTransition(
                  position: Tween<Offset>(begin: Offset.zero, end: const Offset(0,-0.5))
                      .animate(CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeInOut)),
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
      backgroundColor: Colors.transparent,
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
                icon: Icon(Icons.arrow_back, color: isCardFront ? Colors.black : Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
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
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Ad load failed: $error');
        },
      ),
    );
  }
}
