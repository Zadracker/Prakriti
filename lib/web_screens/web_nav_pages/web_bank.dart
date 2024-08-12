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
  final UserService _userService = UserService();
  final PointsService _pointsService = PointsService();
  final TextEditingController _redeemCodeController = TextEditingController();

  @override
  void dispose() {
    _redeemCodeController.dispose();
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
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large card with image
              GestureDetector(
                onTap: () => _showSupportPopup(context),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 300,
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
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Buy more eco-points section
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

              // Row for eco-points cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildImageCard(
                      context, 
                      'lib/assets/Bank/eco_points_1.png', 
                      'Buy 100 Eco-Points', 
                      100,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageCard(
                      context, 
                      'lib/assets/Bank/eco_points_2.png', 
                      'Buy 500 Eco-Points', 
                      500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageCard(
                      context, 
                      'lib/assets/Bank/eco_points_3.png', 
                      'Buy 2000 Eco-Points', 
                      2000,
                    ),
                  ),
                ],
              ),

              // Redeem code section
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: TextField(
                            controller: _redeemCodeController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Enter your code',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _redeemCode,
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

  // Builds a card for eco-points purchase
  Widget _buildImageCard(BuildContext context, String imagePath, String text, int ecoPoints) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () async {
          try {
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              int currentCoins = await _userService.getUserEnviroCoins(user.uid);
              await _userService.updateEnviroCoins(user.uid, currentCoins + ecoPoints);
              _showSupportPopup(context);
            } else {
              _showErrorPopup(context, 'User not logged in');
            }
          } catch (e) {
            _showErrorPopup(context, 'Error updating Eco-Points: $e');
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Container(
                width: double.infinity,
                height: 180,
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
              width: double.infinity,
              child: Text(
                text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Redeem code logic
  void _redeemCode() async {
    String code = _redeemCodeController.text.trim();

    if (code.isEmpty) {
      _showSnackbar('Please enter a code');
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _pointsService.redeemSecretCode(user.uid, code);
        _showSnackbar('Code redeemed successfully!');
      } else {
        _showErrorPopup(context, 'User not logged in');
      }
    } catch (e) {
      _showErrorPopup(context, 'Error redeeming code: $e');
    }
  }

  // Show support popup
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show error popup
  void _showErrorPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show snackbar message
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
