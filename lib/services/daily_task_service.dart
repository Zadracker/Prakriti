import 'dart:async'; // For asynchronous programming
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore database operations
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase authentication
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For loading environment variables
import 'package:google_generative_ai/google_generative_ai.dart'; // For using Google Generative AI
import 'points_service.dart'; // For managing points

// Service class to handle daily tasks
class DailyTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance for database operations
  final PointsService _pointsService = PointsService(); // Points service for awarding points

  // Generates daily tasks for the current day
  Future<void> generateDailyTasks() async {
    try {
      final today = DateTime.now(); // Get the current date
      final collectionName = _getFormattedDate(today); // Format the date to use as a collection name
      final tasksCollection = _firestore.collection('daily_tasks').doc(collectionName).collection('tasks');

      // Check if tasks already exist for today
      final existingTasksSnapshot = await tasksCollection.get();
      if (existingTasksSnapshot.docs.isNotEmpty) {
        return; // Exit if tasks already exist
      }

      // Generate new tasks using Gemini model
      final tasks = await _generateTasksWithGemini();

      // Add each generated task to the Firestore collection
      for (var task in tasks) {
        await tasksCollection.add({
          'task': task, // Task description
          'timestamp': Timestamp.now(), // Current timestamp
          'points': 10, // Points awarded for completing the task
          'completed_by': [], // List of users who have completed the task
        });
      }

      // Delete tasks older than 5 days
      await _deleteOldTasks();
    } catch (e) {
      // Handle exceptions (e.g., log the error)
    }
  }

  // Generates tasks using the Gemini AI model
  Future<List<String>> _generateTasksWithGemini() async {
    final apiKey = dotenv.env['API_KEY']; // Retrieve the API key from environment variables
    if (apiKey == null) {
      return []; // Return an empty list if API key is not available
    }

    // Initialize the GenerativeModel with API key and configuration
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    // Request tasks from the AI model
    final content = [Content.text('Generate 10 eco-friendly tasks for the day {only the task - no other text} {unordered}')];
    final response = await model.generateContent(content);

    // Split the response text into individual tasks
    return response.text?.split('\n').where((task) => task.isNotEmpty).toList() ?? [];
  }

  // Deletes tasks older than 5 days from Firestore
  Future<void> _deleteOldTasks() async {
    final today = DateTime.now(); // Get the current date
    final cutoffDate = today.subtract(const Duration(days: 5)); // Calculate the cutoff date

    try {
      final dailyTasksCollection = _firestore.collection('daily_tasks');
      final snapshot = await dailyTasksCollection.get(); // Retrieve all documents in the collection

      // Iterate through each document
      for (var doc in snapshot.docs) {
        final docDate = DateTime.tryParse(doc.id); // Parse document ID as a date
        if (docDate != null && docDate.isBefore(cutoffDate)) {
          
          // Delete all tasks in the subcollection
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
      // Handle exceptions (e.g., log the error)
    }
  }

  // Streams the daily tasks for the current day
  Stream<QuerySnapshot> getDailyTasksStream() {
    final today = DateTime.now(); // Get the current date
    final collectionName = _getFormattedDate(today); // Format the date to use as a collection name

    // Return a stream of snapshots for the tasks collection
    return _firestore.collection('daily_tasks').doc(collectionName).collection('tasks').snapshots();
  }

  // Marks a task as completed by the current user
  Future<void> markTaskAsComplete(String taskId) async {
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user == null) {
      throw Exception('User not logged in'); // Throw an exception if user is not logged in
    }

    final today = DateTime.now(); // Get the current date
    final collectionName = _getFormattedDate(today); // Format the date to use as a collection name
    final taskRef = _firestore.collection('daily_tasks').doc(collectionName).collection('tasks').doc(taskId);

    try {
      // Use a transaction to ensure atomic updates
      final points = await _firestore.runTransaction<int>((transaction) async {
        final taskSnapshot = await transaction.get(taskRef);

        if (!taskSnapshot.exists) {
          return 0; // Return zero points if the task does not exist
        }

        final taskData = taskSnapshot.data() as Map<String, dynamic>;
        final completedBy = List<String>.from(taskData['completed_by'] ?? []);

        // Check if the user has already completed the task
        if (!completedBy.contains(user.uid)) {
          completedBy.add(user.uid);
          transaction.update(taskRef, {'completed_by': completedBy});

          // Return the points awarded for the task
          final taskPoints = taskData['points'] as int;
          return taskPoints;
        } else {
          return 0; // Return zero points if the user already completed the task
        }
      });

      // Award points to the user if they completed the task
      if (points > 0) {
        final date = _getFormattedDate(today);
        await _pointsService.awardDailyTaskPoints(user.uid, date, taskId);
      }
    } catch (e) {
      // Handle exceptions (e.g., log the error)
    }
  }

  // Formats a DateTime object to a string in 'YYYY-MM-DD' format
  String _getFormattedDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
