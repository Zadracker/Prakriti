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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance for database operations
  final FirebaseAuth _auth = FirebaseAuth.instance; // Auth instance for user authentication
  final UserService _userService = UserService(); // Service for user-related operations

  // Create a new post
  Future<void> createPost({
    required String title,
    required String details,
    String? imageUrl,
    required String currentUsername,
  }) async {
    final String userID = _auth.currentUser?.uid ?? ''; // Get current user ID

    // Fetch the current user's username from UserService
    final userSnapshot = await _userService.getUser(userID);
    final currentUsername = userSnapshot.data()?['username'] ?? 'Unknown User';

    // Create a new post document in Firestore
    await _firestore.collection('posts').add({
      'title': title, // Post title
      'details': details, // Post details
      'imageAttached': imageUrl, // URL of the attached image, if any
      'timestamp': FieldValue.serverTimestamp(), // Timestamp for sorting posts by date
      'authorUsername': currentUsername, // Username of the post author
      'userID': userID, // ID of the user who created the post
      'likes': [], // List of user IDs who liked the post
      'commentsCount': 0, // Initial count of comments
      'likesCount': 0, // Initial count of likes
    });
  }

  // Get all posts with optional filter
  Stream<List<Post>> getPosts({String? filter}) {
    Query query = _firestore.collection('posts'); // Reference to the posts collection

    // Apply filter if specified
    if (filter != null) {
      switch (filter) {
        case 'Most Liked':
          query = query.orderBy('likesCount', descending: true); // Order by likes count in descending order
          break;
        case 'Most Commented':
          query = query.orderBy('commentsCount', descending: true); // Order by comments count in descending order
          break;
        default: // Most Recent
          query = query.orderBy('timestamp', descending: true); // Order by timestamp in descending order
          break;
      }
    }

    // Listen to snapshots of the query and convert to List<Post>
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final document = doc as DocumentSnapshot<Map<String, dynamic>>;
        return Post.fromDocument(document); // Convert document to Post model
      }).toList();
    });
  }

  // Get a specific post by ID as a Stream
  Stream<Post> getPostStream(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Post not found'); // Handle case where post does not exist
      }
      final document = snapshot;
      return Post.fromDocument(document); // Convert document to Post model
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
          likes.add(userID); // Add userID to likes list
          transaction.update(postDoc, {'likes': likes});
          transaction.update(postDoc, {'likesCount': FieldValue.increment(1)}); // Increment likes count
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
          likes.remove(userID); // Remove userID from likes list
          transaction.update(postDoc, {'likes': likes});
          transaction.update(postDoc, {'likesCount': FieldValue.increment(-1)}); // Decrement likes count
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
      return likes.contains(userID); // Return true if userID is in likes list
    }
    return false;
  }

  // Add a comment to a post
  Future<void> addComment(String postId, String commentText, String userID, String role, String username) async {
    final commentId = const Uuid().v4(); // Generate a unique ID for the comment

    // Fetch the current user's username and role from UserService
    final userSnapshot = await _userService.getUser(userID);
    final username = userSnapshot.data()?['username'] ?? 'Unknown User';
    final role = userSnapshot.data()?['role'] ?? 'Unknown Role';

    // Add comment document to Firestore
    await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).set({
      'text': commentText, // Comment text
      'username': username, // Username of the commenter
      'userID': userID, // ID of the user who commented
      'role': role, // Role of the user who commented
      'timestamp': FieldValue.serverTimestamp(), // Timestamp for sorting comments by date
    });
    // Increment comments count for the post
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
        .orderBy('timestamp', descending: true) // Order comments by timestamp in descending order
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final document = doc as DocumentSnapshot<Map<String, dynamic>>;
        return Comment.fromDocument(document); // Convert document to Comment model
      }).toList();
    });
  }

  // Delete a post and its comments
  Future<void> deletePost(String postId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final commentsRef = postRef.collection('comments');

    // Delete all comments first
    final commentsSnapshot = await commentsRef.get();
    final batch = _firestore.batch();
    for (var doc in commentsSnapshot.docs) {
      batch.delete(doc.reference); // Add delete operation for each comment
    }

    // Delete the post itself
    batch.delete(postRef);

    await batch.commit(); // Commit the batch delete operations
  }

  // Upload an image
  Future<String> uploadImage(XFile imageFile) async {
    try {
      String fileName = const Uuid().v4(); // Generate a unique file name
      Reference ref = FirebaseStorage.instance.ref().child('post_images').child(fileName); // Reference to Firebase Storage

      Uint8List imageBytes;
      String contentType;

      // Handle image upload differently for web and non-web platforms
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes(); // Read image bytes for web
        contentType = imageFile.mimeType ?? 'image/jpeg'; // Use MIME type provided by image picker
      } else {
        io.File file = io.File(imageFile.path); // Handle image file on non-web platforms
        imageBytes = await file.readAsBytes();
        contentType = 'image/jpeg'; // Default MIME type
      }

      // Upload image data to Firebase Storage
      UploadTask uploadTask = ref.putData(imageBytes, SettableMetadata(contentType: contentType));
      TaskSnapshot taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL(); // Get the download URL of the uploaded image
      return downloadUrl; // Return the download URL
    } catch (e) {
      throw Exception('Image upload failed: $e'); // Handle and throw exceptions
    }
  }
}

// Model class for Post
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

  // Convert Firestore document to Post model
  factory Post.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Post(
      id: doc.id,
      title: data['title'] ?? '', // Post title
      details: data['details'] ?? '', // Post details
      authorUsername: data['authorUsername'] ?? '', // Username of the post author
      imageAttached: data['imageAttached'], // URL of the attached image
      likes: List<String>.from(data['likes'] ?? []), // List of user IDs who liked the post
      likesCount: data['likesCount'] ?? 0, // Number of likes
      commentsCount: data['commentsCount'] ?? 0, // Number of comments
      userID: data['userID'] ?? '', // ID of the user who created the post
    );
  }
}

// Model class for Comment
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

  // Convert Firestore document to Comment model
  factory Comment.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Comment(
      id: doc.id,
      text: data['text'] ?? '', // Comment text
      username: data['username'] ?? '', // Username of the commenter
      userID: data['userID'] ?? '', // ID of the user who commented
      role: data['role'] ?? '', // Role of the user who commented
    );
  }
}
