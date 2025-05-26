// lib/widgets/tutorial_cutout_clipper.dart
import 'package:flutter/material.dart';

class TutorialCutoutClipper extends CustomClipper<Path> {
  final Rect rect;
  final BorderRadius borderRadius;
  final bool isCircular;

  TutorialCutoutClipper({
    required this.rect,
    required this.borderRadius,
    this.isCircular = false,
  });

  @override
  Path getClip(Size size) {
    Path cutoutPath;
    if (isCircular) {
      // For a circular cutout, rect should ideally be a square.
      // The addOval method will inscribe an oval within the given rect.
      // If rect is a square, it will be a circle.
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

    // Create a path for the full screen (or the size of the widget being clipped)
    final Path fullScreenPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Subtract the cutout path from the full screen path
    // This makes the area of cutoutPath transparent, and the rest opaque (based on the child of ClipPath).
    return Path.combine(
      PathOperation.difference,
      fullScreenPath,
      cutoutPath,
    );
  }

  @override
  bool shouldReclip(TutorialCutoutClipper oldClipper) {
    return oldClipper.rect != rect ||
        oldClipper.borderRadius != borderRadius ||
        oldClipper.isCircular != isCircular;
  }
}