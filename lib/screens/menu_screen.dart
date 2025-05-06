import 'dart:async';
// import 'dart:io'; // Was marked as unused, can be removed if truly not needed
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:collection/collection.dart';
import 'package:audioplayers/audioplayers.dart';

// Adjust path as per your project structure
import '../data/globals.dart';
import 'HowToPlay.dart'; // Assuming these are in the same directory or a 'screens' subdirectory
import 'AboutScreen.dart';
import 'generational_card_screen.dart';
import 'settings_screen.dart';

import 'game_button.dart'; // Assuming this is in the same directory or a 'widgets' subdirectory

const _kRemoveAdsProductId = 'remove_ads_premium'; // Make sure this matches your IAP ID

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  int? _selectedButtonIndex;

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _sub;
  bool _storeAvailable = false;
  List<ProductDetails> _products = [];
  bool _adsRemoved = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _initEverything();
  }

  Future<void> _initEverything() async {
    _adsRemoved = await getAdsRemovedStatus();
    if (!mounted) return;

    _sub = _iap.purchaseStream.listen(_onPurchaseUpdates, onError: (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Purchase stream error: $e";
        _loading = false; // Also set loading to false on stream error
      });
    });

    final available = await _iap.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() {
        _storeAvailable = false;
        _loading = false;
        _errorMessage = "Store not available";
      });
      return;
    }

    _storeAvailable = true;
    // Wrap product query in try-catch for robustness
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

  @override
  void dispose() {
    _controller.dispose();
    _sub.cancel();
    super.dispose();
  }

  void _onPurchaseUpdates(List<PurchaseDetails> detailsList) {
    if (!mounted) return;
    for (final pd in detailsList) {
      switch (pd.status) {
        case PurchaseStatus.pending:
          setState(() => _purchasePending = true);
          break;
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
      await setAdsRemoved(true); // Use the global setter
      if (!mounted) return;
      setState(() {
        _adsRemoved = true;
        _purchasePending = false;
      });
      _showSuccessDialog();
    }
    if (pd.pendingCompletePurchase) await _iap.completePurchase(pd);
  }

  void _showSuccessDialog() {
    if (!mounted || !Navigator.of(context).canPop()) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogTitleFontSize = screenWidth * 0.05;
    final dialogContentFontSize = screenWidth * 0.04;
    final dialogActionFontSize = screenWidth * 0.04;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Success', style: TextStyle(fontSize: dialogTitleFontSize, fontWeight: FontWeight.bold)),
        content: Text('Ads removed! Restart the app if you still see ads.', style: TextStyle(fontSize: dialogContentFontSize)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(fontSize: dialogActionFontSize, color: Theme.of(context).primaryColor))),
        ],
      ),
    );
  }

  Future<void> _playUiClickSound() async { // Consistent naming
    if (await getSoundEnabled()) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource('audio/click.mp3'));
    }
  }

  void _startRemoveAdsPurchase() async { // Added async
    await _playUiClickSound(); // Play sound
    if (_adsRemoved || _purchasePending || !_storeAvailable) return;
    final pd = _products.firstWhereOrNull((p) => p.id == _kRemoveAdsProductId);
    if (pd == null) {
      if (!mounted) return;
      setState(() => _errorMessage = "Product info unavailable.");
      return;
    }
    if (!mounted) return;
    setState(() => _purchasePending = true);
    _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: pd));
  }

  void _navigateTo(int index, Widget screen) async { // Added async
    if (_controller.isAnimating || _selectedButtonIndex != null) return;
    await _playUiClickSound(); // Play sound
    if (!mounted) return;
    setState(() => _selectedButtonIndex = index);
    _controller.forward().then((_) {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
          if (mounted) {
            _controller.reset();
            setState(() => _selectedButtonIndex = null);
          }
        });
      } else {
        _controller.reset();
      }
    });
  }

  Widget _buildButton(int index, String text, VoidCallback onTap, {bool disabled = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double maxButtonWidth = 400.0;
    final double buttonWidthFactor = 0.8;
    final double buttonHeightFactor = 0.07;
    final double buttonWidth = min(screenWidth * buttonWidthFactor, maxButtonWidth);
    final double buttonHeight = screenHeight * buttonHeightFactor;
    final double buttonFontSize = buttonHeight * 0.3;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Transform.translate(
        offset: _selectedButtonIndex == index
            ? Offset(_controller.value * screenWidth, 0)
            : Offset.zero,
        child: GameButton(
          text: text,
          width: buttonWidth,
          height: buttonHeight,
          onPressed: disabled ? null : onTap,
          isBold: true,
          fontSize: buttonFontSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = screenHeight * 0.06;
    final double backIconSize = screenWidth * 0.07;
    final double titleFontSize = screenWidth * 0.085;
    final double titleTopSpacing = screenHeight * 0.05;
    final double titleBottomSpacing = screenHeight * 0.06;
    final double buttonVerticalPadding = screenHeight * 0.015;
    final double adsRemovedTextSize = screenWidth * 0.045;
    final double errorTextSize = screenWidth * 0.035;
    final double bottomScreenPadding = screenHeight * 0.02;

    final removeAdsProduct = _products.firstWhereOrNull((p) => p.id == _kRemoveAdsProductId);
    final priceLabel = removeAdsProduct?.price ?? (_loading ? 'Loading...' : 'N/A');

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: titleTopSpacing + topPadding),
                  Text('Menu', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold)),
                  SizedBox(height: titleBottomSpacing),

                  _buildButton(0, 'How to Play', () => _navigateTo(0, const Howtoplay())),
                  SizedBox(height: buttonVerticalPadding),
                  _buildButton(1, 'Generational Card', () => _navigateTo(1, const GenerationalCardScreen())),
                  SizedBox(height: buttonVerticalPadding),

                  if (!_adsRemoved) ...[
                    _buildButton(
                      2,
                      _loading ? 'Remove Ads (Loading...)' : 'Remove Ads ($priceLabel)',
                      _startRemoveAdsPurchase,
                      disabled: _loading || _purchasePending || removeAdsProduct == null,
                    ),
                  ] else ...[
                    SizedBox(
                      height: screenHeight * 0.07,
                      child: Center(
                        child: Text('Ads Removed!',
                            style: TextStyle(
                                fontSize: adsRemovedTextSize,
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  SizedBox(height: buttonVerticalPadding),

                  _buildButton(3, 'Settings', () => _navigateTo(3, const SettingsScreen())),
                  SizedBox(height: buttonVerticalPadding),
                  _buildButton(4, 'About', () => _navigateTo(4, const AboutScreen())),
                  SizedBox(height: buttonVerticalPadding),

                  if (_errorMessage != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      child: Text(
                        'Error: $_errorMessage',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red, fontSize: errorTextSize),
                      ),
                    ),
                  SizedBox(height: bottomScreenPadding),
                ],
              ),
            ),
          ),
          Positioned(
            top: topPadding,
            left: screenWidth * 0.03,
            child: SafeArea(
              child: Material( // Added for consistent splash effect
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: backIconSize),
                  onPressed: () async { // Make async for sound
                    await _playUiClickSound();
                    if (mounted) { // Check mounted before pop
                      Navigator.pop(context);
                    }
                  },
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  splashRadius: backIconSize * 0.7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}