import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prakriti/android_screens/quiz_pages/an_questions.dart'; // Import the page to start the quiz
import 'package:prakriti/android_screens/quiz_pages/an_results.dart'; // Import the page to show quiz results
import 'package:prakriti/services/quiz_generation_service.dart'; // Import the service to generate quiz questions

class AnQuiz extends StatelessWidget {
  final QuizGenerationService _quizGenerationService = QuizGenerationService(); // Create an instance of the QuizGenerationService

  AnQuiz({super.key}); // Constructor with a key for widget identification

  // Method to check if the user has completed the quiz for today
  Future<bool> _checkIfQuizCompleted() async {
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user == null) {
      throw Exception('User not logged in'); // Throw an exception if no user is logged in
    }

    final today = DateTime.now(); // Get today's date
    final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}'; // Format date as a string for Firestore collection
    final responseDoc = await FirebaseFirestore.instance.collection('quiz_questions').doc(collectionName).collection('responses').doc(user.uid).get(); // Get the user's quiz response document

    if (responseDoc.exists) {
      final data = responseDoc.data()!;
      return data['completed_status'] == true; // Check if the quiz is marked as completed
    }

    return false; // Return false if no response document exists
  }

  // Method to ensure that quiz questions exist for today
  Future<bool> _ensureQuizQuestionsExist() async {
    final today = DateTime.now(); // Get today's date
    final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}'; // Format date as a string for Firestore collection
    final questionsCollection = FirebaseFirestore.instance.collection('quiz_questions').doc(collectionName).collection('questions'); // Get the questions collection

    final questionsSnapshot = await questionsCollection.get(); // Fetch the snapshot of questions

    if (questionsSnapshot.docs.isEmpty) {
      await _quizGenerationService.generateQuizQuestions(); // Generate quiz questions if none exist
      await Future.delayed(const Duration(seconds: 5)); // Wait 5 seconds to allow time for questions to be generated
      final newQuestionsSnapshot = await questionsCollection.get(); // Retry fetching the questions
      return newQuestionsSnapshot.docs.isNotEmpty; // Return true if questions are now available
    } else {
      return true; // Return true if questions already exist
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // Get the current user

    return Scaffold(
      body: FutureBuilder<bool>(
        future: Future.wait([
          _checkIfQuizCompleted(), // Check if the quiz is completed
          _ensureQuizQuestionsExist() // Ensure quiz questions exist
        ]).then((results) => results[0]), // Use the result of _checkIfQuizCompleted
        builder: (context, snapshot) {
          // Build the widget based on the future's result
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Show loading spinner while waiting for results
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Show error message if there's an issue
          }

          if (snapshot.data == true) {
            // If the quiz is completed
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Good job! Come back tomorrow for more.'), // Message for users who completed the quiz
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnResultsPage()), // Navigate to results page
                      );
                    },
                    child: const Text('Show Results'),
                  ),
                ],
              ),
            );
          }

          // If the quiz is not completed
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(user?.email == 'eco_advocate@example.com' ? 'Welcome ${user?.displayName}! Ready for quiz? (Due to your role - you will not be awarded points)' : 'Welcome ${user?.displayName}! Ready for today\'s quiz?'), // Personalized message based on user role
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnQuestions()), // Navigate to quiz questions page
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
