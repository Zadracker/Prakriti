import 'package:flutter/material.dart';
import 'package:prakriti/services/auth_service.dart';
import 'package:prakriti/web_screens/web_authentication/web_login.dart';

class PasswordReset extends StatefulWidget {
  const PasswordReset({super.key});

  @override
  _PasswordResetState createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _sendPasswordResetEmail() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      setState(() {
        _message = 'Password reset email sent. Please check your inbox.';
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to send password reset email. Please try again.';
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 24),
              _message != null
                  ? Text(
                      _message!,
                      style: const TextStyle(color: Colors.green),
                    )
                  : Container(),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _sendPasswordResetEmail,
                      child: const Text('Send Password Reset Email'),
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
    );
  }
}
