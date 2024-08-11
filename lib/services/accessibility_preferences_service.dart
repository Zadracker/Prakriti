import 'package:cloud_firestore/cloud_firestore.dart';

class AccessibilityPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserPreferences(String userId, String font, int fontSize, bool readAloud) async {
    try {
      await _firestore.collection('user_preferences').doc(userId).set({
        'font': font,
        'fontSize': fontSize,
        'readAloud': readAloud,
      });
    } catch (e) {
    }
  }

  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await _firestore.collection('user_preferences').doc(userId).get();

      if (docSnapshot.exists) {
        return {
          'font': docSnapshot.data()?['font'] ?? 'OpenSans',
          'fontSize': docSnapshot.data()?['fontSize'] ?? 1,
          'readAloud': docSnapshot.data()?['readAloud'] ?? false,
        };
      } else {
        // Return default preferences if none are found
        return {
          'font': 'OpenSans',
          'fontSize': 1,
          'readAloud': false,
        };
      }
    } catch (e) {
      // Return default preferences in case of error
      return {
        'font': 'OpenSans',
        'fontSize': 1,
        'readAloud': false,
      };
    }
  }
}
