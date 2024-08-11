import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/services/points_service.dart'; // Import PointsService

class AnBankPage extends StatefulWidget {
  const AnBankPage({super.key});

  @override
  _AnBankPageState createState() => _AnBankPageState();
}

class _AnBankPageState extends State<AnBankPage> {
  final UserService _userService = UserService();
  final PointsService _pointsService = PointsService(); // Instantiate PointsService
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopCard(),
            _buildSupportSection(),
            _buildEcoPointsList(),
            _buildRedeemCodeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCard() {
    return GestureDetector(
      onTap: () => _showSupportPopup(context),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Container(
          width: double.infinity,
          height: 200,
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
                    fontSize: 16,
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
    );
  }

  Widget _buildSupportSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        'Buy more Eco-Points! Support us!!',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEcoPointsList() {
    return Container(
      height: 200,
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildImageCard('lib/assets/Bank/eco_points_1.png', 'Buy 100 Eco-Points', 100),
          const SizedBox(width: 16),
          _buildImageCard('lib/assets/Bank/eco_points_2.png', 'Buy 500 Eco-Points', 500),
          const SizedBox(width: 16),
          _buildImageCard('lib/assets/Bank/eco_points_3.png', 'Buy 2000 Eco-Points', 2000),
        ],
      ),
    );
  }

  Widget _buildRedeemCodeSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Redeem Code',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _redeemCodeController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Enter your code',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _redeemCode,
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String imagePath, String text, int ecoPoints) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.6,
      child: GestureDetector(
        onTap: () => _buyEcoPoints(ecoPoints),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Container(
                width: double.infinity,
                height: 120,
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
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyEcoPoints(int ecoPoints) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        int currentCoins = await _userService.getUserEnviroCoins(user.uid);
        await _userService.updateEnviroCoins(user.uid, currentCoins + ecoPoints);
        _showSupportPopup(context);
      } else {
        _showRoleBasedSnackbar('User not logged in');
      }
    } catch (e) {
      _showRoleBasedSnackbar('Error updating Eco-Points: $e');
    }
  }

  Future<void> _redeemCode() async {
    String code = _redeemCodeController.text.trim();

    if (code.isEmpty) {
      _showRoleBasedSnackbar('Please enter a code');
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _pointsService.redeemSecretCode(user.uid, code); // Call redeemSecretCode from PointsService
        _showRoleBasedSnackbar('Code Redeemed!');
      } else {
        _showRoleBasedSnackbar('User not logged in');
      }
    } catch (e) {
      _showRoleBasedSnackbar('Error redeeming code: $e');
    }
  }

  Future<void> _showRoleBasedSnackbar(String message) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? role = await _userService.getUserRole(user.uid); // Fetch user's role
      String roleMessage;

      switch (role) {
        case 'admin':
          roleMessage = 'Admin: $message';
          break;
        case 'eco_advocate':
          roleMessage = 'Eco Advocate: $message';
          break;
        case 'terra_knight':
          roleMessage = 'Terra Knight: $message';
          break;
        default:
          roleMessage = message;
          break;
      }

      _showSnackbar(roleMessage);
    } else {
      _showSnackbar(message);
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
              onPressed: () => Navigator.of(context).pop(),
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
