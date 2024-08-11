import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prakriti/web_screens/web_scaffold.dart';
import '../web_quiz_dir/web_questions.dart';
import 'web_results.dart'; // Import WebResultsPage

class WebQuiz extends StatelessWidget {
  const WebQuiz({super.key});

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

  Future<bool> _ensureQuizQuestionsExist() async {
    final today = DateTime.now();
    final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final questionsCollection = FirebaseFirestore.instance
        .collection('quiz_questions')
        .doc(collectionName)
        .collection('questions');
    
    final questionsSnapshot = await questionsCollection.get();

    if (questionsSnapshot.docs.isEmpty) {
      // Add your quiz generation logic here if needed
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.data == true) {
          // User has completed the quiz, redirect to WebResultsPage
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WebResultsPage()),
            );
          });
          return const SizedBox(); // Return an empty widget while navigating
        }

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
