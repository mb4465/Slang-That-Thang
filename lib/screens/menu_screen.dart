import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:collection/collection.dart';
import 'package:audioplayers/audioplayers.dart';

// Adjust these import paths based on your actual project structure
import '../data/globals.dart';
import 'HowToPlay.dart'; // Keep this, as "How to Play" button navigates to it
import 'AboutScreen.dart';
import 'generational_card_screen.dart';
import 'settings_screen.dart';
import 'game_button.dart';
import 'home_screen.dart'; // Added import for HomeScreen

const _kRemoveAdsProductId = 'remove_ads_premium';
const String _kGooglePlayReviewCouponCode = "REVIEWACCESS2025";

enum MenuTutorialStep {
  none,
  howToPlay,
  generationalCard,
  removeAds,
  settings,
  about,
  tutorialButton, // Represents the "Tutorial" button itself
  backArrow,
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _TutorialCutoutClipper extends CustomClipper<Path> {
  final Rect rect;
  final BorderRadius borderRadius; // Keep for buttons
  final bool isCircular; // Added for back arrow

  _TutorialCutoutClipper({required this.rect, required this.borderRadius, this.isCircular = false});

  @override
  Path getClip(Size size) {
    Path cutoutPath;
    if (isCircular) {
      cutoutPath = Path()..addOval(rect);
    } else {
      final RRect cutoutRRect = RRect.fromRectAndCorners(
        rect,
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
        bottomLeft: borderRadius.bottomLeft,
        bottomRight: borderRadius.bottomRight,
      );
      cutoutPath = Path()..addRRect(cutoutRRect);
    }

    final Path fullScreenPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    return Path.combine(
      PathOperation.difference,
      fullScreenPath,
      cutoutPath,
    );
  }

  @override
  bool shouldReclip(_TutorialCutoutClipper oldClipper) {
    return oldClipper.rect != rect || oldClipper.borderRadius != borderRadius || oldClipper.isCircular != isCircular;
  }
}


class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _buttonPressController;
  int? _selectedButtonIndex;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Shared AudioPlayer instance

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _sub;
  bool _storeAvailable = false;
  List<ProductDetails> _products = [];
  bool _adsRemoved = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _errorMessage;
  final TextEditingController _couponController = TextEditingController();

  bool _isLoadingMenuTutorialStatus = true;
  MenuTutorialStep _currentMenuTutorialStep = MenuTutorialStep.none;
  bool _prefsForMenuTutorialLoaded = false;

  AnimationController? _menuTutorialAnimationController;
  Animation<double>? _menuTutorialCircleScale;
  Animation<double>? _menuTutorialCircleOpacity;
  Animation<Offset>? _menuTutorialPointerOffset;
  Animation<double>? _menuTutorialTextOpacity;

  // Keys for tutorial targeting - ensure they match the button order in build()
  final GlobalKey _tutorialButtonKey = GlobalKey();
  final GlobalKey _howToPlayKey = GlobalKey();
  final GlobalKey _generationalCardKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _removeAdsKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _backArrowKey = GlobalKey();

  // Tutorial hint texts
  final Map<MenuTutorialStep, String> tutorialTexts = {
    MenuTutorialStep.tutorialButton: "Tap here to restart the full app tutorial, including game play.",
    MenuTutorialStep.howToPlay: "You can see the game rules here.",
    MenuTutorialStep.generationalCard: "View the list of generations and their timeframes.",
    MenuTutorialStep.settings: "You can mute/unmute all the sounds.",
    MenuTutorialStep.removeAds: "You get 20 rounds free. After that, you'll need to pay to remove ads for Full Access.",
    MenuTutorialStep.about: "Learn more about SLANG THAT THANG!!", // Simplified
    MenuTutorialStep.backArrow: "Click the back arrow to go back to the Home Screen.",
  };

  @override
  void initState() {
    super.initState();
    _buttonPressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _initIapAndAdsStatus();
    _initMenuTutorialAnimations();
    _loadMenuTutorialState();
  }

