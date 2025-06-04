// lib/home_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/tutorial_cutout_clipper.dart';
import 'game_button.dart';
import 'menu_screen.dart';
import 'level_screen.dart';
import '../data/globals.dart';

enum HomeScreenTutorialStep {
  none,
  welcome,
  basics,
  howToPlay,
  startGameButton,
  menuButton,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _screenEntryAnimationController;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  Animation<double>? _borderAnimation;
  Animation<double>? _shadowBlurAnimation;
  Animation<double>? _shadowSpreadAnimation;
  Animation<Offset>? _shadowOffsetAnimation;

  late AnimationController _buttonSlideOutController;
  late List<Animation<Offset>> _buttonSlideOutAnimations;
  bool _isButtonSlideOutAnimating = false;

  bool _isLoadingTutorialStatus = true;
  HomeScreenTutorialStep _currentHomeScreenTutorialStep = HomeScreenTutorialStep.none;
  bool _prefsForTutorialLoaded = false;
  bool _showCurrentImageTutorial = false;
  Timer? _welcomeTutorialDelayTimer;

  // New state variable for image expansion
  bool _isTutorialImageExpanded = false;

  AnimationController? _tutorialHintAnimationController;
  Animation<double>? _tutorialCircleScale;
  Animation<double>? _tutorialCircleOpacity;
  Animation<Offset>? _tutorialPointerOffset;
  Animation<double>? _tutorialTextOpacity;

  final GlobalKey _startGameButtonKey = GlobalKey();
  final GlobalKey _menuButtonKey = GlobalKey();
  final GlobalKey _homeScreenStackKey = GlobalKey();

  final Map<HomeScreenTutorialStep, String> _tutorialTexts = {
    HomeScreenTutorialStep.startGameButton: "Start a new game.",
    HomeScreenTutorialStep.menuButton: "Click the Menu to see more options.",
  };

