import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:prakriti/services/eco_camera_services.dart';
import 'package:prakriti/theme.dart';
// Import the new service

class ScanPage extends StatefulWidget {
  final String prompt;

  const ScanPage({super.key, required this.prompt});

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _geminiOutput;
  bool _isLoading = false; // State variable for loading status
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final buttonWidth = MediaQuery.of(context).size.width * 0.4; // 40% of screen width for buttons
    final scanButtonWidth = MediaQuery.of(context).size.width * 0.9; // 90% of screen width for "Scan" button

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Scan Page'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _imageFile != null
                  ? Image.file(
                      _imageFile!,
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.5,
                      fit: BoxFit.contain,
                    )
                  : const Text('No image selected.'),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSquareButton(
                    Icons.camera_alt,
                    'Take Picture',
                    () => _pickImage(ImageSource.camera),
                    buttonWidth,
                  ),
                  const SizedBox(width: 16.0),
                  _buildSquareButton(
                    Icons.photo_library,
                    'Gallery',
                    () => _pickImage(ImageSource.gallery),
                    buttonWidth,
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildSubmitButton(scanButtonWidth),
              const SizedBox(height: 24.0), // Separation between buttons and output
              _isLoading
                  ? const LinearProgressIndicator() // Show loading indicator
                  : const SizedBox.shrink(),
              const SizedBox(height: 24.0),
              _geminiOutput != null
                  ? Text(
                      'Gemini Output:\n$_geminiOutput',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18.0),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareButton(IconData icon, String label, VoidCallback onPressed, double width) {
    return SizedBox(
      width: width,
      height: 100.0, // Fixed height to align with the submit button
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.all(16.0),
          backgroundColor: AppTheme.darkAccentColor, // Use theme color
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36.0, color: Colors.white),
            const SizedBox(height: 8.0),
            Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(double width) {
    return SizedBox(
      width: width,
      height: 50.0, // Consistent height with the other buttons
      child: ElevatedButton(
        onPressed: _imageFile != null ? () => _submitToGemini(widget.prompt) : null,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          backgroundColor: AppTheme.darkAccentColor, // Use theme color
        ),
        child: const Text(
          'Scan',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _geminiOutput = null;  // Reset Gemini output when a new image is selected
      });
    }
  }

  void _submitToGemini(String prompt) async {
    setState(() {
      _isLoading = true; // Set loading to true when starting the request
    });

    final result = await submitImageToGemini(_imageFile, prompt);
    setState(() {
      _geminiOutput = result.output;
      _isLoading = false; // Set loading to false when response is received
    });
  }
}
