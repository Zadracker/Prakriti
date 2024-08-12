import 'package:cloud_firestore/cloud_firestore.dart';

// Service class for managing user accessibility preferences
class AccessibilityPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance for database operations

  // Saves user accessibility preferences to Firestore
  Future<void> saveUserPreferences(String userId, String font, int fontSize, bool readAloud) async {
    try {
      // Save preferences to the 'user_preferences' collection
      await _firestore.collection('user_preferences').doc(userId).set({
        'font': font,            // Font style preference
        'fontSize': fontSize,    // Font size preference
        'readAloud': readAloud,  // Read aloud preference (boolean)
      });
    } catch (e) {
      // Handle potential errors (e.g., network issues, permission errors)
      // Optionally log the error or notify the user
    }
  }

  // Retrieves user accessibility preferences from Firestore
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    try {
      // Fetch user preferences document from the 'user_preferences' collection
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await _firestore.collection('user_preferences').doc(userId).get();

      if (docSnapshot.exists) {
        // Return user preferences if document exists
        return {
          'font': docSnapshot.data()?['font'] ?? 'OpenSans', // Default font if not set
          'fontSize': docSnapshot.data()?['fontSize'] ?? 1,   // Default font size if not set
          'readAloud': docSnapshot.data()?['readAloud'] ?? false, // Default read aloud setting if not set
        };
      } else {
        // Return default preferences if document does not exist
        return {
          'font': 'OpenSans',
          'fontSize': 1,
          'readAloud': false,
        };
      }
    } catch (e) {
      // Return default preferences in case of any error
      // This ensures that the application can function with default settings
      return {
        'font': 'OpenSans',
        'fontSize': 1,
        'readAloud': false,
      };
    }
  }
}
