import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/commons/points.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/services/quiz_completion_service.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import SVG package
import 'package:prakriti/web_screens/web_nav_pages/web_bank.dart';
import 'web_nav_pages/web_news.dart';
import 'web_nav_pages/web_leaderboard.dart';
import 'web_nav_pages/web_chatbot.dart';
import 'web_nav_pages/web_settings.dart';
import 'web_nav_pages/web_scan.dart';
import 'web_nav_pages/web_forum.dart';
import 'web_nav_pages/web_quiz.dart';
import 'web_nav_pages/web_results.dart';
import 'web_nav_pages/web_tasks.dart'; // Import WebTasksPage
import 'web_nav_pages/web_shop.dart'; // Import WebShopPage

class WebScaffold extends StatefulWidget {
  final int initialIndex;

  const WebScaffold({super.key, this.initialIndex = 0}); // Default to News page

  @override
  _WebScaffoldState createState() => _WebScaffoldState();
}

class _WebScaffoldState extends State<WebScaffold> {
  int _selectedIndex = 0; // Default to News page
  bool _isQuizCompleted = false;
  bool _isEcoAdvocate = false;
  final ValueNotifier<int> _pointsNotifier = ValueNotifier<int>(0);
  late List<Widget> _pages; // Declare the pages list

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _getUserProfileImageUrl() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // String? imageUrl = await UserService().getUserProfileImageUrl(user.uid);
      setState(() {
        // _profileImageUrl = imageUrl;
      });
    }
  }

  Future<void> _checkQuizCompletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final quizCompletionStatus = await QuizCompletionService().getQuizResponses(user.uid, DateTime.now());
      setState(() {
        _isQuizCompleted = quizCompletionStatus['completed_status'] ?? false;
      });
    }
  }

  Future<void> _checkIfEcoAdvocate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isEcoAdvocate = await UserService().isEcoAdvocate();
      setState(() {
        _isEcoAdvocate = isEcoAdvocate;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _getUserProfileImageUrl();
    _checkQuizCompletion();
    _checkIfEcoAdvocate();

    // Initialize the pages list here
    _pages = [
      const WebNewsPage(), // 0
      WebForumPage(), // 1
      const WebScanPage(), // 2
      WebTasksPage(pointsNotifier: _pointsNotifier), // 3
      WebChatbotPage(), // 4
      WebLeaderboardPage(), // 5
      const WebQuiz(), // 6
      const WebResultsPage(), // 7
    ];
  }


  @override
  Widget build(BuildContext context) {
    const Color navRailColor = Colors.black87; // Change this to match your app's color scheme
    const Color selectedItemColor = Colors.green; // Color for selected item

    final List<NavigationRailDestination> destinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.article),
        label: Text('News'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.forum),
        label: Text('Forum'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.camera),
        label: Text('Scan'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.list),
        label: Text('Tasks'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.chat),
        label: Text('Chatbot'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.leaderboard),
        label: Text('Leaderboard'),
      ),
      NavigationRailDestination(
        icon: _isQuizCompleted ? const Icon(Icons.quiz) : const Icon(Icons.quiz),
        label: Text(_isQuizCompleted ? 'Results' : 'Quiz'),
      ),
    ];

    final int validIndex = _selectedIndex < destinations.length ? _selectedIndex : destinations.length - 1;
    Widget content = _pages[validIndex];

    if (_isQuizCompleted && _selectedIndex == 6) {
      content = _pages[7];
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              'lib/assets/Prakriti_logo.svg', // Update with your SVG asset path
              height: 30,
              color: Colors.green,
            ),
            if (!_isEcoAdvocate)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.star),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PointsPage()), // Navigate to points page
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ShopPage()), // Navigate to webshop page
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.eco),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WebBankPage()), // Navigate to bank page
                      );
                    },
                  ),
                ],
              ),
            IconButton(
              icon: const Icon(Icons.account_circle_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WebSettings()),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: validIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.selected,
            selectedLabelTextStyle: const TextStyle(color: selectedItemColor), // Set selected label color
            selectedIconTheme: const IconThemeData(color: selectedItemColor), // Set selected icon color
            destinations: destinations,
            backgroundColor: navRailColor, // Set NavigationRail color
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: content,
          ),
        ],
      ),
    );
  }
}
