import 'package:flutter/material.dart';
import 'package:prakriti/services/sp_task_creation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebCreateSpecialTaskPage extends StatefulWidget {
  const WebCreateSpecialTaskPage({super.key});

  @override
  _WebCreateSpecialTaskPageState createState() => _WebCreateSpecialTaskPageState();
}

class _WebCreateSpecialTaskPageState extends State<WebCreateSpecialTaskPage> {
  final SpTaskCreationService _taskCreationService = SpTaskCreationService(); // Service to handle task creation
  final TextEditingController _titleController = TextEditingController(); // Controller for the task title
  final TextEditingController _detailsController = TextEditingController(); // Controller for task details
  final TextEditingController _proofDetailsController = TextEditingController(); // Controller for proof details
  final TextEditingController _pointsController = TextEditingController(); // Controller for task points
  bool _isSubmitting = false; // Flag to track the submission state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Special Task'), // Title for the AppBar
      ),
      body: Center(
        child: Container(
          width: 600, // Fixed width for the form container
          padding: const EdgeInsets.all(16.0), // Padding around the form
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TextField for the task title
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(), // Border for the text field
                ),
              ),
              const SizedBox(height: 16), // Space between form fields
              
              // TextField for task details
              TextField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: 'Details',
                  border: OutlineInputBorder(), // Border for the text field
                ),
              ),
              const SizedBox(height: 16), // Space between form fields
              
              // TextField for proof details
              TextField(
                controller: _proofDetailsController,
                decoration: const InputDecoration(
                  labelText: 'Proof Details',
                  border: OutlineInputBorder(), // Border for the text field
                ),
              ),
              const SizedBox(height: 16), // Space between form fields
              
              // TextField for points (numeric input)
              TextField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points',
                  border: OutlineInputBorder(), // Border for the text field
                ),
                keyboardType: TextInputType.number, // Numeric keyboard for points input
              ),
              const SizedBox(height: 16), // Space between form fields
              
              // Button to submit the task
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator()) // Show loading spinner if submitting
                  : ElevatedButton(
                      onPressed: _submitTask, // Call the submitTask method on press
                      child: const Text('Create Task'), // Button text
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to handle task submission
  Future<void> _submitTask() async {
    setState(() {
      _isSubmitting = true; // Set submitting state to true
    });

    final String title = _titleController.text.trim(); // Get title text
    final String details = _detailsController.text.trim(); // Get details text
    final String proofDetails = _proofDetailsController.text.trim(); // Get proof details text
    final int points = int.parse(_pointsController.text.trim()); // Get points value (assumed to be valid integer)
    final String creatorId = FirebaseAuth.instance.currentUser?.uid ?? ''; // Get current user ID

    // Validate form input
    if (title.isEmpty || details.isEmpty || proofDetails.isEmpty || points <= 0) {
      _showSnackBar('Please fill all fields and ensure points are greater than 0.'); // Show error message
      setState(() {
        _isSubmitting = false; // Reset submitting state
      });
      return;
    }

    try {
      // Call the task creation service to create the task
      await _taskCreationService.createTask(title, details, proofDetails, points, creatorId);
      _showSnackBar('Task created successfully.'); // Show success message
      Navigator.pop(context); // Navigate back to the previous screen
    } catch (e) {
      _showSnackBar('Error creating task: $e'); // Show error message
    } finally {
      setState(() {
        _isSubmitting = false; // Reset submitting state
      });
    }
  }

  // Method to display a snackbar with a given message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)), // Show the message in a snackbar
    );
  }
}
