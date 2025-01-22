import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nutritional_information_page.dart'; // Import the new page

class ProcessingPage extends StatefulWidget {
  const ProcessingPage({super.key});

  @override
  _ProcessingPageState createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  String _result = '';
  String _resultImage = '';
  bool _isLoading = false;
  File? _imageFile;

  final ImagePicker _picker = ImagePicker();

  String _userDetails = '';

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final dietaryPreferences = prefs.getString('dietary_preferences') ?? 'N/A';
    final allergies = prefs.getString('allergies') ?? 'N/A';
    final healthGoals = prefs.getString('health_goals') ?? 'N/A';
    final medicalRestrictions =
        prefs.getString('medical_restrictions') ?? 'N/A';
    final ageGroup = prefs.getString('age_group') ?? 'N/A';

    setState(() {
      _userDetails = '''
        Dietary Preferences: $dietaryPreferences
        Allergies: $allergies
        Health Goals: $healthGoals
        Medical Restrictions: $medicalRestrictions
        Age Group: $ageGroup
      ''';
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _generateContent(bool isFoodScan) async {
    if (_imageFile == null) {
      setState(() {
        _result = 'Please capture an image before processing.';
      });
      return;
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final imageBytes = await _imageFile!.readAsBytes();

    // Use the appropriate prompt based on whether it's a food scan or item scan
    final promptToUse = isFoodScan
        ? TextPart(
            '''
      Scan the given food item, is the food in the image suitable for this user?
      Provide the response in markdown format, limited to 300 words. Provide
      an analysis of the food's nutritional content and its impact on the user's health
      goals in bullet points. In the conclusion, include **only one** of the following words:
      "ok to eat", "should not eat" based on the overall analysis. Determine if the user
      should consume it based on their fitness objectives, dietary preferences, or restrictions.
      Justify the suggestion using the food's nutritional profile:

      $_userDetails
      ''',
          )
        : TextPart(
    '''
    Scan the given food item, is the food in the image suitable for this user?
    Provide the response in markdown format, limited to 300 words. Provide:
    - An analysis of the food's nutritional content and its impact on the user's health goals in bullet points.
    - A *reliability percentage* (0-100%) based on the accuracy of the food's nutritional profile, AI confidence in the data, and its match to the user's dietary preferences, fitness objectives, or restrictions.
    - In the conclusion, include only one of the following words: "ok to eat" or "should not eat" based on the overall analysis. Justify the suggestion using the food's nutritional profile.

    If the conclusion is "should not eat," suggest *two alternate meal recommendations* that align with the user's dietary preferences, fitness objectives, and restrictions. Ensure these suggestions are easy to prepare or commonly available.

    User Details:
    $_userDetails
    '''
);

    final imagePart = DataPart('image/jpeg', imageBytes);

    setState(() {
      _isLoading = true;
    });

    try {
      print(promptToUse);
      final imageResponse = await model.generateContent([
        Content.multi([promptToUse, imagePart])
      ]);
      setState(() {
        _resultImage = imageResponse.text ?? 'No response received';

        // Navigate to the new page with the result
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionalInformationPage(
              resultImage: _resultImage,
            ),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40), // Space for where the AppBar would be
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context); // Navigate back to the previous screen
                  },
                ),
                const SizedBox(width: 70,),
                const Text(
                  'Food Scan',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(), // Center align the title
              ],
            ),
            const SizedBox(height: 20),
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: Container(
                  height: 210,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white, // Border color
                      width: 2.0, // Border width
                    ),
                    borderRadius: BorderRadius.circular(
                        25), // Border radius for circular shape
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        24), // Same as the container's radius
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.fill, // To cover the container area
                    ),
                  ),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                backgroundColor: Colors.black.withOpacity(0.8),
              ),
              onPressed: _pickImage,
              child: Text(
                _imageFile == null ? 'Capture Item' : 'Capture Item Again',
                style: const TextStyle(fontSize: 16.0, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                backgroundColor: Colors.black.withOpacity(0.8),
              ),
              onPressed: _pickImage,
              child: Text(
                _imageFile == null ? 'Capture Food' : 'Capture Food Again',
                style: const TextStyle(fontSize: 16.0, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            if (_imageFile !=
                null) // Only show this button if an image is captured
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.8),
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        // Determine which prompt to use based on button pressed
                        final isFoodScan = (_imageFile != null &&
                            context.widget.toStringShort().contains('Food'));
                        _generateContent(isFoodScan);
                      },
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Search',
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                      ),
              ),
            const SizedBox(height: 16.0),
            if (_imageFile == null)
              const Center(
                child: Text(
                  'Capture an image of market item and press search to see results',
                  style: TextStyle(fontSize: 16.0, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
}
