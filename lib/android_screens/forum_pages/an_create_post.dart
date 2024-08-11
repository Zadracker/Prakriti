import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/forum_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final ForumService _forumService = ForumService();
  XFile? _image;
  String _currentUsername = '';
  String? _imageUrl;
  bool _isUploading = false;
  final int _maxTitleLength = 100;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _titleController.addListener(_updateCharacterCount);
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateCharacterCount);
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _currentUsername = user.displayName ?? 'Anonymous';
        });
      }
    } catch (e) {
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
      _imageUrl = null; // Reset image URL while picking a new image
    });
    if (_image != null) {
      setState(() {
        _isUploading = true; // Set uploading flag
      });
      try {
        _imageUrl = await _forumService.uploadImage(_image!); // Use updated uploadImage method
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload failed')),
        );
      } finally {
        setState(() {
          _isUploading = false; // Reset uploading flag
        });
      }
    }
  }

  Future<void> _submitPost() async {
    final String title = _titleController.text;
    final String details = _detailsController.text;

    if (title.isNotEmpty && details.isNotEmpty) {
      await _forumService.createPost(
        title: title,
        details: details,
        imageUrl: _imageUrl, // Pass the image URL as String?
        currentUsername: _currentUsername,
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  void _updateCharacterCount() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final int remainingCharacters = _maxTitleLength - _titleController.text.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxTitleLength), // Limit title to 100 characters
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Characters remaining: $remainingCharacters',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(labelText: 'Details'),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            if (_image != null)
              _isUploading
                  ? const Center(child: CircularProgressIndicator()) // Show progress indicator while uploading
                  : FittedBox(
                      fit: BoxFit.cover,
                      child: Image.file(
                        File(_image!.path),
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.4,
                      ),
                    ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitPost,
              child: const Text('Submit Post'),
            ),
          ],
        ),
      ),
    );
  }
}
