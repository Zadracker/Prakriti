import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // Import the STT package
import '../services/forum_service.dart';
import '../services/user_service.dart';
import '../services/profile_service.dart';
import 'profile_card.dart'; // Import ProfileCard

class WebPostPage extends StatefulWidget {
  final String postId;

  const WebPostPage({super.key, required this.postId});

  @override
  _WebPostPageState createState() => _WebPostPageState();
}

class _WebPostPageState extends State<WebPostPage> {
  final ForumService _forumService = ForumService();
  final UserService _userService = UserService();
  final ProfileService _profileService = ProfileService(userId: '');
  final TextEditingController _commentController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available.')),
      );
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      _speech.listen(
        onResult: (result) {
          setState(() {
            _commentController.text = result.recognizedWords;
          });
        },
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  Future<void> _addComment() async {
    final String commentText = _commentController.text.trim();
    final User? user = FirebaseAuth.instance.currentUser;

    if (commentText.isNotEmpty) {
      try {
        if (user != null) {
          final String userID = user.uid;
          final String? role = await _userService.getUserRole(userID);
          final String username = user.displayName ?? 'Anonymous';

          await _forumService.addComment(
            widget.postId,
            commentText,
            userID,
            role!,
            username,
          );
          _commentController.clear();
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
    }
    return null;
  }

  Future<String?> _getProfileImage(String userId, String role) async {
    try {
      if (role == 'eco_advocate') {
        return await _profileService.getProfileImage(userId);
      } else {
        final profileDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userId)
            .get();
        final profileImageUrl = profileDoc['profile_image'] as String?;
        return profileImageUrl;
      }
    } catch (e) {
    }
    return null;
  }

  void _showProfileCard(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: ProfileCard(userId: userId),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder<Post>(
              stream: _forumService.getPostStream(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return const Center(child: Text('Post not found.'));
                } else {
                  final post = snapshot.data!;
                  return ListView(
                    padding: const EdgeInsets.all(8.0),
                    children: [
                      FutureBuilder<String?>(
                        future: _getAuthorProfileImage(post.authorUsername),
                        builder: (context, imageSnapshot) {
                          final imageUrl = imageSnapshot.data;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundImage: imageUrl != null
                                  ? NetworkImage(imageUrl)
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
                        ),
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
                        stream: _forumService.getComments(widget.postId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No comments found.'));
                          } else {
                            final comments = snapshot.data!;
                            return Column(
                              children: comments.map((comment) {
                                return FutureBuilder<String?>(
                                  future: _getProfileImage(comment.userID, comment.role),
                                  builder: (context, userSnapshot) {
                                    final imageUrl = userSnapshot.data;
                                    if (userSnapshot.hasError) {
                                    }
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                                      leading: GestureDetector(
                                        onTap: () {
                                          if (comment.role != 'eco_advocate') {
                                            _showProfileCard(comment.userID);
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
                  onPressed: _toggleListening,
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
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
