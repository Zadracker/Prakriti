import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:prakriti/android_screens/navbar_pages/an_camera.dart';
import 'package:prakriti/android_screens/navbar_pages/an_chatbot.dart';
import 'package:prakriti/android_screens/navbar_pages/an_leaderboard.dart';
import 'package:prakriti/android_screens/navbar_pages/an_news.dart';
import 'package:prakriti/android_screens/navbar_pages/an_quiz.dart';
import 'package:prakriti/android_screens/navbar_pages/an_settings.dart';
import 'package:prakriti/android_screens/navbar_pages/an_shop.dart'; // Import AnShopPage
import 'package:prakriti/android_screens/navbar_pages/an_bank.dart'; // Import AnBankPage
import 'package:prakriti/android_screens/navbar_pages/an_tasks.dart';
import 'package:prakriti/commons/points.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/theme.dart';

// Main widget for the application scaffold
class AppScaffold extends StatefulWidget {
  final int currentIndex;
  final int userPoints;
  final String profileImageUrl;

  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.userPoints,
    required this.profileImageUrl,
  });

  @override
  _AppScaffoldState createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  late int _currentIndex; // Track the currently selected tab
  late ValueNotifier<int> _pointsNotifier; // Notifier to update points in real-time
  late List<Widget> _children; // List of child widgets for each tab
  String? _userRole; // Variable to store the user role

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex; // Initialize currentIndex from widget
    _pointsNotifier = ValueNotifier<int>(widget.userPoints); // Initialize pointsNotifier
    _loadUserRole(); // Load user role from the server

    // Initialize the list of child widgets for each tab
    _children = [
      const EcoNewsPage(), // Page for eco news
      const EcoCameraPage(), // Page for eco camera
      AnTaskPage(pointsNotifier: _pointsNotifier), // Page for tasks, using pointsNotifier
      AnQuiz(), // Page for quizzes
      const LeaderboardPage(), // Page for leaderboard
      const ChatbotPage(), // Page for chatbot
    ];
  }

  // Fetches the user's role from Firestore
  Future<void> _loadUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch user document from Firestore
        DocumentSnapshot<Map<String, dynamic>> userDoc = await UserService().getUser(user.uid);
        setState(() {
          _userRole = userDoc.data()?['role']; // Set user role in state
        });
      } catch (e) {
        // Handle errors (e.g., user document not found)
      }
    }
  }

  // Handles tab changes in the BottomNavigationBar
  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index; // Update the currentIndex state
    });
  }

  // Navigates to the PointsPage
  void _navigateToPointsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PointsPage(),
      ),
    );
  }

  // Navigates to the ShopPage
  void _navigateToAnShopPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ShopPage(),
      ),
    );
  }

  // Navigates to the AnBankPage
  void _navigateToAnBankPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnBankPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure _currentIndex is within valid bounds to prevent errors
    final validIndex = _currentIndex.clamp(0, _children.length - 1);

    return Scaffold(
      appBar: AppBar(
        leading: SvgPicture.asset(
          'lib/assets/Prakriti_logo.svg',
          height: 40,
          color: Colors.green, // Apply green color to the SVG logo
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show these buttons only if the user role is not ECO_ADVOCATE
            if (_userRole != UserService.ECO_ADVOCATE) ...[
              IconButton(
                icon: const Icon(Icons.star),
                onPressed: _navigateToPointsPage, // Navigate to Points Page
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _navigateToAnShopPage, // Navigate to Shop Page
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.eco),
                onPressed: _navigateToAnBankPage, // Navigate to Bank Page
              ),
            ],
          ],
        ),
        backgroundColor: AppTheme.darkPrimaryColor, // Set AppBar background color
        automaticallyImplyLeading: false, // Disable the default leading back button
        actions: [
          // Action button for settings
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: AppTheme.darkHeadingColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnSettings(), // Navigate to Settings Page
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _children[validIndex], // Display the current tab page
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped, // Handle tab taps
        currentIndex: validIndex, // Set the current tab index
        backgroundColor: AppTheme.darkPrimaryColor, // BottomNavigationBar background color
        selectedItemColor: AppTheme.darkAccentColor, // Color for selected item
        unselectedItemColor: AppTheme.darkSecondaryColor, // Color for unselected items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Eco News', // Tab for Eco News
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Eco Camera', // Tab for Eco Camera
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Eco Tasks', // Tab for Eco Tasks
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Quiz', // Tab for Quiz
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard', // Tab for Leaderboard
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Eco Chat', // Tab for Eco Chat
          ),
        ],
      ),
    );
  }
}
