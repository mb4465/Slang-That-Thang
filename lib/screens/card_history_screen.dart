
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:test2/data/globals.dart';
import 'package:test2/screens/level_screen.dart'; // For CardHistoryItem

class CardHistoryScreen extends StatefulWidget {
  final List<CardHistoryItem> cardHistory;

  const CardHistoryScreen({super.key, required this.cardHistory});

  @override
  State<CardHistoryScreen> createState() => _CardHistoryScreenState();
}

class _CardHistoryScreenState extends State<CardHistoryScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBackSound() async {
    if (await getSoundEnabled()) {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/previous_card.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final iconSize = screenHeight * 0.04;
    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: Colors.black, // Match card back
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.02,
                left: horizontalPadding,
                right: horizontalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: iconSize),
                    onPressed: () async {
                      await _playBackSound();
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'Card History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenHeight * 0.03,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: iconSize), // Placeholder for balance
                ],
              ),
            ),
            Expanded(
              child: widget.cardHistory.isEmpty
                  ? Center(
                      child: Text(
                        'No cards viewed yet.',
                        style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.022),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: screenHeight * 0.02),
                      itemCount: widget.cardHistory.length,
                      itemBuilder: (context, index) {
                        // Display items in reverse order (newest first)
                        final item = widget.cardHistory[widget.cardHistory.length - 1 - index];
                        return Card(
                          color: Colors.grey[850],
                          margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                          child: ListTile(
                            leading: item.icon.isNotEmpty
                                ? Image.asset(item.icon, width: 40, height: 40)
                                : const Icon(Icons.image_not_supported, color: Colors.white70, size: 40),
                            title: Text(
                              item.term,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: screenHeight * 0.022,
                              ),
                            ),
                            subtitle: Text(
                              item.definition,
                              style: TextStyle(color: Colors.white70, fontSize: screenHeight * 0.018),
                            ),
                            trailing: Text(
                              item.generation,
                              style: TextStyle(color: Colors.amber, fontSize: screenHeight * 0.016, fontStyle: FontStyle.italic),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
