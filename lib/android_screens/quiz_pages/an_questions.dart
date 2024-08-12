import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:prakriti/services/quiz_completion_service.dart';
import 'package:prakriti/android_screens/quiz_pages/an_results.dart';

class AnQuestions extends StatefulWidget {
  const AnQuestions({super.key});

  @override
  _AnQuestionsState createState() => _AnQuestionsState();
}

class _AnQuestionsState extends State<AnQuestions> {
  final QuizCompletionService _quizCompletionService = QuizCompletionService();
  final List<TextEditingController> _answerControllers = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false; // Tracks whether the app is listening to speech input
  bool _loading = true; // Tracks whether questions are still loading
  bool _isSubmitting = false; // Tracks whether an answer is currently being submitted
  List<Map<String, dynamic>> _questions = []; // List to hold questions
  int _currentQuestionIndex = 0; // Index of the current question
  int _totalQuestions = 0; // Total number of questions

  @override
  void initState() {
    super.initState();
    _loadQuestions(); // Load questions when the widget initializes
  }

  // Loads quiz questions from Firestore based on the current date
  Future<void> _loadQuestions() async {
    final today = DateTime.now();
    final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('quiz_questions')
          .doc(collectionName)
          .collection('questions')
          .orderBy('seq_no')
          .get();

      setState(() {
        _questions = questionsSnapshot.docs.map((doc) {
          final data = doc.data();
          _answerControllers.add(TextEditingController()); // Add a controller for each question
          return {
            'id': doc.id,
            'question': data['question'],
            'seq_no': data['seq_no'],
          };
        }).toList();
        _totalQuestions = _questions.length; // Update total number of questions
        _loading = false; // Set loading to false after questions are loaded
      });

      await _quizCompletionService.startQuiz(); // Notify the service that the quiz has started
    } catch (e) {
      // Handle potential errors while loading questions
      setState(() {
        _loading = false; // Stop loading if there's an error
      });
      print('Error loading questions: $e');
    }
  }

  // Submits the current answer and processes the result
  Future<void> _submitAnswer() async {
    setState(() {
      _isSubmitting = true; // Set submitting state to true
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    if (_currentQuestionIndex >= _totalQuestions) {
      setState(() {
        _isSubmitting = false; // Stop submitting if there are no more questions
      });
      return;
    }

    final userAnswer = _answerControllers[_currentQuestionIndex].text.trim();
    final question = _questions[_currentQuestionIndex]['question'];

    try {
      final result = await _quizCompletionService.submitAnswer(question, userAnswer);

      final isCorrect = result['isCorrect'] as bool;
      final explanation = result['explanation'] as String;

      if (!isCorrect) {
        // If the answer is incorrect, show an explanation dialog
        showDialog(
          context: context,
          builder: (context) => ExplanationPage(
            explanation: explanation,
            onNext: () {
              setState(() {
                _isSubmitting = false;
                _currentQuestionIndex++;
                if (_currentQuestionIndex >= _totalQuestions) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AnResultsPage()),
                  );
                } else {
                  Navigator.pop(context); // Close the dialog and show the next question
                }
              });
            },
          ),
        );
      } else {
        setState(() {
          _isSubmitting = false;
          if (_currentQuestionIndex < _totalQuestions - 1) {
            _currentQuestionIndex++;
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AnResultsPage()),
            );
          }
        });
      }
    } catch (e) {
      // Handle potential errors while submitting the answer
      setState(() {
        _isSubmitting = false; // Stop submitting if there's an error
      });
      print('Error submitting answer: $e');
    }
  }

  // Toggles speech-to-text functionality
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _answerControllers[_currentQuestionIndex].text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // Show a loading spinner while questions are loading
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Eco-Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final progress = _totalQuestions > 0 ? (_currentQuestionIndex + 1) / _totalQuestions : 0.0;
    final question = _totalQuestions > 0 ? _questions[_currentQuestionIndex] : {'question': 'No questions available'};

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Daily Eco-Quiz')),
        automaticallyImplyLeading: false, // Disable back button
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress), // Display quiz progress
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Q-${question['seq_no']}', style: const TextStyle(fontSize: 18)),
                Text('${_currentQuestionIndex + 1}/$_totalQuestions', style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      question['question'],
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _answerControllers[_currentQuestionIndex],
                      decoration: const InputDecoration(labelText: 'Your answer'),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitAnswer, // Disable button while submitting
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : const Text('Check Answer'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                          onPressed: _listen, // Toggle speech-to-text
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExplanationPage extends StatelessWidget {
  final String explanation;
  final VoidCallback onNext;

  const ExplanationPage({super.key, required this.explanation, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Explanation'),
      content: SingleChildScrollView(
        child: Text(
          explanation,
          style: const TextStyle(fontSize: 18),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onNext, // Proceed to the next question
          child: const Text('Next Question'),
        ),
      ],
    );
  }
}