  @override
  void initState() {
    super.initState();
    _screenEntryAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _positionAnimation = Tween<Offset>(begin: const Offset(0, 2), end: const Offset(0, 0)).animate(CurvedAnimation(parent: _screenEntryAnimationController, curve: Curves.decelerate));
    _rotationAnimation = Tween<double>(begin: 5 * pi, end: 0).animate(CurvedAnimation(parent: _screenEntryAnimationController, curve: Curves.decelerate));
    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _screenEntryAnimationController, curve: Curves.easeIn));
    _screenEntryAnimationController.forward();

    _buttonSlideOutController = AnimationController(duration: const Duration(milliseconds: 625), vsync: this);
    _buttonSlideOutAnimations = List.generate(2, (i) {
      double start = (i == 0) ? 0.0 : 0.25;
      double end = start + 0.5;
      return Tween<Offset>(begin: Offset.zero, end: const Offset(2.0, 0.0)).animate(CurvedAnimation(parent: _buttonSlideOutController, curve: Interval(start, end, curve: Curves.easeInOut)));
    });

    _initTutorialHintAnimations();
    _loadHomeScreenTutorialState();
  }

  void _initTutorialHintAnimations() {
    _tutorialHintAnimationController = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this);
    _tutorialCircleScale = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _tutorialHintAnimationController!, curve: const Interval(0.0, 0.7, curve: Curves.easeInOut)));
    _tutorialCircleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.7), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 45),
    ]).animate(CurvedAnimation(parent: _tutorialHintAnimationController!, curve: Curves.linear));
    _tutorialPointerOffset = Tween<Offset>(begin: const Offset(0, 5), end: const Offset(0, -5)).animate(CurvedAnimation(parent: _tutorialHintAnimationController!, curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic)));
    _tutorialTextOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
    ]).animate(_tutorialHintAnimationController!);
  }

  Future<void> _loadHomeScreenTutorialState() async {
    if (!mounted) return;
    bool seenWelcome = await getHasSeenWelcomeTutorial();
    bool seenBasics = await getHasSeenBasicsTutorial();
    bool seenHowToPlay = await getHasSeenHowToPlayTutorial();
    bool seenStartGameBtn = await getHasSeenStartGameButtonTutorial();
    bool seenMenuBtn = await getHasSeenMenuButtonTutorial();

    if (!mounted) return;
    _prefsForTutorialLoaded = true;

    HomeScreenTutorialStep initialStep = HomeScreenTutorialStep.none;
    if (!seenWelcome) initialStep = HomeScreenTutorialStep.welcome;
    else if (!seenBasics) initialStep = HomeScreenTutorialStep.basics;
    else if (!seenHowToPlay) initialStep = HomeScreenTutorialStep.howToPlay;
    else if (!seenStartGameBtn) initialStep = HomeScreenTutorialStep.startGameButton;
    else if (!seenMenuBtn) initialStep = HomeScreenTutorialStep.menuButton;

    setState(() {
      _currentHomeScreenTutorialStep = initialStep;
      _isLoadingTutorialStatus = false;
      _isTutorialImageExpanded = false; // Reset expansion state

      if (_currentHomeScreenTutorialStep == HomeScreenTutorialStep.welcome) {
        _showCurrentImageTutorial = false;
        _welcomeTutorialDelayTimer?.cancel();
        _welcomeTutorialDelayTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && _currentHomeScreenTutorialStep == HomeScreenTutorialStep.welcome) {
            setState(() { _showCurrentImageTutorial = true; });
          }
        });
      } else if (_currentHomeScreenTutorialStep == HomeScreenTutorialStep.basics ||
          _currentHomeScreenTutorialStep == HomeScreenTutorialStep.howToPlay) {
        _showCurrentImageTutorial = true;
      } else {
        _showCurrentImageTutorial = false;
      }

      if (_currentHomeScreenTutorialStep == HomeScreenTutorialStep.startGameButton ||
          _currentHomeScreenTutorialStep == HomeScreenTutorialStep.menuButton) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tutorialHintAnimationController?.repeat();
        });
      }
    });
  }

  void _advanceHomeScreenTutorial() async {
    if (!mounted) return;

    // Reset expansion state when advancing
    if (_isTutorialImageExpanded) {
      setState(() => _isTutorialImageExpanded = false);
    }

    HomeScreenTutorialStep nextStep = HomeScreenTutorialStep.none;

    switch (_currentHomeScreenTutorialStep) {
      case HomeScreenTutorialStep.welcome:
        await setHasSeenWelcomeTutorial(true);
        if (!await getHasSeenBasicsTutorial()) nextStep = HomeScreenTutorialStep.basics;
        else if (!await getHasSeenHowToPlayTutorial()) nextStep = HomeScreenTutorialStep.howToPlay;
        else if (!await getHasSeenStartGameButtonTutorial()) nextStep = HomeScreenTutorialStep.startGameButton;
        else if (!await getHasSeenMenuButtonTutorial()) nextStep = HomeScreenTutorialStep.menuButton;
        break;
      case HomeScreenTutorialStep.basics:
        await setHasSeenBasicsTutorial(true);
        if (!await getHasSeenHowToPlayTutorial()) nextStep = HomeScreenTutorialStep.howToPlay;
        else if (!await getHasSeenStartGameButtonTutorial()) nextStep = HomeScreenTutorialStep.startGameButton;
        else if (!await getHasSeenMenuButtonTutorial()) nextStep = HomeScreenTutorialStep.menuButton;
        break;
      case HomeScreenTutorialStep.howToPlay:
        await setHasSeenHowToPlayTutorial(true);
        if (!await getHasSeenStartGameButtonTutorial()) nextStep = HomeScreenTutorialStep.startGameButton;
        else if (!await getHasSeenMenuButtonTutorial()) nextStep = HomeScreenTutorialStep.menuButton;
        break;
      case HomeScreenTutorialStep.startGameButton:
        await setHasSeenStartGameButtonTutorial(true);
        if (!await getHasSeenMenuButtonTutorial()) nextStep = HomeScreenTutorialStep.menuButton;
        break;
      case HomeScreenTutorialStep.menuButton:
        await setHasSeenMenuButtonTutorial(true);
        nextStep = HomeScreenTutorialStep.none;
        break;
      case HomeScreenTutorialStep.none:
        return;
    }

    if (!mounted) return;

    setState(() {
      _currentHomeScreenTutorialStep = nextStep;
      _welcomeTutorialDelayTimer?.cancel();
      _isTutorialImageExpanded = false; // Ensure expansion is reset

      if (_currentHomeScreenTutorialStep == HomeScreenTutorialStep.basics ||
          _currentHomeScreenTutorialStep == HomeScreenTutorialStep.howToPlay) {
        _showCurrentImageTutorial = true;
      } else {
        _showCurrentImageTutorial = false;
      }

      if (_currentHomeScreenTutorialStep == HomeScreenTutorialStep.startGameButton ||
          _currentHomeScreenTutorialStep == HomeScreenTutorialStep.menuButton) {
        _tutorialHintAnimationController?.reset();
        _tutorialHintAnimationController?.repeat();
      } else {
        _tutorialHintAnimationController?.stop();
        _tutorialHintAnimationController?.reset();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_borderAnimation == null) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final smallestDimension = min(screenWidth, screenHeight);
      _borderAnimation = Tween<double>(begin: smallestDimension * 0.02, end: smallestDimension * 0.0075).animate(CurvedAnimation(parent: _screenEntryAnimationController, curve: Curves.easeOut));
      _shadowBlurAnimation = Tween<double>(begin: smallestDimension * 0.05, end: smallestDimension * 0.0375).animate(CurvedAnimation(parent: _screenEntryAnimationController, curve: Curves.easeOut));
      _shadowSpreadAnimation = Tween<double>(begin: smallestDimension * 0.02, end: smallestDimension * 0.0125).animate(CurvedAnimation(parent: _screenEntryAnimationController, curve: Curves.easeOut));
      _shadowOffsetAnimation = Tween<Offset>(begin: Offset(0, smallestDimension * 0.035), end: Offset(0, smallestDimension * 0.025)).animate(CurvedAnimation(parent: _screenEntryAnimationController, curve: Curves.easeOut));
    }
  }

  @override
  void dispose() {
    _screenEntryAnimationController.dispose();
    _buttonSlideOutController.dispose();
    _tutorialHintAnimationController?.dispose();
    _welcomeTutorialDelayTimer?.cancel();
    super.dispose();
  }

  void _triggerButtonSlideOutAndNavigate(VoidCallback navigateAction) {
    if (_isButtonSlideOutAnimating) return;
    if (!mounted) return;
    setState(() { _isButtonSlideOutAnimating = true; });
    _buttonSlideOutController.forward().then((_) {
      if (mounted) { navigateAction(); }
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _buttonSlideOutController.reset();
            setState(() { _isButtonSlideOutAnimating = false; });
          }
        });
      } else {
        _buttonSlideOutController.reset();
        _isButtonSlideOutAnimating = false;
      }
    });
  }

  Future<void> _playUiClickSound() async {
    if (await getSoundEnabled()) {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/click.mp3'));
    }
  }

  void _onGameOrMenuButtonPressed(VoidCallback navigateAction, HomeScreenTutorialStep buttonTutorialStep) async {
    if (_currentHomeScreenTutorialStep != HomeScreenTutorialStep.none) {
      if (_currentHomeScreenTutorialStep == buttonTutorialStep) {
        _advanceHomeScreenTutorial();
      }
      return;
    }
    await _playUiClickSound();
    _triggerButtonSlideOutAndNavigate(navigateAction);
  }

  Widget _buildAnimatedButton(
      String text, VoidCallback onPressedAction, int index,
      {required GlobalKey key, required HomeScreenTutorialStep tutorialStepTarget}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const maxButtonWidth = 400.0;
    final buttonWidth = min(screenWidth * 0.7, maxButtonWidth);
    final buttonHeight = screenHeight * 0.075;
    final double fontSize = buttonHeight * 0.3;

    bool isThisButtonTutorialTarget = _currentHomeScreenTutorialStep == tutorialStepTarget;
    bool isAnyTutorialActive = _currentHomeScreenTutorialStep != HomeScreenTutorialStep.none;
    final bool effectivelyDisabled = _isButtonSlideOutAnimating || (isAnyTutorialActive && !isThisButtonTutorialTarget);

    return SlideTransition(
        key: key, position: _buttonSlideOutAnimations[index],
        child: GameButton(text: text, width: buttonWidth, height: buttonHeight,
            onPressed: effectivelyDisabled ? null : () => _onGameOrMenuButtonPressed(onPressedAction, tutorialStepTarget),
            isBold: true, fontSize: fontSize));
  }

  Widget _buildImageBasedTutorialLayout({ required String title, String? assetPath, Widget? customContent}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final overlayWidth = screenWidth * 0.9;
    final overlayMaxHeight = screenHeight * 0.8;
    final imageMaxHeight = overlayMaxHeight * 0.6;
    final imageMaxWidth = overlayWidth * 0.9;

    Widget? imageWidget;
    if (assetPath != null) {
      Widget rawImage = assetPath.toLowerCase().endsWith('.svg')
          ? SvgPicture.asset(assetPath, fit: BoxFit.contain, placeholderBuilder: (_) => Center(child: CircularProgressIndicator(color: Colors.blue)))
          : Image.asset(assetPath, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.error_outline, color: Colors.red, size: 40)));

      imageWidget = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: imageMaxWidth, maxHeight: imageMaxHeight),
        child: GestureDetector(
          onTap: () => setState(() => _isTutorialImageExpanded = true),
          child: rawImage,
        ),
      );
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Material(
            elevation: 10.0,
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
            child: Container(
              width: overlayWidth,
              constraints: BoxConstraints(maxHeight: overlayMaxHeight, minWidth: 300),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: _isTutorialImageExpanded
                  ? Stack(
                children: [
                  Positioned.fill(
                    child: customContent ?? imageWidget ?? const SizedBox(),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 30),
                      onPressed: () => setState(() => _isTutorialImageExpanded = false),
                    ),
                  ),
                ],
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: SingleChildScrollView(
                      child: customContent ?? imageWidget ?? const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _advanceHomeScreenTutorial,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.black, width: 1.5),
                      ),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Next"),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeLayoutWidget() => _buildImageBasedTutorialLayout(
    title: "Welcome to",
    customContent: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
            "SLANG THAT THANG!!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.2)),
        const SizedBox(height: 20),
        Text(
            "Get ready to test your slang knowledge!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.black87)),
      ],
    ),
  );

  Widget _buildBasicsObjectiveLayoutWidget() => _buildImageBasedTutorialLayout(
    title: "Basics & Objectives",
    assetPath: 'assets/images/basics-objectives-tutorial.svg',
  );

  Widget _buildHowToPlayLayoutWidget() => _buildImageBasedTutorialLayout(
    title: "How to Play",
    assetPath: 'assets/images/tutorial-how-to-play.svg',
  );

  Widget _buildButtonHighlightTutorialOverlayWidget() {
    if (_tutorialHintAnimationController == null || _currentHomeScreenTutorialStep == HomeScreenTutorialStep.none ||
        _currentHomeScreenTutorialStep == HomeScreenTutorialStep.welcome || _currentHomeScreenTutorialStep == HomeScreenTutorialStep.basics ||
        _currentHomeScreenTutorialStep == HomeScreenTutorialStep.howToPlay) {
      return const SizedBox.shrink();
    }
    GlobalKey? currentTargetKey;
    switch (_currentHomeScreenTutorialStep) {
      case HomeScreenTutorialStep.startGameButton: currentTargetKey = _startGameButtonKey; break;
      case HomeScreenTutorialStep.menuButton: currentTargetKey = _menuButtonKey; break;
      default: return const SizedBox.shrink();
    }
    if (currentTargetKey.currentContext == null || _homeScreenStackKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() {}); });
      return Positioned.fill(child: Container(color: Colors.black.withOpacity(0.8), child: Center(child: Text("Initializing tutorial...", style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 16)))));
    }
    final RenderBox? targetRenderBox = currentTargetKey.currentContext!.findRenderObject() as RenderBox?;
    final RenderBox? ancestorRenderBox = _homeScreenStackKey.currentContext!.findRenderObject() as RenderBox?;
    if (targetRenderBox == null || !targetRenderBox.attached || ancestorRenderBox == null || !ancestorRenderBox.attached) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() {}); });
      return Positioned.fill(child: Container(color: Colors.black.withOpacity(0.8), child: Center(child: Text("Waiting for layout...", style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 16)))));
    }
    final Offset targetPositionInStack = targetRenderBox.localToGlobal(Offset.zero, ancestor: ancestorRenderBox);
    final Size targetSize = targetRenderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double scaleFactor = screenWidth / 400;
    final double hintTextFontSize = 16 * scaleFactor;
    final double spotlightBorderWidth = 2.5 * scaleFactor;
    final Offset targetCenter = Offset(targetPositionInStack.dx + targetSize.width / 2, targetPositionInStack.dy + targetSize.height / 2);
    final double hintPaddingHorizontal = 12 * scaleFactor;
    final double hintPaddingVertical = 8 * scaleFactor;
    final double hintTextContainerBorderWidth = 1.0 * scaleFactor;
    final double hintContainerCornerRadius = 8.0 * scaleFactor;
    bool pointUpwards = targetCenter.dy > screenHeight * 0.65;
    if (_currentHomeScreenTutorialStep == HomeScreenTutorialStep.menuButton && targetCenter.dy > screenHeight * 0.75) pointUpwards = true;
    double estimatedTextHeight = (_tutorialTexts[_currentHomeScreenTutorialStep] ?? "").length > 30 ? hintTextFontSize * 3.0 : hintTextFontSize * 1.8;
    double estimatedHintBlockHeight = estimatedTextHeight + (hintPaddingVertical * 2);
    double verticalOffsetSpacing = 15 * scaleFactor;
    double hintBlockVerticalOffsetFromTargetCenter = pointUpwards ? -(targetSize.height / 2 + estimatedHintBlockHeight * 0.5 + verticalOffsetSpacing) : (targetSize.height / 2 + verticalOffsetSpacing);
    double initialHintBlockTopPosition = targetCenter.dy + hintBlockVerticalOffsetFromTargetCenter;
    final double topSafeArea = MediaQuery.of(context).padding.top + (10 * scaleFactor);
    final double bottomSafeArea = screenHeight - MediaQuery.of(context).padding.bottom - (10 * scaleFactor);

    return Positioned.fill(
        child: GestureDetector(onTap: _advanceHomeScreenTutorial,
            child: AnimatedBuilder(animation: Listenable.merge([_tutorialHintAnimationController!, _tutorialPointerOffset!]),
                builder: (context, child) {
                  final double currentAnimatedScale = _tutorialCircleScale!.value;
                  final double animatedHighlightWidth = targetSize.width * currentAnimatedScale;
                  final double animatedHighlightHeight = targetSize.height * currentAnimatedScale;
                  final BorderRadius animatedHighlightBorderRadius = BorderRadius.circular(min(animatedHighlightHeight * 0.15, 12.0 * currentAnimatedScale));
                  final Rect cutoutRect = Rect.fromCenter(center: targetCenter, width: animatedHighlightWidth, height: animatedHighlightHeight);
                  double currentHintBlockTopPosition = initialHintBlockTopPosition + _tutorialPointerOffset!.value.dy;
                  if (currentHintBlockTopPosition < topSafeArea) currentHintBlockTopPosition = topSafeArea;
                  else if (currentHintBlockTopPosition + estimatedHintBlockHeight > bottomSafeArea) {
                    if (!pointUpwards && (targetCenter.dy - targetSize.height / 2 - estimatedHintBlockHeight - verticalOffsetSpacing) > topSafeArea) {
                      double newHintBlockVerticalOffset = -(targetSize.height / 2 + estimatedHintBlockHeight * 0.5 + verticalOffsetSpacing);
                      currentHintBlockTopPosition = targetCenter.dy + newHintBlockVerticalOffset + _tutorialPointerOffset!.value.dy;
                      if (currentHintBlockTopPosition < topSafeArea) currentHintBlockTopPosition = topSafeArea;
                    } else { currentHintBlockTopPosition = bottomSafeArea - estimatedHintBlockHeight; }}
                  if (currentHintBlockTopPosition < topSafeArea) currentHintBlockTopPosition = topSafeArea;
                  return Stack(children: [
                    ClipPath(clipper: TutorialCutoutClipper(rect: cutoutRect, borderRadius: animatedHighlightBorderRadius, isCircular: false), child: Container(color: Colors.black.withOpacity(0.85))),
                    Positioned(left: cutoutRect.left, top: cutoutRect.top, child: Opacity(opacity: _tutorialCircleOpacity!.value, child: Container(width: cutoutRect.width, height: cutoutRect.height, decoration: BoxDecoration(borderRadius: animatedHighlightBorderRadius, border: Border.all(color: Colors.white.withOpacity(0.9), width: spotlightBorderWidth))))),
                    Positioned(left: 20 * scaleFactor, right: 20 * scaleFactor, top: currentHintBlockTopPosition, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [ Opacity(opacity: _tutorialTextOpacity!.value, child: Container(padding: EdgeInsets.symmetric(horizontal: hintPaddingHorizontal, vertical: hintPaddingVertical), decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(hintContainerCornerRadius), border: Border.all(color: Colors.white70, width: hintTextContainerBorderWidth)), child: Text(_tutorialTexts[_currentHomeScreenTutorialStep] ?? "Hint", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: hintTextFontSize, fontWeight: FontWeight.w500, decoration: TextDecoration.none))))]))]);
                })));
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsForTutorialLoaded && _isLoadingTutorialStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Widget? currentImageTutorialWidgetToShow;
    if ((_currentHomeScreenTutorialStep == HomeScreenTutorialStep.welcome ||
        _currentHomeScreenTutorialStep == HomeScreenTutorialStep.basics ||
        _currentHomeScreenTutorialStep == HomeScreenTutorialStep.howToPlay) &&
        _showCurrentImageTutorial) {
      switch (_currentHomeScreenTutorialStep) {
        case HomeScreenTutorialStep.welcome: currentImageTutorialWidgetToShow = _buildWelcomeLayoutWidget(); break;
        case HomeScreenTutorialStep.basics: currentImageTutorialWidgetToShow = _buildBasicsObjectiveLayoutWidget(); break;
        case HomeScreenTutorialStep.howToPlay: currentImageTutorialWidgetToShow = _buildHowToPlayLayoutWidget(); break;
        default: break;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final svgHeight = screenHeight * 0.50;
    final topSpacerHeight = screenHeight * 0.05;
    final midSpacerHeight = screenHeight * 0.10;
    final buttonSpacerHeight = screenHeight * 0.02;

    return Scaffold(
      body: Stack(
        key: _homeScreenStackKey,
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_screenEntryAnimationController, if (_borderAnimation != null) _borderAnimation!, if (_shadowBlurAnimation != null) _shadowBlurAnimation!, if (_shadowSpreadAnimation != null) _shadowSpreadAnimation!, if (_shadowOffsetAnimation != null) _shadowOffsetAnimation!]),
                builder: (context, child) {
                  return Transform.translate(offset: _positionAnimation.value * screenHeight / 3,
                      child: Transform.rotate(angle: _rotationAnimation.value,
                          child: Transform.scale(scale: _scaleAnimation.value,
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.black,
                                      border: Border.all(color: Colors.black, width: _borderAnimation?.value ?? (min(screenWidth, screenHeight) * 0.0075)),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: _shadowBlurAnimation?.value ?? (min(screenWidth, screenHeight) * 0.0375), spreadRadius: _shadowSpreadAnimation?.value ?? (min(screenWidth, screenHeight) * 0.0125), offset: _shadowOffsetAnimation?.value ?? Offset(0, min(screenWidth, screenHeight) * 0.025))]),
                                  child: child))));
                },
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: topSpacerHeight),
                      Center(child: SvgPicture.asset('assets/images/main_icon_crop.svg', height: svgHeight, fit: BoxFit.contain)),
                      SizedBox(height: midSpacerHeight),
                      Center(
                        child: Column(
                          children: [
                            _buildAnimatedButton("Start Game", () {
                              if (mounted) {
                                _welcomeTutorialDelayTimer?.cancel();
                                Navigator.push(context, MaterialPageRoute(builder: (context) => LevelScreen()));
                              }
                            }, 0, key: _startGameButtonKey, tutorialStepTarget: HomeScreenTutorialStep.startGameButton),
                            SizedBox(height: buttonSpacerHeight),
                            _buildAnimatedButton("Menu", () {
                              if (mounted) {
                                _welcomeTutorialDelayTimer?.cancel();
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuScreen()));
                              }
                            }, 1, key: _menuButtonKey, tutorialStepTarget: HomeScreenTutorialStep.menuButton),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (currentImageTutorialWidgetToShow != null) currentImageTutorialWidgetToShow,
          _buildButtonHighlightTutorialOverlayWidget(),
        ],
      ),
    );
  }
}