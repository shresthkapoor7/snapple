import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MicroWorkoutPage extends StatefulWidget {
  final String nutritionalAnalysis; // Pass the nutritional analysis as input

  const MicroWorkoutPage({super.key, required this.nutritionalAnalysis});

  @override
  _MicroWorkoutPageState createState() => _MicroWorkoutPageState();
}

class _MicroWorkoutPageState extends State<MicroWorkoutPage> {
  String _workoutSuggestion = '';
  bool _isLoading = false;
  bool isSpeaking = false;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();

    // Optional: Add a completion handler to toggle the `isSpeaking` state
    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });

    _fetchMicroWorkout();
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
    } else if (_workoutSuggestion.isNotEmpty) {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(_workoutSuggestion);
      setState(() {
        isSpeaking = true;
      });
    }
  }

  Future<void> _fetchMicroWorkout() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final prompt = '''
      Based on the nutritional analysis and calorie content of the product, suggest a quick micro workout in markdown format, limited to 150 words, that the user can perform to balance out the consumed calories. Provide the workout suggestion in bullet points, specifying:
      - The type of exercise
      - Duration
      - Intensity
      - Clearly state whether the workout is **heavy** or **light** (only one)
      Briefly explain in a bullet point how this workout matches the calorie burn target and why the intensity (heavy or light) is appropriate.
      Nutritional analysis: ${widget.nutritionalAnalysis}
    ''';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      setState(() {
        _workoutSuggestion =
            response.text ?? 'No response received from the API.';
      });
    } catch (e) {
      setState(() {
        _workoutSuggestion = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _determineColor(String result) {
    final lowerResult = result.toLowerCase();

    if (lowerResult.contains('heavy')) {
      return Colors.red;
    }

    if (lowerResult.contains('light')) {
      return Colors.green;
    }

    return Colors.grey.withOpacity(0.3);
  }

  Future<void> _saveWorkout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('workout_suggestions') &&
        prefs.get('workout_suggestions') is String) {
      await prefs.remove('workout_suggestions');
    }

    final List<String> savedWorkouts =
        prefs.getStringList('workout_suggestions') ?? [];

    savedWorkouts.add(_workoutSuggestion);

    await prefs.setStringList('workout_suggestions', savedWorkouts);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout suggestion saved successfully!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _determineColor(_workoutSuggestion);

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
          const SizedBox(height: 30), // Space for where AppBar used to be
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context); // Navigate back
                },
              ),
              const SizedBox(width: 65,),
              const Text(
                'Micro Workout',
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
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_workoutSuggestion.isNotEmpty)
            Expanded(
              child: Column(
                children: [
                  if (backgroundColor == Colors.red)
                    Image.asset(
                      'assets/workout_heavy.gif',
                      height: 150,
                      fit: BoxFit.fitHeight,
                    ),
                  if (backgroundColor == Colors.green)
                    Image.asset(
                      'assets/workout_light.gif',
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
                        borderRadius: BorderRadius.circular(15), // Rounded corners
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0), // Inner padding
                        child: Markdown(
                          data: _workoutSuggestion,
                          styleSheet: MarkdownStyleSheet.fromTheme(
                            Theme.of(context).copyWith(
                              textTheme: const TextTheme(
                                bodyMedium: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.black, // Text color inside the card
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: Text(
                'No workout suggestion available.',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          const SizedBox(height: 16.0),
          if (_workoutSuggestion.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    backgroundColor: Colors.black,
                  ),
                  onPressed: () async => await _saveWorkout(context),
                  child: const Icon(Icons.save, color: Colors.white, size: 20),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    backgroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.home, color: Colors.white, size: 20),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    backgroundColor: Colors.black,
                  ),
                  onPressed: _toggleSpeech,
                  child: Icon(
                    isSpeaking ? Icons.stop : Icons.volume_up,
                    color: Colors.white,
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
}


class SavedWorkoutsPage extends StatelessWidget {
  const SavedWorkoutsPage({super.key});

  // Method to determine the color based on the workout intensity
  Color _determineColor(String result) {
    final lowerResult = result.toLowerCase();

    if (lowerResult.contains('heavy')) {
      return Colors.pink.shade300; // Lighter red for heavy workouts
    }

    if (lowerResult.contains('light')) {
      return Colors.lightGreen.shade400; // Lighter green for light workouts
    }

    return Colors.pink.shade300; // Default background color
  }

  // Method to load saved workouts from SharedPreferences
  Future<List<String>> _loadSavedWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('workout_suggestions') ?? [];
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
                const SizedBox(width: 70,),
                const Text(
                  'Saved Workouts',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _loadSavedWorkouts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading saved workouts.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No saved workouts found.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final savedWorkouts = snapshot.data!;
                  return ListView.builder(
                    itemCount: savedWorkouts.length,
                    itemBuilder: (context, index) {
                      final cardBackgroundColor =
                          _determineColor(savedWorkouts[index]);

                      return Card(
                        margin: const EdgeInsets.all(20.0),
                        color: cardBackgroundColor, // Set the card's background color
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 200.0, // Limit the height of each card
                            ),
                            child: Markdown(
                              data: savedWorkouts[index],
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context).copyWith(
                                  textTheme: TextTheme(
                                    bodyMedium: TextStyle(fontSize: 16.0, color: cardBackgroundColor == Colors.pink.shade300 ? Colors.white : Colors.black),
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
