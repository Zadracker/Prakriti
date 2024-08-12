import 'dart:typed_data'; // For handling raw binary data (Uint8List)
import 'dart:io' as io; // For handling file operations (File) on Android
import 'package:flutter/foundation.dart' show kIsWeb; // To check if the platform is web
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For environment variable management
import 'package:google_generative_ai/google_generative_ai.dart'; // For interacting with the Gemini AI model

// Define prompts for various actions in a map
const Map<String, String> prompts = {
  'Scan Product': 'What is the product shown in this image? How eco-friendly is this product? How to dispose of this product after use? What are its alternatives? (in plaintext)',
  'Scan Pollution': 'What is the pollution level in this image? How can one go about fixing this? What authorities can I notify about this? (in plaintext)',
  'Recycle Scan': 'What can be recycled in this image? How to recycle the items in this image? (in plaintext)',
  'Info': 'Provide information about this image? Give eco-facts relating to the image (in plaintext)',
};

// Function to submit an image and action to the Gemini AI model and get a response
Future<GeminiResult> submitImageToGemini(dynamic image, String action) async {
  // Retrieve API key from environment variables
  final apiKey = dotenv.env['API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    // Return error if API key is not provided
    return GeminiResult(output: 'Error: No API_KEY provided');
  }

  // Initialize the GenerativeModel with the provided API key
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

  try {
    // Get the appropriate prompt based on the action
    final prompt = prompts[action] ?? 'Default prompt'; // Fallback to a default prompt if action is not recognized
    final promptPart = TextPart(prompt);

    Uint8List imageBytes;
    if (kIsWeb) {
      // If running on the web, assume image is Uint8List directly
      imageBytes = image as Uint8List;
    } else {
      // If running on Android, convert File to Uint8List
      final file = image as io.File;
      imageBytes = await file.readAsBytes(); // Read the file as bytes
    }

    // Create a DataPart with the image bytes and specify MIME type
    final imagePart = DataPart('image/jpeg', imageBytes);

    // Generate content using the Gemini model with both prompt and image
    final response = await model.generateContent([
      Content.multi([promptPart, imagePart])
    ]);

    // Return the result with the response text or a fallback message
    return GeminiResult(output: response.text ?? 'No response from Gemini');
  } catch (e) {
    // Return an error message if any exception occurs
    return GeminiResult(output: 'Error: ${e.toString()}');
  }
}

// Class to encapsulate the result from Gemini AI
class GeminiResult {
  final String output; // The output text from the Gemini model

  GeminiResult({required this.output}); // Constructor to initialize the output
}
