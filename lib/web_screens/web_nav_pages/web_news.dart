import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/news_service.dart';
import '../../../services/accessibility_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebNewsPage extends StatefulWidget {
  const WebNewsPage({super.key});

  @override
  _WebNewsPageState createState() => _WebNewsPageState();
}

class _WebNewsPageState extends State<WebNewsPage> {
  late Future<List<Article>> _articles;
  final NewsService _newsService = NewsService();
  final AccessibilityPreferencesService _preferencesService = AccessibilityPreferencesService();
  final FlutterTts _flutterTts = FlutterTts();
  final User? _user = FirebaseAuth.instance.currentUser;

  String _selectedFont = 'OpenSans';
  int _fontSize = 1;
  bool _readAloud = false;

  @override
  void initState() {
    super.initState();
    _articles = _newsService.fetchEcoNews();
    _loadUserPreferences();
  }

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

  TextStyle _getTextStyle() {
    return TextStyle(
      fontFamily: _selectedFont,
      fontSize: _fontSize.toDouble() * 16,
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
    }
  }

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
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                      _launchURL(article.url);
                      _speak(article.title); // Read aloud article title on tap if enabled
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article.urlToImage.isNotEmpty)
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
