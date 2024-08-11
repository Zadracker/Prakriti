import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class QuizGenerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateQuizQuestions() async {
    try {
      final today = DateTime.now();
      final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final questionsCollection = _firestore.collection('quiz_questions').doc(collectionName).collection('questions');

      // Check if today's questions already exist
      final existingQuestionsSnapshot = await questionsCollection.get();
      if (existingQuestionsSnapshot.docs.isNotEmpty) {
        return;
      }

      // Generate new quiz questions
      final questions = await _generateQuestionsWithGemini();

      for (var i = 0; i < questions.length; i++) {
        await questionsCollection.add({
          'question': questions[i],
          'seq_no': i + 1,
          'points': 1, // Assuming 1 point per question
          'timestamp': Timestamp.now(), // Adding timestamp
        });
      }

      // Delete old questions
      await _deleteOldQuestions();
    } catch (e) {
    }
  }

  Future<List<String>> _generateQuestionsWithGemini() async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      return [];
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final content = [Content.text('Generate 20 quiz questions for an eco-quiz. List each question on a new line. have the questions be related to eco-conscious topics {only give questions - no other text}{keep the questions such that the answers are one or two words long}')];
    final response = await model.generateContent(content);

    return response.text?.split('\n').where((q) => q.isNotEmpty).toList() ?? [];
  }

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
