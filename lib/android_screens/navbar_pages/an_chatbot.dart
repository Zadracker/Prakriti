import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg for SVG support
import 'package:prakriti/services/chatbot_service.dart'; // Import custom chatbot service
import 'package:speech_to_text/speech_to_text.dart' as stt; // Import speech_to_text package for voice input

/// The ChatbotPage provides a chat interface where users can interact with a chatbot.
/// It supports text input, voice input, and displays message recommendations.
class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = []; // List to hold chat messages
  final ChatbotService _chatbotService = ChatbotService(); // Service to handle chatbot interactions
  bool _isLoading = false; // Indicator for loading state (e.g., while waiting for chatbot response)
  late stt.SpeechToText _speech; // Instance for speech-to-text functionality
  bool _isListening = false; // Indicator for whether speech recognition is active
  bool _isTyping = false; // Indicator for whether the user is typing

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // Listener to update _isTyping based on whether the TextEditingController is empty
    _controller.addListener(() {
      setState(() {
        _isTyping = _controller.text.isNotEmpty;
      });
    });
  }

  /// Sends the user's message to the chatbot and displays the response.
  void _sendMessage() async {
    if (_controller.text.isEmpty) return; // Exit if no message is entered

    setState(() {
      _messages.add("User: ${_controller.text}"); // Add user message to message list
      _isLoading = true; // Show loading indicator
    });

    var userMessage = _controller.text;
    var response = await _chatbotService.sendMessage(userMessage); // Send message to chatbot service

    setState(() {
      _messages.add("Bot: $response"); // Add bot's response to message list
      _isLoading = false; // Hide loading indicator
    });

    _controller.clear(); // Clear text input field
  }

  /// Starts listening for voice input and updates the text field with recognized words.
  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true); // Set listening state to true
      _speech.listen(
        onResult: (val) => setState(() {
          _controller.text = val.recognizedWords; // Update text field with recognized words
        }),
      );
    }
  }

  /// Stops listening for voice input.
  void _stopListening() {
    setState(() => _isListening = false); // Set listening state to false
    _speech.stop(); // Stop speech-to-text listening
  }

  /// Applies a recommendation to the text field.
  void _applyRecommendation(String recommendation) {
    setState(() {
      _controller.text = recommendation; // Set text field content to the selected recommendation
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // List of recommended questions for the user to choose from
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
          // Background logo displayed with reduced opacity
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: screenWidth * 0.9, // Set logo width to 90% of screen width
              child: SvgPicture.asset(
                'lib/assets/Prakriti_logo.svg', // Path to the logo SVG file
                fit: BoxFit.contain, // Ensure the logo fits within the container
                color: Colors.white.withOpacity(0.1), // Apply opacity to the logo
              ),
            ),
          ),
          Column(
            children: <Widget>[
              // Display chat messages in a scrollable list
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
                            color: isUserMessage ? Colors.white : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Show a loading indicator if the chatbot is processing a response
              if (_isLoading)
                const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    // Recommendations section: horizontal scrollable row of buttons
                    AnimatedOpacity(
                      opacity: _isTyping ? 0.0 : 1.0, // Fade out recommendations while typing
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
                                  onPressed: () => _applyRecommendation(recommendation), // Apply selected recommendation
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    side: const BorderSide(color: Colors.white),
                                  ),
                                  child: Text(
                                    recommendation,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.0, // Font size for recommendations
                                      fontFamily: 'OpenSans', // Font family for recommendations
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
                        // Voice input button
                        IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                          onPressed: _isListening ? _stopListening : _startListening,
                          color: Colors.green[700], // Primary color for the button
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              labelText: 'Enter your message',
                              fillColor: Colors.transparent,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0), // Round corners of the text field
                                borderSide: const BorderSide(
                                  color: Colors.white, // Default border color
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0), // Round corners when focused
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
                        // Send button
                        ElevatedButton(
                          onPressed: _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700], // Primary color for the button
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
