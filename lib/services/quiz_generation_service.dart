import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class QuizGenerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates quiz questions and stores them in Firestore.
  Future<void> generateQuizQuestions() async {
    try {
      final today = DateTime.now();
      final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final questionsCollection = _firestore.collection('quiz_questions').doc(collectionName).collection('questions');

      // Check if today's questions already exist
      final existingQuestionsSnapshot = await questionsCollection.get();
      if (existingQuestionsSnapshot.docs.isNotEmpty) {
        return; // Exit if questions for today already exist
      }

      // Generate new quiz questions
      final questions = await _generateQuestionsWithGemini();

      // Store the generated questions in Firestore
      for (var i = 0; i < questions.length; i++) {
        await questionsCollection.add({
          'question': questions[i],
          'seq_no': i + 1,
          'points': 1, // Assuming 1 point per question
          'timestamp': Timestamp.now(), // Adding timestamp
        });
      }

      // Delete old questions older than 7 days
      await _deleteOldQuestions();
    } catch (e) {
      // Handle any errors here
      print('Error generating quiz questions: $e');
    }
  }

  /// Uses Generative AI to generate a list of quiz questions.
  Future<List<String>> _generateQuestionsWithGemini() async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      return []; // Return empty list if API key is not available
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final content = [Content.text('Generate 20 quiz questions for an eco-quiz. List each question on a new line. have the questions be related to eco-conscious topics {only give questions - no other text}{keep the questions such that the answers are one or two words long}')];
    final response = await model.generateContent(content);

    // Return a list of questions split by new lines, filtering out empty strings
    return response.text?.split('\n').where((q) => q.isNotEmpty).toList() ?? [];
  }

  /// Deletes old quiz questions that are older than 7 days.
  Future<void> _deleteOldQuestions() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final oldCollections = await _firestore.collection('quiz_questions').get();

    for (var doc in oldCollections.docs) {
      final docDate = DateTime.parse(doc.id);
      if (docDate.isBefore(sevenDaysAgo)) {
        await _firestore.collection('quiz_questions').doc(doc.id).delete();
      }
    }
  }

  /// Awards points to a user.
  Future<void> awardPoints(String userId, String points) async {
    final userDoc = _firestore.collection('points').doc(userId);
    final userSnapshot = await userDoc.get();

    if (userSnapshot.exists) {
      final currentPoints = userSnapshot.data()?['points'] ?? 0;
      await userDoc.update({'points': currentPoints + int.parse(points)});
    } else {
      await userDoc.set({'points': int.parse(points)});
    }
  }
}
