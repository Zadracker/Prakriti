import 'dart:typed_data'; // For Uint8List
import 'dart:io' as io; // For File on Android
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Define prompts directly in this file
const Map<String, String> prompts = {
  'Scan Product': 'What is the product shown in this image? How eco-friendly is this product? How to dispose of this product after use? What are its alternatives? (in plaintext)',
  'Scan Pollution': 'What is the pollution level in this image? How can one go about fixing this? What authorities can I notify about this? (in plaintext)',
  'Recycle Scan': 'What can be recycled in this image? How to recycle the items in this image? (in plaintext)',
  'Info': 'Provide information about this image? Give eco-facts relating to the image (in plaintext)',
};

Future<GeminiResult> submitImageToGemini(dynamic image, String action) async {
  final apiKey = dotenv.env['API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    return GeminiResult(output: 'Error: No API_KEY provided');
  }

  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  try {
    final prompt = prompts[action] ?? 'Default prompt'; // Use prompt from the map
    final promptPart = TextPart(prompt);

    Uint8List imageBytes;
    if (kIsWeb) {
      // If running on the web, assume image is Uint8List
      imageBytes = image as Uint8List;
    } else {
      // If running on Android, convert File to Uint8List
      final file = image as io.File;
      imageBytes = await file.readAsBytes();
    }

    final imagePart = DataPart('image/jpeg', imageBytes);
    final response = await model.generateContent([
      Content.multi([promptPart, imagePart])
    ]);

    return GeminiResult(output: response.text ?? 'No response from Gemini');
  } catch (e) {
    return GeminiResult(output: 'Error: ${e.toString()}');
  }
}

class GeminiResult {
  final String output;

  GeminiResult({required this.output});
}
