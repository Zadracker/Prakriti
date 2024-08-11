import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/services/sp_task_completion_service.dart';

class WebTaskSubmitPage extends StatefulWidget {
  final Map<String, dynamic> task;

  const WebTaskSubmitPage({super.key, required this.task});

  @override
  _WebTaskSubmitPageState createState() => _WebTaskSubmitPageState();
}

class _WebTaskSubmitPageState extends State<WebTaskSubmitPage> {
  final SpTaskCompletionService _taskCompletionService = SpTaskCompletionService();
  Uint8List? _imageData;
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Task: $taskTitle',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Details: $taskDetails',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Proof Details: $proofDetails',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildImagePreview(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _pickImage,
              icon: const Icon(Icons.photo),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitProof,
              icon: const Icon(Icons.send),
              label: const Text('Submit Proof'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),
            if (_isSubmitting) const Center(child: CircularProgressIndicator()),
            _buildVerificationResult(),
          ],
        ),
      ),
    );
  }

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
      return const SizedBox.shrink();
    }
  }

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
      return const SizedBox.shrink();
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _imageData = result.files.single.bytes;
      });
    }
  }

  Future<void> _submitProof() async {
    if (_imageData == null) {
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

      final result = await _taskCompletionService.submitTaskProof(
        taskId,
        widget.task['proofDetails'] ?? '',
        _imageData!,
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
