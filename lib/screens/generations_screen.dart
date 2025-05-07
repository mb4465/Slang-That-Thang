import 'package:flutter/material.dart';
// Import your GenerationRow widget if it's in a separate file
// Make sure the path is correct if you've put GenerationRow in its own file
// For this example, I'll assume it's in a file named 'generation_row.dart' in the same directory or a 'widgets' subdir.
// import 'generation_row.dart'; // If GenerationRow is in the same directory
// import 'widgets/generation_row.dart'; // If in a 'widgets' subdirectory

// Assuming generation_data.dart is in a 'data' subdirectory or similar
import 'generation_data.dart';
import 'generation_row.dart';

class GenerationsScreen extends StatelessWidget {
  const GenerationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Generations", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ListView(
                    // REMOVE 'const' from here
                    children: kAllGenerationDetails.map((detail) {
                      return GenerationRow(
                        key: ValueKey(detail.name), // Good practice for lists
                        title: detail.name,
                        years: detail.years.replaceAll('(', '').replaceAll(')', ''), // Clean up years string for display
                        icon: detail.icon,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Slang That Thang!!",
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}