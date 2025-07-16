import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:test2/widgets/tutorial_cutout_clipper.dart';


import '../data/globals.dart';
import 'card_back.dart';
import 'card_front.dart';

enum CardTutorialOverallStep {
  none,
  frontTerm,
  frontTapToFlip,
  backNextButton,
}

class FlipCardWidget extends StatefulWidget {
  const FlipCardWidget({
    super.key,
    required this.term,
    required this.definition,
    required this.image,
    required this.generation,
    required this.onNextButtonPressed,
    this.onPreviousButtonPressed,
    this.onFlip,
    // this.onHistoryIconPressed, // REMOVED: History icon moved to LevelScreen
  });

  final VoidCallback onNextButtonPressed;
  final VoidCallback? onPreviousButtonPressed;
  // final VoidCallback? onHistoryIconPressed; // REMOVED
  final Image image;
  final String generation;
  final String term;
  final String definition;
  final Function(bool isFront)? onFlip;

  @override
  FlipCardWidgetState createState() => FlipCardWidgetState();
}

class FlipCardWidgetState extends State<FlipCardWidget> with TickerProviderStateMixin {
  final FlipCardController _flipCardController = FlipCardController();
  final Duration _flipDuration = const Duration(milliseconds: 400);
  final Duration _postFlipSettleDelay = const Duration(milliseconds: 150);

  bool _isFront = true;
  bool _isFlipping = false;
  bool _prefsLoaded = false;

  CardTutorialOverallStep _currentCardTutorialStep = CardTutorialOverallStep.none;
  AnimationController? _cardTutorialAnimationController;
  Animation<double>? _tutorialCircleScale;
  Animation<double>? _tutorialCircleOpacity;
  Animation<Offset>? _tutorialPointerOffset;
  Animation<double>? _tutorialTextOpacity;

  final GlobalKey _nextButtonKeyOnBackCard = GlobalKey();
  final GlobalKey _previousButtonKeyOnBackCard = GlobalKey();
  final GlobalKey _flipCardStackKey = GlobalKey();

  Rect? _targetButtonRect;
  Size? _lastKnownScreenSize;

  final AudioPlayer _audioPlayer = AudioPlayer();

  final Map<CardTutorialOverallStep, String> _cardTutorialTexts = {
    CardTutorialOverallStep.backNextButton: "To move on to the next card, click the 'Next' button.",
  };

  @override
  void initState() {
    super.initState();
    _loadInitialPrefsAndTutorialState();
    _initCardTutorialAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _lastKnownScreenSize = MediaQuery.of(context).size;
        _updateTargetButtonRectIfNeeded();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newScreenSize = MediaQuery.of(context).size;
    if (_lastKnownScreenSize != null && _lastKnownScreenSize != newScreenSize) {
      _lastKnownScreenSize = newScreenSize;
      if (_currentCardTutorialStep == CardTutorialOverallStep.backNextButton && !_isFront) {
        if (mounted) {
          setState(() { _targetButtonRect = null; });
          _updateTargetButtonRectIfNeeded();
        }
      }
    } else if (_lastKnownScreenSize == null && mounted) {
      _lastKnownScreenSize = newScreenSize;
    }
  }

