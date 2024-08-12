import 'package:flutter/material.dart';
import 'package:prakriti/android_screens/an_tasks_dir/an_create_special_task.dart';
import 'package:prakriti/android_screens/an_tasks_dir/an_task_submit_page.dart';
import 'package:prakriti/services/daily_task_service.dart';
import 'package:prakriti/services/sp_task_creation_service.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/services/points_service.dart'; // Import PointsService
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnTaskPage extends StatefulWidget {
  final ValueNotifier<int> pointsNotifier; // Add notifier for points

  const AnTaskPage({super.key, required this.pointsNotifier});

  @override
  _AnTaskPageState createState() => _AnTaskPageState();
}

class _AnTaskPageState extends State<AnTaskPage> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final SpTaskCreationService _taskCreationService = SpTaskCreationService();
  final DailyTaskService _dailyTaskService = DailyTaskService();
  final PointsService _pointsService = PointsService(); // Instantiate PointsService
  User? _currentUser;
  late TabController _tabController;
  bool _showBanner = true; // Control banner visibility

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _tabController = TabController(length: 2, vsync: this);
    _dailyTaskService.generateDailyTasks(); // Generate daily tasks
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _userService.isEcoAdvocate(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isEcoAdvocate = snapshot.data!;

        return Scaffold(
          body: Column(
            children: [
              // Display removable banner if _showBanner is true
              if (_showBanner)
                Container(
                  color: Colors.green,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Double tap to mark daily task as complete',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _showBanner = false; // Hide banner when close button is pressed
                          });
                        },
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: isEcoAdvocate
                    ? _buildTaskList(context, isEcoAdvocate)
                    : Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(text: 'Daily Tasks'),
                              Tab(text: 'Special Tasks'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildDailyTasks(context),
                                _buildTaskList(context, isEcoAdvocate),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          floatingActionButton: isEcoAdvocate
              ? FloatingActionButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnCreateSpecialTaskPage(),
                    ),
                  ),
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildDailyTasks(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _dailyTaskService.getDailyTasksStream(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading daily tasks.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No daily tasks found.'));
        }

        var tasks = snapshot.data!.docs;

        var filteredTasks = tasks.where((task) {
          var taskData = task.data() as Map<String, dynamic>;
          var completedUsers = List<String>.from(taskData['completed_by'] ?? []);
          
          // Filter tasks for members to show tasks they haven't completed yet
          return !completedUsers.contains(_currentUser?.uid);
        }).toList();

        if (filteredTasks.isEmpty) {
          return const Center(child: Text('No daily tasks available.'));
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            var task = filteredTasks[index];
            var taskData = task.data() as Map<String, dynamic>;
            taskData['taskId'] = task.id; // Add taskId to taskData

            return GestureDetector(
              onDoubleTap: () async {
                if (_currentUser == null) {
                  return;
                }

                try {
                  // Mark task as complete
                  await _dailyTaskService.markTaskAsComplete(task.id);

                  // Award points to the user
                  final points = taskData['points'] as int; // Use the points variable here
                  await _pointsService.awardPoints(_currentUser!.uid, points.toString());

                  // Notify the parent widget to refresh points
                  widget.pointsNotifier.value += points;

                  // Display success message only in Special Tasks
                } catch (error) {
                  // Display error message only in Special Tasks
                }
              },
              child: ListTile(
                title: Text(taskData['task']),
                subtitle: Text('${taskData['points']} points'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTaskList(BuildContext context, bool isEcoAdvocate) {
    return StreamBuilder<QuerySnapshot>(
      stream: _taskCreationService.getTasks(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No tasks found.'));
        }

        var tasks = snapshot.data!.docs;
        var filteredTasks = tasks.where((task) {
          var taskData = task.data() as Map<String, dynamic>;
          var completedUsers = List<String>.from(taskData['completed_by'] ?? []);
          var creatorID = taskData['creator_ID'];

          if (isEcoAdvocate) {
            // Filter tasks for eco-advocates to only show tasks they created
            return creatorID == _currentUser?.uid;
          } else {
            // Filter tasks for members to show tasks they haven't completed yet
            return !completedUsers.contains(_currentUser?.uid);
          }
        }).toList();

        if (filteredTasks.isEmpty) {
          return const Center(child: Text('No tasks available.'));
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            var task = filteredTasks[index];
            var taskData = task.data() as Map<String, dynamic>;
            taskData['taskId'] = task.id; // Add taskId to taskData

            return ListTile(
              title: Text(taskData['title']),
              subtitle: Text('${taskData['points']} points'),
              trailing: isEcoAdvocate
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTask(context, task.id),
                    )
                  : null,
              onTap: () {
                if (!isEcoAdvocate) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnTaskSubmitPage(task: taskData),
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

  Future<void> _deleteTask(BuildContext context, String taskId) async {
    try {
      await _taskCreationService.deleteTask(taskId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted successfully.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete task.')),
      );
    }
  }
}
