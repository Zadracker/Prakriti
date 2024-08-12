import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/news_service.dart'; // Import the service to fetch news articles
import '../../../services/accessibility_preferences_service.dart'; // Import the service for user preferences
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth for user authentication

class WebNewsPage extends StatefulWidget {
  const WebNewsPage({super.key});

  @override
  _WebNewsPageState createState() => _WebNewsPageState();
}

class _WebNewsPageState extends State<WebNewsPage> {
  late Future<List<Article>> _articles; // Future to manage fetching news articles
  final NewsService _newsService = NewsService(); // Service to fetch news articles
  final AccessibilityPreferencesService _preferencesService = AccessibilityPreferencesService(); // Service for user preferences
  final FlutterTts _flutterTts = FlutterTts(); // Text-to-speech service
  final User? _user = FirebaseAuth.instance.currentUser; // Current authenticated user

  String _selectedFont = 'OpenSans'; // Default font
  int _fontSize = 1; // Default font size multiplier
  bool _readAloud = false; // Flag to determine if text should be read aloud

  @override
  void initState() {
    super.initState();
    _articles = _newsService.fetchEcoNews(); // Fetch news articles
    _loadUserPreferences(); // Load user preferences
  }

  /// Loads user preferences from the service and updates state
  Future<void> _loadUserPreferences() async {
    if (_user != null) {
      final preferences = await _preferencesService.getUserPreferences(_user.uid);
      setState(() {
        _selectedFont = preferences['font'] ?? 'OpenSans';
        _fontSize = preferences['fontSize'] ?? 1;
        _readAloud = preferences['readAloud'] ?? false;
      });
    }
  }

  /// Returns the text style based on user preferences
  TextStyle _getTextStyle() {
    return TextStyle(
      fontFamily: _selectedFont,
      fontSize: _fontSize.toDouble() * 16, // Adjust font size based on user preferences
    );
  }

  /// Launches a URL in the default browser
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Optionally handle the case where the URL cannot be launched
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  /// Speaks the text aloud using the FlutterTts service
  void _speak(String text) async {
    if (_readAloud) {
      await _flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Article>>(
        future: _articles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading spinner while fetching news articles
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Show error message if there's an error fetching articles
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Show message if no articles are found
            return const Center(child: Text('No news articles found.'));
          } else {
            final articles = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    onTap: () {
                      _launchURL(article.url); // Launch article URL
                      _speak(article.title); // Read aloud article title if enabled
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article.urlToImage.isNotEmpty)
                          // Display article image if available
                          Image.network(
                            article.urlToImage,
                            width: 120,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 80,
                                color: Colors.grey,
                                child: const Icon(Icons.broken_image, color: Colors.white),
                              );
                            },
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.title,
                                  style: _getTextStyle().copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // No summary available, so only showing title.
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
