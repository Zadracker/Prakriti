import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prakriti/android_screens/an_authentication/an_signup_screen.dart';
import 'package:prakriti/android_screens/an_scaffold.dart';
import 'package:prakriti/services/auth_service.dart';
import 'package:prakriti/services/points_service.dart'; // Import PointsService

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final PointsService _pointsService = PointsService(); // Initialize PointsService
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  Future<void> _signInWithEmailAndPassword() async {
    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      UserCredential? userCredential = await _authService.signInWithEmailAndPassword(email, password);

      if (userCredential?.user != null) {
        User user = userCredential!.user!;
        
        // Check if email is verified
        if (!user.emailVerified) {
          setState(() {
            _errorMessage = 'Please verify your email before logging in.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage)),
          );
          return;
        }

        await _navigateToHome(user.uid);
      } else {
        setState(() {
          _errorMessage = 'Incorrect email or password.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage)),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    }
  }

  Future<void> _navigateToHome(String uid) async {
    try {
      int userPoints = await _pointsService.getUserPoints(uid);
      String? profileImageUrl = await _getProfileImageUrl(uid);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppScaffold(
            currentIndex: 0,
            userPoints: userPoints,
            profileImageUrl: profileImageUrl ?? '', // Provide default empty string if null
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user details. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    }
  }

  Future<String?> _getProfileImageUrl(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return userDoc.data()?['profileImageUrl'];
    } catch (e) {
      return null;
    }
  }

  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent. Please check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send password reset email. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        automaticallyImplyLeading: false, // Prevents the back button from showing
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signInWithEmailAndPassword,
              child: const Text('Login'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupPage()),
                );
              },
              child: const Text('Sign Up'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _resetPassword,
              child: const Text('Forgot Password'),
            ),
          ],
        ),
      ),
    );
  }
}
