import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/web_screens/web_nav_pages/web_forum.dart';
import '../../services/news_service.dart';
import '../../services/forum_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../forum_pages/an_create_post.dart';

class EcoNewsPage extends StatefulWidget {
  const EcoNewsPage({super.key});

  @override
  _EcoNewsPageState createState() => _EcoNewsPageState();
}

class _EcoNewsPageState extends State<EcoNewsPage> with SingleTickerProviderStateMixin {
  // Future to hold the list of articles from the news service
  late Future<List<Article>> _articles;
  // Controller for handling the tabs
  late TabController _tabController;
  final NewsService _newsService = NewsService(); // Service for fetching news articles
  final ForumService _forumService = ForumService(); // Service for forum-related operations
  late String username; // Store the username of the current user
  String filter = 'Most Recent'; // Default filter for forum posts

  @override
  void initState() {
    super.initState();
    // Fetch articles from the news service
    _articles = _newsService.fetchEcoNews();
    // Initialize TabController with two tabs: News and Forum
    _tabController = TabController(length: 2, vsync: this);
    // Rebuild the widget when the tab changes
    _tabController.addListener(() {
      setState(() {});
    });
    // Initialize user information
    _initializeUser();
  }

  @override
  void dispose() {
    // Dispose of the TabController when no longer needed
    _tabController.dispose();
    super.dispose();
  }

  // Fetch user information from Firebase and update the username
  Future<void> _initializeUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          username = user.displayName ?? 'Anonymous';
        });
      }
    } catch (e) {
      // Handle errors (e.g., network issues)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // TabBar for switching between News and Forum tabs
          PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'News'),
                Tab(text: 'Forum'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildNewsPage(), // Display news articles
                buildForumPage(), // Display forum posts
              ],
            ),
          ),
        ],
      ),
      // Floating action button for creating a new post (visible only in Forum tab)
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostPage()),
                );
              },
              tooltip: 'Create Post',
              backgroundColor: Colors.green,
              child: const Icon(Icons.create),
            )
          : null,
      // Bottom app bar for forum-specific controls (visible only in Forum tab)
      bottomNavigationBar: _tabController.index == 1
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Button to show forum rules
                  IconButton(
                    icon: const Icon(Icons.rule),
                    onPressed: () => _showRules(context),
                  ),
                  // Dropdown button for filtering forum posts
                  DropdownButton<String>(
                    value: filter,
                    items: ['Most Recent', 'Most Liked', 'Most Commented']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        filter = newValue!;
                      });
                    },
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // Build the News page with articles
  Widget buildNewsPage() {
    return FutureBuilder<List<Article>>(
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
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return ListTile(
                leading: article.urlToImage.isNotEmpty
                    ? Image.network(article.urlToImage, width: 100, fit: BoxFit.cover)
                    : null,
                title: Text(article.title),
                onTap: () => _launchURL(article.url),
              );
            },
          );
        }
      },
    );
  }

  // Launch a URL in the browser
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Handle error if URL cannot be launched
    }
  }

  // Build the Forum page with posts
  Widget buildForumPage() {
    return StreamBuilder<List<Post>>(
      stream: _forumService.getPosts(filter: filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No posts found.'));
        } else {
          final posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                username: username,
                onLike: () async {
                  if (username.isNotEmpty) {
                    await _forumService.likePost(post.id, username);
                  }
                },
                onUnlike: () async {
                  if (username.isNotEmpty) {
                    await _forumService.unlikePost(post.id, username);
                  }
                },
                onDelete: () async {
                  final confirmDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text('Are you sure you want to delete this post?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmDelete == true) {
                    try {
                      await _forumService.deletePost(post.id);
                    } catch (e) {
                      // Handle errors (e.g., network issues)
                    }
                  }
                },
              );
            },
          );
        }
      },
    );
  }

  // Show a dialog with the forum rules
  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forum Rules'),
        content: const Text(
            '1. Be respectful\n2. No spam\n3. Stay on topic\n4. No Offensive content\n5. Follow community guidelines'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
