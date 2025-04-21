import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:collection/collection.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:test2/data/globals.dart';
import 'package:test2/screens/HowToPlay.dart';
import 'package:test2/screens/AboutScreen.dart';
import 'package:test2/screens/generational_card_screen.dart';
import 'package:test2/screens/settings_screen.dart';

import 'game_button.dart';

const _kRemoveAdsProductId = 'remove_ads_premium';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  // Animation
  late AnimationController _controller;
  int? _selectedButtonIndex;
  static const _buttonCount = 5;

  // IAP
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
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdates, onError: (e) {
      setState(() { _errorMessage = "Purchase stream error: $e"; });
    });
    final available = await _iap.isAvailable();
    if (!available) {
      setState(() { _storeAvailable = false; _loading = false; _errorMessage = "Store not available"; });
      return;
    }
    _storeAvailable = true;
    final response = await _iap.queryProductDetails({_kRemoveAdsProductId});
    if (response.error != null) {
      setState(() { _errorMessage = response.error!.message; _loading = false; });
      return;
    }
    if (response.productDetails.isEmpty) {
      setState(() { _errorMessage = "Product not found"; _loading = false; });
      return;
    }
    setState(() { _products = response.productDetails; _loading = false; });
  }

  @override
  void dispose() {
    _controller.dispose();
    _sub.cancel();
    super.dispose();
  }

  void _onPurchaseUpdates(List<PurchaseDetails> detailsList) {
    for (final pd in detailsList) {
      switch (pd.status) {
        case PurchaseStatus.pending:
          setState(() => _purchasePending = true);
          break;
        case PurchaseStatus.error:
          setState(() { _errorMessage = pd.error?.message; _purchasePending = false; });
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
      setState(() { _adsRemoved = true; _purchasePending = false; });
      _showSuccessDialog();
    }
    if (pd.pendingCompletePurchase) await _iap.completePurchase(pd);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Ads removed! Restart the app if you still see ads.'),
        actions: [ TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('OK')) ],
      ),
    );
  }

  void _startRemoveAdsPurchase() {
    if (_adsRemoved || _purchasePending || !_storeAvailable) return;
    final pd = _products.firstWhereOrNull((p) => p.id == _kRemoveAdsProductId);
    if (pd == null) { setState(() => _errorMessage = "Product info unavailable."); return; }
    setState(() => _purchasePending = true);
    _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: pd));
  }

  Future<void> _playClick() async {
    if (!await getSoundEnabled()) return;
    final player = AudioPlayer();
    await player.play(AssetSource('audio/click.mp3'));
  }

  void _navigateTo(int index, Widget screen) {
    if (_controller.isAnimating || _selectedButtonIndex != null) return;
    _playClick();
    setState(() => _selectedButtonIndex = index);
    _controller.forward().then((_) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
        _controller.reset();
        setState(() => _selectedButtonIndex = null);
      });
    });
  }

  Widget _buildButton(int index, String text, VoidCallback onTap, {bool disabled = false}) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Transform.translate(
        offset: _selectedButtonIndex==index
            ? Offset(_controller.value * MediaQuery.of(context).size.width, 0)
            : Offset.zero,
        child: GameButton(
          text: text,
          width: 250, height: 60,
          skewAngle: 0.0,
          onPressed: disabled ? null : () => onTap(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pad = SizedBox(height: 14);
    final removeAdsProduct = _products.firstWhereOrNull((p) => p.id==_kRemoveAdsProductId);
    final priceLabel = removeAdsProduct?.price ?? '...';

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 70),
                  const Text('Menu', style: TextStyle(fontSize:35, fontWeight: FontWeight.bold)),
                  const SizedBox(height:100),

                  _buildButton(0, 'How to Play',   () => _navigateTo(0, const Howtoplay())), pad,
                  _buildButton(1, 'Generational Card', () => _navigateTo(1, const GenerationalCardScreen())), pad,

                  if (!_adsRemoved) ...[
                    _buildButton(2, 'Remove Ads ($priceLabel)', _startRemoveAdsPurchase,
                        disabled: _loading||_purchasePending||removeAdsProduct==null),
                  ] else ...[
                    Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: const Text('Ads Removed!', style: TextStyle(color:Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ], pad,

                  _buildButton(3, 'Settings',    () => _navigateTo(3, const SettingsScreen())), pad,
                  _buildButton(4, 'About',       () => _navigateTo(4, const AboutScreen())),
                  const SizedBox(height:20),

                  if (_errorMessage!=null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal:20,vertical:10),
                      child: Text('Error: $_errorMessage', style: const TextStyle(color:Colors.red)),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
