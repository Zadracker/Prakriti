import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/services/points_service.dart';

class LeaderboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PointsService _pointsService = PointsService();

  // Retrieve the top users for the leaderboard
  Future<List<Map<String, dynamic>>> getTopUsers() async {
    try {
      // Query Firestore to get the top 10 users sorted by points in descending order
      QuerySnapshot snapshot = await _db.collection('users')
          .orderBy('points', descending: true) // Sort users by points
          .limit(10) // Limit to the top 10 users
          .get();

      // Convert the query snapshot to a list of user data maps
      List<Map<String, dynamic>> users = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // Fetch and add additional details (e.g., points) for each user
      for (var user in users) {
        var userId = user['uid'] as String?;
        if (userId != null) {
          // Fetch and add points for the user
          int points = await _pointsService.getUserPoints(userId);
          user['points'] = points;

          // Code to fetch profile image URL has been removed for simplicity
        }
      }

      return users;
    } catch (e) {
      // Handle and rethrow exceptions
      throw e;
    }
  }

  // Retrieve stats for the current logged-in user
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      // Get the currently authenticated user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No current user'); // Ensure a user is logged in

      // Fetch the current user's document from Firestore
      DocumentSnapshot snapshot = await _db.collection('users').doc(user.uid).get();

      // Get the user data or initialize an empty map if the document doesn't exist
      var userStats = snapshot.data() as Map<String, dynamic>? ?? {};

      // Fetch and add points for the current user
      int points = await _pointsService.getUserPoints(user.uid);
      userStats['points'] = points;

      // Code to fetch profile image URL has been removed for simplicity

      // Calculate the user's rank and add it to the stats
      userStats['rank'] = await _calculateUserRank(user.uid);

      return userStats;
    } catch (e) {
      // Handle and rethrow exceptions
      throw e;
    }
  }

  // Calculate the rank of a user based on their points
  Future<int> _calculateUserRank(String userId) async {
    try {
      // Query Firestore to get all users sorted by points in descending order
      QuerySnapshot snapshot = await _db.collection('users')
          .orderBy('points', descending: true)
          .get();

      // Get the list of all user documents
      List<DocumentSnapshot> allUsers = snapshot.docs;

      // Determine the rank of the specified user
      for (int i = 0; i < allUsers.length; i++) {
        if (allUsers[i].id == userId) {
          return i + 1; // Return the rank (1-based index)
        }
      }

      return -1; // User not found (should not happen)
    } catch (e) {
      // Handle and rethrow exceptions
      throw e;
    }
  }
}
