import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User roles
  static const String MEMBER = 'member';
  static const String TERRA_KNIGHT = 'terra_knight';
  static const String ECO_ADVOCATE = 'eco_advocate';
  static const String ADMIN = 'admin';

  User? currentUser() {
    return _auth.currentUser;
  }

  // Get user details from Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) async {
    try {
      return await _db.collection('users').doc(uid).get();
    } catch (e) {
      rethrow;
    }
  }

  // Check if the current user is an Eco Advocate
  Future<bool> isEcoAdvocate() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot<Map<String, dynamic>> snapshot = await _db.collection('users').doc(user.uid).get();
      return snapshot.exists && snapshot.data()?['role'] == ECO_ADVOCATE;
    } catch (e) {
      rethrow;
    }
  }

  // Add application to Firestore and upload document to Firebase Storage
  Future<void> addEcoAdvocateApplication(
    String uid,
    String email,
    String username,
    String applicationText,
    String documentUrl,
  ) async {
    try {
      await _db.collection('eco_advocate_applications').add({
        'uid': uid,
        'email': email,
        'username': username,
        'application_text': applicationText,
        'document_url': documentUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get all applications for Eco Advocates
  Stream<QuerySnapshot<Map<String, dynamic>>> getEcoAdvocateApplications() {
    try {
      return _db.collection('eco_advocate_applications').orderBy('timestamp', descending: true).snapshots();
    } catch (e) {
      rethrow;
    }
  }

  // Accept an application and update user role
  Future<void> acceptApplication(String appId, String uid) async {
    try {
      await _db.collection('eco_advocate_applications').doc(appId).update({'status': 'approved'});
      await _db.collection('users').doc(uid).update({'role': ECO_ADVOCATE});
    } catch (e) {
      rethrow;
    }
  }

  // Reject an application
  Future<void> rejectApplication(String appId) async {
    try {
      await _db.collection('eco_advocate_applications').doc(appId).update({'status': 'rejected'});
    } catch (e) {
      rethrow;
    }
  }

  // Upload document to Firebase Storage and get the download URL
  Future<String> uploadDocument(String uid, Uint8List fileBytes) async {
    try {
      final ref = _storage.ref().child('eco_advocate_applications').child('$uid/${DateTime.now().toIso8601String()}.pdf');
      final uploadTask = ref.putData(fileBytes, SettableMetadata(contentType: 'application/pdf'));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Create user profile
  Future<void> createUserProfile(String userId, String username, String email) async {
    try {
      await _db.collection('users').doc(userId).set({
        'username': username,
        'email': email,
        'role': MEMBER, // default role
        'enviroCoins': 0, // Initialize with default value
      });
    } catch (e) {
      rethrow;
    }
  }

  // Download the application document
  Future<void> downloadApplicationDocument(String url) async {
    try {
      // Example implementation using http package
      // final response = await http.get(Uri.parse(url));
      // if (response.statusCode == 200) {
      //   // Save file to local storage
      // } else {
      //   throw Exception('Failed to download document');
      // }
    } catch (e) {
      rethrow;
    }
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get user username
  Future<String?> getUserUsername(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['username'] as String?;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Check if user can upload custom profile image
  Future<bool> canUploadProfileImage(String uid) async {
    String? role = await getUserRole(uid);
    return role == ECO_ADVOCATE;
  }

  // Check if user can create forum posts
  Future<bool> canCreateForumPosts(String uid) async {
    String? role = await getUserRole(uid);
    return role == ECO_ADVOCATE;
  }

  // Upload profile image for Eco Advocates and update Firestore
  Future<String> uploadEcoAdvocateProfileImage(String uid, dynamic image) async {
    try {
      if (await canUploadProfileImage(uid)) {
        final ref = _storage.ref().child('profile_images').child('$uid/${DateTime.now().toIso8601String()}.jpg');
        final uploadTask = kIsWeb
            ? ref.putData(image as Uint8List, SettableMetadata(contentType: 'image/jpeg'))
            : ref.putFile(image as io.File);
        final snapshot = await uploadTask;
        final profileImageUrl = await snapshot.ref.getDownloadURL();

        await _db.collection('users').doc(uid).update({
          'profileImageUrl': profileImageUrl,
        });

        return profileImageUrl; // Return the URL after successful upload
      } else {
        throw Exception('User does not have permission to upload profile images.');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile image URL
  Future<String?> getUserProfileImageUrl(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['profileImageUrl'] as String?;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update profile image URL in Firestore
  Future<void> updateProfileImageUrl(String uid, String profileImageUrl) async {
    try {
      await _db.collection('users').doc(uid).update({
        'profileImageUrl': profileImageUrl,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user Enviro-Coins
  Future<int> getUserEnviroCoins(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['enviroCoins'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      rethrow;
    }
  }

  // Method to redeem a code
  Future<void> redeemCode(String code) async {
    try {
      // Get codes from environment variables
      String adminCode = dotenv.env['ADMIN_CODE'] ?? '';
      String ecoAdvocateCode = dotenv.env['ECO_ADVOCATE_CODE'] ?? '';
      String terraKnightCode = dotenv.env['TERRA_KNIGHT_CODE'] ?? '';

      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in.');
      }

      // Get user document
      DocumentReference<Map<String, dynamic>> userRef = _db.collection('users').doc(user.uid);

      if (code == adminCode) {
        // Update user role to Admin
        await userRef.update({'role': ADMIN});
      } else if (code == ecoAdvocateCode) {
        // Update user role to Eco Advocate
        await userRef.update({'role': ECO_ADVOCATE});
      } else if (code == terraKnightCode) {
        // Update user role to Terra Knight
        await userRef.update({'role': TERRA_KNIGHT});
      } else {
        throw Exception('Invalid code provided.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEnviroCoins(String uid, int amount) async {
    try {
      await _db.collection('users').doc(uid).update({
        'enviroCoins': amount,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Method to get Terra-Knight users along with member users
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getUsersWithRoles() async {
    try {
      final memberDocs = await _db
          .collection('users')
          .where('role', whereIn: [MEMBER, TERRA_KNIGHT])
          .get();

      return memberDocs.docs;
    } catch (e) {
      rethrow;
    }
  }
}
