import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ProcessingPage extends StatefulWidget {
  final String inputText;

  const ProcessingPage({super.key, required this.inputText});

  @override
  _ProcessingPageState createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  String _result = '';
  String _resultImage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateContent();
  }

  Future<void> _generateContent() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final firstImage = await rootBundle.load('assets/image0.jpg');
    final secondImage = await rootBundle.load('assets/image1.jpg');

    final prompt = TextPart("What's different between these pictures?");
    final imageParts = [
      DataPart('image/jpeg', firstImage.buffer.asUint8List()),
      DataPart('image/jpeg', secondImage.buffer.asUint8List()),
    ];

    try {
      final content = [Content.text(widget.inputText)];
      final response = await model.generateContent(content);
      final imageResponse = await model.generateContent([
        Content.multi([prompt, ...imageParts])
      ]);
      setState(() {
        _result = response.text ?? 'No response received';
        _resultImage = imageResponse.text ?? 'No image response received';
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
      appBar: AppBar(
        title: const Text('Processing Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_result.isNotEmpty
                      ? 'Result: $_result'
                      : 'Enter text and press search to see results'),
                  const SizedBox(height: 16.0),
                  Text(_resultImage),
                ],
              ),
      ),
    );
  }
}
