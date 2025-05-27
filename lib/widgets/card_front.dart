// lib/widgets/card_front.dart
import 'dart:async';
import 'dart:math'; // For min()
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/globals.dart'; // Adjust path as needed
import 'tutorial_cutout_clipper.dart'; // IMPORT THE SHARED CLIPPER

// Helper class for clamping animation values (remains the same)
class ClampedAnimationDecorator extends Animation<double> {
  ClampedAnimationDecorator(this.parent);
  final Animation<double> parent;
  @override void addListener(VoidCallback listener) => parent.addListener(listener);
  @override void removeListener(VoidCallback listener) => parent.removeListener(listener);
  @override void addStatusListener(AnimationStatusListener listener) => parent.addStatusListener(listener);
  @override void removeStatusListener(AnimationStatusListener listener) => parent.removeStatusListener(listener);
  @override AnimationStatus get status => parent.status;
  @override double get value => parent.value.clamp(0.0, 1.0);
}

enum CardFrontTutorialStep {
  none,
  term,
  generationIcon,
  tapToFlip,
}

class CardFront extends StatefulWidget {
  final String term;
  final Function(CardFrontTutorialStep step) onTutorialStepChange;
  final CardFrontTutorialStep initialTutorialStep;
  final Widget? previousButton; // MODIFIED: To receive the button widget from FlipCardWidget

  const CardFront({
    super.key,
    required this.term,
    required this.onTutorialStepChange,
    required this.initialTutorialStep,
    this.previousButton, // MODIFIED
  });

  @override
  State<CardFront> createState() => _CardFrontState();
}

class _CardFrontState extends State<CardFront> with TickerProviderStateMixin {
  bool _showGenerationsOverlay = false;

  CardFrontTutorialStep _currentTutorialStep = CardFrontTutorialStep.none;
  AnimationController? _tutorialAnimationController;
  Animation<double>? _tutorialCircleScale;
  Animation<double>? _tutorialCircleOpacity;
  Animation<Offset>? _tutorialPointerOffset;
  Animation<double>? _tutorialTextOpacity;
  AnimationController? _handAnimationController;
  Animation<Offset>? _handPositionAnimation;
  Animation<double>? _handScaleAnimation;

  final GlobalKey _termKey = GlobalKey();
  final GlobalKey _generationIconKey = GlobalKey();
  final GlobalKey _cardFrontStackKey = GlobalKey();

  final Map<CardFrontTutorialStep, String> _tutorialTexts = {
    CardFrontTutorialStep.term: "This is the Slang word whose meaning is to be guessed.",
    CardFrontTutorialStep.generationIcon: "You can see the Generation rules here.",
    CardFrontTutorialStep.tapToFlip: "Tap on the screen to flip the card and see the slang word meaning.",
  };

  @override
  void initState() {
    super.initState();
    _currentTutorialStep = widget.initialTutorialStep;
    _initTutorialAnimations();
    _initHandAnimation();

    if (_currentTutorialStep != CardFrontTutorialStep.none) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tutorialAnimationController?.repeat();
          if (_currentTutorialStep == CardFrontTutorialStep.tapToFlip) {
            _handAnimationController?.repeat(reverse: false);
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant CardFront oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTutorialStep != oldWidget.initialTutorialStep ||
        widget.initialTutorialStep != _currentTutorialStep) {
      setState(() {
        _currentTutorialStep = widget.initialTutorialStep;
        if (_currentTutorialStep != CardFrontTutorialStep.none) {
          _tutorialAnimationController?.reset();
          _tutorialAnimationController?.repeat();
          if (_currentTutorialStep == CardFrontTutorialStep.tapToFlip) {
            _handAnimationController?.reset();
            _handAnimationController?.repeat(reverse: false);
          } else {
            _handAnimationController?.stop();
            _handAnimationController?.reset();
          }
        } else {
          _tutorialAnimationController?.stop();
          _tutorialAnimationController?.reset();
          _handAnimationController?.stop();
          _handAnimationController?.reset();
        }
      });
    }
  }

