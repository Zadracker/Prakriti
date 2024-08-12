import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/web_screens/web_forum_dir/web_create_post.dart';
import 'package:prakriti/commons/posts.dart';
import 'package:prakriti/services/forum_service.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/services/accessibility_preferences_service.dart';

class WebForumPage extends StatefulWidget {
  const WebForumPage({super.key});

  @override
  _WebForumPageState createState() => _WebForumPageState();
}

class _WebForumPageState extends State<WebForumPage> {
  final ForumService _forumService = ForumService();
  final UserService _userService = UserService();
  final AccessibilityPreferencesService _preferencesService = AccessibilityPreferencesService();
  String? username;
  String filter = 'Most Recent'; // Initial filter for sorting posts
  int _fontSize = 1; // Default font size
  String _font = 'OpenSans'; // Default font

  @override
  void initState() {
    super.initState();
    _initializeUser(); // Load user information
    _loadUserPreferences(); // Load user preferences for font size and font
  }

  /// Fetches the current user's information and updates the username.
  Future<void> _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await _userService.getUser(user.uid);
        final userData = userDoc.data();
        if (userData != null) {
          setState(() {
            username = userData['username'] as String?;
          });
        }
      } catch (e) {
        // Handle any errors that occur while fetching user data
      }
    }
  }

  /// Loads user preferences such as font size and font type.
  Future<void> _loadUserPreferences() async {
    if (FirebaseAuth.instance.currentUser != null) {
      final preferences = await _preferencesService.getUserPreferences(FirebaseAuth.instance.currentUser!.uid);
      setState(() {
        _fontSize = preferences['fontSize'] ?? 1;
        _font = preferences['font'] ?? 'OpenSans';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper function to adjust text size based on user preferences
    double textSize(double size) {
      switch (_fontSize) {
        case 2:
          return size * 2;
        case 3:
          return size * 3;
        default:
          return size;
      }
    }

    return Scaffold(
      body: Row(
        children: [
          // Filter Column: Allows users to select how to sort posts
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(textSize(16.0)),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: textSize(20),
                        fontWeight: FontWeight.bold,
                        fontFamily: _font,
                      ),
                    ),
                    SizedBox(height: textSize(20)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ['Most Recent', 'Most Liked', 'Most Commented']
                          .map((String value) {
                        return Row(
                          children: [
                            Flexible(
                              child: Radio<String>(
                                value: value,
                                groupValue: filter,
                                onChanged: (String? newFilter) {
                                  setState(() {
                                    filter = newFilter!;
                                  });
                                },
                              ),
                            ),
                            Flexible(
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: textSize(16),
                                  fontFamily: _font,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: textSize(20)),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WebCreatePostPage()),
                          );
                        },
                        child: Text(
                          'Create Post',
                          style: TextStyle(
                            fontSize: textSize(16),
                            fontFamily: _font,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content Column: Displays the list of posts based on the selected filter
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: StreamBuilder<List<Post>>(
                stream: _forumService.getPosts(filter: filter),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading posts'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No posts available'));
                  }

                  final posts = snapshot.data!;
                  final padding = MediaQuery.of(context).size.width * 0.05; // 5% padding from each side

                  return ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];

                      return PostCard(
                        post: post,
                        username: username,
                        onLike: () async {
                          if (username != null) {
                            await _forumService.likePost(post.id, username!);
                          }
                        },
                        onUnlike: () async {
                          if (username != null) {
                            await _forumService.unlikePost(post.id, username!);
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
                              // Handle any errors that occur while deleting the post
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // Rules Column: Displays the forum rules
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(textSize(16.0)),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rules',
                      style: TextStyle(
                        fontSize: textSize(20),
                        fontWeight: FontWeight.bold,
                        fontFamily: _font,
                      ),
                    ),
                    SizedBox(height: textSize(20)),
                    Text(
                      '1. Be respectful to others.\n'
                      '2. No spamming.\n'
                      '3. Stay on topic.\n'
                      '4. No offensive content.\n'
                      '5. Follow community guidelines.',
                      style: TextStyle(
                        fontSize: textSize(16),
                        fontFamily: _font,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying individual posts in the forum.
class PostCard extends StatelessWidget {
  final Post post;
  final String? username;
  final Future<void> Function() onLike;
  final Future<void> Function() onUnlike;
  final Future<void> Function() onDelete;

  const PostCard({super.key, 
    required this.post,
    this.username,
    required this.onLike,
    required this.onUnlike,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasLiked = post.likes.contains(username);
    final isAuthor = username == post.authorUsername;

    // Truncate the post details text to 500 characters and add ellipsis
    String truncateText(String text, int maxLength) {
      if (text.length <= maxLength) {
        return text;
      } else {
        return '${text.substring(0, maxLength)}...';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebPostPage(postId: post.id),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10), // Adjust vertical spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the post image if available
            if (post.imageAttached != null && post.imageAttached!.isNotEmpty)
              SizedBox(
                height: 200, // Fixed height for image
                child: Image.network(
                  post.imageAttached!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Not able to fetch image - please view this post on phone',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            // Display the post title
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                post.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'OpenSans', // Use your preferred font
                ),
              ),
            ),
            // Display the post author and date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'By ${post.authorUsername}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            // Display the post content with truncation
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                truncateText(post.details, 500),
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            // Buttons for like, comment, and delete actions
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Like/Unlike Button
                  IconButton(
                    icon: Icon(
                      hasLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                      color: hasLiked ? Colors.blue : Colors.grey,
                    ),
                    onPressed: hasLiked ? onUnlike : onLike,
                  ),
                  const SizedBox(width: 8.0),
                  Text('${post.likes.length} Likes'),
                  const SizedBox(width: 16.0),
                  // Comments Button
                  IconButton(
                    icon: const Icon(Icons.comment),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WebPostPage(postId: post.id),
                        ),
                      );
                    },
                  ),
                  Text('${post.commentsCount} Comments'),
                  // Delete Button: Only shown if the user is the author of the post
                  if (isAuthor)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
