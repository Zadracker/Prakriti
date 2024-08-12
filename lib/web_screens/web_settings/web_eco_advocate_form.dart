import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebEcoAdvocateForm extends StatefulWidget {
  const WebEcoAdvocateForm({super.key});

  @override
  _WebEcoAdvocateFormState createState() => _WebEcoAdvocateFormState();
}

class _WebEcoAdvocateFormState extends State<WebEcoAdvocateForm> {
  final _formKey = GlobalKey<FormState>(); // Key to uniquely identify the form
  final _applicationTextController = TextEditingController(); // Controller for the application text field
  Uint8List? _pickedFileBytes; // Variable to store the picked file bytes
  String _fileName = 'No PDF selected'; // Display text for the selected file
  bool _isSubmitting = false; // Flag to indicate whether the form is being submitted

  // Method to handle file picking
  Future<void> _pickFile() async {
    try {
      // Open file picker dialog to select a PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.bytes != null) {
        // Update state if a file is selected
        setState(() {
          _pickedFileBytes = result.files.single.bytes;
          _fileName = result.files.single.name;
        });
      } else {
        // Reset file name if no file is selected
        setState(() {
          _fileName = 'No PDF selected';
        });
      }
    } catch (e) {
      // Handle any errors that occur during file picking
      setState(() {
        _fileName = 'No PDF selected';
      });
    }
  }

  // Method to handle application submission
  Future<void> _submitApplication() async {
    // Check if the form is valid and a file is selected
    if (_formKey.currentState!.validate() && _pickedFileBytes != null) {
      setState(() {
        _isSubmitting = true; // Set submitting flag to true
      });

      try {
        User? user = FirebaseAuth.instance.currentUser; // Get the current user
        if (user != null) {
          // Define the file path in Firebase Storage
          String fileName = _fileName;
          String filePath = 'eco_advocate_applications/${user.uid}/$fileName';
          Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
          UploadTask uploadTask = storageRef.putData(_pickedFileBytes!);

          // Wait for the upload to complete
          TaskSnapshot taskSnapshot = await uploadTask;
          String downloadUrl = await taskSnapshot.ref.getDownloadURL(); // Get the download URL for the uploaded file

          // Save application details in the database
          await UserService().addEcoAdvocateApplication(
            user.uid,
            user.email!,
            user.displayName!,
            _applicationTextController.text,
            downloadUrl,
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Application submitted successfully'),
          ));
        }
      } catch (e) {
        // Show error message if submission fails
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to submit application'),
        ));
      } finally {
        setState(() {
          _isSubmitting = false; // Reset submitting flag
        });
      }
    } else {
      // Show error message if form validation fails or no file is selected
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all fields and select a PDF'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco Advocate Application'), // App bar title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Set the form key to validate the form
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _applicationTextController, // Controller for the text field
                decoration: const InputDecoration(labelText: 'Reason for applying'), // Label for the text field
                maxLines: 4, // Allow multiple lines of input
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason'; // Validation error message
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(_fileName), // Display the selected file name
              ElevatedButton(
                onPressed: _pickFile, // Call the file picker method
                child: const Text('Attach PDF'), // Button text
              ),
              const SizedBox(height: 20),
              _isSubmitting
                  ? const CircularProgressIndicator() // Show loading spinner if submitting
                  : ElevatedButton(
                      onPressed: _submitApplication, // Call the submit method
                      child: const Text('Submit Application'), // Button text
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
