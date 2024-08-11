import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'points_service.dart';

class DailyTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PointsService _pointsService = PointsService();

  Future<void> generateDailyTasks() async {
    try {
      final today = DateTime.now();
      final collectionName = _getFormattedDate(today);
      final tasksCollection = _firestore.collection('daily_tasks').doc(collectionName).collection('tasks');

      final existingTasksSnapshot = await tasksCollection.get();
      if (existingTasksSnapshot.docs.isNotEmpty) {
        return;
      }

      final tasks = await _generateTasksWithGemini();

      for (var task in tasks) {
        await tasksCollection.add({
          'task': task,
          'timestamp': Timestamp.now(),
          'points': 10,
          'completed_by': [],
        });
      }

      await _deleteOldTasks();
    } catch (e) {
    }
  }

  Future<List<String>> _generateTasksWithGemini() async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      return [];
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final content = [Content.text('Generate 10 eco-friendly tasks for the day {only the task - no other text} {unordered}')];
    final response = await model.generateContent(content);

    return response.text?.split('\n').where((task) => task.isNotEmpty).toList() ?? [];
  }

  Future<void> _deleteOldTasks() async {
    final today = DateTime.now();
    final cutoffDate = today.subtract(const Duration(days: 5));

    try {
      final dailyTasksCollection = _firestore.collection('daily_tasks');
      final snapshot = await dailyTasksCollection.get();

      for (var doc in snapshot.docs) {
        final docDate = DateTime.tryParse(doc.id);
        if (docDate != null && docDate.isBefore(cutoffDate)) {
          
          // Delete all subcollections first
          final tasksCollection = dailyTasksCollection.doc(doc.id).collection('tasks');
          final tasksSnapshot = await tasksCollection.get();
          for (var taskDoc in tasksSnapshot.docs) {
            await taskDoc.reference.delete();
          }
          
          // Delete the main document
          await dailyTasksCollection.doc(doc.id).delete();
        }
      }
    } catch (e) {
    }
  }

  Stream<QuerySnapshot> getDailyTasksStream() {
    final today = DateTime.now();
    final collectionName = _getFormattedDate(today);

    return _firestore.collection('daily_tasks').doc(collectionName).collection('tasks').snapshots();
  }

  Future<void> markTaskAsComplete(String taskId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final today = DateTime.now();
    final collectionName = _getFormattedDate(today);
    final taskRef = _firestore.collection('daily_tasks').doc(collectionName).collection('tasks').doc(taskId);

    try {
      final points = await _firestore.runTransaction<int>((transaction) async {
        final taskSnapshot = await transaction.get(taskRef);

        if (!taskSnapshot.exists) {
          return 0; // Early return without throwing an error
        }

        final taskData = taskSnapshot.data() as Map<String, dynamic>;
        final completedBy = List<String>.from(taskData['completed_by'] ?? []);

        if (!completedBy.contains(user.uid)) {
          completedBy.add(user.uid);
          transaction.update(taskRef, {'completed_by': completedBy});

          final taskPoints = taskData['points'] as int;
          return taskPoints;
        } else {
          return 0; // Return zero points if the user already completed the task
        }
      });

      if (points > 0) {
        final date = _getFormattedDate(today);
        await _pointsService.awardDailyTaskPoints(user.uid, date, taskId);
      } else {
      }
    } catch (e) {
    }
  }

  String _getFormattedDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
