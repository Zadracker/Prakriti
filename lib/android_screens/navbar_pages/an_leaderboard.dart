import 'package:flutter/material.dart';
import 'package:prakriti/services/leaderboard_service.dart';
import 'package:prakriti/services/user_service.dart'; // Import UserService for user-related operations
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/theme.dart'; // Import custom theme for consistent styling

/// The LeaderboardPage displays the top users in the leaderboard and the current user's statistics.
/// It also hides certain elements based on user role (eco-advocate or not).
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final LeaderboardService _leaderboardService = LeaderboardService(); // Service to fetch leaderboard data
  final UserService _userService = UserService(); // Service to fetch user data
  Future<List<Map<String, dynamic>>>? _topUsersFuture; // Future for top users data
  Future<Map<String, dynamic>>? _userStatsFuture; // Future for current user's stats
  bool _isEcoAdvocate = false; // Track if the current user is an eco-advocate

  @override
  void initState() {
    super.initState();
    _topUsersFuture = _leaderboardService.getTopUsers(); // Initialize top users data
    _userStatsFuture = _leaderboardService.getUserStats(); // Initialize current user's stats
    _checkUserRole(); // Determine the current user's role
  }

  /// Checks if the current user is an eco-advocate and updates the state accordingly.
  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser; // Get the current user from FirebaseAuth
      if (user != null) {
        final userDoc = await _userService.getUser(user.uid); // Fetch user data from UserService
        final userData = userDoc.data();
        if (userData != null) {
          setState(() {
            _isEcoAdvocate = userData['role'] == 'eco_advocate'; // Update state based on user role
          });
        }
      }
    } catch (e) {
      // Handle any errors that occur while fetching user role
      print('Error checking user role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _topUsersFuture,
              builder: (context, snapshot) {
                // Handle the various states of the Future for top users
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator()); // Show loading indicator while waiting
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading top users: ${snapshot.error}')); // Show error message if an error occurs
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No top users found.')); // Show message if no data is available
                }

                List<Map<String, dynamic>> topUsers = snapshot.data!; // Extract top users data

                return ListView.builder(
                  itemCount: topUsers.length,
                  itemBuilder: (context, index) {
                    var user = topUsers[index];

                    // Show only 'member' and 'terra_knight' users
                    if (user['role'] != 'member' && user['role'] != 'terra_knight') {
                      return const SizedBox.shrink(); // Skip non-member and non-terra_knight users
                    }

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.darkAccentColor, // Use accent color for background
                          shape: BoxShape.circle, // Circular shape for leading icon
                        ),
                        child: Text(
                          '#${index + 1}', // Display ranking number
                          style: const TextStyle(
                            color: AppTheme.darkPrimaryColor, // Use primary color for text
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(user['username'] ?? 'No Username', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
                          Text('${user['points']?.toString() ?? '0'} points', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(color: Theme.of(context).dividerColor), // Divider line between leaderboard and user stats
          Expanded(
            flex: 1,
            child: FutureBuilder<Map<String, dynamic>>(
              future: _userStatsFuture,
              builder: (context, snapshot) {
                // Handle the various states of the Future for user stats
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator()); // Show loading indicator while waiting
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading user stats: ${snapshot.error}')); // Show error message if an error occurs
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('User stats not found.')); // Show message if no data is available
                }

                var userStats = snapshot.data!; // Extract user stats data

                // Hide user stats for eco-advocates
                return _isEcoAdvocate
                    ? const SizedBox.shrink()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Your Rank: ${userStats['rank'] ?? 'N/A'}', // Display current user's rank
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your Points: ${userStats['points']?.toString() ?? '0'}', // Display current user's points
                            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
