import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:prakriti/services/points_service.dart';

class QuizCompletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PointsService _pointsService = PointsService();
  final String? apiKey; // API key for Generative AI model

  QuizCompletionService() : apiKey = dotenv.env['API_KEY']; // Initialize API key from environment variables

  /// Starts a quiz for the current user by creating a response document.
  Future<void> startQuiz() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final today = DateTime.now();
    final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Create a response document to track the user's quiz progress
    await _firestore.collection('quiz_questions').doc(collectionName).collection('responses').doc(user.uid).set({
      'userID': user.uid,
      'questions_attempted': 0,
      'completed_status': false,
      'wrong_answers': 0,
      'points_awarded': 0,
      'timestamp': Timestamp.now(),
      'answers': [],
    });
  }

  /// Submits an answer for a given question and updates the quiz progress.
  Future<Map<String, dynamic>> submitAnswer(String question, String answer) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final today = DateTime.now();
    final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final responseDocRef = _firestore.collection('quiz_questions').doc(collectionName).collection('responses').doc(user.uid);

    final result = await validateAnswer(question, answer);

    final isCorrect = result['isCorrect'] as bool;
    final explanation = result['explanation'] as String;

    final responseDoc = await responseDocRef.get();
    if (!responseDoc.exists) {
      throw Exception('Response document not found');
    }

    final data = responseDoc.data()!;
    final answers = List<Map<String, dynamic>>.from(data['answers'] ?? []);
    answers.add({
      'question': question,
      'answer': answer,
      'isCorrect': isCorrect,
      'explanation': explanation,
    });

    int pointsAwarded = data['points_awarded'] as int;
    int wrongAttempts = data['wrong_answers'] as int;

    if (isCorrect) {
      pointsAwarded++;
    } else {
      wrongAttempts++;
    }

    // Update the response document with the new data
    await responseDocRef.update({
      'questions_attempted': answers.length,
      'wrong_answers': wrongAttempts,
      'points_awarded': pointsAwarded,
      'answers': answers,
      'completed_status': answers.length >= 20, // Mark quiz as complete if 20 or more questions answered
    });

    // Award points to the user if the quiz is completed
    if (answers.length >= 20) {
      await _pointsService.awardQuizPoints(user.uid, pointsAwarded);
    }

    // Return the result for the current answer
    return {'isCorrect': isCorrect, 'explanation': explanation};
  }

  /// Validates an answer using a Generative AI model.
  Future<Map<String, dynamic>> validateAnswer(String question, String answer) async {
    if (apiKey == null) {
      return {'isCorrect': false, 'explanation': 'No explanation available'};
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey!);
    final prompt = 'Is the answer "$answer" to the question "$question" correct? Answer "yes" or "no" and explain why the answer is wrong/right and give the answer expected. - answer in plaintext only (the questions are supposed to be answered in a few words so accept answers which are close to the real answers - keep in ming answers do not need to be comprehensive)';
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    final explanation = response.text ?? 'No explanation available';
    final isCorrect = explanation.toLowerCase().startsWith('yes');

    return {'isCorrect': isCorrect, 'explanation': explanation};
  }

  /// Retrieves the quiz responses for a user on a specific date.
  Future<DocumentSnapshot> getQuizResponses(String userId, DateTime date) async {
    final collectionName = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final responseDoc = await _firestore.collection('quiz_questions').doc(collectionName).collection('responses').doc(userId).get();
    return responseDoc;
  }
}
