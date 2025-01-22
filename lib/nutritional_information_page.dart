import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'micro_workout_page.dart'; // Import the MicroWorkoutPage

class NutritionalInformationPage extends StatefulWidget {
  final String resultImage;

  const NutritionalInformationPage({super.key, required this.resultImage});

  @override
  _NutritionalInformationPageState createState() =>
      _NutritionalInformationPageState();
}

class _NutritionalInformationPageState
    extends State<NutritionalInformationPage> {
  late FlutterTts flutterTts;
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();

    // Optional: Add a completion handler to toggle the `isSpeaking` state
    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeech() async {
    if (isSpeaking) {
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
    } else {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(widget.resultImage);
      setState(() {
        isSpeaking = true;
      });
    }
  }

  Color _determineColor(String result) {
    final lowerResult = result.toLowerCase();

    if (lowerResult.contains('should not eat')) {
      return Colors.red;
    }

    if (lowerResult.contains('ok to eat') || lowerResult.contains('yes')) {
      return Colors.green;
    }

    return Colors.grey.withOpacity(0.3);
  }

  Future<void> _saveInformation(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('nutritional_information') &&
        prefs.get('nutritional_information') is String) {
      await prefs.remove('nutritional_information');
    }

    final List<String> savedResponses =
        prefs.getStringList('nutritional_information') ?? [];

    savedResponses.add(widget.resultImage);

    await prefs.setStringList('nutritional_information', savedResponses);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Information saved successfully!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _determineColor(widget.resultImage);
    final percentage = extractPercentage(widget.resultImage);
    return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9A9E), // Soft pink
            Color(0xFF96E1F4), // Light bluish
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 10),
                const Text(
                  'Nutritional Information',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
              ],
            ),
            if (backgroundColor == Colors.red)
                Image.asset(
                  'assets/unhealthy.gif',
                  height: 150,
                  fit: BoxFit.fitHeight,
                ),
              if (backgroundColor == Colors.green)
                Image.asset(
                  'assets/healthy.gif',
                  height: 150,
                  fit: BoxFit.fitHeight,
                ),
              const SizedBox(height: 10),
              Container(
                height: 10,
                color: backgroundColor,
              ),
            const SizedBox(height: 10),
            Expanded(
              child: Card(
                color: Colors.white, // White background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Markdown(
                    data: widget.resultImage,
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context).copyWith(
                        textTheme: const TextTheme(
                          bodyMedium: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            // Meter-like Visual
            Column(
              children: [
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    getMeterColor(percentage), // Dynamic color based on percentage
                  ),
                  minHeight: 10,
                ),
                const SizedBox(height: 5),
                Text(
                  'Reliability Meter : ${percentage.toInt()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20)),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MicroWorkoutPage(
                          nutritionalAnalysis: widget.resultImage,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 30,
                  ),
                  tooltip: 'Micro Workout',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20)),
                child: IconButton(
                  onPressed: () async {
                    await _saveInformation(context);
                  },
                  icon: const Icon(
                    Icons.save,
                    color: Colors.white,
                    size: 30,
                  ),
                  tooltip: 'Save Information',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20)),
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.home,
                    color: Colors.white,
                    size: 30,
                  ),
                  tooltip: 'Home',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20)),
                child: IconButton(
                  onPressed: _toggleSpeech,
                  icon: Icon(
                    isSpeaking ? Icons.stop : Icons.volume_up,
                    color: Colors.white,
                  ),
                  tooltip: isSpeaking ? 'Stop Reading' : 'Read Information',
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    ),
    );
  }

  double extractPercentage(String input) {
    final percentageRegex = RegExp(r'(\d+)%');
    final match = percentageRegex.firstMatch(input.toLowerCase());
    return match != null ? double.tryParse(match.group(1) ?? '0') ?? 0 : 0;
  }

  /// Determines the color of the meter based on the percentage
  Color getMeterColor(double percentage) {
    if (percentage < 50) {
      return Colors.red; // Poor health
    } else if (percentage < 75) {
      return Colors.yellow; // Moderate health
    } else {
      return Colors.green; // Good health
    }
  }
}

class SavedInformationPage extends StatelessWidget {
  const SavedInformationPage({super.key});

  // Method to determine the color based on the result
  Color _determineColor(String result) {
    final lowerResult = result.toLowerCase();

    if (lowerResult.contains('should not eat')) {
      return Colors.pink.shade300; // Lighter red for better readability
    }

    if (lowerResult.contains('ok to eat') || lowerResult.contains('yes')) {
      return Colors.lightGreen.shade400; // Lighter green for better readability
    }

    return Colors.pink.shade300; // Default background color
  }

  Future<List<String>> _loadSavedInformation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('nutritional_information') ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF9A9E), // Soft pink
              Color(0xFF96E1F4), // Light bluish
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40), // Space for where the AppBar would be
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context); // Navigate back
                  },
                ),
                const SizedBox(
                  width: 65,
                ),
                const Text(
                  'Saved Information',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _loadSavedInformation(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading saved information.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No saved information found.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final savedInformation = snapshot.data!;
                  return ListView.builder(
                    itemCount: savedInformation.length,
                    itemBuilder: (context, index) {
                      final cardBackgroundColor =
                          _determineColor(savedInformation[index]);

                      return Card(
                        margin: const EdgeInsets.all(20.0),
                        color:
                            cardBackgroundColor, // Set the card's background color
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 200.0, // Limit the height of each card
                            ),
                            child: Markdown(
                              data: savedInformation[index],
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context).copyWith(
                                  textTheme: TextTheme(
                                    bodyMedium: TextStyle(
                                        fontSize: 16.0,
                                        color: cardBackgroundColor ==
                                                Colors.pink.shade300
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                ),
                              ),
                              shrinkWrap:
                                  true, // Ensures the Markdown widget adapts properly
                            ),
                          ),
                        ),
                      );
                    },
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
