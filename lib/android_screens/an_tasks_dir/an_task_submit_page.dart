import 'dart:io'; // Used for working with files.
import 'dart:typed_data'; // Used for working with binary data, e.g., converting images to bytes.
import 'package:flutter/material.dart'; // Flutter's material design package.
import 'package:image_picker/image_picker.dart'; // Package to pick images from the gallery or camera.
import 'package:prakriti/services/sp_task_completion_service.dart'; // Service for task completion logic.
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication package.

class AnTaskSubmitPage extends StatefulWidget {
  // Task information passed from previous screen
  final Map<String, dynamic> task;

  const AnTaskSubmitPage({super.key, required this.task});

  @override
  _AnTaskSubmitPageState createState() => _AnTaskSubmitPageState();
}

class _AnTaskSubmitPageState extends State<AnTaskSubmitPage> {
  final SpTaskCompletionService _taskCompletionService = SpTaskCompletionService(); // Service to handle task completion.
  File? _imageFile; // Selected image file.
  bool _isSubmitting = false; // Tracks if the form is currently being submitted.
  String _verificationResult = ''; // Stores the result of the proof verification.

  @override
  Widget build(BuildContext context) {
    // Extract task details from the provided task map.
    final taskTitle = widget.task['title'] ?? 'Unknown Task';
    final taskDetails = widget.task['details'] ?? 'No details available';
    final proofDetails = widget.task['proofDetails'] ?? 'No proof details provided';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Task Proof'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display task title.
            Text(
              'Task: $taskTitle',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Display task details.
            Text(
              'Details: $taskDetails',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            // Display proof details.
            Text(
              'Proof Details: $proofDetails',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildImagePreview(), // Display the selected image preview.
            const SizedBox(height: 16),
            // Button to pick an image from the gallery.
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _pickImage, // Disable button if submitting.
              icon: const Icon(Icons.photo),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            // Button to submit the proof.
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitProof, // Disable button if submitting.
              icon: const Icon(Icons.send),
              label: const Text('Submit Proof'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            // Display a loading indicator if the form is being submitted.
            if (_isSubmitting) const Center(child: CircularProgressIndicator()),
            _buildVerificationResult(), // Display the result of the proof verification.
          ],
        ),
      ),
    );
  }

  // Widget to display the selected image preview.
  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selected Image:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Image.file(_imageFile!, height: 200, fit: BoxFit.cover), // Display the image.
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink(); // Return an empty widget if no image is selected.
    }
  }

  // Widget to display the result of the verification process.
  Widget _buildVerificationResult() {
    if (_verificationResult.isNotEmpty) {
      return Card(
        elevation: 4,
        // Change the card color based on verification result.
        color: _verificationResult.toLowerCase().startsWith('yes') ? Colors.green[50] : Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Verification Result:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Display the verification result text with color indicating success or failure.
              Text(
                _verificationResult,
                style: TextStyle(
                  fontSize: 16,
                  color: _verificationResult.toLowerCase().startsWith('yes') ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink(); // Return an empty widget if no verification result is available.
    }
  }

  // Function to pick an image from the gallery.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path); // Set the selected image file.
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e'); // Show error if image picking fails.
    }
  }

  // Function to submit the selected image as proof.
  Future<void> _submitProof() async {
    if (_imageFile == null) {
      _showSnackBar('Please select an image.'); // Show message if no image is selected.
      return;
    }

    setState(() {
      _isSubmitting = true; // Indicate that submission is in progress.
      _verificationResult = ''; // Clear previous verification result.
    });

    try {
      // Check if the user is logged in.
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('User not logged in.');
        return;
      }
      String userId = user.uid;

      // Ensure taskId is present.
      String taskId = widget.task['taskId'] ?? '';
      if (taskId.isEmpty) {
        _showSnackBar('Task ID is missing.');
        return;
      }

      // Convert the image file to Uint8List (binary format).
      final Uint8List imageBytes = await _imageFile!.readAsBytes();

      // Submit the proof and get the result.
      final result = await _taskCompletionService.submitTaskProof(
        taskId,
        widget.task['proofDetails'] ?? '',
        imageBytes, // Pass the Uint8List instead of File.
        userId,
      );

      setState(() {
        _verificationResult = result; // Set the verification result.
      });

      // Show a success message and navigate back if the task was completed successfully.
      if (result.toLowerCase().startsWith('yes')) {
        _showSnackBar('Task successfully completed.');
        Navigator.pop(context);
      } else {
        _showSnackBar('Task failed - check reason.');
      }
    } catch (e) {
      _showSnackBar('Error submitting proof: $e'); // Show error if submission fails.
    } finally {
      setState(() {
        _isSubmitting = false; // Reset submission state.
      });
    }
  }

  // Function to show a snackbar with a message.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
