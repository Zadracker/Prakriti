import 'dart:typed_data'; // For Uint8List
import 'dart:io' as io; // For File on non-web platforms
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package

import '../../services/forum_service.dart';

class WebCreatePostPage extends StatefulWidget {
  const WebCreatePostPage({super.key});

  @override
  _WebCreatePostPageState createState() => _WebCreatePostPageState();
}

class _WebCreatePostPageState extends State<WebCreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final ForumService _forumService = ForumService();
  XFile? _image;
  String _currentUsername = '';
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  // Initialize user details
  Future<void> _initializeUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _currentUsername = user.displayName ?? 'Anonymous';
        });
      }
    } catch (e) {
      // Handle potential errors
    }
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
      _imageUrl = null; // Reset image URL while uploading a new image
    });
    if (_image != null) {
      setState(() {
        _isUploading = true; // Set uploading flag
      });
      try {
        _imageUrl = await _uploadImage(_image!); // Update to use _uploadImage method
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

  // Upload image to Firebase Storage and return the download URL
  Future<String> _uploadImage(XFile imageFile) async {
    try {
      String fileName = const Uuid().v4();
      Reference ref = FirebaseStorage.instance.ref().child('uploads/$fileName');

      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = await io.File(imageFile.path).readAsBytes();
      }

      UploadTask uploadTask = ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  // Submit the post data
  Future<void> _submitPost() async {
    final String title = _titleController.text;
    final String details = _detailsController.text;

    if (title.isNotEmpty && details.isNotEmpty && title.length <= 100) {
      try {
        await _forumService.createPost(
          title: title,
          details: details,
          imageUrl: _imageUrl, // Use _imageUrl which is the image URL
          currentUsername: _currentUsername,
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create post')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields and ensure the title is under 100 characters')),
      );
    }
  }

  // Fetch image from URL
  Future<void> _fetchImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Handle successful image fetch if needed
      } else {
        // Handle unsuccessful fetch
      }
    } catch (e) {
      // Handle fetch error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                maxLength: 100,
              ),
              TextField(
                controller: _detailsController,
                decoration: const InputDecoration(labelText: 'Details'),
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator()) // Show progress indicator while uploading
                      : _imageUrl != null
                          ? FutureBuilder(
                              future: _fetchImage(_imageUrl!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return const Text('Error loading image');
                                } else {
                                  return Image.network(
                                    _imageUrl!,
                                    width: MediaQuery.of(context).size.width * 0.8,
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Text('Error loading image');
                                    },
                                  );
                                }
                              },
                            )
                          : Container(), // Empty container to avoid error when _imageUrl is null
                ),
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
      ),
    );
  }
}
