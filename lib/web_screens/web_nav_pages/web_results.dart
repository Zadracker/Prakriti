import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/services/quiz_completion_service.dart';
import 'package:fl_chart/fl_chart.dart'; // Import FL Chart package for graphs

class WebResultsPage extends StatefulWidget {
  const WebResultsPage({super.key});

  @override
  _WebResultsPageState createState() => _WebResultsPageState();
}

class _WebResultsPageState extends State<WebResultsPage> with SingleTickerProviderStateMixin {
  final QuizCompletionService _quizCompletionService = QuizCompletionService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              color: Colors.black, // TabBar background color
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Results'),
                  Tab(text: 'Attempts'),
                ],
                indicatorColor: Colors.white,
                labelColor: Colors.green, // Selected tab text color
                unselectedLabelColor: Colors.white, // Unselected tab text color
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildResultsTab(),
                  _buildAttemptsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsTab() {
    return FutureBuilder<DocumentSnapshot>(
      future: _loadResults(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No results found'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final pointsAwarded = (data['points_awarded'] as int?)?.toDouble() ?? 0.0;
        final wrongAttempts = (data['wrong_answers'] as int?)?.toDouble() ?? 0.0;

        // Data for the pie chart
        final totalAttempts = pointsAwarded + wrongAttempts;
        final correctPercentage = totalAttempts > 0 ? (pointsAwarded / totalAttempts) * 100 : 0.0;
        final incorrectPercentage = totalAttempts > 0 ? (wrongAttempts / totalAttempts) * 100 : 0.0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quiz Completed!', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Points Awarded: $pointsAwarded', style: const TextStyle(fontSize: 18.0)),
                  Text('Wrong Attempts: $wrongAttempts', style: const TextStyle(fontSize: 18.0)),
                ],
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        color: Colors.blue,
                        value: correctPercentage,
                        title: '${correctPercentage.toStringAsFixed(1)}%',
                        radius: 80,
                        titleStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        color: Colors.red,
                        value: incorrectPercentage,
                        title: '${incorrectPercentage.toStringAsFixed(1)}%',
                        radius: 80,
                        titleStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttemptsTab() {
    return FutureBuilder<DocumentSnapshot>(
      future: _loadAttempts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No attempts found'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final answers = data['answers'] as List<dynamic>? ?? [];

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
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 4.0,
                child: ListTile(
                  title: Text('Q: $question', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }

  Future<DocumentSnapshot> _loadResults() async {
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

    return responseDoc;
  }

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
