import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prakriti/android_screens/an_authentication/an_login_screen.dart';
import 'package:prakriti/android_screens/an_settings/an_eco_advocate_form.dart';
import 'package:prakriti/commons/accessibility_menu.dart';
import 'package:prakriti/commons/achievements.dart';
import 'package:prakriti/commons/friends.dart';
import 'package:prakriti/commons/profile_card_edit.dart';
import 'package:prakriti/commons/credits.dart'; // Import the CreditsPage
import 'package:prakriti/services/auth_service.dart';
import 'package:prakriti/services/profile_service.dart';
import 'package:prakriti/services/user_service.dart';
import 'dart:io';
import 'package:prakriti/services/shop_service.dart';
import 'package:flutter/services.dart'; // Import for clipboard functionality

// The AnSettings class provides a settings screen for the application.
class AnSettings extends StatefulWidget {
  const AnSettings({super.key});

  @override
  _AnSettingsState createState() => _AnSettingsState();
}

class _AnSettingsState extends State<AnSettings> {
  User? _user; // Holds the currently logged-in user
  String? _profileImageUrl; // Holds the URL of the user's profile image
  String? _userRole; // Holds the user's role (e.g., Member, Eco Advocate)
  String? _userId; // Holds the user's ID

  final UserService _userService = UserService(); // Service to handle user operations
  final AuthService _authService = AuthService(); // Service to handle authentication
  final ImagePicker _picker = ImagePicker(); // For picking images from the gallery
  ProfileService? _profileService; // Service to handle profile operations
  final ShopService _shopService = ShopService(); // Service for shop-related operations

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser; // Get the current user
    _loadUserData(); // Load user data when the widget is initialized
  }
  
  // Method to load user data from Firestore
  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        // Fetch user data from Firestore
        DocumentSnapshot<Map<String, dynamic>> userDoc = await _userService.getUser(_user!.uid);

        String? userRole = userDoc.data()?['role']; // Get the user's role

        String? profileImageUrl;

        if (userRole != null) {
          // If the user is an Eco Advocate, fetch their profile image URL
          if (userRole == UserService.ECO_ADVOCATE) {
            profileImageUrl = userDoc.data()?['profileImageUrl'];
          } else {
            // For other roles, fetch the profile image from the 'profiles' collection
            DocumentSnapshot<Map<String, dynamic>> profileDoc = await FirebaseFirestore.instance
                .collection('profiles')
                .doc(_user!.uid)
                .get();

            profileImageUrl = profileDoc.data()?['profile_image'];
          }
        }

        setState(() {
          _profileImageUrl = profileImageUrl; // Update the profile image URL
          _userRole = userRole; // Update the user's role
          _userId = _user!.uid; // Update the user ID
          _profileService = ProfileService(userId: _userId!); // Initialize ProfileService
        });
      } catch (e) {
        // Handle any errors that occur while loading user data
      }
    }
  }

  // Method to pick an image and upload it as the profile image
  Future<void> _pickAndUploadProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        File file = File(image.path); // Convert the picked image to a File
        String downloadUrl = await _userService.uploadEcoAdvocateProfileImage(_user!.uid, file); // Upload the image and get the download URL
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
          'profileImageUrl': downloadUrl, // Update the user's profile image URL in Firestore
        });
        setState(() {
          _profileImageUrl = downloadUrl; // Update the profile image URL state
        });
      }
    } catch (e) {
      // Handle any errors that occur while picking or uploading the image
    }
  }

  // Method to show a confirmation dialog for logout
  Future<void> _showLogoutConfirmation() async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: const Text('No', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(false); // Dismiss the dialog with a 'No' response
              },
            ),
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true); // Dismiss the dialog with a 'Yes' response
              },
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      await _authService.signOut(); // Sign out the user
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to the login page
      );
    }
  }

  // Method to handle profile image tap based on user role
  void _handleProfileImageTap() {
    if (_userRole == UserService.ECO_ADVOCATE) {
      _pickAndUploadProfileImage(); // Allow Eco Advocates to pick and upload a new profile image
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileCardEdit(
            profileService: _profileService!,
            shopService: _shopService,
          ),
        ),
      ); // Navigate to the ProfileCardEdit page for other roles
    }
  }

  // Method to copy the user ID to the clipboard
  Future<void> _copyUserIdToClipboard() async {
    if (_userId != null) {
      await Clipboard.setData(ClipboardData(text: _userId!)); // Copy user ID to clipboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID copied to clipboard!'), // Show confirmation message
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No User ID to copy.'), // Show error message if no user ID
        ),
      );
    }
  }

  // Method to navigate to the Planet Pals page
  void _navigateToPlanetPals() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FriendsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'), // App bar title
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData, // Refresh user data when pulled down
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _handleProfileImageTap, // Handle profile image tap
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImageUrl != null
                            ? (_userRole == UserService.ECO_ADVOCATE
                                ? NetworkImage(_profileImageUrl!) // Use network image for Eco Advocates
                                : AssetImage(_profileImageUrl!) // Use asset image for other roles
                            )
                            : null,
                        child: _profileImageUrl == null
                            ? const Icon(
                                Icons.account_circle,
                                size: 100,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _user?.displayName ?? 'User', // Display user name or 'User' if not available
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _user?.uid ?? 'User ID', // Display user ID or 'User ID' if not available
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _copyUserIdToClipboard, // Copy user ID to clipboard on button press
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_userRole == UserService.MEMBER) ...[
                ListTile(
                  leading: const Icon(Icons.app_registration),
                  title: const Text('Eco-Advocate Application'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnEcoAdvocateForm()),
                    ); // Navigate to the Eco-Advocate application form for members
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.accessibility),
                title: const Text('Accessibility Settings'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AccessibilityMenu()),
                  ); // Navigate to the Accessibility Settings page
                },
              ),
              if (_userRole != UserService.ECO_ADVOCATE) ...[
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Planet Pals'),
                  onTap: _navigateToPlanetPals, // Navigate to the Planet Pals page
                ),
                ListTile(
                  leading: const Icon(Icons.celebration),
                  title: const Text('Achievements'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AchievementsPage()),
                    ); // Navigate to the Achievements page
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text('Credits', style: TextStyle(color: Colors.blue)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreditsPage()), // Navigate to the Credits page
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: _showLogoutConfirmation, // Show logout confirmation dialog
              ),
            ],
          ),
        ),
      ),
    );
  }
}
