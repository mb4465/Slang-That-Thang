// lib/widgets/flip_card_widget.dart
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
  frontGeneration,
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
    this.onPreviousButtonPressed, // Callback from LevelScreen
    this.onFlip,
  });

  final VoidCallback onNextButtonPressed;
  final VoidCallback? onPreviousButtonPressed; // Nullable callback for "previous term"
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
  bool _isSoundEnabled = true;
  bool _prefsLoaded = false;

  CardTutorialOverallStep _currentCardTutorialStep = CardTutorialOverallStep.none;
  AnimationController? _cardTutorialAnimationController;
  Animation<double>? _tutorialCircleScale;
  Animation<double>? _tutorialCircleOpacity;
  Animation<Offset>? _tutorialPointerOffset;
  Animation<double>? _tutorialTextOpacity;

  final GlobalKey _nextButtonKeyOnBackCard = GlobalKey(); // For tutorial targeting
  final GlobalKey _previousButtonKeyOnBackCard = GlobalKey(); // NEW: Key for previous button on back card
  final GlobalKey _flipCardStackKey = GlobalKey();


  Rect? _targetButtonRect; // For backNextButton tutorial
  Size? _lastKnownScreenSize;

  final Map<CardTutorialOverallStep, String> _cardTutorialTexts = {
    CardTutorialOverallStep.backNextButton: "To move on to the next card, click the 'Next' button.",
    // No specific tutorial text for the Previous button within FlipCardWidget itself for now
  };

  @override
  void initState() {
    super.initState();
    _loadInitialPrefsAndTutorialState();
    _initCardTutorialAnimations(); // For back card tutorial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _lastKnownScreenSize = MediaQuery.of(context).size;
        _updateTargetButtonRectIfNeeded(); // For back card tutorial
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
    bool sound = await getSoundEnabled();
    CardTutorialOverallStep initialStep = CardTutorialOverallStep.none;

    // Determine initial tutorial step based on seen flags
    if (!await getHasSeenCardFrontTermTutorial()) {
      initialStep = CardTutorialOverallStep.frontTerm;
    } else if (!await getHasSeenCardFrontGenerationTutorial()) {
      initialStep = CardTutorialOverallStep.frontGeneration;
    } else if (!await getHasSeenCardFrontTapToFlipTutorial()) {
      initialStep = CardTutorialOverallStep.frontTapToFlip;
    } else if (!_isFront && !await getHasSeenCardBackNextButtonTutorial()) { // Check if back is showing
      initialStep = CardTutorialOverallStep.backNextButton;
    }

    if (!mounted) return;
    setState(() {
      _isSoundEnabled = sound;
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

  void _initCardTutorialAnimations() { // For backNextButton tutorial
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

  void _updateTargetButtonRectIfNeeded() { // For backNextButton tutorial
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
        // If contexts are null, reset rect and stop animation
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

    if (frontStep == CardFrontTutorialStep.none) { // CardFront tutorial finished
      // Check if all front tutorials are done
      bool termDone = await getHasSeenCardFrontTermTutorial();
      bool genDone = await getHasSeenCardFrontGenerationTutorial();
      bool flipDone = await getHasSeenCardFrontTapToFlipTutorial();

      if(termDone && genDone && flipDone){
        // If card is still front and all front tutorials are done, there's no next step for front.
        // If it flips to back, backNextButton tutorial might trigger.
        nextOverallStep = CardTutorialOverallStep.none;
      } else {
        // This case implies frontStep became none but not all parts were marked.
        // This might happen if tapToFlip was the last step on front.
        // Re-evaluate based on what FlipCard thinks is next.
        if (!termDone) nextOverallStep = CardTutorialOverallStep.frontTerm;
        else if (!genDone) nextOverallStep = CardTutorialOverallStep.frontGeneration;
        else if (!flipDone) nextOverallStep = CardTutorialOverallStep.frontTapToFlip;
        else nextOverallStep = CardTutorialOverallStep.none;
      }

    } else { // Specific step from CardFront
      switch (frontStep) {
        case CardFrontTutorialStep.term: nextOverallStep = CardTutorialOverallStep.frontTerm; break;
        case CardFrontTutorialStep.generationIcon: nextOverallStep = CardTutorialOverallStep.frontGeneration; break;
        case CardFrontTutorialStep.tapToFlip: nextOverallStep = CardTutorialOverallStep.frontTapToFlip; break;
        case CardFrontTutorialStep.none: // Should be handled by the block above
          break;
      }
    }

    bool stepChanged = _currentCardTutorialStep != nextOverallStep;
    if (stepChanged) {
      setState(() {
        _currentCardTutorialStep = nextOverallStep;
        if (nextOverallStep != CardTutorialOverallStep.backNextButton) {
          // Stop and reset back card tutorial animations if we are not on it
          _cardTutorialAnimationController?.stop();
          _cardTutorialAnimationController?.reset();
          if (_targetButtonRect != null) _targetButtonRect = null;
        }
      });
      _updateTargetButtonRectIfNeeded(); // Re-evaluate if backNextButton tutorial should run
    }
  }

  void _advanceBackCardTutorial() async { // For backNextButton tutorial
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
    super.dispose();
  }

  void _playFlipSound() async {
    AudioPlayer audioPlayer = AudioPlayer(); // Create a new instance each time
    await audioPlayer.play(AssetSource('audio/card_flip.mp3'));
    audioPlayer.onPlayerComplete.first.then((_) => audioPlayer.dispose());
  }

  void _handleFlip() async {
    if (_isFlipping || !_prefsLoaded) return;
    if (_currentCardTutorialStep == CardTutorialOverallStep.frontTerm ||
        _currentCardTutorialStep == CardTutorialOverallStep.frontGeneration) {
      // Prevent flipping if these tutorials are active and not advanced by their specific interactions
      return;
    }

    _isFlipping = true;

    // If frontTapToFlip is active, tapping anywhere (which calls _handleFlip) should advance it.
    if (_isFront && _currentCardTutorialStep == CardTutorialOverallStep.frontTapToFlip) {
      // CardFront's _advanceTutorialStep should have already marked it via its own GestureDetector.
      // This is a fallback / double-check.
      await setHasSeenCardFrontTapToFlipTutorial(true);
    }
    // If backNextButton tutorial is active and card flips back to front, mark as seen.
    if (!_isFront && _currentCardTutorialStep == CardTutorialOverallStep.backNextButton) {
      await setHasSeenCardBackNextButtonTutorial(true);
    }

    _flipCardController.flipcard();
    if (_isSoundEnabled) _playFlipSound();

    final bool newIsFront = !_isFront;
    CardTutorialOverallStep nextTutorialStepAfterFlip = CardTutorialOverallStep.none;

    if (newIsFront) { // Flipped TO FRONT
      if (!await getHasSeenCardFrontTermTutorial()) {
        nextTutorialStepAfterFlip = CardTutorialOverallStep.frontTerm;
      } else if (!await getHasSeenCardFrontGenerationTutorial()) {
        nextTutorialStepAfterFlip = CardTutorialOverallStep.frontGeneration;
      } else if (!await getHasSeenCardFrontTapToFlipTutorial()) {
        nextTutorialStepAfterFlip = CardTutorialOverallStep.frontTapToFlip;
      }
    } else { // Flipped TO BACK
      if (!await getHasSeenCardBackNextButtonTutorial()) {
        nextTutorialStepAfterFlip = CardTutorialOverallStep.backNextButton;
      }
    }

    if (mounted) {
      setState(() {
        _isFront = newIsFront;
        _currentCardTutorialStep = nextTutorialStepAfterFlip;

        // If flipped to front, or if the next step isn't the back button tutorial,
        // ensure back button tutorial elements are reset.
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
    // After flip settles, if we are on back and backNextButton tutorial is active, start it.
    if (!newIsFront && _currentCardTutorialStep == CardTutorialOverallStep.backNextButton) {
      _updateTargetButtonRectIfNeeded(); // This will try to get rect and start animation if rect is found
    }
    _isFlipping = false;
  }

  Widget _buildCardBackTutorialOverlayWidget() { // For backNextButton tutorial
    if (_cardTutorialAnimationController == null ||
        _tutorialCircleScale == null || _tutorialCircleOpacity == null ||
        _tutorialPointerOffset == null || _tutorialTextOpacity == null ||
        _currentCardTutorialStep != CardTutorialOverallStep.backNextButton ||
        _isFront) { // Only show if on back card and it's the active tutorial
      return const SizedBox.shrink();
    }

    if (_targetButtonRect == null) {
      // _updateTargetButtonRectIfNeeded(); // Already called in _handleFlip or initState
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
    // Position text above the button
    double initialHintBlockTopPosition = targetCenter.dy - (targetSize.height / 2) - estimatedHintBlockHeight - verticalOffsetSpacing;

    final double topSafeArea = MediaQuery.of(context).padding.top + (10 * scaleFactor);
    final double bottomSafeArea = screenHeight - MediaQuery.of(context).padding.bottom - (10 * scaleFactor);

    // Adjust if text block goes out of bounds
    if (initialHintBlockTopPosition < topSafeArea) { // If text block is too high
      initialHintBlockTopPosition = topSafeArea;
    } else if (initialHintBlockTopPosition + estimatedHintBlockHeight > targetCenter.dy - (targetSize.height / 2) - (5 * scaleFactor)) {
      // If it overlaps with the button or goes too low (while trying to be above)
      // This specific condition may need tuning. Try to keep it above.
      initialHintBlockTopPosition = targetCenter.dy - (targetSize.height / 2) - estimatedHintBlockHeight - verticalOffsetSpacing;
      if (initialHintBlockTopPosition < topSafeArea) initialHintBlockTopPosition = topSafeArea;
    }
    // Fallback if it still overflows bottom after trying to be above (e.g. very large text on small screen)
    if (initialHintBlockTopPosition + estimatedHintBlockHeight > bottomSafeArea) {
      initialHintBlockTopPosition = bottomSafeArea - estimatedHintBlockHeight;
      if (initialHintBlockTopPosition < topSafeArea) initialHintBlockTopPosition = topSafeArea;
    }


    return Positioned.fill(
      child: GestureDetector(
        onTap: _advanceBackCardTutorial,
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

            // Re-check bounds for animated position
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

    // --- Button Styling ---
    final double buttonWidth = screenWidth * 0.3;
    final double buttonHeight = screenHeight * 0.06;
    final double iconSize = min(screenWidth, screenHeight) * 0.04;
    final double iconBottomPadding = buttonHeight * 0.1;

    // NEW: Smaller dimensions for the "Previous" button
    final double smallButtonWidth = buttonWidth * 0.8; // 80% of normal width
    final double smallButtonHeight = buttonHeight * 0.8; // 80% of normal height
    final double smallIconSize = iconSize * 0.8; // 80% of normal icon size
    final double smallIconBottomPadding = smallButtonHeight * 0.1;

    // --- "Next" button for CardBack ---
    final nextButtonWidget = SizedBox(
      key: _nextButtonKeyOnBackCard, // Key for tutorial targeting
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
        onPressed: () {
          if (_isFlipping) return;
          // If tutorial for "Next" button is active, pressing it advances tutorial
          if (!_isFront && _currentCardTutorialStep == CardTutorialOverallStep.backNextButton) {
            _advanceBackCardTutorial(); // This sets tutorial step to none
            // widget.onNextButtonPressed(); // Optionally also trigger next card immediately
          }
          // If no tutorial is active for this button, or tutorial just completed, perform normal action
          else if (_currentCardTutorialStep == CardTutorialOverallStep.none && !_isFront) {
            widget.onNextButtonPressed();
          }
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: iconBottomPadding),
          child: Icon(Icons.arrow_forward, size: iconSize, color: Colors.white),
        ),
      ),
    );

    // --- "Previous Term" button for CardBack (NEW) ---
    Widget? backCardPreviousButton;
    // Only build the button if the callback from LevelScreen is provided
    if (widget.onPreviousButtonPressed != null) {
      backCardPreviousButton = SizedBox(
        key: _previousButtonKeyOnBackCard, // Key for the previous button
        width: smallButtonWidth, // Use smaller width
        height: smallButtonHeight, // Use smaller height
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.zero,
            alignment: Alignment.center,
          ),
          onPressed: () {
            if (_isFlipping) return;
            // The previous button does not participate in the current tutorial flow for the back card.
            // It should always work if available and not flipping.
            if (!_isFlipping) {
              widget.onPreviousButtonPressed!();
            }
          },
          child: Padding(
            padding: EdgeInsets.only(bottom: smallIconBottomPadding), // Use smaller padding
            child: Icon(Icons.arrow_back, size: smallIconSize, color: Colors.white), // Use smaller icon
          ),
        ),
      );
    }
    // --- End "Previous Term" button ---


    CardFrontTutorialStep initialFrontStepForCardFront = CardFrontTutorialStep.none;
    if (_isFront) {
      switch(_currentCardTutorialStep) {
        case CardTutorialOverallStep.frontTerm: initialFrontStepForCardFront = CardFrontTutorialStep.term; break;
        case CardTutorialOverallStep.frontGeneration: initialFrontStepForCardFront = CardFrontTutorialStep.generationIcon; break;
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
                  // previousButton: frontCardPreviousButton, // REMOVED: No longer passing to CardFront
                ),
              ),
              backWidget: SizedBox(
                width: screenWidth, height: screenHeight,
                child: CardBack(
                  image: widget.image,
                  term: widget.term,
                  definition: widget.definition,
                  generation: widget.generation,
                  nextButton: nextButtonWidget, // Changed `button` to `nextButton` for clarity
                  previousButton: backCardPreviousButton, // NEW: Pass the previous button
                  nextButtonKey: _nextButtonKeyOnBackCard,
                  previousButtonKey: _previousButtonKeyOnBackCard, // NEW: Pass its key
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