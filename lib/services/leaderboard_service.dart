import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/services/points_service.dart';

class LeaderboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PointsService _pointsService = PointsService();

  // Get top users for the leaderboard
  Future<List<Map<String, dynamic>>> getTopUsers() async {
    try {
      // Fetch users sorted by points
      QuerySnapshot snapshot = await _db.collection('users')
          .orderBy('points', descending: true) // Modify based on your criteria
          .limit(10) // Adjust limit as needed
          .get();

      // Map the documents to a list of user data
      List<Map<String, dynamic>> users = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // Fetch additional details for each user
      for (var user in users) {
        var userId = user['uid'] as String?;
        if (userId != null) {
          // Fetch points
          int points = await _pointsService.getUserPoints(userId);
          user['points'] = points;

          // Profile image URL fetch code has been removed
        }
      }

      return users;
    } catch (e) {
      throw e;
    }
  }

  // Get user stats for the current user
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      // Fetch stats for the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No current user');

      DocumentSnapshot snapshot = await _db.collection('users').doc(user.uid).get();

      // Ensure the data exists and include points
      var userStats = snapshot.data() as Map<String, dynamic>? ?? {};

      // Fetch points for the current user
      int points = await _pointsService.getUserPoints(user.uid);
      userStats['points'] = points;

      // Profile image URL fetch code has been removed

      // Calculate rank
      userStats['rank'] = await _calculateUserRank(user.uid);

      return userStats;
    } catch (e) {
      throw e;
    }
  }

  // Helper method to calculate the rank of a user
  Future<int> _calculateUserRank(String userId) async {
    try {
      QuerySnapshot snapshot = await _db.collection('users')
          .orderBy('points', descending: true)
          .get();

      List<DocumentSnapshot> allUsers = snapshot.docs;

      for (int i = 0; i < allUsers.length; i++) {
        if (allUsers[i].id == userId) {
          return i + 1; // Rank is 1-based
        }
      }

      return -1; // User not found (should not happen)
    } catch (e) {
      throw e;
    }
  }
}
