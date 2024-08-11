import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prakriti/android_screens/quiz_pages/an_questions.dart'; // Ensure this import is correct
import 'package:prakriti/android_screens/quiz_pages/an_results.dart'; // Import the an_results.dart page
import 'package:prakriti/services/quiz_generation_service.dart'; // Import the QuizGenerationService

class AnQuiz extends StatelessWidget {
  final QuizGenerationService _quizGenerationService = QuizGenerationService();

  AnQuiz({super.key}); // Initialize QuizGenerationService

  Future<bool> _checkIfQuizCompleted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final today = DateTime.now();
    final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final responseDoc = await FirebaseFirestore.instance.collection('quiz_questions').doc(collectionName).collection('responses').doc(user.uid).get();

    if (responseDoc.exists) {
      final data = responseDoc.data()!;
      return data['completed_status'] == true;
    }

    return false;
  }

  Future<bool> _ensureQuizQuestionsExist() async {
    final today = DateTime.now();
    final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final questionsCollection = FirebaseFirestore.instance.collection('quiz_questions').doc(collectionName).collection('questions');
    
    final questionsSnapshot = await questionsCollection.get();

    if (questionsSnapshot.docs.isEmpty) {
      await _quizGenerationService.generateQuizQuestions();
      await Future.delayed(const Duration(seconds: 5)); // Wait a moment before retrying
      final newQuestionsSnapshot = await questionsCollection.get();
      return newQuestionsSnapshot.docs.isNotEmpty; // Return true if questions exist after generation
    } else {
      return true; // Return true if questions exist
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: FutureBuilder<bool>(
        future: Future.wait([
          _checkIfQuizCompleted(),
          _ensureQuizQuestionsExist()
        ]).then((results) => results[0]), // Use the result of _checkIfQuizCompleted
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.data == true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Good job! Come back tomorrow for more.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnResultsPage()), // Ensure AnResultsPage is defined and imported
                      );
                    },
                    child: const Text('Show Results'),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(user?.email == 'eco_advocate@example.com' ? 'Welcome ${user?.displayName}! Ready for quiz? (Due to your role - you will not be awarded points)' : 'Welcome ${user?.displayName}! Ready for today\'s quiz?'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnQuestions()), // Ensure AnQuestions is defined and imported
                    );
                  },
                  child: const Text('Start Quiz'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
