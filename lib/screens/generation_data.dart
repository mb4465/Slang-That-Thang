import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GenerationDetail {
  final String name; // e.g., "Gen Z"
  final String years; // e.g., "(1997 - 2012)"
  final IconData icon;
  final String fullNameWithYears; // e.g., "Gen Z (1997 - 2012)"

  GenerationDetail({
    required this.name,
    required this.years,
    required this.icon,
  }) : fullNameWithYears = '$name $years'; // Construct the full name here for easier matching

  // Helper to match against the 'generation' string you pass to CardBack
  bool matches(String generationString) {
    // Trim both strings for robust comparison
    return generationString.trim() == fullNameWithYears.trim();
  }
}

// It's good practice to use a more descriptive name for global constants (e.g., k prefix or ALL_CAPS)
final List<GenerationDetail> kAllGenerationDetails = [
  GenerationDetail(name: "Silent Generation", years: "(1928 - 1945)", icon: Icons.mic),
  GenerationDetail(name: "Baby Boomers", years: "(1946 - 1964)", icon: FontAwesomeIcons.peace),
  GenerationDetail(name: "Gen X", years: "(1965 - 1980)", icon: Icons.computer),
  GenerationDetail(name: "Millennials", years: "(1981 - 1996)", icon: Icons.smartphone),
  GenerationDetail(name: "Gen Z", years: "(1997 - 2012)", icon: Icons.videogame_asset),
  GenerationDetail(name: "Gen Alpha", years: "(2013 - present)", icon: FontAwesomeIcons.vrCardboard),
];

IconData? getIconForGeneration(String generationString) {
  // Ensure generationString is not null and trim it
  final trimmedGenerationString = generationString.trim();
  for (var genDetail in kAllGenerationDetails) {
    if (genDetail.matches(trimmedGenerationString)) {
      return genDetail.icon;
    }
  }
  // Fallback if no specific match (e.g., if generationString format changes unexpectedly)
  // This can happen if addNewlineBeforeBracket is applied before this check
  // Consider a more robust matching, e.g., checking if generationString starts with genDetail.name
  for (var genDetail in kAllGenerationDetails) {
    if (trimmedGenerationString.startsWith(genDetail.name)) {
      return genDetail.icon;
    }
  }
  return null; // Or a default icon if not found
}