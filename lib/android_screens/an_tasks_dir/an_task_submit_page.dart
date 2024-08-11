import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prakriti/services/sp_task_completion_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnTaskSubmitPage extends StatefulWidget {
  final Map<String, dynamic> task;

  const AnTaskSubmitPage({super.key, required this.task});

  @override
  _AnTaskSubmitPageState createState() => _AnTaskSubmitPageState();
}

class _AnTaskSubmitPageState extends State<AnTaskSubmitPage> {
  final SpTaskCompletionService _taskCompletionService = SpTaskCompletionService();
  File? _imageFile;
  bool _isSubmitting = false;
  String _verificationResult = '';

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Task: $taskTitle',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Details: $taskDetails',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Proof Details: $proofDetails',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildImagePreview(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _pickImage,
              icon: const Icon(Icons.photo),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitProof,
              icon: const Icon(Icons.send),
              label: const Text('Submit Proof'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            if (_isSubmitting) const Center(child: CircularProgressIndicator()),
            _buildVerificationResult(),
          ],
        ),
      ),
    );
  }

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
              Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildVerificationResult() {
    if (_verificationResult.isNotEmpty) {
      return Card(
        elevation: 4,
        color: _verificationResult.toLowerCase().startsWith('yes') ? Colors.green[50] : Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Verification Result:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
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
      return const SizedBox.shrink();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }

  Future<void> _submitProof() async {
    if (_imageFile == null) {
      _showSnackBar('Please select an image.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _verificationResult = '';
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('User not logged in.');
        return;
      }
      String userId = user.uid;

      // Ensure taskId is present
      String taskId = widget.task['taskId'] ?? '';
      if (taskId.isEmpty) {
        _showSnackBar('Task ID is missing.');
        return;
      }

      // Convert the image file to Uint8List
      final Uint8List imageBytes = await _imageFile!.readAsBytes();

      final result = await _taskCompletionService.submitTaskProof(
        taskId,
        widget.task['proofDetails'] ?? '',
        imageBytes, // Pass the Uint8List instead of File
        userId,
      );

      setState(() {
        _verificationResult = result;
      });

      if (result.toLowerCase().startsWith('yes')) {
        _showSnackBar('Task successfully completed.');
        Navigator.pop(context);
      } else {
        _showSnackBar('Task failed - check reason.');
      }
    } catch (e) {
      _showSnackBar('Error submitting proof: $e');
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
