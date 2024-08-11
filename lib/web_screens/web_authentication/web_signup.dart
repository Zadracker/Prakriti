import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prakriti/services/auth_service.dart';
import 'package:prakriti/web_screens/web_authentication/web_login.dart';

class WebSignup extends StatefulWidget {
  const WebSignup({super.key});

  @override
  _WebSignupState createState() => _WebSignupState();
}

class _WebSignupState extends State<WebSignup> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  File? _profileImage;


  Future<void> _signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password should be longer than 5 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential? user = await _authService.signUpWithEmailAndPassword(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _profileImage,
      );

      if (user != null) {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await _authService.sendEmailVerification(currentUser);
        }
        setState(() {
          _errorMessage = 'Check your email for a verification message';
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WebLogin()),
        );
      } else {
        setState(() {
          _errorMessage = 'Signup failed. Please try again.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unknown error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Form Card
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade800,
              padding: const EdgeInsets.all(32),
              child: FractionallySizedBox(
                widthFactor: 1.0, // Full width
                heightFactor: 1.0, // Full height
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Username'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(labelText: 'Confirm Password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 32),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _signup,
                              child: const Text('Sign Up'),
                            ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const WebLogin()),
                          );
                        },
                        child: const Text('Return to login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Image Card
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('lib/assets/signup_image.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.9),
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  'WELCOME!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
