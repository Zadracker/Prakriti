import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/services/quiz_completion_service.dart';
import 'package:prakriti/services/accessibility_preferences_service.dart'; // Import AccessibilityPreferencesService
import 'package:flutter_tts/flutter_tts.dart'; // Import flutter_tts for Text-to-Speech functionality
import 'package:speech_to_text/speech_to_text.dart' as stt; // Import Speech-to-Text functionality

class WebQuestions extends StatefulWidget {
  final Function(int) onQuizComplete;

  const WebQuestions({super.key, required this.onQuizComplete});

  @override
  _WebQuestionsState createState() => _WebQuestionsState();
}

class _WebQuestionsState extends State<WebQuestions> with SingleTickerProviderStateMixin {
  final QuizCompletionService _quizCompletionService = QuizCompletionService();
  final List<TextEditingController> _answerControllers = []; // Controllers for text fields where answers are entered
  final FlutterTts _flutterTts = FlutterTts(); // Instance of Text-to-Speech for reading questions aloud
  final AccessibilityPreferencesService _accessibilityService = AccessibilityPreferencesService(); // Service for user preferences
  final stt.SpeechToText _speechToText = stt.SpeechToText(); // Instance of Speech-to-Text for converting speech to text

  bool _loading = true; // Flag to indicate loading state
  bool _isSubmitting = false; // Flag to indicate if an answer is being submitted
  List<Map<String, dynamic>> _questions = []; // List to hold the quiz questions
  int _currentQuestionIndex = 0; // Index of the current question being displayed
  int _totalQuestions = 0; // Total number of questions in the quiz
  User? _currentUser; // Current logged-in user
  String _fontSize = '1X'; // Default font size setting
  String _fontType = 'Default'; // Default font type setting
  bool _readAloud = false; // Setting to determine if questions should be read aloud
  bool _isListening = false; // Flag to indicate if speech-to-text is active

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser; // Get the current user
    _loadAccessibilityPreferences(); // Load user accessibility preferences
    _loadQuestions(); // Load the quiz questions
  }

  // Load user accessibility preferences from the service
  Future<void> _loadAccessibilityPreferences() async {
    final preferences = await _accessibilityService.getUserPreferences(FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      _fontSize = preferences['fontSize'] ?? '1X';
      _fontType = preferences['font'] ?? 'Default';
      _readAloud = preferences['readAloud'] ?? false;
    });
  }

  // Load quiz questions for the current date from Firestore
  Future<void> _loadQuestions() async {
    final today = DateTime.now();
    final collectionName = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
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
      _totalQuestions = _questions.length;
      _loading = false; // Update loading state
    });

    // Start quiz by creating a response document in Firestore
    await _quizCompletionService.startQuiz();
  }

  // Handle submission of the current answer
  Future<void> _submitAnswer() async {
    if (_currentUser == null) {
      return;
    }

    if (_currentQuestionIndex >= _totalQuestions) {
      return;
    }

    setState(() {
      _isSubmitting = true; // Indicate that the submission is in progress
    });

    final userAnswer = _answerControllers[_currentQuestionIndex].text.trim();
    final question = _questions[_currentQuestionIndex]['question'];

    try {
      final result = await _quizCompletionService.submitAnswer(question, userAnswer);
      final isCorrect = result['isCorrect'] as bool;
      final explanation = result['explanation'] as String;

      if (!isCorrect) {
        _showIncorrectAnswerDialog(explanation); // Show dialog if the answer is incorrect
      }

      setState(() {
        if (_currentQuestionIndex < _totalQuestions - 1) {
          _currentQuestionIndex++;
          if (_readAloud) {
            _flutterTts.speak(_questions[_currentQuestionIndex]['question']); // Read the next question aloud if enabled
          }
        } else {
          widget.onQuizComplete(8); // Notify that the quiz is complete and pass the index for results page
          Navigator.pop(context); // Return to the previous screen (WebScaffold)
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit answer.')), // Show error message if submission fails
      );
    } finally {
      setState(() {
        _isSubmitting = false; // Reset the submitting state
      });
    }
  }

  // Show a dialog with the explanation if the answer is incorrect
  void _showIncorrectAnswerDialog(String explanation) {
    if (_readAloud) {
      _flutterTts.speak(explanation); // Read the explanation aloud if enabled
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Incorrect Answer', style: TextStyle(fontSize: _fontSize == '2X' ? 20 : (_fontSize == '3X' ? 24 : 16), fontFamily: _fontType == 'OpenDyslexic' ? 'OpenDyslexic' : 'Default')),
          content: Text(explanation, style: TextStyle(fontSize: _fontSize == '2X' ? 20 : (_fontSize == '3X' ? 24 : 16), fontFamily: _fontType == 'OpenDyslexic' ? 'OpenDyslexic' : 'Default')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK', style: TextStyle(fontSize: _fontSize == '2X' ? 18 : (_fontSize == '3X' ? 22 : 14), fontFamily: _fontType == 'OpenDyslexic' ? 'OpenDyslexic' : 'Default')),
            ),
          ],
        );
      },
    );
  }

  // Start listening for speech input
  void _startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize(); // Initialize speech-to-text service

      if (available) {
        setState(() => _isListening = true); // Update listening state
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _answerControllers[_currentQuestionIndex].text = result.recognizedWords; // Set the recognized words as the answer
            });
          },
        );
      }
    }
  }

  // Stop listening for speech input
  void _stopListening() {
    setState(() => _isListening = false); // Update listening state
    _speechToText.stop(); // Stop the speech-to-text service
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // Show loading spinner while questions are being loaded
      );
    }

    final progress = _totalQuestions > 0 ? (_currentQuestionIndex + 1) / _totalQuestions : 0.0;
    final question = _totalQuestions > 0 ? _questions[_currentQuestionIndex] : {'question': 'No questions available'};

    final textStyle = TextStyle(
      fontSize: _fontSize == '2X' ? 20 : (_fontSize == '3X' ? 24 : 16),
      fontFamily: _fontType == 'OpenDyslexic' ? 'OpenDyslexic' : 'Default',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz', style: textStyle), // Title of the app bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress), // Show progress of the quiz
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Q-${question['seq_no']}', style: textStyle), // Display the question number
                Text('${_currentQuestionIndex + 1}/$_totalQuestions', style: textStyle), // Display the current question index
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      question['question'],
                      style: textStyle,
                      textAlign: TextAlign.center, // Center-align the question text
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _answerControllers[_currentQuestionIndex], // TextField for user to input answer
                            decoration: InputDecoration(
                              labelText: 'Your answer',
                              labelStyle: textStyle,
                            ),
                            style: textStyle,
                            keyboardType: TextInputType.text,
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none), // Mic icon indicating listening state
                          onPressed: _isListening ? _stopListening : _startListening,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAnswer, // Disable button if an answer is being submitted
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Text color for the button
                        backgroundColor: _isSubmitting ? Colors.grey : Colors.green, // Button color changes when submitting
                        minimumSize: const Size(150, 50),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white) // Show loading spinner when submitting
                          : Text('Submit Answer', style: textStyle),
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
