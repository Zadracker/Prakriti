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

class AnSettings extends StatefulWidget {
  const AnSettings({super.key});

  @override
  _AnSettingsState createState() => _AnSettingsState();
}

class _AnSettingsState extends State<AnSettings> {
  User? _user;
  String? _profileImageUrl;
  String? _userRole;
  String? _userId;

  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  ProfileService? _profileService;
  final ShopService _shopService = ShopService();

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> userDoc = await _userService.getUser(_user!.uid);

        String? userRole = userDoc.data()?['role'];

        String? profileImageUrl;

        if (userRole != null) {
          if (userRole == UserService.ECO_ADVOCATE) {
            profileImageUrl = userDoc.data()?['profileImageUrl'];
          } else {
            DocumentSnapshot<Map<String, dynamic>> profileDoc = await FirebaseFirestore.instance
                .collection('profiles')
                .doc(_user!.uid)
                .get();

            profileImageUrl = profileDoc.data()?['profile_image'];
          }
        }

        setState(() {
          _profileImageUrl = profileImageUrl;
          _userRole = userRole;
          _userId = _user!.uid;
          _profileService = ProfileService(userId: _userId!);
        });
      } catch (e) {
      }
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        File file = File(image.path);
        String downloadUrl = await _userService.uploadEcoAdvocateProfileImage(_user!.uid, file);
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
          'profileImageUrl': downloadUrl,
        });
        setState(() {
          _profileImageUrl = downloadUrl;
        });
      }
    } catch (e) {
    }
  }

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
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      await _authService.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  void _handleProfileImageTap() {
    if (_userRole == UserService.ECO_ADVOCATE) {
      _pickAndUploadProfileImage();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileCardEdit(
            profileService: _profileService!,
            shopService: _shopService,
          ),
        ),
      );
    }
  }

  Future<void> _copyUserIdToClipboard() async {
    if (_userId != null) {
      await Clipboard.setData(ClipboardData(text: _userId!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID copied to clipboard!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No User ID to copy.'),
        ),
      );
    }
  }

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
        title: const Text('Settings'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _handleProfileImageTap,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImageUrl != null
                            ? (_userRole == UserService.ECO_ADVOCATE
                                ? NetworkImage(_profileImageUrl!)
                                : AssetImage(_profileImageUrl!))
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
                      _user?.displayName ?? 'User',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _user?.uid ?? 'User ID',
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _copyUserIdToClipboard,
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
                    );
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
                  );
                },
              ),
              if (_userRole != UserService.ECO_ADVOCATE) ...[
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Planet Pals'),
                  onTap: _navigateToPlanetPals,
                ),
                ListTile(
                  leading: const Icon(Icons.celebration),
                  title: const Text('Achievements'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AchievementsPage()),
                    );
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text('Credits', style: TextStyle(color: Colors.blue)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreditsPage()), // Navigate to CreditsPage
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: _showLogoutConfirmation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
