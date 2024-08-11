import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatbotService {
  late final GenerativeModel _model;
  late List<Content> _history;

  ChatbotService() {
    _initializeChatbot();
  }

  void _initializeChatbot() async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(maxOutputTokens: 100),
    );

    _history = [
      Content.text('Hello I am here to learn more about climate change, environmental impact, pollution, etc..'),
      Content.model([TextPart('Great to meet you. What would you like to know?')]),
    ];
  }

  Future<String> sendMessage(String message) async {
    var userMessage = Content.text(message);
    _history.add(userMessage);

    var response = await _model.generateContent(_history);
    return response.text ?? 'No response from Gemini';
  }
}
