import 'package:flutter/material.dart';
import 'package:prakriti/services/leaderboard_service.dart';
import 'package:prakriti/services/user_service.dart'; // Import UserService
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/theme.dart'; // Import your theme

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final UserService _userService = UserService(); // Instantiate UserService
  Future<List<Map<String, dynamic>>>? _topUsersFuture;
  Future<Map<String, dynamic>>? _userStatsFuture;
  bool _isEcoAdvocate = false; // Track if user is an eco-advocate

  @override
  void initState() {
    super.initState();
    _topUsersFuture = _leaderboardService.getTopUsers();
    _userStatsFuture = _leaderboardService.getUserStats();
    _checkUserRole(); // Fetch user role on initialization
  }

  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await _userService.getUser(user.uid);
        final userData = userDoc.data();
        if (userData != null) {
          setState(() {
            _isEcoAdvocate = userData['role'] == 'eco_advocate';
          });
        }
      }
    } catch (e) {
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading top users: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No top users found.'));
                }

                List<Map<String, dynamic>> topUsers = snapshot.data!;

                return ListView.builder(
                  itemCount: topUsers.length,
                  itemBuilder: (context, index) {
                    var user = topUsers[index];

                    // Show both 'member' and 'terra_knight' users
                    if (user['role'] != 'member' && user['role'] != 'terra_knight') {
                      return const SizedBox.shrink(); // Skip non-member and non-terra_knight users
                    }

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.darkAccentColor, // Use darkAccentColor
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#${index + 1}',
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
          Divider(color: Theme.of(context).dividerColor),
          Expanded(
            flex: 1,
            child: FutureBuilder<Map<String, dynamic>>(
              future: _userStatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading user stats: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('User stats not found.'));
                }

                var userStats = snapshot.data!;

                return _isEcoAdvocate
                    ? const SizedBox.shrink() // Hide stats for eco-advocates
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Your Rank: ${userStats['rank'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your Points: ${userStats['points']?.toString() ?? '0'}',
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
