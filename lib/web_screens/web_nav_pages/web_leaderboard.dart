import 'package:flutter/material.dart';
import 'package:prakriti/services/leaderboard_service.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/services/accessibility_preferences_service.dart'; // Import the service
import 'package:prakriti/theme.dart'; // Ensure you import your theme

class WebLeaderboardPage extends StatefulWidget {
  const WebLeaderboardPage({super.key});

  @override
  _WebLeaderboardPageState createState() => _WebLeaderboardPageState();
}

class _WebLeaderboardPageState extends State<WebLeaderboardPage> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final UserService _userService = UserService();
  final AccessibilityPreferencesService _preferencesService = AccessibilityPreferencesService();
  
  Future<List<Map<String, dynamic>>>? _topUsersFuture;
  Future<Map<String, dynamic>>? _userStatsFuture;
  Future<bool>? _isEcoAdvocateFuture;
  Future<Map<String, dynamic>>? _userPreferencesFuture;

  String _font = 'OpenSans';
  double _fontSize = 14.0;
  bool _readAloud = false;

  @override
  void initState() {
    super.initState();
    _topUsersFuture = _leaderboardService.getTopUsers();
    _userStatsFuture = _leaderboardService.getUserStats();
    _isEcoAdvocateFuture = _userService.isEcoAdvocate();
    _userPreferencesFuture = _fetchUserPreferences();
  }

  Future<Map<String, dynamic>> _fetchUserPreferences() async {
    const userId = 'your_user_id'; // Replace with the actual user ID
    return await _preferencesService.getUserPreferences(userId);
  }

  void _speak(String text) {
    if (_readAloud) {
      // Implement text-to-speech functionality here
      // For example, using the flutter_tts package:
      // FlutterTts flutterTts = FlutterTts();
      // flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userPreferencesFuture,
      builder: (context, preferencesSnapshot) {
        if (preferencesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (preferencesSnapshot.hasError) {
          return Center(child: Text('Error loading preferences: ${preferencesSnapshot.error}'));
        }
        if (!preferencesSnapshot.hasData) {
          return const Center(child: Text('No preferences found.'));
        }

        final preferences = preferencesSnapshot.data!;
        _font = preferences['font'] ?? 'OpenSans';
        _fontSize = (preferences['fontSize'] ?? 1) * 14.0; // Adjust base font size as needed
        _readAloud = preferences['readAloud'] ?? false;

        return FutureBuilder<bool>(
          future: _isEcoAdvocateFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading user role: ${snapshot.error}'));
            }
            bool isEcoAdvocate = snapshot.data ?? false;

            return Scaffold(
              body: Row(
                children: [
                  Expanded(
                    flex: isEcoAdvocate ? 1 : 2,
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

                            if (user['role'] != 'member' && user['role'] != 'terra_knight') {
                              return const SizedBox.shrink(); // Skip users who are not member or terra_knight
                            }

                            return ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.darkAccentColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '#${index + 1}',
                                      style: TextStyle(
                                        color: AppTheme.darkPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: _fontSize,
                                        fontFamily: _font,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(user['username'] ?? 'No Username', style: TextStyle(fontSize: _fontSize, fontFamily: _font, color: Theme.of(context).textTheme.bodyLarge?.color))),
                                  Text('${user['points']?.toString() ?? '0'} points', style: TextStyle(fontSize: _fontSize, fontFamily: _font, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                ],
                              ),
                              onTap: () {
                                // Optionally add TTS feedback for the tapped user
                                _speak('${user['username']} has ${user['points']} points');
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (!isEcoAdvocate) ...[
                    VerticalDivider(color: Theme.of(context).dividerColor),
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

                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Rank: ${userStats['rank']}',
                                  style: TextStyle(fontSize: _fontSize + 6, fontWeight: FontWeight.bold, fontFamily: _font, color: Theme.of(context).textTheme.bodyLarge?.color),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your Points: ${userStats['points']?.toString() ?? '0'}',
                                  style: TextStyle(fontSize: _fontSize + 2, fontFamily: _font, color: Theme.of(context).textTheme.bodyLarge?.color),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }
}
