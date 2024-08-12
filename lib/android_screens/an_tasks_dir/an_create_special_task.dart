import 'package:flutter/material.dart';
import 'package:prakriti/services/sp_task_creation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnCreateSpecialTaskPage extends StatefulWidget {
  const AnCreateSpecialTaskPage({super.key});

  @override
  _AnCreateSpecialTaskPageState createState() => _AnCreateSpecialTaskPageState();
}

class _AnCreateSpecialTaskPageState extends State<AnCreateSpecialTaskPage> {
  // Instance of SpTaskCreationService to handle task creation logic
  final SpTaskCreationService _taskCreationService = SpTaskCreationService();
  
  // Controllers for the input fields to capture user input
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _proofDetailsController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  
  // Boolean to manage the submission state
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Special Task'), // Title of the page
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding around the form
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TextField for task title input
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            // TextField for task details input
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(labelText: 'Details'),
            ),
            // TextField for proof details input
            TextField(
              controller: _proofDetailsController,
              decoration: const InputDecoration(labelText: 'Proof Details'),
            ),
            // TextField for points input, only allowing numeric input
            TextField(
              controller: _pointsController,
              decoration: const InputDecoration(labelText: 'Points'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16), // Spacing before the submit button
            // Submit button, disabled if the form is being submitted
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTask,
              child: const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }

  // Function to handle task submission
  Future<void> _submitTask() async {
    setState(() {
      _isSubmitting = true; // Set the submitting state to true
    });

    // Retrieve and trim user input from the form fields
    final String title = _titleController.text.trim();
    final String details = _detailsController.text.trim();
    final String proofDetails = _proofDetailsController.text.trim();
    final int points = int.parse(_pointsController.text.trim());
    final String creatorId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Validate that all fields are filled and points are greater than 0
    if (title.isEmpty || details.isEmpty || proofDetails.isEmpty || points <= 0) {
      _showSnackBar('Please fill all fields and ensure points are greater than 0.');
      setState(() {
        _isSubmitting = false; // Reset the submitting state
      });
      return;
    }

    try {
      // Attempt to create the task using the provided service
      await _taskCreationService.createTask(title, details, proofDetails, points, creatorId);
      _showSnackBar('Task created successfully.');
      Navigator.pop(context); // Navigate back after successful submission
    } catch (e) {
      // Show error message if task creation fails
      _showSnackBar('Error creating task: $e');
    } finally {
      setState(() {
        _isSubmitting = false; // Reset the submitting state
      });
    }
  }

  // Helper function to show a snackbar with a message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
