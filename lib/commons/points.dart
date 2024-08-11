import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/services/points_service.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/services/accessibility_preferences_service.dart'; // Import the service
import 'package:flutter_tts/flutter_tts.dart'; // Import the TTS package if used

class PointsPage extends StatefulWidget {
  const PointsPage({super.key});

  @override
  _PointsPageState createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  final PointsService _pointsService = PointsService();
  final UserService _userService = UserService();
  final AccessibilityPreferencesService _preferencesService = AccessibilityPreferencesService();
  final FlutterTts _flutterTts = FlutterTts(); // Initialize TTS
  
  late Future<int> _pointsFuture;
  late Future<int> _enviroCoinsFuture;
  late Future<int> _currentLevelFuture;
  late Future<int> _pointsToNextLevelFuture;
  late Future<int> _nextLevelEnviroCoinsFuture;
  late Future<bool> _isTerraKnightFuture;
  late Future<Map<String, dynamic>> _userPreferencesFuture;

  String _font = 'OpenSans';
  double _fontSize = 14.0;
  bool _readAloud = false;

  @override
  void initState() {
    super.initState();
    String userId = FirebaseAuth.instance.currentUser!.uid;
    _pointsFuture = _pointsService.getUserPoints(userId);
    _enviroCoinsFuture = _pointsService.getUserEnviroCoins(userId);
    _currentLevelFuture = _pointsService.getUserLevel(userId);
    _pointsToNextLevelFuture = _pointsService.getPointsToNextLevel(userId);
    _nextLevelEnviroCoinsFuture = _pointsService.getNextLevelEnviroCoins(userId);
    _isTerraKnightFuture = _userService.getUserRole(userId).then((role) => role == UserService.TERRA_KNIGHT);
    _userPreferencesFuture = _fetchUserPreferences();
  }

  Future<Map<String, dynamic>> _fetchUserPreferences() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return await _preferencesService.getUserPreferences(userId);
  }

  void _speak(String text) {
    if (_readAloud) {
      _flutterTts.speak(text);
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

        return FutureBuilder(
          future: Future.wait([
            _pointsFuture,
            _enviroCoinsFuture,
            _currentLevelFuture,
            _pointsToNextLevelFuture,
            _nextLevelEnviroCoinsFuture,
            _isTerraKnightFuture
          ]),
          builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No data available'));
            } else {
              int points = snapshot.data![0];
              int enviroCoins = snapshot.data![1];
              int currentLevel = snapshot.data![2];
              int pointsToNextLevel = snapshot.data![3];
              int nextLevelEnviroCoins = snapshot.data![4];
              bool isTerraKnight = snapshot.data![5];

              // Optionally speak the data
              _speak('Points: $points. Enviro-Coins: $enviroCoins. Current Level: $currentLevel. Points to Next Level: $pointsToNextLevel. Enviro-Coins for Next Level: $nextLevelEnviroCoins');

              return Scaffold(
                appBar: AppBar(
                  title: Text('My Points', style: TextStyle(fontFamily: _font, fontSize: _fontSize)),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Icon(Icons.star, color: Colors.yellow, size: _fontSize),
                        title: Text('Points', style: TextStyle(fontSize: _fontSize, fontFamily: _font)),
                        trailing: Text(points.toString(), style: TextStyle(fontSize: _fontSize, fontFamily: _font)),
                      ),
                      ListTile(
                        leading: Icon(Icons.eco, color: Colors.green, size: _fontSize),
                        title: Text('Enviro-Coins', style: TextStyle(fontSize: _fontSize, fontFamily: _font)),
                        trailing: Text(enviroCoins.toString(), style: TextStyle(fontSize: _fontSize, fontFamily: _font)),
                      ),
                      ListTile(
                        leading: Icon(Icons.trending_up, color: Colors.blue, size: _fontSize),
                        title: Text('Current Level', style: TextStyle(fontSize: _fontSize, fontFamily: _font)),
                        trailing: Text(currentLevel.toString(), style: TextStyle(fontSize: _fontSize, fontFamily: _font)),
                      ),
                      ListTile(
                        leading: Icon(Icons.arrow_upward, color: Colors.orange, size: _fontSize),
                        title: Text('Points to Next Level', style: TextStyle(fontSize: _fontSize, fontFamily: _font)),
                        trailing: Text(pointsToNextLevel.toString(), style: TextStyle(fontSize: _fontSize, fontFamily: _font)),
                      ),
                      ListTile(
                        leading: Icon(Icons.monetization_on, color: Colors.purple, size: _fontSize),
                        title: Text('Enviro-Coins for Next Level', style: TextStyle(fontSize: _fontSize, fontFamily: _font)),
                        trailing: Text(nextLevelEnviroCoins.toString(), style: TextStyle(fontSize: _fontSize, fontFamily: _font)),
                      ),
                      if (isTerraKnight) 
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            'As a Terra-Knight, you receive double the Enviro-Coins for reaching new levels!',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: _fontSize, fontFamily: _font),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
