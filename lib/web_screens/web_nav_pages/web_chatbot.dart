import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:prakriti/services/chatbot_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:prakriti/services/accessibility_preferences_service.dart';

class WebChatbotPage extends StatefulWidget {
  const WebChatbotPage({super.key});

  @override
  _WebChatbotPageState createState() => _WebChatbotPageState();
}

class _WebChatbotPageState extends State<WebChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  final ChatbotService _chatbotService = ChatbotService();
  final AccessibilityPreferencesService _preferencesService = AccessibilityPreferencesService();
  bool _isLoading = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _font = 'OpenSans';
  double _fontSize = 14.0;
  bool _readAloud = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _fetchUserPreferences();
    _controller.addListener(() {
      setState(() {
        _isTyping = _controller.text.isNotEmpty;
      });
    });
  }

  Future<void> _fetchUserPreferences() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        final preferences = await _preferencesService.getUserPreferences(userId);

        setState(() {
          _font = preferences['font'] ?? 'OpenSans';
          _fontSize = (preferences['fontSize'] ?? 1) * 14.0; // Adjust base font size as needed
          _readAloud = preferences['readAloud'] ?? false;
        });
      } else {
      }
    } catch (e) {
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add("User: ${_controller.text}");
      _isLoading = true;
      _isTyping = false;
    });

    var userMessage = _controller.text;
    var response = await _chatbotService.sendMessage(userMessage);

    setState(() {
      _messages.add("Bot: $response");
      _isLoading = false;
    });

    _controller.clear();

    if (_readAloud) {
      _speak(response);
    }
  }

  void _speak(String text) {
    // Implement text-to-speech functionality here
    // For example, using the flutter_tts package:
    // FlutterTts flutterTts = FlutterTts();
    // flutterTts.speak(text);
  }

  void _startListening() async {
    bool available = await _speech.initialize(
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _controller.text = val.recognizedWords;
        }),
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _applyRecommendation(String recommendation) {
    setState(() {
      _controller.text = recommendation;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Recommendations for questions
    final List<String> recommendations = [
      "What are the benefits of recycling?",
      "How can I reduce my carbon footprint?",
      "What are some eco-friendly products?",
      "How does composting help the environment?",
      "What are the latest trends in sustainability?",
      "How can I save energy at home?",
      "What are the effects of plastic pollution?",
      "How can I start a zero-waste lifestyle?",
      "What is the importance of renewable energy?",
      "How can I get involved in local environmental efforts?",
    ];

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: screenWidth * 0.9,
              child: SvgPicture.asset(
                'lib/assets/Prakriti_logo.svg',
                fit: BoxFit.contain,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    bool isUserMessage = _messages[index].startsWith("User:");
                    String message = _messages[index].substring(6); // Remove "User:" or "Bot:"
                    return Align(
                      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
                        decoration: BoxDecoration(
                          color: isUserMessage ? Colors.green.shade500 : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: _fontSize,
                            fontFamily: _font,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isLoading)
                const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    // Recommendations section with fading effect
                    AnimatedOpacity(
                      opacity: _isTyping ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: recommendations.map((recommendation) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: OutlinedButton(
                                  onPressed: () => _applyRecommendation(recommendation),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    side: const BorderSide(color: Colors.white),
                                  ),
                                  child: Text(
                                    recommendation,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _fontSize,
                                      fontFamily: _font,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                          onPressed: _isListening ? _stopListening : _startListening,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.transparent,
                              labelText: 'Enter your message',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: const BorderSide(color: Colors.white), // Default border color
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: const BorderSide(color: Colors.green), // Border color when focused
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: const BorderSide(color: Colors.white), // Border color when enabled
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                            ),
                            style: TextStyle(
                              fontSize: _fontSize,
                              fontFamily: _font,
                              color: Colors.white, // Text color
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: _sendMessage,
                          child: const Text('Send'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
