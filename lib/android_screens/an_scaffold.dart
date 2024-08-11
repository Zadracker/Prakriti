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

class AppScaffold extends StatefulWidget {
  final int currentIndex;
  final int userPoints;
  final String profileImageUrl;

  const AppScaffold({super.key, 
    required this.currentIndex,
    required this.userPoints,
    required this.profileImageUrl,
  });

  @override
  _AppScaffoldState createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  late int _currentIndex;
  late ValueNotifier<int> _pointsNotifier;
  late List<Widget> _children;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _pointsNotifier = ValueNotifier<int>(widget.userPoints);
    _loadUserRole();

    // Initialize _children here
    _children = [
      const EcoNewsPage(),
      const EcoCameraPage(),
      AnTaskPage(pointsNotifier: _pointsNotifier),
      AnQuiz(),
      const LeaderboardPage(),
      const ChatbotPage(),
    ];
  }

  Future<void> _loadUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> userDoc = await UserService().getUser(user.uid);
        setState(() {
          _userRole = userDoc.data()?['role'];
        });
      } catch (e) {
      }
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToPointsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PointsPage(),
      ),
    );
  }

  void _navigateToAnShopPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ShopPage(),
      ),
    );
  }

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
    // Ensure _currentIndex is within bounds
    final validIndex = _currentIndex.clamp(0, _children.length - 1);

    return Scaffold(
      appBar: AppBar(
        leading: SvgPicture.asset(
          'lib/assets/Prakriti_logo.svg',
          height: 40,
          color: Colors.green, // Apply green color to the SVG
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_userRole != UserService.ECO_ADVOCATE) ...[
              IconButton(
                icon: const Icon(Icons.star),
                onPressed: _navigateToPointsPage,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _navigateToAnShopPage,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.eco),
                onPressed: _navigateToAnBankPage,
              ),
            ],
          ],
        ),
        backgroundColor: AppTheme.darkPrimaryColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: AppTheme.darkHeadingColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnSettings(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _children[validIndex], // Use validIndex to avoid range errors
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: validIndex,
        backgroundColor: AppTheme.darkPrimaryColor,
        selectedItemColor: AppTheme.darkAccentColor,
        unselectedItemColor: AppTheme.darkSecondaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Eco News',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Eco Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Eco Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Eco Chat',
          ),
        ],
      ),
    );
  }
}
