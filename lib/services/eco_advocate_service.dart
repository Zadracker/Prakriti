import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore database operations
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase authentication
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage operations
import 'package:file_picker/file_picker.dart'; // For file picking

// Service class to handle the submission of eco-advocate applications
class EcoAdvocateService {
  // Method to submit an eco-advocate application
  Future<void> submitApplication(String reason, PlatformFile pickedFile) async {
    // Check if a file was selected
    if (pickedFile.bytes == null) {
      throw Exception('No file selected'); // Throw an exception if no file is provided
    }

    try {
      final user = FirebaseAuth.instance.currentUser; // Get the current authenticated user
      if (user == null) throw Exception('No user logged in'); // Throw an exception if no user is logged in

      // Create a reference to the file location in Firebase Storage
      final fileRef = FirebaseStorage.instance
          .ref()
          .child('eco_advocate_applications') // Directory for applications
          .child(user.uid) // Subdirectory for the specific user
          .child(pickedFile.name); // File name

      // Upload the file to Firebase Storage
      await fileRef.putData(pickedFile.bytes!);

      // Get the download URL of the uploaded file
      final fileUrl = await fileRef.getDownloadURL();

      // Save the application data to Firestore
      await FirebaseFirestore.instance
          .collection('eco_advocate_applications') // Collection for applications
          .doc(user.uid) // Document ID is the user's UID
          .set({
        'username': user.displayName ?? user.email!.split('@')[0], // Use display name or email prefix as username
        'email': user.email, // User's email
        'application_text': reason, // Application reason
        'documents': fileUrl, // URL of the uploaded file
        'status': 'pending', // Initial status of the application
        'timestamp': FieldValue.serverTimestamp(), // Timestamp when the application was submitted
      });
    } catch (e) {
      // Handle exceptions and throw a new exception with an error message
      throw Exception('Failed to submit application: $e');
    }
  }
}
