import 'package:cloud_firestore/cloud_firestore.dart';

class SpTaskCreationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTasks() {
    return _firestore.collection('eco_tasks').snapshots();
  }

  Future<void> createTask(String title, String details, String proofDetails, int points, String creatorId) async {
    await _firestore.collection('eco_tasks').add({
      'title': title,
      'details': details,
      'proofDetails': proofDetails,
      'points': points,
      'creator_ID': creatorId,
      'completed_by': [], // Initialize as an empty list
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('eco_tasks').doc(taskId).delete();
  }
}
