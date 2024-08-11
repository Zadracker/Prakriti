import 'dart:typed_data'; // For Uint8List
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:prakriti/services/points_service.dart';

class SpTaskCompletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PointsService _pointsService = PointsService();

  Future<String> submitTaskProof(String taskId, String proofText, Uint8List imageBytes, String userId) async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'Error: API key not found';
    }

    final generationConfig = GenerationConfig(
      stopSequences: ["red"],
      maxOutputTokens: 200,
      temperature: 0.1,
      topP: 0.1,
      topK: 16,
    );

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: generationConfig,
    );

    final prompt = TextPart('$proofText - give a yes or no answer, in the next line provide reasoning for whether the image is correct or incorrect relative to the text.');
    final imageParts = [
      DataPart('image/jpeg', imageBytes),
    ];

    try {
      final response = await model.generateContent(
        [
          Content.multi([prompt, ...imageParts])
        ]
      );

      final resultText = response.text?.trim() ?? '';

      // Check response format
      if (resultText.isEmpty || !resultText.contains('\n')) {
        return 'Error: Invalid response format';
      }

      final lines = resultText.split('\n');
      if (lines.length < 2) {  // Expecting at least two lines (answer and reasoning)
        return 'Error: Unexpected response format';
      }

      final firstWord = lines[0].toLowerCase().trim();
      lines.sublist(1).join('\n').trim();  // Reasoning starts from the second line

      // Debugging line
      final taskDoc = await _firestore.collection('eco_tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        return 'Error: Task not found';
      }

      if (firstWord == 'yes') {
        await _pointsService.awardPoints(userId, taskId);
        await _firestore.collection('user_tasks').doc(userId).collection('tasks').doc(taskId).delete();

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