  Future<void> _initIapAndAdsStatus() async {
    _adsRemoved = await getAdsRemovedStatus();
    if (!mounted) return;
    setState(() {});

    _sub = _iap.purchaseStream.listen(_onPurchaseUpdates, onError: (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Purchase stream error: $e";
        _purchasePending = false;
        _loading = false;
      });
    });

    final available = await _iap.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() {
        _storeAvailable = false;
        _loading = false;
        _errorMessage = "Store not available. In-app purchases are disabled.";
      });
      return;
    }

    _storeAvailable = true;
    try {
      final response = await _iap.queryProductDetails({_kRemoveAdsProductId});
      if (!mounted) return;
      if (response.error != null) {
        setState(() {
          _errorMessage = response.error!.message;
          _loading = false;
        });
        return;
      }
      if (response.productDetails.isEmpty) {
        setState(() {
          _errorMessage = "Product '$_kRemoveAdsProductId' not found in store.";
          _loading = false;
        });
        return;
      }
      setState(() {
        _products = response.productDetails;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to query products: $e";
        _loading = false;
      });
    }
  }

  void _initMenuTutorialAnimations() {
    _menuTutorialAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _menuTutorialCircleScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _menuTutorialAnimationController!, curve: const Interval(0.0, 0.7, curve: Curves.easeInOut)),
    );
    _menuTutorialCircleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.7), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 45),
    ]).animate(CurvedAnimation(parent: _menuTutorialAnimationController!, curve: Curves.linear));
    _menuTutorialPointerOffset = Tween<Offset>(begin: const Offset(0, 5), end: const Offset(0, -5)).animate(
      CurvedAnimation(parent: _menuTutorialAnimationController!, curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic)),
    );
    _menuTutorialTextOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
    ]).animate(_menuTutorialAnimationController!);
  }

  Future<void> _loadMenuTutorialState() async {
    if (!mounted) return;
    bool seenMenuTutorial = await getHasSeenMenuScreenTutorial();
    if (!mounted) return;

    _prefsForMenuTutorialLoaded = true;
    if (!seenMenuTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentMenuTutorialStep = MenuTutorialStep.tutorialButton;
            _menuTutorialAnimationController?.repeat();
          });
        }
      });
    } else {
      _currentMenuTutorialStep = MenuTutorialStep.none;
    }
    setState(() => _isLoadingMenuTutorialStatus = false);
  }

  void _advanceMenuTutorial() async {
    if (!mounted) return;
    MenuTutorialStep nextStep = MenuTutorialStep.none;
    switch (_currentMenuTutorialStep) {
      case MenuTutorialStep.tutorialButton: nextStep = MenuTutorialStep.howToPlay; break;
      case MenuTutorialStep.howToPlay: nextStep = MenuTutorialStep.generationalCard; break;
      case MenuTutorialStep.generationalCard: nextStep = MenuTutorialStep.settings; break;
      case MenuTutorialStep.settings: nextStep = MenuTutorialStep.removeAds; break;
      case MenuTutorialStep.removeAds: nextStep = MenuTutorialStep.about; break;
      case MenuTutorialStep.about: nextStep = MenuTutorialStep.backArrow; break;
      case MenuTutorialStep.backArrow:
        nextStep = MenuTutorialStep.none;
        await setHasSeenMenuScreenTutorial(true);
        break;
      case MenuTutorialStep.none: return;
    }
    setState(() {
      _currentMenuTutorialStep = nextStep;
      if (nextStep == MenuTutorialStep.none) {
        _menuTutorialAnimationController?.stop();
        _menuTutorialAnimationController?.reset();
      } else {
        _menuTutorialAnimationController?.reset();
        _menuTutorialAnimationController?.repeat();
      }
    });
  }

  Future<void> _startHomeTutorial() async { // This is an action, not a tutorial step advancement
    await _playStandardClickSound(); // Play standard click for this action
    await setHasSeenWelcomeTutorial(false);
    await setHasSeenBasicsTutorial(false);
    await setHasSeenHowToPlayTutorial(false);
    await setHasSeenStartGameButtonTutorial(false);
    await setHasSeenMenuButtonTutorial(false);
    await setHasSeenMenuScreenTutorial(false);
    await setHasSeenCardFrontTermTutorial(false);
    await setHasSeenCardFrontGenerationTutorial(false);
    await setHasSeenCardFrontTapToFlipTutorial(false);
    await setHasSeenCardBackNextButtonTutorial(false);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void dispose() {
    _buttonPressController.dispose();
    _sub.cancel();
    _couponController.dispose();
    _menuTutorialAnimationController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onPurchaseUpdates(List<PurchaseDetails> detailsList) {
    if (!mounted) return;
    for (final pd in detailsList) {
      switch (pd.status) {
        case PurchaseStatus.pending: setState(() => _purchasePending = true); break;
        case PurchaseStatus.error:
          setState(() {
            _errorMessage = pd.error?.message ?? "Unknown purchase error";
            _purchasePending = false;
          });
          if (pd.pendingCompletePurchase) _iap.completePurchase(pd);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliver(pd);
          break;
        case PurchaseStatus.canceled:
          setState(() => _purchasePending = false);
          if (pd.pendingCompletePurchase) _iap.completePurchase(pd);
          break;
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails pd) async {
    final valid = pd.productID == _kRemoveAdsProductId;
    if (valid) {
      await setAdsRemoved(true);
      if (!mounted) return;
      setState(() {
        _adsRemoved = true;
        _purchasePending = false;
      });
      _showSuccessDialog('Purchase successful! Ads removed. You may need to restart the app.');
    }
    if (pd.pendingCompletePurchase) await _iap.completePurchase(pd);
  }

  void _showSuccessDialog([String? customMessage]) {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogTitleFontSize = max(18.0, screenWidth * 0.05);
    final dialogContentFontSize = max(14.0, screenWidth * 0.04);
    final dialogActionFontSize = max(14.0, screenWidth * 0.04);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Success', style: TextStyle(fontSize: dialogTitleFontSize, fontWeight: FontWeight.bold)),
        content: Text(customMessage ?? 'Ads removed! Restart the app if you still see ads.', style: TextStyle(fontSize: dialogContentFontSize)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(fontSize: dialogActionFontSize, color: Theme.of(context).primaryColor))),
        ],
      ),
    );
  }

  // --- RENAMED and MODIFIED Sound Methods ---
  Future<void> _playStandardClickSound() async {
    if (await getSoundEnabled()) {
      await _audioPlayer.play(AssetSource('audio/click.mp3'));
    }
  }

  Future<void> _playTutorialAdvanceSound() async {
    if (await getSoundEnabled()) {
      await _audioPlayer.play(AssetSource('audio/rules.mp3'));
    }
  }
  // --- END Sound Method Modifications ---


  Future<void> _initiateInAppPurchase() async {
    // This action itself might have a sound if considered a UI interaction
    // For now, let's assume the button click (_showRemoveAdsOptionsDialog) handles the sound.
    final pd = _products.firstWhereOrNull((p) => p.id == _kRemoveAdsProductId);
    if (pd == null) {
      if (!mounted) return;
      setState(() => _errorMessage = "Product info unavailable for purchase.");
      return;
    }
    if (!mounted) return;
    setState(() => _purchasePending = true);
    _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: pd));
  }

  Widget _buildDialogGameButton({ required String text, required VoidCallback? onPressed}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double buttonWidth = min(screenWidth * 0.65, 260.0);
    const double buttonHeight = 48.0;
    final double buttonFontSize = max(14.0, buttonHeight * 0.32);
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: GameButton(text: text, width: buttonWidth, height: buttonHeight, onPressed: onPressed, isBold: true, fontSize: buttonFontSize),
      ),
    );
  }

  Future<void> _showCouponInputDialog() async {
    if (!mounted) return;
    _couponController.clear();
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Center(child: Text('Enter Coupon Code', style: TextStyle(fontSize: max(18.0, screenWidth * 0.055), fontWeight: FontWeight.bold))),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _couponController, decoration: const InputDecoration(hintText: "Coupon Code", border: OutlineInputBorder()), autofocus: true),
                const SizedBox(height: 20),
                _buildDialogGameButton(text: 'Submit', onPressed: () async {
                  await _playStandardClickSound(); // Sound for submit button
                  final enteredCode = _couponController.text.trim();
                  Navigator.of(dialogContext).pop();
                  if (enteredCode == _kGooglePlayReviewCouponCode) {
                    await setAdsRemoved(true);
                    if (!mounted) return;
                    setState(() => _adsRemoved = true);
                    _showSuccessDialog("Coupon applied! Ads removed. You may need to restart.");
                  } else {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid coupon code.')));
                  }
                },
                ),
              ],
            ),
          ),
          actions: <Widget>[TextButton(child: Text('Cancel', style: TextStyle(color: Theme.of(context).primaryColor)), onPressed: () async {
            await _playStandardClickSound(); // Sound for cancel
            Navigator.of(dialogContext).pop();
          })],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      },
    );
  }

  Future<void> _showRemoveAdsOptionsDialog() async {
    await _playStandardClickSound(); // Sound for opening this dialog
    if (!mounted) return;
    final productDetailsForDialog = _products.firstWhereOrNull((p) => p.id == _kRemoveAdsProductId);
    final screenWidth = MediaQuery.of(context).size.width;
    String payButtonText;
    bool canPay = false;
    if (_purchasePending) payButtonText = 'Processing...';
    else if (!_storeAvailable) payButtonText = 'Pay (Store Unavailable)';
    else if (_loading && productDetailsForDialog == null) payButtonText = 'Pay (Loading Store...)';
    else if (productDetailsForDialog == null) payButtonText = 'Pay (Item Unavailable)';
    else { payButtonText = 'Pay ${productDetailsForDialog.price}'; canPay = true; }
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Center(child: Text('Remove Ads', style: TextStyle(fontSize: max(18.0, screenWidth * 0.06), fontWeight: FontWeight.bold))),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _buildDialogGameButton(text: 'Enter Coupon Code', onPressed: () async {
                  await _playStandardClickSound(); // Sound for button
                  Navigator.of(dialogContext).pop(); _showCouponInputDialog();
                }),
                _buildDialogGameButton(text: payButtonText, onPressed: canPay ? () async {
                  await _playStandardClickSound(); // Sound for button
                  Navigator.of(dialogContext).pop(); _initiateInAppPurchase();
                } : null),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextButton(child: Text('Cancel', style: TextStyle(fontSize: max(14.0, screenWidth * 0.04), color: Theme.of(context).hintColor)),
                  onPressed: () async {
                    await _playStandardClickSound(); // Sound for cancel
                    Navigator.of(dialogContext).pop();
                  }),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      },
    );
  }

  void _navigateTo(int index, Widget screen) async {
    if (_buttonPressController.isAnimating || _selectedButtonIndex != null ||
        (_currentMenuTutorialStep != MenuTutorialStep.none && _currentMenuTutorialStep != MenuTutorialStep.backArrow)) return;

    await _playStandardClickSound(); // Standard sound for navigation
    if (!mounted) return;
    setState(() => _selectedButtonIndex = index);
    _buttonPressController.forward().then((_) {
      if (!mounted) {
        _buttonPressController.reset();
        setState(() => _selectedButtonIndex = null);
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
        if (mounted) {
          _buttonPressController.reset();
          setState(() => _selectedButtonIndex = null);
        }
      });
    }).catchError((_){
      if (mounted) {
        _buttonPressController.reset();
        setState(() => _selectedButtonIndex = null);
      }
    });
  }

  void _handleTutorialPress(int index) async { // This is for the "Tutorial" button action
    if (_buttonPressController.isAnimating || _selectedButtonIndex != null ||
        (_currentMenuTutorialStep != MenuTutorialStep.none && _currentMenuTutorialStep != MenuTutorialStep.backArrow)) return;

    // Sound is played by _startHomeTutorial
    if (!mounted) return;
    setState(() => _selectedButtonIndex = index);

    try {
      await _buttonPressController.forward().orCancel;
      if (mounted) {
        await _startHomeTutorial(); // Action for "Tutorial" button (plays its own sound)
      }
    } catch (e) {
      // Error handling
    } finally {
      if (mounted && _selectedButtonIndex == index) {
        _buttonPressController.reset();
        setState(() => _selectedButtonIndex = null);
      }
    }
  }

  Widget _buildButton(int index, String text, VoidCallback onTap, {bool disabled = false, GlobalKey? key}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double maxButtonWidth = 400.0;
    final double buttonWidth = min(screenWidth * 0.8, maxButtonWidth);
    final double buttonHeight = screenHeight * 0.07;
    final double buttonFontSize = max(14.0, buttonHeight * 0.3);

    String currentButtonText = text;
    bool isTutorialTargetingThisButton = false;

    if (_currentMenuTutorialStep != MenuTutorialStep.none) {
      switch (_currentMenuTutorialStep) {
        case MenuTutorialStep.tutorialButton:
          if (key == _tutorialButtonKey) isTutorialTargetingThisButton = true;
          break;
        case MenuTutorialStep.howToPlay:
          if (key == _howToPlayKey) isTutorialTargetingThisButton = true;
          break;
        case MenuTutorialStep.generationalCard:
          if (key == _generationalCardKey) isTutorialTargetingThisButton = true;
          break;
        case MenuTutorialStep.settings:
          if (key == _settingsKey) isTutorialTargetingThisButton = true;
          break;
        case MenuTutorialStep.removeAds:
          if (key == _removeAdsKey) isTutorialTargetingThisButton = true;
          break;
        case MenuTutorialStep.about:
          if (key == _aboutKey) isTutorialTargetingThisButton = true;
          break;
        default: break;
      }
    }

    final bool effectivelyDisabled = disabled ||
        (_currentMenuTutorialStep != MenuTutorialStep.none &&
            _currentMenuTutorialStep != MenuTutorialStep.backArrow &&
            !isTutorialTargetingThisButton);

    VoidCallback? finalOnPressed;
    if (effectivelyDisabled) {
      finalOnPressed = null;
    } else if (isTutorialTargetingThisButton && _currentMenuTutorialStep != MenuTutorialStep.backArrow) {
      // If this button is the tutorial target, its press should advance the tutorial.
      // Sound will be played by the overlay's tap.
      finalOnPressed = () {
        _advanceMenuTutorial();
      };
    } else {
      finalOnPressed = onTap; // Standard action, associated sound is played within onTap (e.g., _navigateTo)
    }

    return Opacity(
      opacity: finalOnPressed == null ? 0.5 : 1.0,
      child: Transform.translate(
        key: key,
        offset: _selectedButtonIndex == index ? Offset(_buttonPressController.value * screenWidth, 0) : Offset.zero,
        child: GameButton(
            text: currentButtonText, // Keep original text even if highlighted by tutorial
            width: buttonWidth,
            height: buttonHeight,
            onPressed: finalOnPressed,
            isBold: true,
            fontSize: buttonFontSize
        ),
      ),
    );
  }

  Widget _buildMenuTutorialHintOverlayWidget() {
    if (_menuTutorialAnimationController == null || _currentMenuTutorialStep == MenuTutorialStep.none) {
      return const SizedBox.shrink();
    }

    GlobalKey? currentTargetKey;
    switch (_currentMenuTutorialStep) {
      case MenuTutorialStep.tutorialButton: currentTargetKey = _tutorialButtonKey; break;
      case MenuTutorialStep.howToPlay: currentTargetKey = _howToPlayKey; break;
      case MenuTutorialStep.generationalCard: currentTargetKey = _generationalCardKey; break;
      case MenuTutorialStep.settings: currentTargetKey = _settingsKey; break;
      case MenuTutorialStep.removeAds: currentTargetKey = _removeAdsKey; break;
      case MenuTutorialStep.about: currentTargetKey = _aboutKey; break;
      case MenuTutorialStep.backArrow: currentTargetKey = _backArrowKey; break;
      default: return const SizedBox.shrink();
    }

    if (currentTargetKey.currentContext == null || _stackKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentMenuTutorialStep != MenuTutorialStep.none) {
          setState(() {});
        }
      });
      return Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.8),
          child: const Center(child: Text("Initializing tutorial...", style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 16))),
        ),
      );
    }

    final RenderBox? targetRenderBox = currentTargetKey.currentContext!.findRenderObject() as RenderBox?;
    final RenderBox? ancestorRenderBox = _stackKey.currentContext!.findRenderObject() as RenderBox?;

    if (targetRenderBox == null || !targetRenderBox.attached || ancestorRenderBox == null || !ancestorRenderBox.attached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentMenuTutorialStep != MenuTutorialStep.none) {
          setState(() {});
        }
      });
      return Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.8),
          child: const Center(child: Text("Waiting for layout...", style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 16))),
        ),
      );
    }

    final Offset targetPositionInStack = targetRenderBox.localToGlobal(Offset.zero, ancestor: ancestorRenderBox);
    final Size targetSize = targetRenderBox.size;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double scaleFactor = MediaQuery.of(context).size.width / 400;
    final double hintTextFontSize = 16 * scaleFactor;
    final double spotlightBorderWidth = 2.5 * scaleFactor;
    final double backIconSizeForHint = max(24.0, screenWidth * 0.07);

    final Offset targetCenter = Offset(
      targetPositionInStack.dx + targetSize.width / 2,
      targetPositionInStack.dy + targetSize.height / 2,
    );

    final double hintPaddingHorizontal = max(10.0, 14.0 * scaleFactor);
    final double hintPaddingVertical = max(6.0, 9.0 * scaleFactor);
    final double hintTextContainerBorderWidth = max(1.0, 1.5 * scaleFactor);
    final double hintContainerCornerRadius = max(6.0, 8.0 * scaleFactor);

    bool pointUpwards;
    if (_currentMenuTutorialStep == MenuTutorialStep.backArrow) {
      pointUpwards = false;
    } else {
      pointUpwards = targetCenter.dy > screenHeight * 0.6;
    }

    double estimatedTextHeight = (tutorialTexts[_currentMenuTutorialStep] ?? "").length > 40
        ? hintTextFontSize * 3.5
        : hintTextFontSize * 2.0;
    double estimatedHintBlockHeight = estimatedTextHeight + (hintPaddingVertical * 2);

    double verticalOffsetSpacing = 10 * scaleFactor;
    if (pointUpwards &&
        (_currentMenuTutorialStep == MenuTutorialStep.settings ||
            _currentMenuTutorialStep == MenuTutorialStep.removeAds ||
            _currentMenuTutorialStep == MenuTutorialStep.about)) {
      verticalOffsetSpacing = (targetSize.height * 0.25) + (20 * scaleFactor);
    } else if (_currentMenuTutorialStep == MenuTutorialStep.backArrow) {
      verticalOffsetSpacing = 15 * scaleFactor;
    }

    double referenceTargetHeight = _currentMenuTutorialStep == MenuTutorialStep.backArrow ? backIconSizeForHint : targetSize.height;

    double hintBlockVerticalOffsetFromTargetCenter = pointUpwards
        ? -(referenceTargetHeight / 2 + estimatedHintBlockHeight * 0.5 + verticalOffsetSpacing)
        : (referenceTargetHeight / 2 + verticalOffsetSpacing);

    double initialHintBlockTopPosition = targetCenter.dy + hintBlockVerticalOffsetFromTargetCenter;

    double hintBlockLeftPosition = 20 * scaleFactor;
    double? hintBlockRightPosition = 20 * scaleFactor;

    if (_currentMenuTutorialStep == MenuTutorialStep.backArrow) {
      hintBlockLeftPosition = targetCenter.dx - (backIconSizeForHint /2) + (10 * scaleFactor);
      hintBlockRightPosition = null;
    }

    final double topSafeArea = MediaQuery.of(context).padding.top + (10 * scaleFactor);
    final double bottomSafeArea = screenHeight - MediaQuery.of(context).padding.bottom - (10 * scaleFactor);

    return Positioned.fill(
      child: GestureDetector(
        onTap: () async {
          await _playTutorialAdvanceSound(); // Play tutorial sound for overlay tap
          _advanceMenuTutorial();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_menuTutorialAnimationController!, _menuTutorialPointerOffset!]),
          builder: (context, child) {
            final double currentAnimatedScale = _menuTutorialCircleScale!.value;
            double animatedHighlightWidth;
            double animatedHighlightHeight;
            BorderRadius animatedHighlightBorderRadius;
            bool isCutoutCircular = false;

            if (_currentMenuTutorialStep == MenuTutorialStep.backArrow) {
              double highlightDiameter = (backIconSizeForHint + 16.0) * currentAnimatedScale;
              animatedHighlightWidth = highlightDiameter;
              animatedHighlightHeight = highlightDiameter;
              animatedHighlightBorderRadius = BorderRadius.circular(highlightDiameter / 2);
              isCutoutCircular = true;
            } else {
              animatedHighlightWidth = targetSize.width * currentAnimatedScale;
              animatedHighlightHeight = targetSize.height * currentAnimatedScale;
              animatedHighlightBorderRadius = BorderRadius.circular(min(animatedHighlightHeight * 0.2, 12.0 * currentAnimatedScale));
              isCutoutCircular = false;
            }

            final Rect cutoutRect = Rect.fromCenter(
              center: targetCenter,
              width: animatedHighlightWidth,
              height: animatedHighlightHeight,
            );

            double currentHintBlockTopPosition = initialHintBlockTopPosition + _menuTutorialPointerOffset!.value.dy;

            if (currentHintBlockTopPosition < topSafeArea) {
              currentHintBlockTopPosition = topSafeArea;
            } else if (currentHintBlockTopPosition + estimatedHintBlockHeight > bottomSafeArea) {
              if (!pointUpwards && (targetCenter.dy - referenceTargetHeight / 2 - estimatedHintBlockHeight - 10 * scaleFactor) > topSafeArea) {
                double newVerticalOffsetSpacing = 10 * scaleFactor;
                if (_currentMenuTutorialStep == MenuTutorialStep.settings ||
                    _currentMenuTutorialStep == MenuTutorialStep.removeAds ||
                    _currentMenuTutorialStep == MenuTutorialStep.about) {
                  newVerticalOffsetSpacing = (targetSize.height * 0.25) + (20 * scaleFactor);
                } else if (_currentMenuTutorialStep == MenuTutorialStep.backArrow) {
                  newVerticalOffsetSpacing = 15 * scaleFactor;
                }
                double newHintBlockVerticalOffset = -(referenceTargetHeight / 2 + estimatedHintBlockHeight * 0.5 + newVerticalOffsetSpacing);
                currentHintBlockTopPosition = targetCenter.dy + newHintBlockVerticalOffset + _menuTutorialPointerOffset!.value.dy;
                if (currentHintBlockTopPosition < topSafeArea) currentHintBlockTopPosition = topSafeArea;
              } else {
                currentHintBlockTopPosition = bottomSafeArea - estimatedHintBlockHeight;
              }
            }
            if (currentHintBlockTopPosition < topSafeArea) currentHintBlockTopPosition = topSafeArea;

            double currentHintBlockLeft = hintBlockLeftPosition;
            if (_currentMenuTutorialStep == MenuTutorialStep.backArrow) {
              final tempTextPainter = TextPainter(
                text: TextSpan(text: tutorialTexts[_currentMenuTutorialStep], style: TextStyle(fontSize: hintTextFontSize)),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
              )..layout(maxWidth: screenWidth * 0.7 - hintPaddingHorizontal * 2);
              double estimatedTextContentWidth = tempTextPainter.width;
              double estimatedTextContainerWidth = estimatedTextContentWidth + hintPaddingHorizontal * 2;
              if (currentHintBlockLeft + estimatedTextContainerWidth > screenWidth - (20 * scaleFactor)) {
                currentHintBlockLeft = screenWidth - (20 * scaleFactor) - estimatedTextContainerWidth;
              }
              if (currentHintBlockLeft < 20 * scaleFactor) {
                currentHintBlockLeft = 20 * scaleFactor;
              }
            }

            return Stack(
              children: [
                ClipPath(
                  clipper: _TutorialCutoutClipper(
                    rect: cutoutRect,
                    borderRadius: animatedHighlightBorderRadius,
                    isCircular: isCutoutCircular,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.85),
                  ),
                ),
                Positioned(
                  left: cutoutRect.left,
                  top: cutoutRect.top,
                  child: Opacity(
                    opacity: _menuTutorialCircleOpacity!.value,
                    child: Container(
                      width: cutoutRect.width,
                      height: cutoutRect.height,
                      decoration: BoxDecoration(
                        shape: isCutoutCircular ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius: isCutoutCircular ? null : animatedHighlightBorderRadius,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.9),
                          width: spotlightBorderWidth,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _currentMenuTutorialStep == MenuTutorialStep.backArrow ? currentHintBlockLeft : hintBlockLeftPosition,
                  right: _currentMenuTutorialStep == MenuTutorialStep.backArrow ? null : hintBlockRightPosition,
                  top: currentHintBlockTopPosition,
                  width: _currentMenuTutorialStep == MenuTutorialStep.backArrow
                      ? (screenWidth * 0.7)
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: _currentMenuTutorialStep == MenuTutorialStep.backArrow
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: _menuTutorialTextOpacity!.value,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: hintPaddingHorizontal, vertical: hintPaddingVertical),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(hintContainerCornerRadius),
                              border: Border.all(color: Colors.white70, width: hintTextContainerBorderWidth)
                          ),
                          child: Text(
                            tutorialTexts[_currentMenuTutorialStep] ?? "Hint",
                            textAlign: _currentMenuTutorialStep == MenuTutorialStep.backArrow
                                ? TextAlign.left
                                : TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: hintTextFontSize,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
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
    if (!_prefsForMenuTutorialLoaded && _isLoadingMenuTutorialStatus) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double topPaddingValue = MediaQuery.of(context).padding.top + screenHeight * 0.02;
    final double backIconVisualSize = max(24.0, screenWidth * 0.07);
    final double titleFontSize = max(22.0, screenWidth * 0.085);
    final double buttonVerticalPadding = screenHeight * 0.018;
    final double errorTextSize = max(12.0, screenWidth * 0.035);
    final double bottomScreenPadding = screenHeight * 0.02;

    final removeAdsProduct = _products.firstWhereOrNull((p) => p.id == _kRemoveAdsProductId);
    String priceLabel = 'N/A';
    if (_loading && !_storeAvailable) priceLabel = 'Loading Store...';
    else if (_loading && _storeAvailable && removeAdsProduct == null) priceLabel = 'Loading Price...';
    else if (!_storeAvailable && !_loading) priceLabel = 'Store N/A';
    else if (removeAdsProduct != null) priceLabel = removeAdsProduct.price;
    else if (_storeAvailable && !_loading && removeAdsProduct == null) priceLabel = 'Item N/A';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        key: _stackKey,
        children: [
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: topPaddingValue + titleFontSize + screenHeight * 0.05),

                  _buildButton(0, 'Tutorial', () => _handleTutorialPress(0), key: _tutorialButtonKey),
                  SizedBox(height: buttonVerticalPadding),
                  _buildButton(1, 'How to Play', () => _navigateTo(1, const Howtoplay()), key: _howToPlayKey),
                  SizedBox(height: buttonVerticalPadding),
                  _buildButton(2, 'Generations', () => _navigateTo(2, const GenerationalCardScreen()), key: _generationalCardKey),
                  SizedBox(height: buttonVerticalPadding),
                  _buildButton(3, 'Settings', () => _navigateTo(3, const SettingsScreen()), key: _settingsKey),
                  SizedBox(height: buttonVerticalPadding),
                  _buildButton(
                    4,
                    _adsRemoved
                        ? 'Ads Removed!'
                        : (_purchasePending ? 'Remove Ads (Processing...)' : 'Remove Ads ($priceLabel)'),
                    _adsRemoved ? () {} : _showRemoveAdsOptionsDialog,
                    disabled: _adsRemoved || _purchasePending || (!_storeAvailable && !_loading) ||
                        (_storeAvailable && _loading && removeAdsProduct == null) ||
                        (_storeAvailable && !_loading && removeAdsProduct == null),
                    key: _removeAdsKey,
                  ),
                  SizedBox(height: buttonVerticalPadding),
                  _buildButton(5, 'About', () => _navigateTo(5, const AboutScreen()), key: _aboutKey),

                  if (_errorMessage != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      child: Text('Error: $_errorMessage', textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontSize: errorTextSize)),
                    ),
                  SizedBox(height: bottomScreenPadding),
                ],
              ),
            ),
          ),
          Positioned(
            top: topPaddingValue,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: topPaddingValue - screenHeight * 0.02,
            left: screenWidth * 0.03,
            child: SafeArea(
              child: Material(
                key: _backArrowKey,
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: backIconVisualSize),
                  onPressed: () async {
                    if (_currentMenuTutorialStep == MenuTutorialStep.backArrow) {
                      // Sound and action handled by overlay's onTap.
                      // This direct press should advance tutorial.
                      _advanceMenuTutorial();
                    } else {
                      // Normal back press or tutorial active on another element.
                      // Overlay tap handles tutorial advance for other elements.
                      // This direct press is a standard navigation.
                      await _playStandardClickSound();
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  padding: EdgeInsets.all(max(8.0, screenWidth * 0.02)),
                  splashRadius: max(20.0, backIconVisualSize * 0.7),
                ),
              ),
            ),
          ),
          if (_currentMenuTutorialStep != MenuTutorialStep.none && _prefsForMenuTutorialLoaded)
            _buildMenuTutorialHintOverlayWidget(),
        ],
      ),
    );
  }
}