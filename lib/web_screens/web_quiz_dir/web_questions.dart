import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/services/quiz_completion_service.dart';
import 'package:prakriti/services/accessibility_preferences_service.dart'; // Import AccessibilityPreferencesService
import 'package:flutter_tts/flutter_tts.dart'; // Import flutter_tts
import 'package:speech_to_text/speech_to_text.dart' as stt; // Import Speech-to-Text

class WebQuestions extends StatefulWidget {
  final Function(int) onQuizComplete;

  const WebQuestions({super.key, required this.onQuizComplete});

  @override
  _WebQuestionsState createState() => _WebQuestionsState();
}

class _WebQuestionsState extends State<WebQuestions> with SingleTickerProviderStateMixin {
  final QuizCompletionService _quizCompletionService = QuizCompletionService();
  final List<TextEditingController> _answerControllers = [];
  final FlutterTts _flutterTts = FlutterTts(); // Text-to-Speech instance
  final AccessibilityPreferencesService _accessibilityService = AccessibilityPreferencesService();
  final stt.SpeechToText _speechToText = stt.SpeechToText(); // Speech-to-Text instance

  bool _loading = true;
  bool _isSubmitting = false; // Add a boolean to track the submission state
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _totalQuestions = 0;
  User? _currentUser;
  String _fontSize = '1X'; // Default font size
  String _fontType = 'Default'; // Default font type
  bool _readAloud = false; // Default text-to-speech setting
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadAccessibilityPreferences();
    _loadQuestions();
  }

  Future<void> _loadAccessibilityPreferences() async {
    final preferences = await _accessibilityService.getUserPreferences(FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      _fontSize = preferences['fontSize'] ?? '1X';
      _fontType = preferences['font'] ?? 'Default';
      _readAloud = preferences['readAloud'] ?? false;
    });
    }

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
        _answerControllers.add(TextEditingController());
        return {
          'id': doc.id,
          'question': data['question'],
          'seq_no': data['seq_no'],
        };
      }).toList();
      _totalQuestions = _questions.length;
      _loading = false;
    });

    // Start quiz by creating a response document
    await _quizCompletionService.startQuiz();
  }

  Future<void> _submitAnswer() async {
    if (_currentUser == null) {
      return;
    }

    if (_currentQuestionIndex >= _totalQuestions) {
      return;
    }

    setState(() {
      _isSubmitting = true; // Set the submitting state to true
    });

    final userAnswer = _answerControllers[_currentQuestionIndex].text.trim();
    final question = _questions[_currentQuestionIndex]['question'];

    try {
      final result = await _quizCompletionService.submitAnswer(question, userAnswer);
      final isCorrect = result['isCorrect'] as bool;
      final explanation = result['explanation'] as String;

      if (!isCorrect) {
        _showIncorrectAnswerDialog(explanation);
      }

      setState(() {
        if (_currentQuestionIndex < _totalQuestions - 1) {
          _currentQuestionIndex++;
          if (_readAloud) {
            _flutterTts.speak(_questions[_currentQuestionIndex]['question']);
          }
        } else {
          widget.onQuizComplete(8); // Index for the Results page
          Navigator.pop(context); // Go back to WebScaffold
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit answer.')),
      );
    } finally {
      setState(() {
        _isSubmitting = false; // Reset the submitting state
      });
    }
  }

  void _showIncorrectAnswerDialog(String explanation) {
    if (_readAloud) {
      _flutterTts.speak(explanation);
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
                Navigator.of(context).pop();
              },
              child: Text('OK', style: TextStyle(fontSize: _fontSize == '2X' ? 18 : (_fontSize == '3X' ? 22 : 14), fontFamily: _fontType == 'OpenDyslexic' ? 'OpenDyslexic' : 'Default')),
            ),
          ],
        );
      },
    );
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize(
      );

      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _answerControllers[_currentQuestionIndex].text = result.recognizedWords;
            });
          },
        );
      }
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speechToText.stop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
        title: Text('Quiz', style: textStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Q-${question['seq_no']}', style: textStyle),
                Text('${_currentQuestionIndex + 1}/$_totalQuestions', style: textStyle),
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
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _answerControllers[_currentQuestionIndex],
                            decoration: InputDecoration(
                              labelText: 'Your answer',
                              labelStyle: textStyle,
                            ),
                            style: textStyle,
                            keyboardType: TextInputType.text,
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                          onPressed: _isListening ? _stopListening : _startListening,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Text color
                        backgroundColor: _isSubmitting ? Colors.grey : Colors.green, // Button color changes when submitting
                        minimumSize: const Size(150, 50),
                      ), // Disable button when submitting
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white) // Show loading spinner
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
