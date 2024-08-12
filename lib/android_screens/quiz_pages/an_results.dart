import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/android_screens/an_scaffold.dart';
import 'package:prakriti/services/quiz_completion_service.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the fl_chart package for pie charts

// This page displays the results of the quiz
class AnResultsPage extends StatelessWidget {
  const AnResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false, // Disable the default back button
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _loadResults(), // Fetch the quiz results
        builder: (context, snapshot) {
          // Display a loading spinner while results are being fetched
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Handle the case where no data is found
          if (!snapshot.hasData) {
            return const Center(
              child: Text('No results found'),
            );
          }

          // Extract data from the snapshot
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final pointsAwarded = data['points_awarded'] as int;
          final wrongAttempts = data['wrong_answers'] as int;

          // Handle potentially missing profile image URL
          final profileImageUrl = data.containsKey('profileImageUrl') && data['profileImageUrl'] != null
              ? data['profileImageUrl']
              : '';

          final totalQuestions = pointsAwarded + wrongAttempts; // Calculate total questions

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Quiz Completed!',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Points Awarded: $pointsAwarded',
                  style: const TextStyle(fontSize: 18.0),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Wrong Attempts: $wrongAttempts',
                  style: const TextStyle(fontSize: 18.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                // Pie chart to visualize the quiz results
                SizedBox(
                  height: 200.0,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: pointsAwarded.toDouble(),
                          color: Colors.blue,
                          title: '${(pointsAwarded / totalQuestions * 100).toStringAsFixed(1)}%',
                          titleStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: wrongAttempts.toDouble(),
                          color: Colors.red,
                          title: '${(wrongAttempts / totalQuestions * 100).toStringAsFixed(1)}%',
                          titleStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                      sectionsSpace: 0,
                      centerSpaceRadius: 40.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // Button to navigate to quiz attempts page
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AnQuizAttemptsPage(profileImageUrl: profileImageUrl, userPoints: pointsAwarded)),
                    );
                  },
                  child: const Text('See Attempts'),
                ),
                // Button to return to the main page
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppScaffold(
                          currentIndex: 3, // Index of the Quiz page in the BottomNavigationBar
                          userPoints: pointsAwarded,
                          profileImageUrl: profileImageUrl,
                        ),
                      ),
                    );
                  },
                  child: const Text('Return'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Fetches the quiz results from Firestore
  Future<DocumentSnapshot> _loadResults() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final today = DateTime.now();
    final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Fetch the document containing the user's quiz responses
    final responseDoc = await FirebaseFirestore.instance
        .collection('quiz_questions')
        .doc(collectionName)
        .collection('responses')
        .doc(user.uid)
        .get();

    return responseDoc;
  }
}

// This page displays the details of the user's quiz attempts
class AnQuizAttemptsPage extends StatelessWidget {
  final QuizCompletionService _quizCompletionService = QuizCompletionService();
  final String profileImageUrl;
  final int userPoints;

  AnQuizAttemptsPage({super.key, required this.profileImageUrl, required this.userPoints});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Attempts'),
        automaticallyImplyLeading: false, // Remove the back arrow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AnResultsPage(), // Redirect to Results page
              ),
            );
          },
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _loadAttempts(), // Fetch the quiz attempts
        builder: (context, snapshot) {
          // Display a loading spinner while attempts are being fetched
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Handle the case where no data is found
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('No attempts found'),
            );
          }

          // Extract data from the snapshot
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final answers = data['answers'] as List<dynamic>? ?? []; // Get the list of answers

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: answers.length,
              itemBuilder: (context, index) {
                final answerData = answers[index] as Map<String, dynamic>;
                final question = answerData['question'] ?? 'Question not found';
                final userAnswer = answerData['answer'] ?? 'User answer not found';
                final isCorrect = answerData['isCorrect'] ?? false;
                final explanation = answerData['explanation'] ?? 'No explanation available';

                return Card(
                  child: ListTile(
                    title: Text('Q: $question'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Answer: $userAnswer'),
                        Text('Correct: ${isCorrect ? "Yes" : "No"}'),
                        Text('Explanation: $explanation'),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Fetches the quiz attempts from Firestore
  Future<DocumentSnapshot> _loadAttempts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final today = DateTime.now();
    final responseDoc = await _quizCompletionService.getQuizResponses(user.uid, today);

    return responseDoc;
  }
}
