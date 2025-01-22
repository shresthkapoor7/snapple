import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormPage extends StatefulWidget {
  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dietaryController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController healthGoalsController = TextEditingController();
  final TextEditingController medicalRestrictionsController =
      TextEditingController();
  String selectedAgeGroup = '18-35'; // Default age group

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Load saved preferences when the page is initialized
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('name') ?? '';
      dietaryController.text = prefs.getString('dietary_preferences') ?? '';
      allergiesController.text = prefs.getString('allergies') ?? '';
      healthGoalsController.text = prefs.getString('health_goals') ?? '';
      medicalRestrictionsController.text =
          prefs.getString('medical_restrictions') ?? '';
      selectedAgeGroup = prefs.getString('age_group') ?? '18-35';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', nameController.text);
    await prefs.setString('dietary_preferences', dietaryController.text);
    await prefs.setString('allergies', allergiesController.text);
    await prefs.setString('health_goals', healthGoalsController.text);
    await prefs.setString(
        'medical_restrictions', medicalRestrictionsController.text);
    await prefs.setString('age_group', selectedAgeGroup);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences Saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0, // Removes the default shadow
        title: const Text(
          'Information Form',
          style: TextStyle(
            fontFamily: 'Roboto', // Optional: Custom font if added
            fontSize: 24.0, // Larger font size for emphasis
            fontWeight: FontWeight.bold,
            color: Colors.black, // Title text color
          ),
        ),
        centerTitle: true, // Centers the title and icon
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              width: 150, // Adjust the size as needed
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage('https://img.freepik.com/free-photo/young-adult-man-wearing-hoodie-beanie_23-2149393636.jpg'), // Replace with your image URL
                  fit: BoxFit.contain, // Ensures the image covers the circle
                ),
              ),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dietaryController,
              decoration: const InputDecoration(
                labelText: 'Dietary Preferences',
                hintText: 'e.g., Vegetarian, Vegan, Gluten-Free',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: allergiesController,
              decoration: const InputDecoration(
                labelText: 'Allergies or Intolerances',
                hintText: 'e.g., Nuts, Dairy, Gluten',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: healthGoalsController,
              decoration: const InputDecoration(
                labelText: 'Health Goals',
                hintText: 'e.g., Weight Management, Blood Sugar Control',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: medicalRestrictionsController,
              decoration: const InputDecoration(
                labelText: 'Medical Restrictions',
                hintText: 'e.g., Diabetes, Hypertension',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Age Group:'),
            DropdownButton<String>(
              value: selectedAgeGroup,
              items: <String>['Under 18', '18-35', '36-50', '50+']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedAgeGroup = newValue!;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                backgroundColor: Colors.black,
              ),
              onPressed: _savePreferences,
              child: const Icon(Icons.save, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}