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
const String _kGooglePlayReviewCouponCode = "REVIEWACCESS2025";

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

  final TextEditingController _couponController = TextEditingController();

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

  @override
  void dispose() {
    _controller.dispose();
    _sub.cancel();
    _couponController.dispose();
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
      await setAdsRemoved(true);
      if (!mounted) return;
      setState(() {
        _adsRemoved = true;
        _purchasePending = false;
      });
      _showSuccessDialog('Purchase successful! Ads removed. Restart the app if you still see ads.');
    }
    if (pd.pendingCompletePurchase) await _iap.completePurchase(pd);
  }

  void _showSuccessDialog([String? customMessage]) {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogTitleFontSize = screenWidth * 0.05;
    final dialogContentFontSize = screenWidth * 0.04;
    final dialogActionFontSize = screenWidth * 0.04;

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

  Future<void> _playUiClickSound() async {
    if (await getSoundEnabled()) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource('audio/click.mp3'));
    }
  }

  Future<void> _initiateInAppPurchase() async {
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

  // Helper to build GameButtons for dialogs
  Widget _buildDialogGameButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust width for dialogs - make them noticeable but not overly wide
    final double buttonWidth = min(screenWidth * 0.65, 260.0);
    const double buttonHeight = 48.0; // A slightly larger, more touch-friendly height for dialog buttons
    final double buttonFontSize = buttonHeight * 0.32;

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1.0, // Visual cue for disabled state
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0), // Spacing between buttons if stacked
        child: GameButton(
          text: text,
          width: buttonWidth,
          height: buttonHeight,
          onPressed: onPressed,
          isBold: true,
          fontSize: buttonFontSize,
        ),
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
          title: Center(child: Text('Enter Coupon Code', style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold))),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0), // Adjust padding
          content: SingleChildScrollView( // Ensure content can scroll if needed
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _couponController,
                  decoration: const InputDecoration(
                    hintText: "Coupon Code",
                    border: OutlineInputBorder(), // Give TextField a border
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                _buildDialogGameButton(
                  text: 'Submit',
                  onPressed: () async {
                    final enteredCode = _couponController.text.trim();
                    Navigator.of(dialogContext).pop(); // Close coupon dialog first
                    if (enteredCode == _kGooglePlayReviewCouponCode) {
                      await setAdsRemoved(true);
                      if (!mounted) return;
                      setState(() {
                        _adsRemoved = true;
                      });
                      _showSuccessDialog("Coupon applied successfully! Ads have been removed.");
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid coupon code.')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).primaryColor)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Softer corners
        );
      },
    );
  }

  Future<void> _showRemoveAdsOptionsDialog() async {
    await _playUiClickSound();
    if (!mounted) return;

    final productDetailsForDialog = _products.firstWhereOrNull((p) => p.id == _kRemoveAdsProductId);
    final screenWidth = MediaQuery.of(context).size.width;

    String payButtonText;
    bool canPay = false;

    if (_purchasePending) {
      payButtonText = 'Processing...';
      canPay = false;
    } else if (!_storeAvailable) {
      payButtonText = 'Pay (Store Unavailable)';
      canPay = false;
    } else if (_loading && productDetailsForDialog == null) { // If still loading AND no product yet
      payButtonText = 'Pay (Loading Store...)';
      canPay = false;
    }
    else if (productDetailsForDialog == null) {
      payButtonText = 'Pay (Item Unavailable)';
      canPay = false;
    } else {
      payButtonText = 'Pay ${productDetailsForDialog.price}';
      canPay = true;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Center(child: Text('Remove Ads', style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold))),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0), // Standard padding, less at bottom if actions are present
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _buildDialogGameButton(
                  text: 'Enter Coupon Code',
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _showCouponInputDialog();
                  },
                ),
                _buildDialogGameButton(
                  text: payButtonText,
                  onPressed: canPay
                      ? () {
                    Navigator.of(dialogContext).pop();
                    _initiateInAppPurchase();
                  }
                      : null, // onPressed: null will be handled by _buildDialogGameButton opacity
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center, // Center the cancel button
          actions: <Widget>[
            Padding( // Add some padding to the cancel button for better spacing
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextButton(
                child: Text('Cancel', style: TextStyle(fontSize: screenWidth * 0.04, color: Theme.of(context).hintColor)), // Use a less prominent color
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Softer corners for dialog
        );
      },
    );
  }


  void _navigateTo(int index, Widget screen) async {
    if (_controller.isAnimating || _selectedButtonIndex != null) return;
    await _playUiClickSound();
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

  // @override
  // Widget build(BuildContext context) {
  //   final screenWidth = MediaQuery.of(context).size.width;
  //   final screenHeight = MediaQuery.of(context).size.height;
  //   final double topPadding = screenHeight * 0.06;
  //   final double backIconSize = screenWidth * 0.07;
  //   final double titleFontSize = screenWidth * 0.085;
  //   final double titleTopSpacing = screenHeight * 0.05;
  //   final double titleBottomSpacing = screenHeight * 0.06;
  //   final double buttonVerticalPadding = screenHeight * 0.015;
  //   final double adsRemovedTextSize = screenWidth * 0.045;
  //   final double errorTextSize = screenWidth * 0.035;
  //   final double bottomScreenPadding = screenHeight * 0.02;
  //
  //   final removeAdsProduct = _products.firstWhereOrNull((p) => p.id == _kRemoveAdsProductId);
  //   String priceLabel = 'N/A';
  //   if (_loading && !_storeAvailable) { // If still loading initial store availability
  //     priceLabel = 'Loading Store...';
  //   } else if (_loading && _storeAvailable && removeAdsProduct == null) { // If store available, but product query is loading
  //     priceLabel = 'Loading Price...';
  //   } else if (!_storeAvailable && !_loading) { // Store checked and not available
  //     priceLabel = 'Store N/A';
  //   } else if (removeAdsProduct != null) {
  //     priceLabel = removeAdsProduct.price;
  //   } else if (_storeAvailable && !_loading && removeAdsProduct == null) { // Store available, loaded, but product not found
  //     priceLabel = 'Item N/A';
  //   }
  //
  //
  //   return Scaffold(
  //     body: Stack(
  //       children: [
  //         Center(
  //           child: SingleChildScrollView(
  //             padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               crossAxisAlignment: CrossAxisAlignment.center,
  //               children: [
  //                 SizedBox(height: titleTopSpacing + topPadding),
  //                 Text('Menu', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold)),
  //                 SizedBox(height: titleBottomSpacing),
  //
  //                 _buildButton(0, 'How to Play', () => _navigateTo(0, const Howtoplay())),
  //                 SizedBox(height: buttonVerticalPadding),
  //                 _buildButton(1, 'Generational Card', () => _navigateTo(1, const GenerationalCardScreen())),
  //                 SizedBox(height: buttonVerticalPadding),
  //
  //                 if (!_adsRemoved) ...[
  //                   _buildButton(
  //                     2,
  //                     _purchasePending
  //                         ? 'Remove Ads (Processing...)'
  //                         : 'Remove Ads ($priceLabel)',
  //                     _showRemoveAdsOptionsDialog,
  //                     disabled: _purchasePending ||
  //                         (!_storeAvailable && !_loading) || // Store definitely not available
  //                         (_storeAvailable && _loading && removeAdsProduct == null) || // Store available, products loading
  //                         (_storeAvailable && !_loading && removeAdsProduct == null), // Store available, products loaded, item not found
  //                   ),
  //                 ] else ...[
  //                   SizedBox(
  //                     height: screenHeight * 0.07,
  //                     child: Center(
  //                       child: Text('Ads Removed!',
  //                           style: TextStyle(
  //                               fontSize: adsRemovedTextSize,
  //                               color: Colors.green,
  //                               fontWeight: FontWeight.bold)),
  //                     ),
  //                   ),
  //                 ],
  //                 SizedBox(height: buttonVerticalPadding),
  //
  //                 _buildButton(3, 'Settings', () => _navigateTo(3, const SettingsScreen())),
  //                 SizedBox(height: buttonVerticalPadding),
  //                 _buildButton(4, 'About', () => _navigateTo(4, const AboutScreen())),
  //                 SizedBox(height: buttonVerticalPadding),
  //
  //                 if (_errorMessage != null)
  //                   Padding(
  //                     padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
  //                     child: Text(
  //                       'Error: $_errorMessage',
  //                       textAlign: TextAlign.center,
  //                       style: TextStyle(color: Colors.red, fontSize: errorTextSize),
  //                     ),
  //                   ),
  //                 SizedBox(height: bottomScreenPadding),
  //               ],
  //             ),
  //           ),
  //         ),
  //         Positioned(
  //           top: topPadding,
  //           left: screenWidth * 0.03,
  //           child: SafeArea(
  //             child: Material(
  //               color: Colors.transparent,
  //               child: IconButton(
  //                 icon: Icon(Icons.arrow_back, color: Colors.black, size: backIconSize),
  //                 onPressed: () async {
  //                   await _playUiClickSound();
  //                   if (mounted) {
  //                     Navigator.pop(context);
  //                   }
  //                 },
  //                 padding: EdgeInsets.all(screenWidth * 0.02),
  //                 splashRadius: backIconSize * 0.7,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
// ... other imports and class definition

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
  String priceLabel = 'N/A';
  if (_loading && !_storeAvailable) {
  priceLabel = 'Loading Store...';
  } else if (_loading && _storeAvailable && removeAdsProduct == null) {
  priceLabel = 'Loading Price...';
  } else if (!_storeAvailable && !_loading) {
  priceLabel = 'Store N/A';
  } else if (removeAdsProduct != null) {
  priceLabel = removeAdsProduct.price;
  } else if (_storeAvailable && !_loading && removeAdsProduct == null) {
  priceLabel = 'Item N/A';
  }

  return Scaffold(
  backgroundColor: Colors.white, // <--- ADD THIS LINE
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

  // ... (rest of your Column children)

  _buildButton(0, 'How to Play', () => _navigateTo(0, const Howtoplay())),
  SizedBox(height: buttonVerticalPadding),
  _buildButton(1, 'Generational Card', () => _navigateTo(1, const GenerationalCardScreen())),
  SizedBox(height: buttonVerticalPadding),

  if (!_adsRemoved) ...[
  _buildButton(
  2,
  _purchasePending
  ? 'Remove Ads (Processing...)'
      : 'Remove Ads ($priceLabel)',
  _showRemoveAdsOptionsDialog,
  disabled: _purchasePending ||
  (!_storeAvailable && !_loading) ||
  (_storeAvailable && _loading && removeAdsProduct == null) ||
  (_storeAvailable && !_loading && removeAdsProduct == null),
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
  child: Material(
  color: Colors.transparent,
  child: IconButton(
  icon: Icon(Icons.arrow_back, color: Colors.black, size: backIconSize),
  onPressed: () async {
  await _playUiClickSound();
  if (mounted) {
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