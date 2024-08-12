import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prakriti/models/profile_assets.dart';
import 'package:prakriti/services/shop_service.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:provider/provider.dart';

// The ShopPage class represents the main shop page of the application.
class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'), // Title of the app bar
      ),
      body: const ShopContent(), // Main content of the shop page
      bottomNavigationBar: const BottomBar(), // Bottom navigation bar to show Eco-Coins
    );
  }
}

// The ShopContent class is a StatefulWidget that displays the shop content.
class ShopContent extends StatefulWidget {
  const ShopContent({super.key});

  @override
  _ShopContentState createState() => _ShopContentState();
}

class _ShopContentState extends State<ShopContent> {
  // Maps to store user assets and asset prices
  Map<String, List<String>> _userAssets = {
    'profileImages': [],
    'backgrounds': [],
  };
  Map<String, int> _assetPrices = {}; // Stores asset prices
  bool _isLoading = true; // Loading state for displaying loading indicator

  @override
  void initState() {
    super.initState();
    _initializeShop(); // Initialize shop when the widget is created
  }

  // Initializes the shop by ensuring the shop collection is set up and fetching user assets and prices
  Future<void> _initializeShop() async {
    final shopService = Provider.of<ShopService>(context, listen: false);

    // Ensure the shop collection is initialized
    await shopService.initializeShopCollection();

    // Fetch user assets and asset prices
    _fetchUserAssets();
  }

  // Fetches user assets and asset prices from the shop service
  Future<void> _fetchUserAssets() async {
    try {
      final shopService = Provider.of<ShopService>(context, listen: false);
      final userAssets = await shopService.getUserUnlockedAssets(); // Fetch user assets
      final assetPrices = await shopService.getAssetPrices(); // Fetch asset prices

      setState(() {
        _userAssets = userAssets;
        _assetPrices = assetPrices;
        _isLoading = false; // Data is fetched, update loading state
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')), // Show error message
      );
      setState(() {
        _isLoading = false; // Ensure loading state is updated on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(), // Loading spinner
                SizedBox(height: 16),
                Text('Fetching prices', style: TextStyle(fontSize: 18)), // Loading message
              ],
            ),
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Build sections for different types of assets
                _buildSection('Normal Profile Images', ProfileAssets.normalProfileImages, 'profileImages'),
                _buildSection('Premium Profile Images', ProfileAssets.premiumProfileImages, 'profileImages'),
                _buildSection('Special Profile Images', ProfileAssets.specialProfileImages, 'profileImages'),
                _buildSection('Normal Backgrounds', ProfileAssets.normalBackgrounds, 'backgrounds'),
                _buildSection('Premium Backgrounds', ProfileAssets.premiumBackgrounds, 'backgrounds'),
                _buildSection('Special Backgrounds', ProfileAssets.specialBackgrounds, 'backgrounds'),
              ],
            ),
          );
  }

  // Builds a section of the shop page for a specific type of asset
  Widget _buildSection(String title, Map<String, dynamic> assets, String assetType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Section title style
          ),
        ),
        // Build a list of cards for each asset in the section
        ...assets.entries.map((entry) {
          final assetId = entry.key; // Asset identifier
          final assetValue = entry.value; // Asset value (e.g., image path)
          final isBought = _userAssets[assetType]?.contains(assetId) ?? false; // Check if the asset is already bought

          if (isBought) return Container(); // Skip if asset is already bought

          final price = _assetPrices[assetId] ?? 0; // Fetch price for the asset

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: Image.asset(assetValue as String), // Display image
              title: Text('$assetId - \$${price}'), // Display asset ID and price
              onTap: () {
                _confirmPurchase(context, assetType, assetId, price);
              },
            ),
          );
        }),
        // Display a message if no assets are available for purchase
        if ((assets.isEmpty || assets.entries.where((entry) => !_userAssets[assetType]!.contains(entry.key)).isEmpty)) 
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'None bought',
              style: TextStyle(fontSize: 16, color: Colors.grey), // Message style
            ),
          ),
      ],
    );
  }

  // Confirms the purchase of an asset and updates the UI accordingly
  Future<void> _confirmPurchase(BuildContext context, String assetType, String assetId, int price) async {
    final shopService = Provider.of<ShopService>(context, listen: false);

    try {
      // Show a loading indicator while processing the purchase
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
        builder: (BuildContext context) => const Center(child: CircularProgressIndicator()), // Loading indicator
      );

      await shopService.purchaseAsset(assetType, assetId, price); // Process the purchase
      Navigator.pop(context); // Dismiss the loading indicator
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase successful'))); // Show success message
      _fetchUserAssets(); // Refresh the asset list to reflect the purchase
    } catch (e) {
      Navigator.pop(context); // Dismiss the loading indicator
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase failed: $e'))); // Show error message
    }
  }
}

// The BottomBar class is a StatelessWidget that displays the bottom navigation bar.
class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  // State variable to track loading state of Eco-Coins
  bool _isLoading = true;
  int _enviroCoins = 0;

  @override
  void initState() {
    super.initState();
    _fetchEnviroCoins(); // Fetch Eco-Coins when the widget is created
  }

  // Fetches the Eco-Coins from the UserService and updates the state
  Future<void> _fetchEnviroCoins() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final userId = Provider.of<FirebaseAuth>(context, listen: false).currentUser!.uid;
      final enviroCoins = await userService.getUserEnviroCoins(userId);

      setState(() {
        _enviroCoins = enviroCoins;
        _isLoading = false; // Update loading state
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching Eco-Coins: $e')));
      setState(() {
        _isLoading = false; // Ensure loading state is updated on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching Eco-Coins
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco, color: Colors.green),
                  const SizedBox(width: 8.0),
                  Text('Enviro-Coins: $_enviroCoins', style: const TextStyle(fontSize: 16)), // Display Eco-Coins
                ],
              ),
      ),
    );
  }
}
