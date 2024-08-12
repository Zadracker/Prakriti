import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// This widget represents a form where users can apply to become an Eco Advocate.
class AnEcoAdvocateForm extends StatefulWidget {
  const AnEcoAdvocateForm({super.key});

  @override
  _AnEcoAdvocateFormState createState() => _AnEcoAdvocateFormState();
}

class _AnEcoAdvocateFormState extends State<AnEcoAdvocateForm> {
  // A GlobalKey is used to identify the form and manage its state.
  final _formKey = GlobalKey<FormState>();

  // Controllers to manage the input text for the application reason.
  final _applicationTextController = TextEditingController();

  // Variables to handle file selection and submission status.
  File? _pickedFile;
  String _fileName = 'No PDF selected';
  bool _isSubmitting = false;

  /// Function to pick a PDF file using FilePicker.
  Future<void> _pickFile() async {
    try {
      // Allow the user to pick only PDF files.
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      // If a file is selected, store it and update the file name display.
      if (result != null && result.files.single.path != null) {
        setState(() {
          _pickedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      } else {
        // If no file is selected, reset the file name display.
        setState(() {
          _fileName = 'No PDF selected';
        });
      }
    } catch (e) {
      // In case of an error during file selection, reset the file name display.
      setState(() {
        _fileName = 'No PDF selected';
      });
    }
  }

  /// Function to submit the application to Firebase.
  Future<void> _submitApplication() async {
    // Check if the form is valid and a file is selected.
    if (_formKey.currentState!.validate() && _pickedFile != null) {
      setState(() {
        _isSubmitting = true; // Show loading indicator.
      });

      try {
        // Get the current logged-in user.
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Create a file path in Firebase Storage based on the user's UID.
          String fileName = _pickedFile!.path.split('/').last;
          String filePath = 'eco_advocate_applications/${user.uid}/$fileName';
          
          // Upload the selected file to Firebase Storage.
          UploadTask uploadTask = FirebaseStorage.instance
              .ref()
              .child(filePath)
              .putFile(_pickedFile!);

          // Wait for the upload to complete and get the download URL.
          TaskSnapshot taskSnapshot = await uploadTask;
          String downloadUrl = await taskSnapshot.ref.getDownloadURL();

          // Save the application data, including the download URL, to Firestore.
          await UserService().addEcoAdvocateApplication(
            user.uid,
            user.email!,
            user.displayName!,
            _applicationTextController.text,
            downloadUrl, // Pass the download URL as a string.
          );

          // Show a success message to the user.
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Application submitted successfully'),
          ));
        }
      } catch (e) {
        // If there's an error during submission, show an error message.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to submit application'),
        ));
      } finally {
        setState(() {
          _isSubmitting = false; // Hide loading indicator.
        });
      }
    } else {
      // If the form is incomplete or no file is selected, show an error message.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all fields and select a PDF'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco Advocate Application'), // Title of the app bar.
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding around the form.
        child: Form(
          key: _formKey, // Attach the form key to the form widget.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start.
            children: <Widget>[
              // Text field for entering the reason for applying.
              TextFormField(
                controller: _applicationTextController,
                decoration: const InputDecoration(labelText: 'Reason for applying'),
                maxLines: 4, // Allow up to 4 lines of input.
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason'; // Validate that the input is not empty.
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20), // Add vertical space.
              Text(_fileName), // Display the name of the selected file.
              ElevatedButton(
                onPressed: _pickFile, // Trigger file picker on button press.
                child: const Text('Attach PDF'), // Button label.
              ),
              const SizedBox(height: 20), // Add vertical space.
              _isSubmitting
                  ? const CircularProgressIndicator() // Show loading indicator if submitting.
                  : ElevatedButton(
                      onPressed: _submitApplication, // Trigger submission on button press.
                      child: const Text('Submit Application'), // Button label.
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
