import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:prakriti/web_screens/web_tasks_dir/web_create_special_task.dart';
import 'package:prakriti/web_screens/web_tasks_dir/web_task_submit_page.dart';
import 'package:prakriti/services/daily_task_service.dart';
import 'package:prakriti/services/sp_task_creation_service.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/services/points_service.dart';
import 'package:prakriti/services/accessibility_preferences_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebTasksPage extends StatefulWidget {
  final ValueNotifier<int> pointsNotifier;

  const WebTasksPage({super.key, required this.pointsNotifier});

  @override
  _WebTasksPageState createState() => _WebTasksPageState();
}

class _WebTasksPageState extends State<WebTasksPage> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final SpTaskCreationService _taskCreationService = SpTaskCreationService();
  final DailyTaskService _dailyTaskService = DailyTaskService();
  final PointsService _pointsService = PointsService();
  final AccessibilityPreferencesService _accessibilityService = AccessibilityPreferencesService();

  User? _currentUser;
  TabController? _tabController;
  String _fontSize = '1X'; // Default font size
  String _fontType = 'Default'; // Default font type
  bool _readAloud = false; // Default text-to-speech setting

  final FlutterTts _flutterTts = FlutterTts(); // Text-to-Speech instance

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _dailyTaskService.generateDailyTasks();
    _loadAccessibilityPreferences();
  }

  Future<void> _loadAccessibilityPreferences() async {
    final preferences = await _accessibilityService.getUserPreferences(FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      _fontSize = preferences['fontSize'] ?? '1X';
      _fontType = preferences['font'] ?? 'Default';
      _readAloud = preferences['readAloud'] ?? false;
    });
    // Update TabController after preferences are loaded
    _updateTabController();
    }

  void _updateTabController() {
    if (_currentUser != null) {
      _userService.isEcoAdvocate().then((isEcoAdvocate) {
        setState(() {
          _tabController = TabController(length: isEcoAdvocate ? 1 : 2, vsync: this);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: _fontSize == '2X' ? 20 : (_fontSize == '3X' ? 24 : 16),
      fontFamily: _fontType == 'OpenDyslexic' ? 'OpenDyslexic' : 'Default',
    );

    return FutureBuilder<bool>(
      future: _userService.isEcoAdvocate(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isEcoAdvocate = snapshot.data!;
        if (_tabController == null || _tabController!.length != (isEcoAdvocate ? 1 : 2)) {
          _tabController = TabController(length: isEcoAdvocate ? 1 : 2, vsync: this);
        }

        return Scaffold(
          body: Column(
            children: [
              Container(
                color: Colors.black,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.green, // Selected tab text color
                  unselectedLabelColor: Colors.white, // Unselected tab text color
                  tabs: [
                    if (!isEcoAdvocate) const Tab(text: 'Daily Tasks'),
                    const Tab(text: 'Special Tasks'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    if (!isEcoAdvocate) _buildDailyTasks(textStyle),
                    _buildTaskList(isEcoAdvocate, textStyle),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: isEcoAdvocate
              ? FloatingActionButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WebCreateSpecialTaskPage()),
                  ),
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildDailyTasks(TextStyle textStyle) {
    return StreamBuilder<QuerySnapshot>(
      stream: _dailyTaskService.getDailyTasksStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading daily tasks.', style: textStyle));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No daily tasks found.', style: textStyle));
        }

        var tasks = snapshot.data!.docs;
        var filteredTasks = tasks.where((task) {
          var taskData = task.data() as Map<String, dynamic>;
          var completedUsers = List<String>.from(taskData['completed_by'] ?? []);
          return !completedUsers.contains(_currentUser?.uid);
        }).toList();

        if (filteredTasks.isEmpty) {
          return Center(child: Text('No daily tasks available.', style: textStyle));
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            var task = filteredTasks[index];
            var taskData = task.data() as Map<String, dynamic>;
            taskData['taskId'] = task.id;

            return GestureDetector(
              onDoubleTap: () => _completeTask(taskData, task.id),
              onTap: () => _speakText(taskData['task']),
              child: ListTile(
                title: Text(taskData['task'], style: textStyle),
                trailing: Text('${taskData['points']} points', style: textStyle),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTaskList(bool isEcoAdvocate, TextStyle textStyle) {
    return StreamBuilder<QuerySnapshot>(
      stream: _taskCreationService.getTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No tasks found.', style: textStyle));
        }

        var tasks = snapshot.data!.docs;
        var filteredTasks = tasks.where((task) {
          var taskData = task.data() as Map<String, dynamic>;
          var completedUsers = List<String>.from(taskData['completed_by'] ?? []);
          var creatorID = taskData['creator_ID'];

          if (isEcoAdvocate) {
            return creatorID == _currentUser?.uid;
          } else {
            return !completedUsers.contains(_currentUser?.uid);
          }
        }).toList();

        if (filteredTasks.isEmpty) {
          return Center(child: Text('No tasks available.', style: textStyle));
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            var task = filteredTasks[index];
            var taskData = task.data() as Map<String, dynamic>;
            taskData['taskId'] = task.id;

            return ListTile(
              title: Text(taskData['title'], style: textStyle),
              trailing: isEcoAdvocate
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () => _deleteTask(task.id),
                    )
                  : Text('${taskData['points']} points', style: textStyle),
              onTap: () {
                if (!isEcoAdvocate) {
                  _speakText(taskData['title']);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WebTaskSubmitPage(task: taskData),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Future<void> _completeTask(Map<String, dynamic> taskData, String taskId) async {
    if (_currentUser == null) {
      return;
    }

    await _dailyTaskService.markTaskAsComplete(taskId);
    final points = taskData['points'] as int;
    await _pointsService.awardPoints(_currentUser!.uid, points.toString());
    widget.pointsNotifier.value += points;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Good job! Points added.', style: TextStyle(
        fontSize: _fontSize == '2X' ? 20 : (_fontSize == '3X' ? 24 : 16),
        fontFamily: _fontType == 'OpenDyslexic' ? 'OpenDyslexic' : 'Default',
      ))),
    );
  }

  Future<void> _deleteTask(String taskId) async {
    await _taskCreationService.deleteTask(taskId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task deleted.', style: TextStyle(
        fontSize: _fontSize == '2X' ? 20 : (_fontSize == '3X' ? 24 : 16),
        fontFamily: _fontType == 'OpenDyslexic' ? 'OpenDyslexic' : 'Default',
      ))),
    );
  }

  Future<void> _speakText(String text) async {
    if (_readAloud) {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.speak(text);
    }
  }
}
