import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // Import Speech-to-Text (STT) package
import '../services/forum_service.dart'; // Import the service for forum-related operations
import '../services/user_service.dart'; // Import the service for user-related operations
import '../services/profile_service.dart'; // Import the service for profile-related operations
import 'profile_card.dart'; // Import ProfileCard widget

// WebPostPage is a StatefulWidget that displays the details of a post and allows users to add comments
class WebPostPage extends StatefulWidget {
  final String postId; // The ID of the post to be displayed

  const WebPostPage({super.key, required this.postId});

  @override
  _WebPostPageState createState() => _WebPostPageState();
}

class _WebPostPageState extends State<WebPostPage> {
  final ForumService _forumService = ForumService(); // Service for managing forum posts and comments
  final UserService _userService = UserService(); // Service for user-related operations
  final ProfileService _profileService = ProfileService(userId: ''); // Service for fetching user profiles
  final TextEditingController _commentController = TextEditingController(); // Controller for the comment input field
  final stt.SpeechToText _speech = stt.SpeechToText(); // STT instance for speech recognition
  bool _isListening = false; // Flag to track if the app is currently listening for speech input

  @override
  void initState() {
    super.initState();
    _initializeSpeech(); // Initialize speech recognition when the widget is first created
  }

  // Initializes the Speech-to-Text (STT) service
  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available.')),
      );
    }
  }

  // Toggles the speech recognition state (start/stop listening)
  void _toggleListening() async {
    if (_isListening) {
      _speech.stop(); // Stop listening if currently listening
      setState(() {
        _isListening = false;
      });
    } else {
      _speech.listen(
        onResult: (result) {
          setState(() {
            _commentController.text = result.recognizedWords; // Update the comment field with recognized words
          });
        },
      );
      setState(() {
        _isListening = true; // Update the listening state
      });
    }
  }

  // Adds a new comment to the post
  Future<void> _addComment() async {
    final String commentText = _commentController.text.trim(); // Get and trim the comment text
    final User? user = FirebaseAuth.instance.currentUser; // Get the current user

    if (commentText.isNotEmpty) {
      try {
        if (user != null) {
          final String userID = user.uid;
          final String? role = await _userService.getUserRole(userID); // Fetch the user's role
          final String username = user.displayName ?? 'Anonymous'; // Get the username or default to 'Anonymous'

          await _forumService.addComment(
            widget.postId,
            commentText,
            userID,
            role!,
            username,
          ); // Add the comment to the forum
          _commentController.clear(); // Clear the comment input field
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add comment')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
    }
  }

  // Retrieves the profile image URL of the post author
  Future<String?> _getAuthorProfileImage(String authorUsername) async {
    try {
      final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: authorUsername)
          .get();
      
      if (userSnapshot.docs.isNotEmpty) {
        final doc = userSnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return data['profileImageUrl'] as String?;
      }
    } catch (e) {
      // Handle errors if necessary
    }
    return null; // Return null if no image URL is found
  }

  // Retrieves the profile image URL based on user ID and role
  Future<String?> _getProfileImage(String userId, String role) async {
    try {
      if (role == 'eco_advocate') {
        return await _profileService.getProfileImage(userId); // Fetch image for eco-advocates
      } else {
        final profileDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userId)
            .get();
        final profileImageUrl = profileDoc['profile_image'] as String?;
        return profileImageUrl;
      }
    } catch (e) {
      // Handle errors if necessary
    }
    return null; // Return null if no image URL is found
  }

  // Shows a profile card dialog for a specific user
  void _showProfileCard(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: ProfileCard(userId: userId), // Display the profile card
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'), // Title of the page
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder<Post>(
              stream: _forumService.getPostStream(widget.postId), // Stream of the post data
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Show loading indicator while data is being fetched
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  // Show error message if there's an issue fetching the post
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  // Show message if no data is found
                  return const Center(child: Text('Post not found.'));
                } else {
                  final post = snapshot.data!;
                  return ListView(
                    padding: const EdgeInsets.all(8.0),
                    children: [
                      FutureBuilder<String?>(
                        future: _getAuthorProfileImage(post.authorUsername), // Fetch the author's profile image
                        builder: (context, imageSnapshot) {
                          final imageUrl = imageSnapshot.data;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundImage: imageUrl != null
                                  ? NetworkImage(imageUrl) // Display the author's profile image
                                  : null,
                              child: imageUrl == null ? const Icon(Icons.account_circle, size: 24) : null,
                            ),
                            title: Text(post.authorUsername),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.details,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      if (post.imageAttached != null && post.imageAttached!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: post.imageAttached!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                          placeholder: (context, url) => const CircularProgressIndicator(),
                        ), // Display the attached post image
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<Comment>>(
                        stream: _forumService.getComments(widget.postId), // Stream of comments for the post
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            // Show loading indicator while comments are being fetched
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            // Show error message if there's an issue fetching comments
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            // Show message if no comments are found
                            return const Center(child: Text('No comments found.'));
                          } else {
                            final comments = snapshot.data!;
                            return Column(
                              children: comments.map((comment) {
                                return FutureBuilder<String?>(
                                  future: _getProfileImage(comment.userID, comment.role), // Fetch the commenter's profile image
                                  builder: (context, userSnapshot) {
                                    final imageUrl = userSnapshot.data;
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                                      leading: GestureDetector(
                                        onTap: () {
                                          if (comment.role != 'eco_advocate') {
                                            _showProfileCard(comment.userID); // Show profile card on tap
                                          }
                                        },
                                        child: CircleAvatar(
                                          radius: 24,
                                          backgroundImage: imageUrl != null
                                              ? (comment.role == 'eco_advocate'
                                                  ? NetworkImage(imageUrl)
                                                  : AssetImage(imageUrl)) as ImageProvider
                                              : null,
                                          child: imageUrl == null
                                              ? const Icon(
                                                  Icons.account_circle,
                                                  size: 24,
                                                  color: Colors.grey,
                                                )
                                              : null,
                                        ),
                                      ),
                                      title: Text(comment.text),
                                      subtitle: Text('By: ${comment.username}'),
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          }
                        },
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: _isListening ? Colors.red : Colors.blue,
                  ),
                  onPressed: _toggleListening, // Toggle speech recognition
                ),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment, // Add comment to the post
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
