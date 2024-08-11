import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg
import 'package:prakriti/services/chatbot_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  final ChatbotService _chatbotService = ChatbotService();
  bool _isLoading = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _controller.addListener(() {
      setState(() {
        _isTyping = _controller.text.isNotEmpty;
      });
    });
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add("User: ${_controller.text}");
      _isLoading = true;
    });

    var userMessage = _controller.text;
    var response = await _chatbotService.sendMessage(userMessage);

    setState(() {
      _messages.add("Bot: $response");
      _isLoading = false;
    });

    _controller.clear();
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
          // Background logo
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: screenWidth * 0.9, // 90% of screen width
              child: SvgPicture.asset(
                'lib/assets/Prakriti_logo.svg', // Replace with your logo's path
                fit: BoxFit.contain, // Ensure the logo fits within the container
                color: Colors.white.withOpacity(0.1), // Adjust opacity as needed
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
                    return Align(
                      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isUserMessage ? Colors.green.shade500 : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          _messages[index].substring(_messages[index].indexOf(':') + 1).trim(),
                          style: TextStyle(
                            color: isUserMessage ? Colors.white: Colors.white,
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
                    // Recommendations section
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.0, // Adjust font size as needed
                                      fontFamily: 'OpenSans', // Adjust font family as needed
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: <Widget>[
                        IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                          onPressed: _isListening ? _stopListening : _startListening,
                          color: Colors.green[700], // Primary color
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              labelText: 'Enter your message',
                              fillColor: Colors.transparent,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0), // Increase border radius
                                borderSide: const BorderSide(
                                  color: Colors.white, // Default border color
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0), // Increase border radius
                                borderSide: BorderSide(
                                  color: Colors.green[700]!, // Border color when focused
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.white, // Text color
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700], // Primary color
                          ),
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
