import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GenerationalCardScreen extends StatelessWidget {
  const GenerationalCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(  // Use Stack to overlay the button on the image
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/generations.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Back Button
          Positioned( // Use Positioned to precisely place the button
            top: 20,   // Adjust top position as needed
            left: 20,  // Adjust left position as needed
            child: SafeArea( //Added safe area
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black), // Style the button
                onPressed: () {
                  Navigator.pop(context);  // Navigate back
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}