import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/forum_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

// This is the main page class that allows users to create a new post.
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

// The state class for the CreatePostPage that handles the UI and functionality.
class _CreatePostPageState extends State<CreatePostPage> {
  // Controllers for handling input from title and details text fields.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  
  // Instance of ForumService to handle post creation and image upload.
  final ForumService _forumService = ForumService();
  
  // Variables to store the picked image and current user's username.
  XFile? _image;
  String _currentUsername = '';
  
  // Variable to store the uploaded image URL.
  String? _imageUrl;
  
  // Flag to indicate if an image is being uploaded.
  bool _isUploading = false;
  
  // Max length for the title input.
  final int _maxTitleLength = 100;

  // Initialize the user and add a listener to update the character count.
  @override
  void initState() {
    super.initState();
    _initializeUser();
    _titleController.addListener(_updateCharacterCount);
  }

  // Clean up controllers and listeners when the page is disposed.
  @override
  void dispose() {
    _titleController.removeListener(_updateCharacterCount);
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  // Method to initialize the current user's username.
  Future<void> _initializeUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _currentUsername = user.displayName ?? 'Anonymous'; // Default to 'Anonymous' if no display name is set.
        });
      }
    } catch (e) {
      // Handle any errors that occur during user initialization.
    }
  }

  // Method to pick an image from the gallery.
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
      _imageUrl = null; // Reset image URL when picking a new image.
    });

    // If an image is selected, upload it and get the URL.
    if (_image != null) {
      setState(() {
        _isUploading = true; // Show loading indicator during upload.
      });
      try {
        _imageUrl = await _forumService.uploadImage(_image!); // Upload the image and get the URL.
      } catch (e) {
        // Show error message if the upload fails.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload failed')),
        );
      } finally {
        setState(() {
          _isUploading = false; // Hide loading indicator after upload.
        });
      }
    }
  }

  // Method to submit the post with title, details, and optional image.
  Future<void> _submitPost() async {
    final String title = _titleController.text;
    final String details = _detailsController.text;

    // Check if title and details are not empty before submitting.
    if (title.isNotEmpty && details.isNotEmpty) {
      await _forumService.createPost(
        title: title,
        details: details,
        imageUrl: _imageUrl, // Pass the uploaded image URL, if available.
        currentUsername: _currentUsername, // Pass the current user's username.
      );
      Navigator.of(context).pop(); // Return to the previous page after submission.
    } else {
      // Show error message if title or details are empty.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  // Method to update the character count for the title input.
  void _updateCharacterCount() {
    setState(() {});
  }

  // Main build method to create the UI of the page.
  @override
  Widget build(BuildContext context) {
    // Calculate the remaining characters for the title input.
    final int remainingCharacters = _maxTitleLength - _titleController.text.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'), // Page title
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Padding around the content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align child widgets to the start
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'), // Input for post title
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxTitleLength), // Limit the title length
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Characters remaining: $remainingCharacters', // Display remaining characters
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(labelText: 'Details'), // Input for post details
              maxLines: 5, // Allow multi-line input for details
            ),
            const SizedBox(height: 20),
            if (_image != null)
              _isUploading
                  ? const Center(child: CircularProgressIndicator()) // Show loading indicator during image upload
                  : FittedBox(
                      fit: BoxFit.cover, // Fit image to the available space
                      child: Image.file(
                        File(_image!.path), // Display the selected image
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.4,
                      ),
                    ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage, // Button to pick an image from the gallery
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitPost, // Button to submit the post
              child: const Text('Submit Post'),
            ),
          ],
        ),
      ),
    );
  }
}
