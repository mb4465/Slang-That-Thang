// lib/flip_card_widget.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:test2/widgets/tutorial_cutout_clipper.dart'; // Ensure this path is correct
import '../data/globals.dart'; // Adjust path
import 'card_back.dart';
import 'card_front.dart';

// Enum to manage the overall tutorial flow for the card
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

class FlipCardWidgetState extends State<FlipCardWidget> with TickerProviderStateMixin {
  final FlipCardController _flipCardController = FlipCardController();
  final Duration _flipDuration = const Duration(milliseconds: 400);
  bool _isFront = true;
  bool _isFlipping = false;
  bool _isSoundEnabled = true;
  bool _prefsLoaded = false;

  // --- Card Tutorial State ---
  CardTutorialOverallStep _currentCardTutorialStep = CardTutorialOverallStep.none;
  AnimationController? _cardTutorialAnimationController; // For back card hint
  Animation<double>? _tutorialCircleScale;
  Animation<double>? _tutorialCircleOpacity;
  Animation<Offset>? _tutorialPointerOffset;
  Animation<double>? _tutorialTextOpacity;

  final GlobalKey _nextButtonKeyOnBackCard = GlobalKey();
  final GlobalKey _flipCardStackKey = GlobalKey(); // Key for the main Stack

  final Map<CardTutorialOverallStep, String> _cardTutorialTexts = {
    CardTutorialOverallStep.backNextButton: "To move on to the next card, click the 'Next' button.",
  };
  // --- End Card Tutorial State ---

  @override
  void initState() {
    super.initState();
    _loadInitialPrefsAndTutorialState();
    _initCardTutorialAnimations();
  }

