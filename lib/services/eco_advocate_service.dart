import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class EcoAdvocateService {
  Future<void> submitApplication(String reason, PlatformFile pickedFile) async {
    if (pickedFile.bytes == null) {
      throw Exception('No file selected');
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Upload file to Firebase Storage
      final fileRef = FirebaseStorage.instance
          .ref()
          .child('eco_advocate_applications')
          .child(user.uid)
          .child(pickedFile.name);
      await fileRef.putData(pickedFile.bytes!);

      final fileUrl = await fileRef.getDownloadURL();

      // Save application data to Firestore
      await FirebaseFirestore.instance
          .collection('eco_advocate_applications')
          .doc(user.uid)
          .set({
        'username': user.displayName ?? user.email!.split('@')[0],
        'email': user.email,
        'application_text': reason,
        'documents': fileUrl,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }
}
