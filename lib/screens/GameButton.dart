import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GameButton extends StatelessWidget { // Renamed to GameButton
  final String text;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final double skewAngle;
  final bool isBold;

  const GameButton({ // Renamed constructor
    Key? key,
    required this.text,
    required this.onPressed,
    required this.width,
    required this.height,
    required this.skewAngle,
    this.isBold = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // White background
          foregroundColor: Colors.black, // Black text
          elevation: 8, // Add a shadow for depth
          shadowColor: Colors.grey.shade700, // Shadow color (dark grey)
          side: BorderSide(color: Colors.black, width: 2), // Black border
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // More rounded corners
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // More padding
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18, // Slightly larger text
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, // Use w900 for extra boldness
            letterSpacing: 1.2, // Add letter spacing
          ),
        ),
      ),
    );
  }
}