import 'package:flutter/material.dart';
import 'package:prakriti/services/sp_task_creation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebCreateSpecialTaskPage extends StatefulWidget {
  const WebCreateSpecialTaskPage({super.key});

  @override
  _WebCreateSpecialTaskPageState createState() => _WebCreateSpecialTaskPageState();
}

class _WebCreateSpecialTaskPageState extends State<WebCreateSpecialTaskPage> {
  final SpTaskCreationService _taskCreationService = SpTaskCreationService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _proofDetailsController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Special Task'),
      ),
      body: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: 'Details',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _proofDetailsController,
                decoration: const InputDecoration(
                  labelText: 'Proof Details',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitTask,
                      child: const Text('Create Task'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitTask() async {
    setState(() {
      _isSubmitting = true;
    });

    final String title = _titleController.text.trim();
    final String details = _detailsController.text.trim();
    final String proofDetails = _proofDetailsController.text.trim();
    final int points = int.parse(_pointsController.text.trim());
    final String creatorId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (title.isEmpty || details.isEmpty || proofDetails.isEmpty || points <= 0) {
      _showSnackBar('Please fill all fields and ensure points are greater than 0.');
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    try {
      await _taskCreationService.createTask(title, details, proofDetails, points, creatorId);
      _showSnackBar('Task created successfully.');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error creating task: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
