// services/news_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsService {
  final String _apiKey = dotenv.env['NEWS_API'] ?? '';

  Future<List<Article>> fetchEcoNews() async {
    final url = 'https://newsapi.org/v2/everything?q=climate change OR sustainable development&apiKey=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> articlesJson = data['articles'];
      return articlesJson.map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load news');
    }
  }
}

class Article {
  final String title;
  final String url;
  final String urlToImage;

  Article({required this.title, required this.url, required this.urlToImage});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'],
      url: json['url'],
      urlToImage: json['urlToImage'] ?? '',
    );
  }
}
