import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/android_screens/an_authentication/an_login_screen.dart';
import 'package:prakriti/services/auth_service.dart';

/// SignupPage is a stateful widget that allows users to create a new account.
/// It handles user input, form validation, and Firebase authentication for sign-up.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // AuthService instance to handle Firebase authentication logic
  final AuthService _authService = AuthService();

  // TextEditingController instances to manage user input for each form field
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// _signUp is an asynchronous function that handles the sign-up process.
  /// It validates user input, creates a new user in Firebase, and sends an email verification.
  Future<void> _signUp() async {
    // Get user input and trim any extra spaces
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // Check if any of the fields are empty
    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog('Please fill all fields.');
      return;
    }

    // Check if the password length is greater than 5 characters
    if (password.length <= 5) {
      _showErrorDialog('Password should be longer than 5 characters.');
      return;
    }

    // Check if password and confirm password match
    if (password != confirmPassword) {
      _showErrorDialog('Passwords do not match.');
      return;
    }

    try {
      // Attempt to sign up the user with Firebase Authentication
      UserCredential? userCredential = await _authService.signUpWithEmailAndPassword(
        username, 
        email, 
        password, 
        null,
      );

      // If the sign-up is successful, get the current user
      User? user = userCredential?.user;

      if (user != null) {
        // Send an email verification link to the user's email address
        await _authService.sendEmailVerification(user);

        // Show a dialog informing the user that a verification link has been sent
        _showInfoDialog('An email verification link has been sent to your email address. Please verify your email and then log in.');
      } else {
        // Handle the case where the user is null (unlikely but possible)
        _showErrorDialog('An unknown error occurred. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific exceptions and display the error message
      _showErrorDialog(e.message ?? 'An error occurred. Please try again.');
    } catch (e) {
      // Handle any other exceptions that may occur
      _showErrorDialog('An error occurred. Please try again.');
    }
  }

  /// _showErrorDialog displays an error message in a dialog box.
  /// This is used to inform the user of any issues during the sign-up process.
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  /// _showInfoDialog displays an informational message in a dialog box.
  /// This is used to inform the user that they need to verify their email.
  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Info'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                _authService.signOut(); // Sign out the user after showing the info dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()), // Redirect to the login page
                  (Route<dynamic> route) => false, // Remove all previous routes from the stack
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        leading: const SizedBox.shrink(), // Remove the back button to prevent users from navigating back
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Username input field
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              // Email input field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              // Password input field (obscured text)
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              // Confirm password input field (obscured text)
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              // Sign Up button
              ElevatedButton(
                onPressed: _signUp, // Trigger the sign-up process when pressed
                child: const Text('Sign Up'),
              ),
              const SizedBox(height: 16.0),
              // Button to navigate back to the login page
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()), // Redirect to the login page
                    (Route<dynamic> route) => false, // Remove all previous routes from the stack
                  );
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