  Future<void> _loadInitialPrefsAndTutorialState() async {
    CardTutorialOverallStep initialStep = CardTutorialOverallStep.none;

    if (!await getHasSeenCardFrontTermTutorial()) {
      initialStep = CardTutorialOverallStep.frontTerm;
    } else if (!await getHasSeenCardFrontTapToFlipTutorial()) {
      initialStep = CardTutorialOverallStep.frontTapToFlip;
    } else if (!_isFront && !await getHasSeenCardBackNextButtonTutorial()) {
      initialStep = CardTutorialOverallStep.backNextButton;
    }

    if (!mounted) return;
    setState(() {
      _currentCardTutorialStep = initialStep;
      _prefsLoaded = true;
    });

    if (_currentCardTutorialStep == CardTutorialOverallStep.backNextButton && !_isFront) {
      _updateTargetButtonRectIfNeeded();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _targetButtonRect != null) {
          _cardTutorialAnimationController?.reset();
          _cardTutorialAnimationController?.repeat();
        } else if (mounted) {
          _cardTutorialAnimationController?.reset();
        }
      });
    }
  }

  void _initCardTutorialAnimations() {
    _cardTutorialAnimationController?.dispose();
    _cardTutorialAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    final clampedCardTutorialController = ClampedAnimationDecorator(_cardTutorialAnimationController!);
    final curvedCardTutorialParentLinear = CurvedAnimation(parent: _cardTutorialAnimationController!, curve: Curves.linear);
    final clampedCurvedCardTutorialParentLinear = ClampedAnimationDecorator(curvedCardTutorialParentLinear);
    _tutorialCircleScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _cardTutorialAnimationController!, curve: const Interval(0.0, 0.7, curve: Curves.easeInOut)),
    );
    _tutorialCircleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.7), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 45),
    ]).animate(clampedCurvedCardTutorialParentLinear);
    _tutorialPointerOffset = Tween<Offset>(begin: const Offset(0, 5), end: const Offset(0, -5)).animate(
      CurvedAnimation(parent: _cardTutorialAnimationController!, curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic)),
    );
    _tutorialTextOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
    ]).animate(clampedCardTutorialController);
  }

  void _updateTargetButtonRectIfNeeded() {
    if (_currentCardTutorialStep == CardTutorialOverallStep.backNextButton && !_isFront) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final targetContext = _nextButtonKeyOnBackCard.currentContext;
        final stackContext = _flipCardStackKey.currentContext;
        if (targetContext != null && stackContext != null) {
          final targetRenderBox = targetContext.findRenderObject() as RenderBox?;
          final ancestorRenderBox = stackContext.findRenderObject() as RenderBox?;
          if (targetRenderBox != null && targetRenderBox.attached &&
              ancestorRenderBox != null && ancestorRenderBox.attached) {
            try {
              final position = targetRenderBox.localToGlobal(Offset.zero, ancestor: ancestorRenderBox);
              final size = targetRenderBox.size;
              final newRect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
              if (_targetButtonRect != newRect) {
                setState(() { _targetButtonRect = newRect; });
              }
              if (_targetButtonRect != null && _cardTutorialAnimationController != null &&
                  !_cardTutorialAnimationController!.isAnimating) {
                _cardTutorialAnimationController!.reset();
                _cardTutorialAnimationController!.repeat();
              }
            } catch (e) {
              if (mounted && _targetButtonRect != null) {
                setState(() => _targetButtonRect = null);
              }
            }
            return;
          }
        }
        if (_targetButtonRect != null) setState(() => _targetButtonRect = null);
        _cardTutorialAnimationController?.reset();
      });
    } else if (_targetButtonRect != null) {
      setState(() { _targetButtonRect = null; });
      if (_cardTutorialAnimationController?.isAnimating ?? false) {
        _cardTutorialAnimationController?.stop();
        _cardTutorialAnimationController?.reset();
      }
    }
  }

  void _handleCardFrontTutorialStepChange(CardFrontTutorialStep frontStep) async {
    if (!mounted) return;
    CardTutorialOverallStep nextOverallStep = _currentCardTutorialStep;

    if (frontStep == CardFrontTutorialStep.none) {
      bool termDone = await getHasSeenCardFrontTermTutorial();
      bool flipDone = await getHasSeenCardFrontTapToFlipTutorial();

      if(termDone && flipDone){
        nextOverallStep = CardTutorialOverallStep.none;
      } else {
        if (!termDone) nextOverallStep = CardTutorialOverallStep.frontTerm;
        else if (!flipDone) nextOverallStep = CardTutorialOverallStep.frontTapToFlip;
        else nextOverallStep = CardTutorialOverallStep.none;
      }
    } else {
      switch (frontStep) {
        case CardFrontTutorialStep.term: nextOverallStep = CardTutorialOverallStep.frontTerm; break;
        case CardFrontTutorialStep.tapToFlip: nextOverallStep = CardTutorialOverallStep.frontTapToFlip; break;
        case CardFrontTutorialStep.none: break;
      }
    }

    bool stepChanged = _currentCardTutorialStep != nextOverallStep;
    if (stepChanged) {
      setState(() {
        _currentCardTutorialStep = nextOverallStep;
        if (nextOverallStep != CardTutorialOverallStep.backNextButton) {
          _cardTutorialAnimationController?.stop();
          _cardTutorialAnimationController?.reset();
          if (_targetButtonRect != null) _targetButtonRect = null;
        }
      });
      _updateTargetButtonRectIfNeeded();
    }
  }

  Future<void> _playStandardClickSound() async {
    if (await getSoundEnabled()) {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/next_card.mp3'));
      player.onPlayerComplete.first.then((_) => player.dispose());
    }
  }

  Future<void> _playTutorialAdvanceSound() async {
    if (await getSoundEnabled()) {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/rules.mp3'));
      player.onPlayerComplete.first.then((_) => player.dispose());
    }
  }

  void _advanceBackCardTutorial() async {
    if (_currentCardTutorialStep == CardTutorialOverallStep.backNextButton) {
      await setHasSeenCardBackNextButtonTutorial(true);
      if (mounted) {
        setState(() {
          _currentCardTutorialStep = CardTutorialOverallStep.none;
          _cardTutorialAnimationController?.stop();
          _cardTutorialAnimationController?.reset();
          _targetButtonRect = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _cardTutorialAnimationController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playFlipSound() async {
    if (await getSoundEnabled()) {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/card_flip.mp3'));
      player.onPlayerComplete.first.then((_) => player.dispose());
    }
  }

  void _handleFlip() async {
    if (_isFlipping || !_prefsLoaded) return;

    if (_isFront &&
        (_currentCardTutorialStep == CardTutorialOverallStep.frontTerm)) {
      return;
    }

    _isFlipping = true;

    if (!_isFront && _currentCardTutorialStep == CardTutorialOverallStep.backNextButton) {
      await setHasSeenCardBackNextButtonTutorial(true);
    }

    _flipCardController.flipcard();
    _playFlipSound();

    final bool newIsFront = !_isFront;
    CardTutorialOverallStep nextTutorialStepAfterFlip = CardTutorialOverallStep.none;

    if (newIsFront) {
      if (!await getHasSeenCardFrontTermTutorial()) {
        nextTutorialStepAfterFlip = CardTutorialOverallStep.frontTerm;
      } else if (!await getHasSeenCardFrontTapToFlipTutorial()) {
        nextTutorialStepAfterFlip = CardTutorialOverallStep.frontTapToFlip;
      }
    } else {
      if (!await getHasSeenCardBackNextButtonTutorial()) {
        nextTutorialStepAfterFlip = CardTutorialOverallStep.backNextButton;
      }
    }

    if (mounted) {
      setState(() {
        _isFront = newIsFront;
        _currentCardTutorialStep = nextTutorialStepAfterFlip;
        if (newIsFront || nextTutorialStepAfterFlip != CardTutorialOverallStep.backNextButton) {
          _targetButtonRect = null;
          if (_cardTutorialAnimationController?.isAnimating ?? false) {
            _cardTutorialAnimationController?.stop();
          }
          _cardTutorialAnimationController?.reset();
        }
      });
    }

    widget.onFlip?.call(newIsFront);
    await Future.delayed(_flipDuration + _postFlipSettleDelay);

    if (!mounted) {
      _isFlipping = false;
      return;
    }

    if (!newIsFront && _currentCardTutorialStep == CardTutorialOverallStep.backNextButton) {
      _updateTargetButtonRectIfNeeded();
    }
    _isFlipping = false;
  }

  Widget _buildCardBackTutorialOverlayWidget() {
    if (_cardTutorialAnimationController == null ||
        _tutorialCircleScale == null || _tutorialCircleOpacity == null ||
        _tutorialPointerOffset == null || _tutorialTextOpacity == null ||
        _currentCardTutorialStep != CardTutorialOverallStep.backNextButton ||
        _isFront) {
      return const SizedBox.shrink();
    }

    if (_targetButtonRect == null) {
      return Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: const Center(
            child: Text("Positioning hint...", style: TextStyle(color: Colors.white, fontSize: 14, decoration: TextDecoration.none)),
          ),
        ),
      );
    }

    final Offset targetPositionInStack = _targetButtonRect!.topLeft;
    final Size targetSize = _targetButtonRect!.size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double scaleFactor = screenWidth / 400;
    final double hintTextFontSize = 16 * scaleFactor;
    final double spotlightBorderWidth = 2.0 * scaleFactor;
    final Offset targetCenter = Offset(targetPositionInStack.dx + targetSize.width / 2, targetPositionInStack.dy + targetSize.height / 2);
    final double hintPaddingHorizontal = 12 * scaleFactor;
    final double hintPaddingVertical = 8 * scaleFactor;
    final double hintTextContainerBorderWidth = 1.0 * scaleFactor;
    final double hintContainerCornerRadius = 8.0 * scaleFactor;
    double estimatedTextHeight = (_cardTutorialTexts[_currentCardTutorialStep] ?? "").length > 40
        ? hintTextFontSize * 3.0 : hintTextFontSize * 1.8;
    double estimatedHintBlockHeight = estimatedTextHeight + (hintPaddingVertical * 2) + (hintTextContainerBorderWidth * 2);
    double verticalOffsetSpacing = 20 * scaleFactor;
    double initialHintBlockTopPosition = targetCenter.dy - (targetSize.height / 2) - estimatedHintBlockHeight - verticalOffsetSpacing;

    final double topSafeArea = MediaQuery.of(context).padding.top + (10 * scaleFactor);
    final double bottomSafeArea = screenHeight - MediaQuery.of(context).padding.bottom - (10 * scaleFactor);

    if (initialHintBlockTopPosition < topSafeArea) {
      initialHintBlockTopPosition = topSafeArea;
    } else if (initialHintBlockTopPosition + estimatedHintBlockHeight > targetCenter.dy - (targetSize.height / 2) - (5 * scaleFactor)) {
      initialHintBlockTopPosition = targetCenter.dy - (targetSize.height / 2) - estimatedHintBlockHeight - verticalOffsetSpacing;
      if (initialHintBlockTopPosition < topSafeArea) initialHintBlockTopPosition = topSafeArea;
    }
    if (initialHintBlockTopPosition + estimatedHintBlockHeight > bottomSafeArea) {
      initialHintBlockTopPosition = bottomSafeArea - estimatedHintBlockHeight;
      if (initialHintBlockTopPosition < topSafeArea) initialHintBlockTopPosition = topSafeArea;
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: () async {
          await _playTutorialAdvanceSound();
          _advanceBackCardTutorial();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _cardTutorialAnimationController!, _tutorialPointerOffset!,
            _tutorialCircleScale!, _tutorialCircleOpacity!, _tutorialTextOpacity!,
          ]),
          builder: (context, child) {
            final double currentAnimatedScale = _tutorialCircleScale!.value;
            final double highlightPadding = 10 * scaleFactor;
            final double animatedHighlightWidth = (targetSize.width + highlightPadding) * currentAnimatedScale;
            final double animatedHighlightHeight = (targetSize.height + highlightPadding) * currentAnimatedScale;
            final BorderRadius animatedHighlightBorderRadius = BorderRadius.circular(12.0 * currentAnimatedScale * scaleFactor);
            final Rect cutoutRect = Rect.fromCenter(center: targetCenter, width: animatedHighlightWidth, height: animatedHighlightHeight);
            double currentHintBlockTopPosition = initialHintBlockTopPosition + (_tutorialPointerOffset!.value.dy);

            if (currentHintBlockTopPosition < topSafeArea) {
              currentHintBlockTopPosition = topSafeArea;
            } else if (currentHintBlockTopPosition + estimatedHintBlockHeight > bottomSafeArea) {
              currentHintBlockTopPosition = bottomSafeArea - estimatedHintBlockHeight;
              if (currentHintBlockTopPosition < topSafeArea) currentHintBlockTopPosition = topSafeArea;
            }

            return Stack(
              children: [
                ClipPath(
                  clipper: TutorialCutoutClipper(rect: cutoutRect, borderRadius: animatedHighlightBorderRadius, isCircular: false),
                  child: Container(color: Colors.black.withOpacity(0.80)),
                ),
                Positioned(
                  left: cutoutRect.left, top: cutoutRect.top,
                  child: Opacity(
                    opacity: _tutorialCircleOpacity!.value,
                    child: Container(
                      width: cutoutRect.width, height: cutoutRect.height,
                      decoration: BoxDecoration(
                        borderRadius: animatedHighlightBorderRadius,
                        border: Border.all(color: Colors.white.withOpacity(0.8), width: spotlightBorderWidth),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20 * scaleFactor, right: 20 * scaleFactor,
                  top: currentHintBlockTopPosition,
                  child: Opacity(
                    opacity: _tutorialTextOpacity!.value,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: hintPaddingHorizontal, vertical: hintPaddingVertical),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(hintContainerCornerRadius),
                          border: Border.all(color: Colors.white70, width: hintTextContainerBorderWidth)
                      ),
                      child: Text(
                        _cardTutorialTexts[_currentCardTutorialStep] ?? "Hint",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: hintTextFontSize, fontWeight: FontWeight.w500, decoration: TextDecoration.none),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double buttonWidth = screenWidth * 0.3;
    final double buttonHeight = screenHeight * 0.06;
    final double iconSize = min(screenWidth, screenHeight) * 0.04;
    final double iconBottomPadding = buttonHeight * 0.1;
    final double smallButtonWidth = buttonWidth * 0.8;
    final double smallButtonHeight = buttonHeight * 0.8;
    final double smallIconSize = iconSize * 0.8;
    final double smallIconBottomPadding = smallButtonHeight * 0.1;

    final nextButtonWidget = SizedBox(
      key: _nextButtonKeyOnBackCard,
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
          alignment: Alignment.center,
        ),
        onPressed: () async {
          if (_isFlipping) return;
          if (!_isFront && _currentCardTutorialStep == CardTutorialOverallStep.backNextButton) {
            await _playTutorialAdvanceSound();
            _advanceBackCardTutorial();
          } else if (_currentCardTutorialStep == CardTutorialOverallStep.none && !_isFront) {
            await _playStandardClickSound();
            widget.onNextButtonPressed();
          }
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: iconBottomPadding),
          child: Icon(Icons.arrow_forward, size: iconSize, color: Colors.white),
        ),
      ),
    );

    Widget? backCardPreviousButton;
    if (widget.onPreviousButtonPressed != null) {
      backCardPreviousButton = SizedBox(
        key: _previousButtonKeyOnBackCard,
        width: smallButtonWidth,
        height: smallButtonHeight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.zero,
            alignment: Alignment.center,
          ),
          onPressed: () async {
            if (_isFlipping) return;
            if (!_isFlipping) {
              await _playStandardClickSound();
              widget.onPreviousButtonPressed!();
            }
          },
          child: Padding(
            padding: EdgeInsets.only(bottom: smallIconBottomPadding),
            child: Icon(Icons.arrow_back, size: smallIconSize, color: Colors.white),
          ),
        ),
      );
    }

    CardFrontTutorialStep initialFrontStepForCardFront = CardFrontTutorialStep.none;
    if (_isFront) {
      switch(_currentCardTutorialStep) {
        case CardTutorialOverallStep.frontTerm: initialFrontStepForCardFront = CardFrontTutorialStep.term; break;
        case CardTutorialOverallStep.frontTapToFlip: initialFrontStepForCardFront = CardFrontTutorialStep.tapToFlip; break;
        default: break;
      }
    }

    return GestureDetector(
      onTap: _handleFlip,
      child: Stack(
        key: _flipCardStackKey,
        alignment: Alignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: FlipCard(
              animationDuration: _flipDuration,
              rotateSide: RotateSide.right,
              disableSplashEffect: true,
              onTapFlipping: false,
              axis: FlipAxis.vertical,
              controller: _flipCardController,
              frontWidget: SizedBox(
                width: screenWidth, height: screenHeight,
                child: CardFront(
                  term: widget.term,
                  initialTutorialStep: initialFrontStepForCardFront,
                  onTutorialStepChange: _handleCardFrontTutorialStepChange,
                  // onHistoryIconPressed: widget.onHistoryIconPressed, // REMOVED
                ),
              ),
              backWidget: SizedBox(
                width: screenWidth, height: screenHeight,
                child: CardBack(
                  image: widget.image,
                  term: widget.term,
                  definition: widget.definition,
                  generation: widget.generation,
                  nextButton: nextButtonWidget,
                  previousButton: backCardPreviousButton,
                  nextButtonKey: _nextButtonKeyOnBackCard,
                  previousButtonKey: _previousButtonKeyOnBackCard,
                  // onHistoryIconPressed: widget.onHistoryIconPressed, // REMOVED
                ),
              ),
            ),
          ),
          _buildCardBackTutorialOverlayWidget(),
        ],
      ),
    );
  }
}