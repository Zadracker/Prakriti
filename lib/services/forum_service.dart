import 'dart:typed_data'; // For Uint8List
import 'dart:io' as io; // For File on Android
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/user_service.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService(); 

  // Create a new post
   Future<void> createPost({
    required String title,
    required String details,
    String? imageUrl,
    required String currentUsername,
  }) async {
    final String userID = _auth.currentUser?.uid ?? '';

    final userSnapshot = await _userService.getUser(userID);
    final currentUsername = userSnapshot.data()?['username'] ?? 'Unknown User';

    // Create a new post document in Firestore
    await _firestore.collection('posts').add({
      'title': title,
      'details': details,
      'imageAttached': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'authorUsername': currentUsername,
      'userID': userID,
      'likes': [],
      'commentsCount': 0,
      'likesCount': 0,
    });
  }

  // Get all posts with optional filter
  Stream<List<Post>> getPosts({String? filter}) {
    Query query = _firestore.collection('posts');

    // Apply filter if specified
    if (filter != null) {
      switch (filter) {
        case 'Most Liked':
          query = query.orderBy('likesCount', descending: true);
          break;
        case 'Most Commented':
          query = query.orderBy('commentsCount', descending: true);
          break;
        default: // Most Recent
          query = query.orderBy('timestamp', descending: true);
          break;
      }
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final document = doc as DocumentSnapshot<Map<String, dynamic>>;
        return Post.fromDocument(document);
      }).toList();
    });
  }

  // Get a specific post by ID as a Stream
  Stream<Post> getPostStream(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Post not found');
      }
      final document = snapshot;
      return Post.fromDocument(document);
    });
  }

  // Like a post
  Future<void> likePost(String postId, String userID) async {
    final postDoc = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postDoc);
      final postData = postSnapshot.data();
      if (postData != null) {
        List<String> likes = List<String>.from(postData['likes'] ?? []);
        if (!likes.contains(userID)) {
          likes.add(userID);
          transaction.update(postDoc, {'likes': likes});
          transaction.update(postDoc, {'likesCount': FieldValue.increment(1)});
        }
      }
    });
  }

  // Unlike a post
  Future<void> unlikePost(String postId, String userID) async {
    final postDoc = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postDoc);
      final postData = postSnapshot.data();
      if (postData != null) {
        List<String> likes = List<String>.from(postData['likes'] ?? []);
        if (likes.contains(userID)) {
          likes.remove(userID);
          transaction.update(postDoc, {'likes': likes});
          transaction.update(postDoc, {'likesCount': FieldValue.increment(-1)});
        }
      }
    });
  }

  // Check if user has liked a post
  Future<bool> hasUserLikedPost(String postId, String userID) async {
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    final postData = postDoc.data();
    if (postData != null) {
      List<String> likes = List<String>.from(postData['likes'] ?? []);
      return likes.contains(userID);
    }
    return false;
  }

  // Add a comment to a post
  Future<void> addComment(String postId, String commentText, String userID, String role, String username) async {
    final commentId = const Uuid().v4();

    // Fetch the current user's username
    final userSnapshot = await _userService.getUser(userID);
    final username = userSnapshot.data()?['username'] ?? 'Unknown User';
    final role = userSnapshot.data()?['role'] ?? 'Unknown Role';

    await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).set({
      'text': commentText,
      'username': username,
      'userID': userID,
      'role': role,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('posts').doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  // Get comments for a post
  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final document = doc as DocumentSnapshot<Map<String, dynamic>>;
        return Comment.fromDocument(document);
      }).toList();
    });
  }

  // Delete a post and its comments
  Future<void> deletePost(String postId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final commentsRef = postRef.collection('comments');

    // Delete all comments
    final commentsSnapshot = await commentsRef.get();
    final batch = _firestore.batch();
    for (var doc in commentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the post
    batch.delete(postRef);

    await batch.commit();
  }

  // Upload image method
  Future<String> uploadImage(XFile imageFile) async {
    try {
      String fileName = const Uuid().v4();
      Reference ref = FirebaseStorage.instance.ref().child('post_images').child(fileName);

      Uint8List imageBytes;
      String contentType;

      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
        contentType = imageFile.mimeType ?? 'image/jpeg';
      } else {
        io.File file = io.File(imageFile.path);
        imageBytes = await file.readAsBytes();
        contentType = 'image/jpeg';
      }

      UploadTask uploadTask = ref.putData(imageBytes, SettableMetadata(contentType: contentType));
      TaskSnapshot taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }
}

class Post {
  final String id;
  final String title;
  final String details;
  final String authorUsername;
  final String? imageAttached;
  final List<String> likes;
  final int likesCount;
  final int commentsCount;
  final String userID;

  Post({
    required this.id,
    required this.title,
    required this.details,
    required this.authorUsername,
    this.imageAttached,
    required this.likes,
    required this.likesCount,
    required this.commentsCount,
    required this.userID,
  });

  factory Post.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Post(
      id: doc.id,
      title: data['title'] ?? '',
      details: data['details'] ?? '',
      authorUsername: data['authorUsername'] ?? '',
      imageAttached: data['imageAttached'],
      likes: List<String>.from(data['likes'] ?? []),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      userID: data['userID'] ?? '',
    );
  }
}

class Comment {
  final String id;
  final String text;
  final String username;
  final String userID;
  final String role;

  Comment({
    required this.id,
    required this.text,
    required this.username,
    required this.userID,
    required this.role,
  });

  factory Comment.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Comment(
      id: doc.id,
      text: data['text'] ?? '',
      username: data['username'] ?? '',
      userID: data['userID'] ?? '',
      role: data['role'] ?? '',
    );
  }
}