  Future<void> _loadInitialPrefsAndTutorialState() async {
    bool sound = await getSoundEnabled();

    CardTutorialOverallStep initialStep = CardTutorialOverallStep.none;
    if (!await getHasSeenCardFrontTermTutorial()) {
      initialStep = CardTutorialOverallStep.frontTerm;
    } else if (!await getHasSeenCardFrontGenerationTutorial()) {
      initialStep = CardTutorialOverallStep.frontGeneration;
    } else if (!await getHasSeenCardFrontTapToFlipTutorial()) {
      initialStep = CardTutorialOverallStep.frontTapToFlip;
    } else if (!await getHasSeenCardBackNextButtonTutorial() && !_isFront) { // Check !_isFront for initial load if starting on back
      initialStep = CardTutorialOverallStep.backNextButton;
    }

    if (!mounted) return;
    setState(() {
      _isSoundEnabled = sound;
      _currentCardTutorialStep = initialStep;
      _prefsLoaded = true;

      if (_currentCardTutorialStep == CardTutorialOverallStep.backNextButton && !_isFront) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _cardTutorialAnimationController?.reset();
            _cardTutorialAnimationController?.repeat();
          }
        });
      }
    });
  }

  void _initCardTutorialAnimations() {
    _cardTutorialAnimationController?.dispose(); // Ensure previous controller is disposed
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

  void _handleCardFrontTutorialStepChange(CardFrontTutorialStep frontStep) async {
    if (!mounted) return;
    CardTutorialOverallStep nextOverallStep = _currentCardTutorialStep;

    if (frontStep == CardFrontTutorialStep.none) {
      if (!await getHasSeenCardFrontTapToFlipTutorial()){ // Should be already set by CardFront
        await setHasSeenCardFrontTapToFlipTutorial(true);
      }
      nextOverallStep = CardTutorialOverallStep.none;
    } else {
      switch (frontStep) {
        case CardFrontTutorialStep.term: nextOverallStep = CardTutorialOverallStep.frontTerm; break;
        case CardFrontTutorialStep.generationIcon: nextOverallStep = CardTutorialOverallStep.frontGeneration; break;
        case CardFrontTutorialStep.tapToFlip: nextOverallStep = CardTutorialOverallStep.frontTapToFlip; break;
        case CardFrontTutorialStep.none: break;
      }
    }

    setState(() {
      _currentCardTutorialStep = nextOverallStep;
      if (_currentCardTutorialStep == CardTutorialOverallStep.frontTerm ||
          _currentCardTutorialStep == CardTutorialOverallStep.frontGeneration ||
          _currentCardTutorialStep == CardTutorialOverallStep.frontTapToFlip) {
        _cardTutorialAnimationController?.stop();
        _cardTutorialAnimationController?.reset();
      }
    });
  }

  void _advanceBackCardTutorial() async {
    if (_currentCardTutorialStep == CardTutorialOverallStep.backNextButton) {
      await setHasSeenCardBackNextButtonTutorial(true);
      if (mounted) {
        setState(() {
          _currentCardTutorialStep = CardTutorialOverallStep.none;
          _cardTutorialAnimationController?.stop();
          _cardTutorialAnimationController?.reset();
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
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(AssetSource('audio/card_flip.mp3'));
  }

  void _handleFlip() async {
    if (_isFlipping || !_prefsLoaded) return;
    _isFlipping = true;

    if (_isFront && _currentCardTutorialStep == CardTutorialOverallStep.frontTapToFlip) {
      await setHasSeenCardFrontTapToFlipTutorial(true);
    }
    // No need to advance backNextButton tutorial on flip FROM back, it's advanced on tap or next button press
    // if (!_isFront && _currentCardTutorialStep == CardTutorialOverallStep.backNextButton) {
    //   await setHasSeenCardBackNextButtonTutorial(true);
    // }

    _flipCardController.flipcard();
    bool newIsFront = !_isFront;
    CardTutorialOverallStep nextTutorialStepAfterFlip = CardTutorialOverallStep.none;

    // Stop any ongoing back card tutorial animations when flipping away from back
    if (!newIsFront && _currentCardTutorialStep == CardTutorialOverallStep.backNextButton) {
      _cardTutorialAnimationController?.stop();
      _cardTutorialAnimationController?.reset();
    }


    if (newIsFront) { // Just flipped to front
      // Stop and reset any animations that might have been running for the back
      _cardTutorialAnimationController?.stop();
      _cardTutorialAnimationController?.reset();

      if (!await getHasSeenCardFrontTermTutorial()) {
        nextTutorialStepAfterFlip = CardTutorialOverallStep.frontTerm;
      } else if (!await getHasSeenCardFrontGenerationTutorial()) {
        nextTutorialStepAfterFlip = CardTutorialOverallStep.frontGeneration;
      } else if (!await getHasSeenCardFrontTapToFlipTutorial()) {
        nextTutorialStepAfterFlip = CardTutorialOverallStep.frontTapToFlip;
      }
    } else { // Just flipped to back
      if (!await getHasSeenCardBackNextButtonTutorial()) {
        nextTutorialStepAfterFlip = CardTutorialOverallStep.backNextButton;
      }
    }

    if (mounted) {
      setState(() {
        _isFront = newIsFront;
        _currentCardTutorialStep = nextTutorialStepAfterFlip;
      });

      // If we are now on the back and the back tutorial is active,
      // ensure layout is complete, then start its animation.
      if (nextTutorialStepAfterFlip == CardTutorialOverallStep.backNextButton && !_isFront) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentCardTutorialStep == CardTutorialOverallStep.backNextButton) {
            _cardTutorialAnimationController?.reset();
            _cardTutorialAnimationController?.repeat();
          }
        });
      }
    }

    widget.onFlip?.call(_isFront);
    if (_isSoundEnabled) _playFlipSound();
    await Future.delayed(_flipDuration);
    _isFlipping = false;
  }

  Widget _buildCardBackTutorialOverlayWidget() {
    if (_cardTutorialAnimationController == null ||
        _currentCardTutorialStep != CardTutorialOverallStep.backNextButton ||
        _isFront) {
      return const SizedBox.shrink();
    }

    GlobalKey currentTargetKey = _nextButtonKeyOnBackCard;

    if (currentTargetKey.currentContext == null || _flipCardStackKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() {}); });
      return Positioned.fill(
          child: Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                  child: Text("Initializing hint...",
                      style: TextStyle(color: Colors.white, fontSize: 14, decoration: TextDecoration.none)))));
    }

    final RenderBox? targetRenderBox = currentTargetKey.currentContext!.findRenderObject() as RenderBox?;
    final RenderBox? ancestorRenderBox = _flipCardStackKey.currentContext!.findRenderObject() as RenderBox?;

    if (targetRenderBox == null || !targetRenderBox.attached || ancestorRenderBox == null || !ancestorRenderBox.attached) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() {}); });
      return Positioned.fill(
          child: Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                  child: Text("Waiting for Next button layout...",
                      style: TextStyle(color: Colors.white, fontSize: 14, decoration: TextDecoration.none)))));
    }

    // --- START DEBUG PRINTS ---
    final Offset targetGlobalPosition = targetRenderBox.localToGlobal(Offset.zero);
    final Size targetSize = targetRenderBox.size;
    final Offset ancestorGlobalPosition = ancestorRenderBox.localToGlobal(Offset.zero);
    final Size ancestorSize = ancestorRenderBox.size;
    final Offset targetPositionInStack = targetRenderBox.localToGlobal(Offset.zero, ancestor: ancestorRenderBox);

    debugPrint("--- Tutorial Overlay Debug ---");
    debugPrint("Timestamp: ${DateTime.now().toIso8601String()}");
    debugPrint("Screen Size (MediaQuery): ${MediaQuery.of(context).size}");
    debugPrint("Target Widget Key: $_nextButtonKeyOnBackCard");
    debugPrint("Target RenderBox Attached: ${targetRenderBox.attached}, Size: $targetSize");
    debugPrint("Target Global Position (from screen origin): $targetGlobalPosition");
    debugPrint("Ancestor Stack Key: $_flipCardStackKey");
    debugPrint("Ancestor RenderBox Attached: ${ancestorRenderBox.attached}, Size: $ancestorSize");
    debugPrint("Ancestor Global Position (from screen origin): $ancestorGlobalPosition");
    debugPrint("Calculated Target Position IN STACK (relative to ancestor): $targetPositionInStack");
    // --- END DEBUG PRINTS ---

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height; // Use this for consistency in scaling
    final double scaleFactor = screenWidth / 400; // Base scale factor on width
    final double hintTextFontSize = 16 * scaleFactor;
    final double spotlightBorderWidth = 2.0 * scaleFactor;

    // Recalculate targetCenter based on potentially more accurate targetPositionInStack
    final Offset targetCenter = Offset(
        targetPositionInStack.dx + targetSize.width / 2,
        targetPositionInStack.dy + targetSize.height / 2);

    debugPrint("Calculated Target Center for Cutout (in Stack coords): $targetCenter");
    debugPrint("--- End Tutorial Overlay Debug ---");


    final double hintPaddingHorizontal = 12 * scaleFactor;
    final double hintPaddingVertical = 8 * scaleFactor;
    final double hintTextContainerBorderWidth = 1.0 * scaleFactor;
    final double hintContainerCornerRadius = 8.0 * scaleFactor;

    // bool pointUpwards = true; // Not used, can remove if not planned

    double estimatedTextHeight = (_cardTutorialTexts[_currentCardTutorialStep] ?? "").length > 40
        ? hintTextFontSize * 3.0  // Approx 2 lines with some padding
        : hintTextFontSize * 1.8; // Approx 1 line with some padding
    double estimatedHintBlockHeight = estimatedTextHeight + (hintPaddingVertical * 2) + (hintTextContainerBorderWidth * 2);
    double verticalOffsetSpacing = 20 * scaleFactor;

    // Attempt to place above the target by default
    double hintBlockVerticalOffsetFromTargetCenter = -(targetSize.height / 2 + estimatedHintBlockHeight * 0.5 + verticalOffsetSpacing);
    double initialHintBlockTopPosition = targetCenter.dy + hintBlockVerticalOffsetFromTargetCenter;

    final double topSafeArea = MediaQuery.of(context).padding.top + (10 * scaleFactor);
    final double bottomSafeArea = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.bottom - (10 * scaleFactor);


    return Positioned.fill(
      child: GestureDetector(
        onTap: _advanceBackCardTutorial,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            if (_cardTutorialAnimationController != null) _cardTutorialAnimationController!,
            if (_tutorialPointerOffset != null) _tutorialPointerOffset!, // Ensure this is not null
            if (_tutorialCircleScale != null) _tutorialCircleScale!,   // Ensure this is not null
            if (_tutorialCircleOpacity != null) _tutorialCircleOpacity!, // Ensure this is not null
            if (_tutorialTextOpacity != null) _tutorialTextOpacity!,   // Ensure this is not null
          ]),
          builder: (context, child) {
            final double currentAnimatedScale = _tutorialCircleScale?.value ?? 1.0;
            final double highlightPadding = 10 * scaleFactor; // Padding around the target for the highlight
            final double animatedHighlightWidth = (targetSize.width + highlightPadding) * currentAnimatedScale;
            final double animatedHighlightHeight = (targetSize.height + highlightPadding) * currentAnimatedScale;
            final BorderRadius animatedHighlightBorderRadius = BorderRadius.circular(12.0 * currentAnimatedScale * scaleFactor); // Scale border radius too

            // Cutout rect is centered on targetCenter, uses animated dimensions
            final Rect cutoutRect = Rect.fromCenter(
                center: targetCenter,
                width: animatedHighlightWidth,
                height: animatedHighlightHeight);

            double currentHintBlockTopPosition = initialHintBlockTopPosition + (_tutorialPointerOffset?.value.dy ?? 0);

            // Adjust hint block position to stay within safe area
            if (currentHintBlockTopPosition < topSafeArea) {
              currentHintBlockTopPosition = topSafeArea;
            } else if (currentHintBlockTopPosition + estimatedHintBlockHeight > bottomSafeArea) {
              // Try to position below the target if it overflows top and still overflows bottom
              double alternativeHintBlockTop = targetCenter.dy + (targetSize.height / 2 + verticalOffsetSpacing) + (_tutorialPointerOffset?.value.dy ?? 0);
              if (alternativeHintBlockTop + estimatedHintBlockHeight <= bottomSafeArea) {
                currentHintBlockTopPosition = alternativeHintBlockTop;
              } else {
                currentHintBlockTopPosition = bottomSafeArea - estimatedHintBlockHeight; // Fallback: stick to bottom safe area
              }
            }
            // Final check to ensure it's not above top safe area if alternative placement was used
            if (currentHintBlockTopPosition < topSafeArea) currentHintBlockTopPosition = topSafeArea;


            // --- START: CHOOSE ONE OVERLAY STYLE FOR TESTING ---

            // OPTION 1: Original CutoutClipper Overlay (DEFAULT)
            return Stack(
              children: [
                ClipPath(
                  clipper: TutorialCutoutClipper(rect: cutoutRect, borderRadius: animatedHighlightBorderRadius, isCircular: false),
                  child: Container(color: Colors.black.withOpacity(0.80)),
                ),
                Positioned(
                  left: cutoutRect.left, top: cutoutRect.top,
                  child: Opacity(
                    opacity: _tutorialCircleOpacity?.value ?? 0.0,
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
                    opacity: _tutorialTextOpacity?.value ?? 0.0,
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

            /*
            // OPTION 2: Simplified Red Box Overlay (UNCOMMENT TO TEST)
            // This helps verify if targetPositionInStack and targetSize are correct.
            // If this red box is correctly placed, the issue is likely in cutoutRect, clipper, or animations.
            return Stack(
              children: [
                // The semi-transparent background (optional for this test, but good for context)
                Container(color: Colors.black.withOpacity(0.80)),
                // A simple box at the calculated position and size of the target
                Positioned(
                  left: targetPositionInStack.dx,
                  top: targetPositionInStack.dy,
                  width: targetSize.width,
                  height: targetSize.height,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 3), // Thicker red border
                    ),
                    child: Center(child: Text("TARGET", style: TextStyle(color: Colors.red, fontSize: 10 * scaleFactor, decoration: TextDecoration.none, fontWeight: FontWeight.normal))),
                  ),
                ),
                // A marker for the ancestor's 0,0 to verify coordinate system
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(width: 15, height: 15, color: Colors.green.withOpacity(0.7)),
                ),
                // Your existing text hint (can be kept to see its positioning too)
                Positioned(
                  left: 20 * scaleFactor, right: 20 * scaleFactor,
                  top: currentHintBlockTopPosition,
                  child: Opacity(
                    opacity: _tutorialTextOpacity?.value ?? 0.0, // Use the same opacity animation
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: hintPaddingHorizontal, vertical: hintPaddingVertical),
                      decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.85), // Different color for distinction
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
            */
            // --- END: CHOOSE ONE OVERLAY STYLE FOR TESTING ---
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

    final nextButtonWidget = SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero, alignment: Alignment.center,
        ),
        onPressed: () {
          if (!_isFront && _currentCardTutorialStep == CardTutorialOverallStep.backNextButton) {
            _advanceBackCardTutorial(); // This will also hide the tutorial
            widget.onNextButtonPressed(); // Proceed to next card
          }
          else if (_currentCardTutorialStep == CardTutorialOverallStep.none && !_isFront) {
            widget.onNextButtonPressed();
          }
          // If tutorial is active but not for the back button (e.g. front tutorial still showing due to quick flip),
          // or if on front, the button press is effectively ignored here, flip handles front tutorial advancement.
        },
        child: Icon(Icons.arrow_forward, size: iconSize, color: Colors.white),
      ),
    );

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
        key: _flipCardStackKey, // Assign key to the Stack
        alignment: Alignment.center, // Usually good for Stacks that fill space
        children: [
          Material( // Material for elevation, ink effects if any deeper
            color: Colors.transparent, // Make material transparent if card has its own bg
            child: FlipCard(
              animationDuration: _flipDuration,
              rotateSide: RotateSide.right,
              disableSplashEffect: true,
              onTapFlipping: false, // We handle tap via GestureDetector on Stack
              axis: FlipAxis.vertical,
              controller: _flipCardController,
              frontWidget: SizedBox( // Ensure front/back widgets fill the space if desired
                width: screenWidth, height: screenHeight,
                child: CardFront(
                  term: widget.term,
                  initialTutorialStep: initialFrontStepForCardFront,
                  onTutorialStepChange: _handleCardFrontTutorialStepChange,
                ),
              ),
              backWidget: SizedBox( // Ensure front/back widgets fill the space if desired
                width: screenWidth, height: screenHeight,
                child: CardBack(
                  image: widget.image,
                  term: widget.term,
                  definition: widget.definition,
                  generation: widget.generation,
                  button: nextButtonWidget,
                  nextButtonKey: _nextButtonKeyOnBackCard, // Pass the key to CardBack
                ),
              ),
            ),
          ),
          _buildCardBackTutorialOverlayWidget(), // Overlay on top
        ],
      ),
    );
  }
}

// Helper class for clamping animations that might overshoot with certain curves
// when used with .repeat() if the curve isn't symmetrical around 0.5.
// For linear or simple curves, this might not be strictly necessary but adds robustness.
class ClampedAnimationDecorator<T> extends Animation<T> with AnimationWithParentMixin<T> {
  @override
  final Animation<T> parent;
  ClampedAnimationDecorator(this.parent);

  @override
  T get value {
    final parentStatus = parent.status;
    final parentValue = parent.value;
    if (parent is Animation<double>) {
      if (parentStatus == AnimationStatus.forward || parentStatus == AnimationStatus.completed) {
        return parentValue;
      } else if (parentStatus == AnimationStatus.reverse || parentStatus == AnimationStatus.dismissed) {
        // This clamping logic assumes the parent animation (especially TweenSequence)
        // might produce values outside [0,1] when reversing if not carefully constructed.
        // For simple Tweens, this is less of an issue.
        // For TweenSequence, ensure weights and tweens behave well in reverse.
        // A common pattern is for parent.value to go from 1.0 down to 0.0.
        // If it goes below 0.0 or above 1.0 due to complex easing, this can help.
        // However, your current tweens seem okay.
      }
    }
    return parentValue;
  }
}