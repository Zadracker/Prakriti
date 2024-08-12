import 'package:flutter_dotenv/flutter_dotenv.dart'; // For loading environment variables
import 'package:google_generative_ai/google_generative_ai.dart'; // For using Google Generative AI

// Service class to interact with the chatbot
class ChatbotService {
  late final GenerativeModel _model; // Instance of GenerativeModel for generating responses
  late List<Content> _history; // History of conversation content

  // Constructor initializes the chatbot
  ChatbotService() {
    _initializeChatbot(); // Call to initialize chatbot configuration
  }

  // Initializes the chatbot model with API key and settings
  void _initializeChatbot() async {
    // Retrieve the API key from environment variables
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return; // Exit if API key is not available or empty
    }

    // Initialize the GenerativeModel with the API key and configuration
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Specify the model to use
      apiKey: apiKey, // API key for authentication
      generationConfig: GenerationConfig(maxOutputTokens: 100), // Configuration for response generation
    );

    // Initialize conversation history with a welcome message
    _history = [
      Content.text('Hello I am here to learn more about climate change, environmental impact, pollution, etc..'),
      Content.model([TextPart('Great to meet you. What would you like to know?')]),
    ];
  }

  // Sends a user message to the chatbot and retrieves the response
  Future<String> sendMessage(String message) async {
    // Create a Content object for the user's message and add it to history
    var userMessage = Content.text(message);
    _history.add(userMessage);

    try {
      // Generate a response from the chatbot using the conversation history
      var response = await _model.generateContent(_history);
      // Return the generated response text, or a default message if no response
      return response.text ?? 'No response from Gemini';
    } catch (e) {
      // Print error and return a default error message in case of exception
      print('Error generating response: $e');
      return 'Error generating response';
    }
  }
}
