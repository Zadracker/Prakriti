import 'package:cloud_firestore/cloud_firestore.dart';

class SpTaskCreationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Streams a snapshot of the 'eco_tasks' collection from Firestore.
  /// This allows real-time updates to be observed.
  Stream<QuerySnapshot> getTasks() {
    return _firestore.collection('eco_tasks').snapshots();
  }

  /// Creates a new task in the 'eco_tasks' collection.
  /// 
  /// [title]: The title of the task.
  /// [details]: Detailed description of the task.
  /// [proofDetails]: Information on what constitutes proof for task completion.
  /// [points]: Points awarded for completing the task.
  /// [creatorId]: The ID of the user who created the task.
  Future<void> createTask(String title, String details, String proofDetails, int points, String creatorId) async {
    await _firestore.collection('eco_tasks').add({
      'title': title,
      'details': details,
      'proofDetails': proofDetails,
      'points': points,
      'creator_ID': creatorId,
      'completed_by': [], // Initialize as an empty list of user IDs who have completed the task
      'timestamp': FieldValue.serverTimestamp(), // Automatically sets the timestamp when the task is created
    });
  }

  /// Deletes a task from the 'eco_tasks' collection.
  /// 
  /// [taskId]: The ID of the task to be deleted.
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('eco_tasks').doc(taskId).delete();
  }
}