  void _initTutorialAnimations() {
    _tutorialAnimationController?.dispose();
    _tutorialAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    final clampedTutorialController = ClampedAnimationDecorator(_tutorialAnimationController!);
    final curvedTutorialParentLinear = CurvedAnimation(parent: _tutorialAnimationController!, curve: Curves.linear);
    final clampedCurvedTutorialParentLinear = ClampedAnimationDecorator(curvedTutorialParentLinear);

    _tutorialCircleScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _tutorialAnimationController!, curve: const Interval(0.0, 0.7, curve: Curves.easeInOut)),
    );
    _tutorialCircleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.7), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 45),
    ]).animate(clampedCurvedTutorialParentLinear);
    _tutorialPointerOffset = Tween<Offset>(begin: const Offset(0, 5), end: const Offset(0, -5)).animate(
      CurvedAnimation(parent: _tutorialAnimationController!, curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic)),
    );
    _tutorialTextOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
    ]).animate(clampedTutorialController);
  }

  void _initHandAnimation() {
    _handAnimationController?.dispose();
    _handAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    final curvedHandPositionParent = CurvedAnimation(parent: _handAnimationController!, curve: Curves.easeInOut);
    final clampedHandPositionParent = ClampedAnimationDecorator(curvedHandPositionParent);
    _handPositionAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: const Offset(0.05, 0.05), end: const Offset(0, 0)), weight: 30),
      TweenSequenceItem(tween: ConstantTween(const Offset(0,0)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: const Offset(0,0), end: const Offset(0.05, 0.05)), weight: 30),
    ]).animate(clampedHandPositionParent);
    final curvedHandScaleParent = CurvedAnimation(parent: _handAnimationController!, curve: Curves.elasticOut);
    final clampedHandScaleParent = ClampedAnimationDecorator(curvedHandScaleParent);
    _handScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.85), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
    ]).animate(clampedHandScaleParent);
  }

  void _advanceTutorialStep() async {
    if (!mounted) return;
    CardFrontTutorialStep nextStep = CardFrontTutorialStep.none;
    switch (_currentTutorialStep) {
      case CardFrontTutorialStep.term:
        await setHasSeenCardFrontTermTutorial(true);
        if (!await getHasSeenCardFrontGenerationTutorial()) {
          nextStep = CardFrontTutorialStep.generationIcon;
        } else if (!await getHasSeenCardFrontTapToFlipTutorial()) {
          nextStep = CardFrontTutorialStep.tapToFlip;
        }
        break;
      case CardFrontTutorialStep.generationIcon:
        await setHasSeenCardFrontGenerationTutorial(true);
        if (!await getHasSeenCardFrontTapToFlipTutorial()) {
          nextStep = CardFrontTutorialStep.tapToFlip;
        }
        break;
      case CardFrontTutorialStep.tapToFlip:
        await setHasSeenCardFrontTapToFlipTutorial(true);
        nextStep = CardFrontTutorialStep.none;
        break;
      case CardFrontTutorialStep.none:
        return;
    }
    setState(() {
      _currentTutorialStep = nextStep;
      widget.onTutorialStepChange(nextStep); // Notify FlipCardWidget
      if (nextStep != CardFrontTutorialStep.none) {
        _tutorialAnimationController?.reset();
        _tutorialAnimationController?.repeat();
        if (nextStep == CardFrontTutorialStep.tapToFlip) {
          _handAnimationController?.reset();
          _handAnimationController?.repeat(reverse: false);
        } else {
          _handAnimationController?.stop();
          _handAnimationController?.reset();
        }
      } else {
        _tutorialAnimationController?.stop();
        _tutorialAnimationController?.reset();
        _handAnimationController?.stop();
        _handAnimationController?.reset();
      }
    });
  }

  @override
  void dispose() {
    _tutorialAnimationController?.dispose();
    _handAnimationController?.dispose();
    super.dispose();
  }

  Widget _buildGenerationsOverlay(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final overlayWidth = screenWidth * 0.85;
    final overlayMaxHeight = screenHeight * 0.7;
    return Center(
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(16.0),
        color: Colors.transparent,
        child: Container(
          width: overlayWidth,
          constraints: BoxConstraints(maxHeight: overlayMaxHeight, minWidth: 280),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.black54),
                    tooltip: 'Close',
                    onPressed: () {
                      if (_currentTutorialStep == CardFrontTutorialStep.generationIcon) {
                        _advanceTutorialStep();
                      }
                      setState(() { _showGenerationsOverlay = false; });
                    },
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                  child: SvgPicture.asset('assets/images/generations.svg', fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFrontTutorialOverlayWidget() {
    if (_tutorialAnimationController == null ||
        _tutorialCircleScale == null || _tutorialCircleOpacity == null ||
        _tutorialPointerOffset == null || _tutorialTextOpacity == null ||
        _currentTutorialStep == CardFrontTutorialStep.none) {
      return const SizedBox.shrink();
    }
    GlobalKey? currentTargetKey;
    bool isHighlightCircular = false;
    double highlightPadding = 0;
    switch (_currentTutorialStep) {
      case CardFrontTutorialStep.term:
        currentTargetKey = _termKey;
        highlightPadding = 10.0 * (MediaQuery.of(context).size.width / 400);
        break;
      case CardFrontTutorialStep.generationIcon:
        currentTargetKey = _generationIconKey;
        isHighlightCircular = true;
        highlightPadding = 8.0 * (MediaQuery.of(context).size.width / 400);
        break;
      case CardFrontTutorialStep.tapToFlip:
        if (_handAnimationController == null || _handPositionAnimation == null || _handScaleAnimation == null) {
          return const SizedBox.shrink();
        }
        return _buildTapToFlipOverlay();
      default:
        return const SizedBox.shrink();
    }
    if (currentTargetKey.currentContext == null || _cardFrontStackKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() {}); });
      return Positioned.fill(child: Container(color: Colors.black.withOpacity(0.7), child: Center(child: Text("Initializing hint...", style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 14)))));
    }
    final RenderBox? targetRenderBox = currentTargetKey.currentContext!.findRenderObject() as RenderBox?;
    final RenderBox? ancestorRenderBox = _cardFrontStackKey.currentContext!.findRenderObject() as RenderBox?;
    if (targetRenderBox == null || !targetRenderBox.attached || ancestorRenderBox == null || !ancestorRenderBox.attached) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() {}); });
      return Positioned.fill(child: Container(color: Colors.black.withOpacity(0.7), child: Center(child: Text("Waiting for element...", style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 14)))));
    }
    final Offset targetPositionInStack = targetRenderBox.localToGlobal(Offset.zero, ancestor: ancestorRenderBox);
    final Size targetSize = targetRenderBox.size;
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
    bool pointUpwards;
    if (_currentTutorialStep == CardFrontTutorialStep.term) {
      pointUpwards = targetCenter.dy > screenHeight * 0.6;
    } else if (_currentTutorialStep == CardFrontTutorialStep.generationIcon) {
      pointUpwards = false; // Text appears to the left for generation icon
    } else { // Should not happen for other steps needing this logic
      pointUpwards = targetCenter.dy > screenHeight * 0.6;
    }
    double estimatedTextHeight = (_tutorialTexts[_currentTutorialStep] ?? "").length > 40 ? hintTextFontSize * 3.0 : hintTextFontSize * 1.8;
    double estimatedHintBlockHeight = estimatedTextHeight + (hintPaddingVertical * 2) + (hintTextContainerBorderWidth*2);
    double verticalOffsetSpacing = 15 * scaleFactor;
    double initialHintBlockTopPosition = pointUpwards
        ? targetCenter.dy - (targetSize.height/2) - estimatedHintBlockHeight - verticalOffsetSpacing
        : targetCenter.dy + (targetSize.height/2) + verticalOffsetSpacing;
    double hintBlockLeftPosition = 20 * scaleFactor;
    double? hintBlockRightPosition = 20 * scaleFactor;
    double? textWidthConstraint; // For generationIcon text
    if (_currentTutorialStep == CardFrontTutorialStep.generationIcon) {
      textWidthConstraint = screenWidth * 0.55; // Max width for the text box
      // Calculate actual required width for the text box
      final tempTextPainter = TextPainter(
          text: TextSpan(text: _tutorialTexts[_currentTutorialStep], style: TextStyle(fontSize: hintTextFontSize)),
          textDirection: TextDirection.ltr)..layout(maxWidth: textWidthConstraint - hintPaddingHorizontal *2);
      double estimatedTextContentWidth = tempTextPainter.width;
      double estimatedContainerWidth = estimatedTextContentWidth + hintPaddingHorizontal * 2 + hintTextContainerBorderWidth *2;

      // Position text box to the left of the icon
      hintBlockLeftPosition = max(20 * scaleFactor, targetCenter.dx - (targetRenderBox.size.width/2) - estimatedContainerWidth - (15 * scaleFactor));
      hintBlockRightPosition = null; // Let width be determined by content or textWidthConstraint
      // Vertically center the text box with the icon
      initialHintBlockTopPosition = targetCenter.dy - estimatedHintBlockHeight / 2;
    }
    final double topSafeArea = MediaQuery.of(context).padding.top + (10 * scaleFactor);
    final double bottomSafeArea = screenHeight - MediaQuery.of(context).padding.bottom - (10 * scaleFactor);
    return Positioned.fill(
      child: GestureDetector(
        onTap: _advanceTutorialStep,
        child: AnimatedBuilder(
          animation: Listenable.merge([_tutorialAnimationController!, _tutorialPointerOffset!, _tutorialCircleScale!, _tutorialCircleOpacity!, _tutorialTextOpacity!]),
          builder: (context, child) {
            final double currentAnimatedScale = _tutorialCircleScale!.value;
            double animatedHighlightWidth = (targetSize.width + highlightPadding * 2) * currentAnimatedScale;
            double animatedHighlightHeight = (targetSize.height + highlightPadding * 2) * currentAnimatedScale;
            if (isHighlightCircular) {
              animatedHighlightWidth = (max(targetSize.width, targetSize.height) + highlightPadding * 2) * currentAnimatedScale;
              animatedHighlightHeight = animatedHighlightWidth;
            }
            final BorderRadius animatedHighlightBorderRadius = isHighlightCircular
                ? BorderRadius.circular(animatedHighlightWidth / 2)
                : BorderRadius.circular(8.0 * currentAnimatedScale * scaleFactor);
            final Rect cutoutRect = Rect.fromCenter(center: targetCenter, width: animatedHighlightWidth, height: animatedHighlightHeight);
            double currentHintBlockTopPosition = initialHintBlockTopPosition;
            // Only apply pointer offset for non-generationIcon steps
            if (_currentTutorialStep != CardFrontTutorialStep.generationIcon) {
              currentHintBlockTopPosition += _tutorialPointerOffset!.value.dy;
            }
            // Adjust hint block position to stay within safe area
            if (currentHintBlockTopPosition < topSafeArea) {
              currentHintBlockTopPosition = topSafeArea;
            } else if (currentHintBlockTopPosition + estimatedHintBlockHeight > bottomSafeArea) {
              // If it overflows bottom, try to reposition based on original logic, or clamp
              if (_currentTutorialStep == CardFrontTutorialStep.generationIcon) {
                currentHintBlockTopPosition = bottomSafeArea - estimatedHintBlockHeight;
                if (currentHintBlockTopPosition < topSafeArea) currentHintBlockTopPosition = topSafeArea; // Clamp to top if still too big
              } else { // For term, try placing above if it was below, or vice-versa
                double alternativeTopPosition = !pointUpwards // if it was pointing down (text below)
                    ? targetCenter.dy - (targetSize.height/2) - estimatedHintBlockHeight - verticalOffsetSpacing // try above
                    : targetCenter.dy + (targetSize.height/2) + verticalOffsetSpacing; // try below
                if (_currentTutorialStep != CardFrontTutorialStep.generationIcon) {
                  alternativeTopPosition += _tutorialPointerOffset!.value.dy;
                }

                if (alternativeTopPosition >= topSafeArea && (alternativeTopPosition + estimatedHintBlockHeight <= bottomSafeArea)) {
                  currentHintBlockTopPosition = alternativeTopPosition;
                } else { // If alternative also doesn't fit, clamp to bottom
                  currentHintBlockTopPosition = bottomSafeArea - estimatedHintBlockHeight;
                  if (currentHintBlockTopPosition < topSafeArea) currentHintBlockTopPosition = topSafeArea;
                }
              }
            }
            double currentHintBlockLeft = hintBlockLeftPosition;
            double? currentHintBlockRight = hintBlockRightPosition;

            // Recalculate left for generationIcon in case textWidthConstraint is used
            if (_currentTutorialStep == CardFrontTutorialStep.generationIcon && textWidthConstraint != null) {
              final tempTextPainter = TextPainter(
                  text: TextSpan(text: _tutorialTexts[_currentTutorialStep], style: TextStyle(fontSize: hintTextFontSize)),
                  textDirection: TextDirection.ltr)..layout(maxWidth: textWidthConstraint - hintPaddingHorizontal * 2);
              double actualTextContentWidth = tempTextPainter.width;
              double actualContainerWidth = actualTextContentWidth + hintPaddingHorizontal * 2 + hintTextContainerBorderWidth * 2;

              currentHintBlockLeft = max(20 * scaleFactor, targetCenter.dx - (targetRenderBox.size.width/2) - actualContainerWidth - (15 * scaleFactor));

              // Ensure it doesn't go off-screen left
              if (currentHintBlockLeft < (20 * scaleFactor)) {
                currentHintBlockLeft = (20*scaleFactor);
              }
            }

            return Stack(
              children: [
                ClipPath(
                  clipper: TutorialCutoutClipper(rect: cutoutRect, borderRadius: animatedHighlightBorderRadius, isCircular: isHighlightCircular),
                  child: Container(color: Colors.black.withOpacity(0.80)),
                ),
                Positioned(
                  left: cutoutRect.left, top: cutoutRect.top,
                  child: Opacity(
                    opacity: _tutorialCircleOpacity!.value,
                    child: Container(
                      width: cutoutRect.width, height: cutoutRect.height,
                      decoration: BoxDecoration(
                        shape: isHighlightCircular ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius: isHighlightCircular ? null : animatedHighlightBorderRadius,
                        border: Border.all(color: Colors.white.withOpacity(0.8), width: spotlightBorderWidth),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: currentHintBlockLeft,
                  right: currentHintBlockRight, // Null for generationIcon if width is set
                  top: currentHintBlockTopPosition,
                  width: (_currentTutorialStep == CardFrontTutorialStep.generationIcon && textWidthConstraint != null) ? textWidthConstraint : null,
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
                        _tutorialTexts[_currentTutorialStep] ?? "Hint",
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

  Widget _buildTapToFlipOverlay() {
    if (_tutorialTextOpacity == null || _tutorialPointerOffset == null ||
        _handAnimationController == null || _handPositionAnimation == null || _handScaleAnimation == null) {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double scaleFactor = screenWidth / 400;
    final double hintTextFontSize = 18 * scaleFactor;
    final double handIconSize = 60 * scaleFactor;
    return Positioned.fill(
      child: GestureDetector(
        onTap: _advanceTutorialStep,
        child: Container(
          color: Colors.black.withOpacity(0.75),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _tutorialTextOpacity!, _tutorialPointerOffset!,
              _handAnimationController!, _handPositionAnimation!, _handScaleAnimation!,
            ]),
            builder: (context, child) {
              double handScreenX = screenWidth * 0.5 - (handIconSize / 2);
              double handScreenY = screenHeight * 0.55;
              double animatedDx = (_handPositionAnimation!.value.dx) * screenWidth * 0.1;
              double animatedDy = (_handPositionAnimation!.value.dy) * screenHeight * 0.1;
              return Opacity(
                opacity: _tutorialTextOpacity!.value.clamp(0.0, 1.0),
                child: Stack(
                  children: [
                    Positioned(
                      left: handScreenX + animatedDx,
                      top: handScreenY + animatedDy,
                      child: Transform.scale(
                        scale: _handScaleAnimation!.value,
                        child: Icon(
                          Icons.touch_app_outlined,
                          size: handIconSize,
                          color: Colors.white.withOpacity(0.9 * _tutorialTextOpacity!.value.clamp(0.0,1.0)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: screenHeight * 0.15 + (_tutorialPointerOffset!.value.dy),
                      left: 20 * scaleFactor, right: 20 * scaleFactor,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor, vertical: 10 * scaleFactor),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(10 * scaleFactor),
                            border: Border.all(color: Colors.white70, width: 1.5 * scaleFactor)
                        ),
                        child: Text(
                          _tutorialTexts[CardFrontTutorialStep.tapToFlip] ?? "Tap to flip",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white, fontSize: hintTextFontSize, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double generationLogoSize = screenWidth * 0.085;
    bool isTutorialActive = _currentTutorialStep != CardFrontTutorialStep.none;

    // Padding for the button container, consistent with CardBack
    final double bottomButtonContainerPadding = screenHeight * 0.10;
    // If CardBack's button had an additional upward offset, match it here.
    // Assuming card_back.dart uses:
    // final double buttonUpwardOffset = screenHeight * 0.02;
    // Then the total padding would be:
    // final double totalBottomPadding = bottomButtonContainerPadding + buttonUpwardOffset;
    // For now, just using the direct bottomButtonContainerPadding from your CardFront.
    final double totalBottomPadding = bottomButtonContainerPadding;


    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        key: _cardFrontStackKey,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.term,
                    key: _termKey,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.09,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SvgPicture.asset(
                'assets/images/slang-icon.svg',
                height: MediaQuery.of(context).size.height * 0.08,
                width: MediaQuery.of(context).size.height * 0.08,
                colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
            ),
          ),
          Positioned(
            key: _generationIconKey,
            top: statusBarHeight + 16.0,
            right: 16.0,
            child: InkWell(
              onTap: () {
                if (isTutorialActive && _currentTutorialStep == CardFrontTutorialStep.generationIcon) {
                  _advanceTutorialStep();
                } else if (!isTutorialActive || _currentTutorialStep != CardFrontTutorialStep.generationIcon) {
                  setState(() { _showGenerationsOverlay = true; });
                }
              },
              borderRadius: BorderRadius.circular(generationLogoSize / 2),
              child: SvgPicture.asset(
                'assets/images/generation-icon.svg',
                height: generationLogoSize,
                width: generationLogoSize,
              ),
            ),
          ),

          // Display the passed "Previous" Button if available
          if (widget.previousButton != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: totalBottomPadding), // Use the calculated padding
                child: widget.previousButton!,
              ),
            ),

          if (_showGenerationsOverlay) _buildGenerationsOverlay(context),
          if (isTutorialActive) _buildCardFrontTutorialOverlayWidget(),
        ],
      ),
    );
  }
}