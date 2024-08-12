import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prakriti/android_screens/an_authentication/an_signup_screen.dart';
import 'package:prakriti/android_screens/an_scaffold.dart';
import 'package:prakriti/services/auth_service.dart';
import 'package:prakriti/services/points_service.dart'; // Import PointsService to handle user points

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Initialize the AuthService to handle authentication tasks
  final AuthService _authService = AuthService();

  // Initialize PointsService to retrieve user points after login
  final PointsService _pointsService = PointsService(); 

  // Controllers to manage email and password input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variable to store error messages
  String _errorMessage = '';

  // Function to handle user sign-in with email and password
  Future<void> _signInWithEmailAndPassword() async {
    try {
      // Retrieve email and password from the input fields
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      // Attempt to sign in the user using the AuthService
      UserCredential? userCredential = await _authService.signInWithEmailAndPassword(email, password);

      if (userCredential?.user != null) {
        User user = userCredential!.user!;
        
        // Check if the user's email is verified
        if (!user.emailVerified) {
          setState(() {
            _errorMessage = 'Please verify your email before logging in.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage)),
          );
          return; // Exit the function if email is not verified
        }

        // If email is verified, navigate to the home screen
        await _navigateToHome(user.uid);
      } else {
        // Handle incorrect email or password
        setState(() {
          _errorMessage = 'Incorrect email or password.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage)),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication errors
      setState(() {
        _errorMessage = e.message ?? 'An error occurred. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    } catch (e) {
      // Handle any other errors
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    }
  }

  // Function to navigate to the home screen after successful login
  Future<void> _navigateToHome(String uid) async {
    try {
      // Retrieve user points using PointsService
      int userPoints = await _pointsService.getUserPoints(uid);

      // Retrieve the user's profile image URL from Firestore
      String? profileImageUrl = await _getProfileImageUrl(uid);

      // Navigate to the main application scaffold
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppScaffold(
            currentIndex: 0,
            userPoints: userPoints,
            profileImageUrl: profileImageUrl ?? '', // Provide a default empty string if the profile image URL is null
          ),
        ),
      );
    } catch (e) {
      // Handle errors that occur during navigation or data retrieval
      setState(() {
        _errorMessage = 'Failed to load user details. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    }
  }

  // Function to get the profile image URL from Firestore
  Future<String?> _getProfileImageUrl(String uid) async {
    try {
      // Fetch user document from Firestore based on user ID (uid)
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return userDoc.data()?['profileImageUrl']; // Return the profile image URL if it exists
    } catch (e) {
      return null; // Return null if there's an error
    }
  }

  // Function to handle password reset via email
  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      // Show a message if the email field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return; // Exit the function if no email is provided
    }

    try {
      // Send a password reset email using AuthService
      await _authService.sendPasswordResetEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent. Please check your inbox.')),
      );
    } catch (e) {
      // Handle errors during the password reset process
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
              obscureText: true, // Hides the password text for security
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signInWithEmailAndPassword, // Trigger the sign-in function
              child: const Text('Login'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the sign-up screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupPage()),
                );
              },
              child: const Text('Sign Up'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _resetPassword, // Trigger the password reset function
              child: const Text('Forgot Password'),
            ),
          ],
        ),
      ),
    );
  }
}
