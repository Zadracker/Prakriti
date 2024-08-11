import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart'; // Import for clipboard functionality

import 'package:prakriti/commons/credits.dart';
import 'package:prakriti/commons/profile_card_edit.dart';
import 'package:prakriti/commons/accessibility_menu.dart';
import 'package:prakriti/commons/achievements.dart';
import 'package:prakriti/commons/friends.dart';
import 'package:prakriti/services/auth_service.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/services/accessibility_preferences_service.dart';
import 'package:prakriti/web_screens/web_settings/web_eco_advocate_form.dart';
import 'package:prakriti/web_screens/web_authentication/web_login.dart';
import 'package:prakriti/services/profile_service.dart';
import 'package:prakriti/services/shop_service.dart';

class WebSettings extends StatefulWidget {
  const WebSettings({super.key});

  @override
  _WebSettingsState createState() => _WebSettingsState();
}

class _WebSettingsState extends State<WebSettings> {
  User? _user;
  String? _profileImageUrl;
  String? _userRole;
  String? _userId;
  int _fontSize = 1;
  String _font = 'OpenSans';
  bool _readAloud = false;
  final FlutterTts _flutterTts = FlutterTts();

  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final AccessibilityPreferencesService _preferencesService = AccessibilityPreferencesService();
  ProfileService? _profileService;
  final ShopService _shopService = ShopService();

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadUserData();
    _loadUserPreferences();
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

  Future<void> _loadUserPreferences() async {
    if (_user != null) {
      final preferences = await _preferencesService.getUserPreferences(_user!.uid);
      setState(() {
        _fontSize = preferences['fontSize'] ?? 1;
        _font = preferences['font'] ?? 'OpenSans';
        _readAloud = preferences['readAloud'] ?? false;
      });
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.bytes != null) {
        Uint8List fileBytes = result.files.single.bytes!;

        String downloadUrl = await _userService.uploadEcoAdvocateProfileImage(_user!.uid, fileBytes);
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
        MaterialPageRoute(builder: (context) => const WebLogin()),
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

  void _speak(String text) async {
    if (_readAloud) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    double textSize(double size) {
      switch (_fontSize) {
        case 2:
          return size * 2;
        case 3:
          return size * 3;
        default:
          return size;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.all(textSize(16.0)),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _handleProfileImageTap,
                    child: CircleAvatar(
                      radius: textSize(50),
                      backgroundImage: _profileImageUrl != null
                          ? (_userRole == UserService.ECO_ADVOCATE
                              ? NetworkImage(_profileImageUrl!)
                              : AssetImage(_profileImageUrl!) as ImageProvider)
                          : null,
                      child: _profileImageUrl == null
                          ? Icon(
                              Icons.account_circle,
                              size: textSize(100),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: textSize(10)),
                  MouseRegion(
                    onEnter: (_) => _speak('User'),
                    child: Text(
                      _user?.displayName ?? 'User',
                      style: TextStyle(
                        fontSize: textSize(16),
                        fontFamily: _font,
                      ),
                    ),
                  ),
                  SizedBox(height: textSize(10)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _userId ?? 'User ID',
                        style: TextStyle(
                          fontSize: textSize(14),
                          fontFamily: _font,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(_userId ?? ''),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: textSize(20)),
            if (_userRole == 'member') ...[
              ListTile(
                leading: Icon(Icons.person_add, size: textSize(24)),
                title: MouseRegion(
                  onEnter: (_) => _speak('Submit Eco Advocate Application'),
                  child: Text(
                    'Submit Eco Advocate Application',
                    style: TextStyle(
                      fontSize: textSize(16),
                      fontFamily: _font,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WebEcoAdvocateForm()),
                  );
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.accessibility_new, size: textSize(24)),
              title: MouseRegion(
                onEnter: (_) => _speak('Accessibility Settings'),
                child: Text(
                  'Accessibility Settings',
                  style: TextStyle(
                    fontSize: textSize(16),
                    fontFamily: _font,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccessibilityMenu()),
                );
              },
            ),
            if (_userRole != UserService.ECO_ADVOCATE) ...[
              ListTile(
                leading: Icon(Icons.group, size: textSize(24)),
                title: MouseRegion(
                  onEnter: (_) => _speak('Planet Pals'),
                  child: Text(
                    'Planet Pals',
                    style: TextStyle(
                      fontSize: textSize(16),
                      fontFamily: _font,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FriendsPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.celebration, size: textSize(24)),
                title: MouseRegion(
                  onEnter: (_) => _speak('Achievements'),
                  child: Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: textSize(16),
                      fontFamily: _font,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AchievementsPage()),
                  );
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.info, color: Colors.blue, size: textSize(24)),
              title: MouseRegion(
                onEnter: (_) => _speak('Credits'),
                child: Text(
                  'Credits',
                  style: TextStyle(
                    fontSize: textSize(16),
                    fontFamily: _font,
                    color: Colors.blue,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreditsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, size: textSize(24), color: Colors.red),
              title: MouseRegion(
                onEnter: (_) => _speak('Logout'),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: textSize(16),
                    fontFamily: _font,
                    color: Colors.red,
                  ),
                ),
              ),
              onTap: _showLogoutConfirmation,
            ),
          ],
        ),
      ),
    );
  }
}
