import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prakriti/web_screens/web_scaffold.dart'; // Import the scaffold for navigation
import '../web_quiz_dir/web_questions.dart'; // Import the WebQuestions page
import 'web_results.dart'; // Import the WebResultsPage

class WebQuiz extends StatelessWidget {
  const WebQuiz({super.key});

  /// Checks if the quiz has already been completed by the current user.
  Future<bool> _checkIfQuizCompleted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final today = DateTime.now();
    final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final responseDoc = await FirebaseFirestore.instance
        .collection('quiz_questions')
        .doc(collectionName)
        .collection('responses')
        .doc(user.uid)
        .get();

    if (responseDoc.exists) {
      final data = responseDoc.data()!;
      return data['completed_status'] == true;
    }

    return false;
  }

  /// Ensures that quiz questions exist for today.
  Future<bool> _ensureQuizQuestionsExist() async {
    final today = DateTime.now();
    final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final questionsCollection = FirebaseFirestore.instance
        .collection('quiz_questions')
        .doc(collectionName)
        .collection('questions');
    
    final questionsSnapshot = await questionsCollection.get();

    if (questionsSnapshot.docs.isEmpty) {
      // Add quiz generation logic here if needed
      return false;
    } else {
      return true; // Return true if questions exist
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Future.wait([
        _checkIfQuizCompleted(),
        _ensureQuizQuestionsExist()
      ]).then((results) => results[0]), // Use the result of _checkIfQuizCompleted
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Show a loading indicator while waiting for the future
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}')); // Show an error message if there's an error
        }

        if (snapshot.data == true) {
          // If the quiz is completed, navigate to the results page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WebResultsPage()),
            );
          });
          return const SizedBox(); // Return an empty widget while navigating
        }

        // If quiz is not completed, show the quiz start screen
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Ready for today\'s Quiz?'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WebQuestions(onQuizComplete: (index) {
                        // Callback function to update index when quiz is complete
                        Navigator.popUntil(context, ModalRoute.withName('/'));
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WebScaffold(initialIndex: index),
                          ),
                        );
                      })),
                    );
                  },
                  child: const Text('Start Quiz'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
