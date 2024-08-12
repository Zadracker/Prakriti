import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/services/sp_task_completion_service.dart';

class WebTaskSubmitPage extends StatefulWidget {
  final Map<String, dynamic> task; // Data about the task to be submitted

  const WebTaskSubmitPage({super.key, required this.task});

  @override
  _WebTaskSubmitPageState createState() => _WebTaskSubmitPageState();
}

class _WebTaskSubmitPageState extends State<WebTaskSubmitPage> {
  final SpTaskCompletionService _taskCompletionService = SpTaskCompletionService(); // Service to handle task completion
  Uint8List? _imageData; // Holds the image data selected by the user
  bool _isSubmitting = false; // Flag to indicate if submission is in progress
  String _verificationResult = ''; // Holds the result of the task verification

  @override
  Widget build(BuildContext context) {
    // Extract task details from widget properties
    final taskTitle = widget.task['title'] ?? 'Unknown Task';
    final taskDetails = widget.task['details'] ?? 'No details available';
    final proofDetails = widget.task['proofDetails'] ?? 'No proof details provided';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Task Proof'), // Title for the AppBar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0), // Padding around the content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Display task title
            Text(
              'Task: $taskTitle',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Display task details
            Text(
              'Details: $taskDetails',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Display proof details
            Text(
              'Proof Details: $proofDetails',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Build the image preview widget
            _buildImagePreview(),
            const SizedBox(height: 24),
            
            // Button to select an image for proof
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _pickImage, // Disable button if submitting
              icon: const Icon(Icons.photo),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),
            
            // Button to submit the selected image as proof
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitProof, // Disable button if submitting
              icon: const Icon(Icons.send),
              label: const Text('Submit Proof'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),
            
            // Show a loading spinner if the form is submitting
            if (_isSubmitting) const Center(child: CircularProgressIndicator()),
            
            // Display the verification result
            _buildVerificationResult(),
          ],
        ),
      ),
    );
  }

  // Widget to preview the selected image
  Widget _buildImagePreview() {
    if (_imageData != null) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Selected Image:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Display the image selected by the user
              Image.memory(
                _imageData!,
                height: 300,
                fit: BoxFit.cover,
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink(); // Return an empty widget if no image is selected
    }
  }

  // Widget to display the result of the task verification
  Widget _buildVerificationResult() {
    if (_verificationResult.isNotEmpty) {
      return Card(
        elevation: 4,
        color: Colors.grey.shade800,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Verification Result:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              // Display verification result with color coding
              Text(
                _verificationResult,
                style: TextStyle(
                  fontSize: 18,
                  color: _verificationResult.toLowerCase().startsWith('yes') ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink(); // Return an empty widget if there is no verification result
    }
  }

  // Method to pick an image file from the device
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, // Allow only image files
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _imageData = result.files.single.bytes; // Update state with selected image data
      });
    }
  }

  // Method to submit the selected proof for verification
  Future<void> _submitProof() async {
    if (_imageData == null) {
      _showSnackBar('Please select an image.'); // Show error if no image is selected
      return;
    }

    setState(() {
      _isSubmitting = true; // Set submitting state to true
      _verificationResult = ''; // Clear previous verification result
    });

    try {
      User? user = FirebaseAuth.instance.currentUser; // Get current user
      if (user == null) {
        _showSnackBar('User not logged in.'); // Show error if user is not logged in
        return;
      }
      String userId = user.uid;

      // Ensure taskId is present in the task data
      String taskId = widget.task['taskId'] ?? '';
      if (taskId.isEmpty) {
        _showSnackBar('Task ID is missing.'); // Show error if task ID is missing
        return;
      }

      // Submit the proof using the task completion service
      final result = await _taskCompletionService.submitTaskProof(
        taskId,
        widget.task['proofDetails'] ?? '',
        _imageData!,
        userId,
      );

      setState(() {
        _verificationResult = result; // Update verification result
      });

      // Show success or failure message based on the verification result
      if (result.toLowerCase().startsWith('yes')) {
        _showSnackBar('Task successfully completed.');
        Navigator.pop(context); // Navigate back to the previous screen
      } else {
        _showSnackBar('Task failed - check reason.');
      }
    } catch (e) {
      _showSnackBar('Error submitting proof: $e'); // Show error if submission fails
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
