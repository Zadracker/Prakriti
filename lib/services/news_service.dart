// services/news_service.dart

import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For environment variable management

class NewsService {
  // API key for accessing the news API, fetched from environment variables
  final String _apiKey = dotenv.env['NEWS_API'] ?? '';

  // Fetches eco-friendly news articles from the news API
  Future<List<Article>> fetchEcoNews() async {
    // URL for the news API with query parameters for eco-friendly topics
    final url = 'https://newsapi.org/v2/everything?q=climate change OR sustainable development&apiKey=$_apiKey';

    // Making an HTTP GET request to fetch the news data
    final response = await http.get(Uri.parse(url));

    // Check if the response status is OK (200)
    if (response.statusCode == 200) {
      // Decode the JSON response into a Dart Map
      final Map<String, dynamic> data = json.decode(response.body);

      // Extract the list of articles from the JSON data
      final List<dynamic> articlesJson = data['articles'];

      // Convert each article JSON object to an Article instance and return the list
      return articlesJson.map((json) => Article.fromJson(json)).toList();
    } else {
      // Throw an exception if the response status is not OK
      throw Exception('Failed to load news');
    }
  }
}

// Class representing a news article
class Article {
  final String title; // Title of the article
  final String url; // URL of the article
  final String urlToImage; // URL of the article's image

  // Constructor for the Article class
  Article({required this.title, required this.url, required this.urlToImage});

  // Factory method to create an Article instance from JSON data
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'], // Title of the article
      url: json['url'], // URL of the article
      urlToImage: json['urlToImage'] ?? '', // URL to the article's image, default to empty string if not available
    );
  }
}
