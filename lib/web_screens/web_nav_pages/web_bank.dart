import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/services/points_service.dart';

class WebBankPage extends StatefulWidget {
  const WebBankPage({super.key});

  @override
  _WebBankPageState createState() => _WebBankPageState();
}

class _WebBankPageState extends State<WebBankPage> {
  final UserService _userService = UserService(); // Create an instance of UserService
  final PointsService _pointsService = PointsService(); // Create an instance of PointsService
  final TextEditingController _redeemCodeController = TextEditingController(); // Controller for redeem code

  @override
  void dispose() {
    _redeemCodeController.dispose(); // Dispose of the controller when not needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0), // Fixed padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Center align column items
            children: [
              // Large card on top with image
              GestureDetector(
                onTap: () {
                  _showSupportPopup(context);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4, // Responsive width
                    height: 300, // Fixed height
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage('lib/assets/Bank/terra_knight.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Text(
                            'Become a Terra Knight!\nGet more Eco Points per level!\nGet 50% discount on Premium items!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              backgroundColor: Colors.black.withOpacity(0.5),
                            ),
                            maxLines: 3, // Ensure text fits within card
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Section: Buy more eco_points!! support us!!
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  'Buy more Eco-Points! Support us!!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Row for three square cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center align row items
                children: [
                  Expanded(
                    child: _buildImageCard(context, 'lib/assets/Bank/eco_points_1.png', 'Buy 100 Eco-Points', 100),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageCard(context, 'lib/assets/Bank/eco_points_2.png', 'Buy 500 Eco-Points', 500),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageCard(context, 'lib/assets/Bank/eco_points_3.png', 'Buy 2000 Eco-Points', 2000),
                  ),
                ],
              ),

              // Section: Redeem code
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // Center align column items
                  children: [
                    const Text(
                      'Redeem Code',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Center align row items
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6, // Responsive width
                          child: TextField(
                            controller: _redeemCodeController, // Use the controller
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Enter your code',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            _redeemCode(); // Call the method to handle code redemption
                          },
                          child: const Text('Redeem'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, String imagePath, String text, int ecoPoints) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0), // Margin to ensure spacing
      child: GestureDetector(
        onTap: () async {
          // Example logic to update Enviro-Coins
          try {
            User? user = FirebaseAuth.instance.currentUser; // Use FirebaseAuth to get the current user
            if (user != null) {
              int currentCoins = await _userService.getUserEnviroCoins(user.uid);
              await _userService.updateEnviroCoins(user.uid, currentCoins + ecoPoints);
              _showSupportPopup(context); // Show the popup after updating
            } else {
              _showErrorPopup(context, 'User not logged in');
            }
          } catch (e) {
            _showErrorPopup(context, 'Error updating Eco-Points: $e');
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center align column items
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Container(
                width: double.infinity, // Ensure full width within expanded area
                height: 180, // Fixed height
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity, // Ensures text fits within card width
              child: Text(
                text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1, // Ensure text fits within card
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center, // Center align text
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _redeemCode() async {
    String code = _redeemCodeController.text.trim();

    if (code.isEmpty) {
      _showSnackbar('Please enter a code');
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser; // Use FirebaseAuth to get the current user
      if (user != null) {
        await _pointsService.redeemSecretCode(user.uid, code); // Call the redeemSecretCode method from PointsService
        _showSnackbar('Code redeemed successfully!');
      } else {
        _showErrorPopup(context, 'User not logged in');
      }
    } catch (e) {
      _showErrorPopup(context, 'Error redeeming code: $e');
    }
  }

  void _showSupportPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thank You!'),
          content: const Text(
            'Thanks for choosing to support this project and for buying Eco-Points. '
            'However, the app is currently in testing and doesn\'t integrate Admob or other methods for accepting money. '
            'If you want to support us, star this project and let others know :)',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
