import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnEcoAdvocateForm extends StatefulWidget {
  const AnEcoAdvocateForm({super.key});

  @override
  _AnEcoAdvocateFormState createState() => _AnEcoAdvocateFormState();
}

class _AnEcoAdvocateFormState extends State<AnEcoAdvocateForm> {
  final _formKey = GlobalKey<FormState>();
  final _applicationTextController = TextEditingController();
  File? _pickedFile;
  String _fileName = 'No PDF selected';
  bool _isSubmitting = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _pickedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      } else {
        setState(() {
          _fileName = 'No PDF selected';
        });
      }
    } catch (e) {
      setState(() {
        _fileName = 'No PDF selected';
      });
    }
  }

  Future<void> _submitApplication() async {
    if (_formKey.currentState!.validate() && _pickedFile != null) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String fileName = _pickedFile!.path.split('/').last;
          String filePath = 'eco_advocate_applications/${user.uid}/$fileName';
          UploadTask uploadTask = FirebaseStorage.instance
              .ref()
              .child(filePath)
              .putFile(_pickedFile!);

          TaskSnapshot taskSnapshot = await uploadTask;
          String downloadUrl = await taskSnapshot.ref.getDownloadURL();

          await UserService().addEcoAdvocateApplication(
            user.uid,
            user.email!,
            user.displayName!,
            _applicationTextController.text,
            downloadUrl, // Pass the download URL as a string
          );

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Application submitted successfully'),
          ));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to submit application'),
        ));
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all fields and select a PDF'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco Advocate Application'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _applicationTextController,
                decoration: const InputDecoration(labelText: 'Reason for applying'),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(_fileName),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Attach PDF'),
              ),
              const SizedBox(height: 20),
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitApplication,
                      child: const Text('Submit Application'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
