import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:prakriti/services/eco_camera_services.dart';
import 'package:prakriti/theme.dart'; // Importing the theme file to access custom theme colors

// Stateful widget for the Scan Page, which allows users to take a picture or select an image and submit it for processing
class ScanPage extends StatefulWidget {
  final String prompt; // The prompt provided by the user, passed as a required parameter

  const ScanPage({super.key, required this.prompt});

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker _picker = ImagePicker(); // ImagePicker instance to handle image selection
  File? _imageFile; // To store the selected image file
  String? _geminiOutput; // To store the output from the Gemini AI service
  bool _isLoading = false; // State variable to track if a submission is in progress (loading status)
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    // Calculate button widths based on the screen width
    final buttonWidth = MediaQuery.of(context).size.width * 0.4; // 40% of screen width for the smaller buttons
    final scanButtonWidth = MediaQuery.of(context).size.width * 0.9; // 90% of screen width for the "Scan" button

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Scan Page'), // AppBar with a simple title
      ),
      body: Center(
        child: SingleChildScrollView( // Allows content to scroll if it overflows the screen height
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Display the selected image or a placeholder text if no image is selected
              _imageFile != null
                  ? Image.file(
                      _imageFile!,
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.5,
                      fit: BoxFit.contain,
                    )
                  : const Text('No image selected.'),
              const SizedBox(height: 16.0), // Spacing between elements
              // Row containing the "Take Picture" and "Gallery" buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSquareButton(
                    Icons.camera_alt,
                    'Take Picture',
                    () => _pickImage(ImageSource.camera), // Open the camera to take a picture
                    buttonWidth,
                  ),
                  const SizedBox(width: 16.0), // Space between the buttons
                  _buildSquareButton(
                    Icons.photo_library,
                    'Gallery',
                    () => _pickImage(ImageSource.gallery), // Open the gallery to select an image
                    buttonWidth,
                  ),
                ],
              ),
              const SizedBox(height: 16.0), // Spacing between the buttons and the submit button
              _buildSubmitButton(scanButtonWidth), // "Scan" button for submitting the image
              const SizedBox(height: 24.0), // Extra spacing before showing the loading indicator or output
              // Show a loading indicator while waiting for Gemini AI's response
              _isLoading
                  ? const LinearProgressIndicator()
                  : const SizedBox.shrink(),
              const SizedBox(height: 24.0), // Spacing between the loading indicator and the output
              // Display the output from Gemini AI, if available
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

  // Helper method to build square-shaped buttons for "Take Picture" and "Gallery"
  Widget _buildSquareButton(IconData icon, String label, VoidCallback onPressed, double width) {
    return SizedBox(
      width: width,
      height: 100.0, // Fixed height to match the design
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // Rounded corners for the button
          ),
          padding: const EdgeInsets.all(16.0),
          backgroundColor: AppTheme.darkAccentColor, // Use custom theme color for the button background
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36.0, color: Colors.white), // Icon inside the button
            const SizedBox(height: 8.0), // Spacing between icon and text
            Text(
              label,
              style: const TextStyle(color: Colors.white), // Button label text
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the "Scan" button, used to submit the selected image
  Widget _buildSubmitButton(double width) {
    return SizedBox(
      width: width,
      height: 50.0, // Consistent height with other buttons for a uniform look
      child: ElevatedButton(
        onPressed: _imageFile != null ? () => _submitToGemini(widget.prompt) : null, // Disable button if no image is selected
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // Rounded corners for the button
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          backgroundColor: AppTheme.darkAccentColor, // Use custom theme color for the button background
        ),
        child: const Text(
          'Scan',
          style: TextStyle(color: Colors.white), // Button label text
        ),
      ),
    );
  }

  // Method to handle image picking from either camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source); // Pick an image using the specified source
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Store the selected image
        _geminiOutput = null;  // Reset Gemini output when a new image is selected
      });
    }
  }

  // Method to submit the selected image to Gemini AI for processing
  void _submitToGemini(String prompt) async {
    setState(() {
      _isLoading = true; // Show the loading indicator when starting the submission
    });

    final result = await submitImageToGemini(_imageFile, prompt); // Call the service to submit the image
    setState(() {
      _geminiOutput = result.output; // Store the result output
      _isLoading = false; // Hide the loading indicator after receiving the result
    });
  }
}
