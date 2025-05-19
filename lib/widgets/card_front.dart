import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CardFront extends StatefulWidget {
  final String term;
  final bool showInitialFlipHint; // Renamed from hasFlippedOnce

  const CardFront({
    super.key,
    required this.term,
    required this.showInitialFlipHint, // Updated parameter
  });

  @override
  State<CardFront> createState() => _CardFrontState();
}

class _CardFrontState extends State<CardFront> {
  bool _showGenerationsOverlay = false;
  bool _showTapToFlipHint = true; // Controls the opacity of the hint

  @override
  void initState() {
    super.initState();
    // Set initial visibility based on the prop
    _showTapToFlipHint = widget.showInitialFlipHint;
  }

  @override
  void didUpdateWidget(covariant CardFront oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the hint was shown but now shouldn't be (because the global flag changed)
    if (oldWidget.showInitialFlipHint && !widget.showInitialFlipHint) {
      setState(() {
        _showTapToFlipHint = false; // Trigger fade out
      });
    }
    // If the prop changes for other reasons, ensure hint visibility matches
    else if (widget.showInitialFlipHint != _showTapToFlipHint) {
      setState(() {
        _showTapToFlipHint = widget.showInitialFlipHint;
      });
    }
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
        child: Container(
          width: overlayWidth,
          constraints: BoxConstraints(
            maxHeight: overlayMaxHeight,
            minWidth: 280,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.black54),
                    tooltip: 'Close',
                    onPressed: () {
                      setState(() {
                        _showGenerationsOverlay = false;
                      });
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final double generationLogoSize = screenWidth * 0.085;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.term,
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
            top: statusBarHeight + 16.0,
            right: 16.0,
            child: InkWell(
              onTap: () {
                setState(() {
                  _showGenerationsOverlay = true;
                });
              },
              borderRadius: BorderRadius.circular(generationLogoSize / 2),
              child: SvgPicture.asset(
                'assets/images/generation-icon.svg', // Ensure this path is correct
                height: generationLogoSize,
                width: generationLogoSize,
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showTapToFlipHint ? 1.0 : 0.0, // Controlled by local state
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: IgnorePointer(
                ignoring: !_showTapToFlipHint,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, size: 50, color: Colors.black54),
                    SizedBox(height: 8),
                    Text(
                      'Tap to Flip',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showGenerationsOverlay) _buildGenerationsOverlay(context),
        ],
      ),
    );
  }
}