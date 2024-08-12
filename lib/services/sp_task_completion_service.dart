import 'dart:typed_data'; // For Uint8List
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:prakriti/services/points_service.dart';

class SpTaskCompletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PointsService _pointsService = PointsService();

  /// Submits the proof of task completion including text proof and an image.
  /// Returns a result string indicating success or error.
  Future<String> submitTaskProof(String taskId, String proofText, Uint8List imageBytes, String userId) async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'Error: API key not found';
    }

    // Configuration for the Generative AI model
    final generationConfig = GenerationConfig(
      stopSequences: ["red"], // Define stop sequences for generation
      maxOutputTokens: 200,   // Limit the response to 200 tokens
      temperature: 0.1,       // Control the randomness of the response
      topP: 0.1,              // Top-p sampling for response generation
      topK: 16,               // Top-k sampling for response generation
    );

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',  // Model to use for generating content
      apiKey: apiKey,
      generationConfig: generationConfig,
    );

    final prompt = TextPart(
      '$proofText - give a yes or no answer, in the next line provide reasoning for whether the image is correct or incorrect relative to the text.'
    );

    final imageParts = [
      DataPart('image/jpeg', imageBytes), // Include the image in the request
    ];

    try {
      // Generate content using the Generative AI model
      final response = await model.generateContent(
        [
          Content.multi([prompt, ...imageParts])
        ]
      );

      final resultText = response.text?.trim() ?? '';

      // Validate response format
      if (resultText.isEmpty || !resultText.contains('\n')) {
        return 'Error: Invalid response format';
      }

      final lines = resultText.split('\n');
      if (lines.length < 2) {  // Ensure there are at least two lines in the response
        return 'Error: Unexpected response format';
      }

      final firstWord = lines[0].toLowerCase().trim();
      lines.sublist(1).join('\n').trim();  // Collect the reasoning part

      // Debugging line to check the task document
      final taskDoc = await _firestore.collection('eco_tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        return 'Error: Task not found';
      }

      if (firstWord == 'yes') {
        // Award points to the user if the response is 'yes'
        await _pointsService.awardPoints(userId, taskId);
        // Remove the task from user tasks
        await _firestore.collection('user_tasks').doc(userId).collection('tasks').doc(taskId).delete();

        // Update the task document to indicate completion
        await _firestore.collection('eco_tasks').doc(taskId).update({
          'completed_by': FieldValue.arrayUnion([userId])
        });
      }

      return resultText;
    } catch (e) {
      return 'Error: Exception occurred';
    }
  }
}
