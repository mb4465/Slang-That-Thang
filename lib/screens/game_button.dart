import 'package:flutter/material.dart';

class GameButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;   // allow null for disabled state
  final double width;
  final double height;
  final double skewAngle;
  final bool isBold;

  const GameButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.width,
    required this.height,
    required this.skewAngle,
    this.isBold = false,
  });

  @override
  GameButtonState createState() => GameButtonState();
}

class GameButtonState extends State<GameButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 8,
                shadowColor: Colors.grey.shade700,
                side: const BorderSide(color: Colors.black, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: widget.onPressed,
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  widget.isBold ? FontWeight.w900 : FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
