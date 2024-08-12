import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/services/auth_service.dart';
import 'package:prakriti/web_screens/landing_page.dart';
import 'package:prakriti/web_screens/web_authentication/web_signup.dart';
import 'package:prakriti/web_screens/web_authentication/web_password_reset.dart'; // Import the password reset screen
import '../web_scaffold.dart';

class WebLogin extends StatefulWidget {
  const WebLogin({super.key});

  @override
  _WebLoginState createState() => _WebLoginState();
}

class _WebLoginState extends State<WebLogin> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Handle login functionality
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sign in with email and password using AuthService
      UserCredential? userCredential = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userCredential != null) {
        User? user = userCredential.user;
        if (user != null && !user.emailVerified) {
          // Send email verification if email is not verified
          await _authService.sendEmailVerification(user);
          setState(() {
            _errorMessage = 'Please verify your email. A verification email has been sent.';
          });
          await _authService.signOut(); // Sign out the user after sending verification email
        } else {
          // Navigate to the main application screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WebScaffold()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
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
      body: Stack(
        children: [
          Row(
            children: [
              // Image Card
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage('lib/assets/login_image.jpg'),
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
              // Form Card
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.grey.shade800,
                  padding: const EdgeInsets.all(32),
                  child: FractionallySizedBox(
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
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
                          const SizedBox(height: 32),
                          _errorMessage != null
                              ? Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                )
                              : Container(),
                          const SizedBox(height: 16),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _login,
                                  child: const Text('Login'),
                                ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PasswordReset(),
                                ),
                              );
                            },
                            child: const Text('Forgot Password?'),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const WebSignup()),
                              );
                            },
                            child: const Text('Don\'t have an account? Sign up'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
