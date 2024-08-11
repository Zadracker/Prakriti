import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:prakriti/services/shop_service.dart';
import 'package:prakriti/web_screens/landing_page.dart';
import 'package:provider/provider.dart'; // Import provider package
import 'package:prakriti/services/points_service.dart'; // Import PointsService
import 'package:prakriti/services/user_service.dart'; // Import UserService
import 'package:prakriti/android_screens/an_authentication/an_login_screen.dart';
import 'package:prakriti/web_screens/web_scaffold.dart';
import 'package:prakriti/manage_applications.dart';
import 'package:prakriti/android_screens/an_scaffold.dart';
import 'firebase_options.dart'; // Ensure this is imported
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:prakriti/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use firebase_options.dart
  );
  
  await dotenv.load(fileName: ".env");

  // Locking the orientation to portrait up
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    MultiProvider(
      providers: [
        Provider<ShopService>(create: (_) => ShopService()),
        Provider<PointsService>(create: (_) => PointsService()), // Provide PointsService
        Provider<UserService>(create: (_) => UserService()), // Provide UserService
        Provider<FirebaseAuth>(create: (_) => FirebaseAuth.instance)
        // Add other providers here if needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prakriti',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return userDoc.data()?['role'];
    } catch (e) {
      return null;
    }
  }

  Future<String?> getUserProfileImage(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return userDoc.data()?['profileImageUrl'];
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData) {
          if (kIsWeb) {
            return const WebScaffold(); // Navigate to WebScaffold if user is logged in on web
          } else {
            return Consumer<UserService>(
              builder: (context, userService, child) {
                return FutureBuilder<String?>(
                  future: getUserRole(snapshot.data!.uid),
                  builder: (context, roleSnapshot) {
                    if (roleSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (roleSnapshot.hasData) {
                      String? role = roleSnapshot.data;
                      if (role == 'admin') {
                        return const ManageApplicationsPage();
                      } else {
                        return Consumer<PointsService>(
                          builder: (context, pointsService, child) {
                            return FutureBuilder<int>(
                              future: pointsService.getUserPoints(snapshot.data!.uid),
                              builder: (context, pointsSnapshot) {
                                if (pointsSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Scaffold(
                                    body: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                } else if (pointsSnapshot.hasData) {
                                  int userPoints = pointsSnapshot.data!;
                                  if (Platform.isAndroid) {
                                    return FutureBuilder<String?>(
                                      future: getUserProfileImage(snapshot.data!.uid),
                                      builder: (context, profileImageSnapshot) {
                                        if (profileImageSnapshot.connectionState == ConnectionState.waiting) {
                                          return const Scaffold(
                                            body: Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          );
                                        } else {
                                          return AppScaffold(
                                            currentIndex: 0,
                                            userPoints: userPoints,
                                            profileImageUrl: profileImageSnapshot.data ?? '',
                                          );
                                        }
                                      },
                                    );
                                  } else {
                                    return const Scaffold(
                                      body: Center(
                                        child: Text('This platform is not supported'),
                                      ),
                                    );
                                  }
                                } else {
                                  return const Scaffold(
                                    body: Center(
                                      child: Text('Error fetching user points'),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      }
                    } else {
                      // Handle error fetching user role by redirecting to the login page
                      return const LoginPage();
                    }
                  },
                );
              },
            );
          }
        } else {
          return kIsWeb ? const LandingPage() : const LoginPage(); // Navigate to LoginPage if user is not logged in
        }
      },
    );
  }
}
