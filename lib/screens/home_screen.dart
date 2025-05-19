import 'dart:async'; // For Timer
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game_button.dart'; // Ensure this path is correct
import 'menu_screen.dart';   // Ensure this path is correct
import 'level_screen.dart';  // Ensure this path is correct
// Adjust this import path if your globals.dart is located elsewhere
import '../data/globals.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _screenController;
  late AnimationController _buttonController;
  late List<Animation<Offset>> _buttonAnimations;
  bool _isAnimating = false;

  // Late initialized variables for animations
  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  Animation<double>? _borderAnimation; // Nullable, initialized in didChangeDependencies
  Animation<double>? _shadowBlurAnimation;
  Animation<double>? _shadowSpreadAnimation;
  Animation<Offset>? _shadowOffsetAnimation;


  // Tutorial State
  bool _isLoadingTutorialStatus = true;
  bool _showGenerationsTutorialOverlay = false;
  bool _showMenuHint = false;
  bool _prefsLoaded = false;

  Timer? _menuHintTimer;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 625),
      vsync: this,
    );

    _buttonAnimations = List.generate(2, (i) {
      double start = 0.0;
      double end = 0.5;
      if (i == 0) {
        start = i * 0.5;
        end = start + 0.5;
      } else {
        start = (i - 1) * 0.5 + 0.25;
        end = start + 0.5;
      }
      return Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(2.0, 0.0),
      ).animate(
        CurvedAnimation(
          parent: _buttonController,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });

    _screenController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _positionAnimation = Tween<Offset>(
      begin: const Offset(0, 2),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _screenController,
      curve: Curves.decelerate,
    ));

    _rotationAnimation = Tween<double>(
      begin: 5 * pi,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _screenController,
      curve: Curves.decelerate,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _screenController,
      curve: Curves.easeIn,
    ));

    // Animations dependent on MediaQuery are initialized in didChangeDependencies
    // Start the main screen animation
    _screenController.forward();
    _loadTutorialState();
  }

  Future<void> _loadTutorialState() async {
    if (!mounted) return;
    bool seenGenTutorial = await getHasSeenGenerationsTutorial();
    bool seenMenuHintFlag = await getHasSeenMenuHint();

    if (!mounted) return; // Check mounted again after async gap
    _prefsLoaded = true;

    setState(() {
      if (!seenGenTutorial) {
        _showGenerationsTutorialOverlay = true;
      } else if (!seenMenuHintFlag) {
        _showMenuHint = true;
        // Mark as seen immediately since we are about to show it and it auto-hides
        setHasSeenMenuHint(true);
        _startMenuHintTimer();
      }
      _isLoadingTutorialStatus = false;
    });
  }

  void _startMenuHintTimer() {
    _menuHintTimer?.cancel();
    _menuHintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && _showMenuHint) {
        setState(() {
          _showMenuHint = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize MediaQuery-dependent animations only if they haven't been initialized
    if (_borderAnimation == null) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final smallestDimension = min(screenWidth, screenHeight);

      _borderAnimation = Tween<double>(
        begin: smallestDimension * 0.02,
        end: smallestDimension * 0.0075,
      ).animate(CurvedAnimation(
        parent: _screenController,
        curve: Curves.easeOut,
      ));

      _shadowBlurAnimation = Tween<double>(
        begin: smallestDimension * 0.05,
        end: smallestDimension * 0.0375,
      ).animate(CurvedAnimation(parent: _screenController, curve: Curves.easeOut));

      _shadowSpreadAnimation = Tween<double>(
        begin: smallestDimension * 0.02,
        end: smallestDimension * 0.0125,
      ).animate(CurvedAnimation(parent: _screenController, curve: Curves.easeOut));

      _shadowOffsetAnimation = Tween<Offset>(
        begin: Offset(0, smallestDimension * 0.035),
        end: Offset(0, smallestDimension * 0.025),
      ).animate(CurvedAnimation(parent: _screenController, curve: Curves.easeOut));
    }
  }

  @override
  void dispose() {
    _screenController.dispose();
    _buttonController.dispose();
    _menuHintTimer?.cancel();
    super.dispose();
  }

  void _animateButtonsAndNavigate(VoidCallback navigate) {
    if (_isAnimating) return;
    if (!mounted) return;
    setState(() {
      _isAnimating = true;
    });
    _buttonController.forward().then((_) {
      if (mounted) {
        navigate();
      }
    });
  }

  Future<void> _playUiClickSound() async {
    if (await getSoundEnabled()) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource('audio/click.mp3'));
    }
  }

  void _onHomeButtonPressed(VoidCallback navigate) async {
    await _playUiClickSound();
    _animateButtonsAndNavigate(navigate);
  }

  Widget _buildAnimatedButton(String text, VoidCallback onPressed, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const maxButtonWidth = 400.0;
    final buttonWidth = min(screenWidth * 0.7, maxButtonWidth);
    final buttonHeight = screenHeight * 0.075;
    final double fontSize = buttonHeight * 0.3;

    return SlideTransition(
      position: _buttonAnimations[index],
      child: GameButton(
        text: text,
        width: buttonWidth,
        height: buttonHeight,
        onPressed: _isAnimating || _showGenerationsTutorialOverlay ? null : onPressed, // Disable buttons during tutorial
        isBold: true,
        fontSize: fontSize,
      ),
    );
  }

  Widget _buildGenerationsTutorialOverlayWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final overlayWidth = screenWidth * 0.85;
    final overlayMaxHeight = screenHeight * 0.7;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              width: overlayWidth,
              constraints: BoxConstraints(
                maxHeight: overlayMaxHeight,
                minWidth: 280,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.black54),
                        tooltip: 'Close Tutorial',
                        onPressed: () async {
                          if (!mounted) return;
                          await setHasSeenGenerationsTutorial(true);
                          setState(() {
                            _showGenerationsTutorialOverlay = false;
                          });
                          // Check if menu hint should be shown next
                          bool seenMenuHintFlag = await getHasSeenMenuHint();
                          if (!mounted) return;
                          if (!seenMenuHintFlag) {
                            setState(() {
                              _showMenuHint = true;
                            });
                            await setHasSeenMenuHint(true);
                            _startMenuHintTimer();
                          }
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                      child: SvgPicture.asset(
                        'assets/images/generations.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Welcome! This explains the different generations featured in the game.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuHintWidget() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Estimate Menu button position. For more accuracy, use GlobalKey on the Menu button.
    double approximateMenuButtonTop = screenHeight * 0.50 + // SVG
        screenHeight * 0.05 +  // topSpacer
        screenHeight * 0.10 +  // midSpacer
        screenHeight * 0.075 + // Start Game button height
        screenHeight * 0.02;   // Spacer between buttons
    double menuButtonCenterY = approximateMenuButtonTop + (screenHeight * 0.075 / 2);

    return Positioned(
      top: menuButtonCenterY - 110, // Position above the Menu button
      left: screenWidth * 0.15,  // Centered more or less
      right: screenWidth * 0.15,
      child: Material(
        color: Colors.transparent,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blueGrey[800]?.withOpacity(0.95),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Explore more options in the Menu!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator only if prefs not loaded AND still in loading tutorial state
    if (!_prefsLoaded && _isLoadingTutorialStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final svgHeight = screenHeight * 0.50;
    final topSpacerHeight = screenHeight * 0.05;
    final midSpacerHeight = screenHeight * 0.10;
    final buttonSpacerHeight = screenHeight * 0.02;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _screenController,
                  if (_borderAnimation != null) _borderAnimation!, // Ensure not null before adding
                  if (_shadowBlurAnimation != null) _shadowBlurAnimation!,
                  if (_shadowSpreadAnimation != null) _shadowSpreadAnimation!,
                  if (_shadowOffsetAnimation != null) _shadowOffsetAnimation!,
                ]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: _positionAnimation.value * screenHeight / 3,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: Colors.black,
                              width: _borderAnimation?.value ?? (min(screenWidth, screenHeight) * 0.0075), // Provide default if null
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: _shadowBlurAnimation?.value ?? (min(screenWidth, screenHeight) * 0.0375),
                                spreadRadius: _shadowSpreadAnimation?.value ?? (min(screenWidth, screenHeight) * 0.0125),
                                offset: _shadowOffsetAnimation?.value ?? Offset(0, min(screenWidth, screenHeight) * 0.025),
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: topSpacerHeight),
                      Center(
                        child: SvgPicture.asset(
                          'assets/images/main_icon_crop.svg',
                          height: svgHeight,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: midSpacerHeight),
                      Center(
                        child: Column(
                          children: [
                            _buildAnimatedButton("Start Game", () {
                              _onHomeButtonPressed(() {
                                if (mounted) {
                                  _menuHintTimer?.cancel();
                                  if(_showMenuHint) setState(() {_showMenuHint = false;});
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => LevelScreen()),
                                  ).then((_) {
                                    if (mounted) {
                                      _buttonController.reset();
                                      setState(() { _isAnimating = false; });
                                    }
                                  });
                                }
                              });
                            }, 0),
                            SizedBox(height: buttonSpacerHeight),
                            _buildAnimatedButton("Menu", () {
                              _onHomeButtonPressed(() {
                                if (mounted) {
                                  _menuHintTimer?.cancel();
                                  if(_showMenuHint) setState(() {_showMenuHint = false;});
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const MenuScreen()),
                                  ).then((_) {
                                    if (mounted) {
                                      _buttonController.reset();
                                      setState(() { _isAnimating = false; });
                                    }
                                  });
                                }
                              });
                            }, 1),
                          ],
                        ),
                      ),
                      const Spacer(), // Pushes buttons up if content is short
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tutorial Overlays
          if (_showGenerationsTutorialOverlay)
            _buildGenerationsTutorialOverlayWidget(),

          if (_showMenuHint)
            _buildMenuHintWidget(),
        ],
      ),
    );
  }
}