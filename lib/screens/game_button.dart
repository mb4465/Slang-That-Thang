import 'package:flutter/material.dart';

class GameButton extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final VoidCallback? onPressed;
  final bool isBold;
  final double? fontSize; // Added fontSize parameter

  const GameButton({
    Key? key,
    required this.text,
    required this.width,
    required this.height,
    required this.onPressed,
    this.isBold = false,
    this.fontSize, // Added to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Default font size if not provided, though HomeScreen should always provide it.
    // This makes the GameButton more robust if used elsewhere without a fontSize.
    final double effectiveFontSize = fontSize ?? height * 0.3; // Default to 30% of button height if not specified

    return SizedBox(
      width: width,
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: EdgeInsets.zero, // Ensure text is centered if button is small
          side: const BorderSide(color: Colors.black, width: 3), // Consider making border width responsive too
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height * 0.25), // Responsive border radius (e.g., 25% of height)
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center, // Ensure text is centered
          style: TextStyle(
            fontSize: effectiveFontSize, // Use the passed or default responsive font size
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black, // Explicitly set text color for TextButton child
          ),
        ),
      ),
    );
  }
}