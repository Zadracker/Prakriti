import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prakriti/models/profile_assets.dart';
import 'package:prakriti/services/shop_service.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:provider/provider.dart';

// Main Shop Page widget
class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'), // Title of the AppBar
      ),
      body: ShopContent(), // The main content of the shop
      bottomNavigationBar: BottomBar(), // The bottom navigation bar displaying Enviro-Coins
    );
  }
}

// Stateful widget for the shop content
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
  Map<String, int> _assetPrices = {}; // Stores the prices of assets
  bool _isLoading = true; // Indicates if data is still being loaded

  @override
  void initState() {
    super.initState();
    _initializeShop(); // Initialize shop data when the widget is created
  }

  // Initializes the shop by setting up the collection and fetching data
  Future<void> _initializeShop() async {
    final shopService = Provider.of<ShopService>(context, listen: false);

    // Ensure the shop collection is properly initialized
    await shopService.initializeShopCollection();

    // Fetch user assets and asset prices
    _fetchUserAssets();
  }

  // Fetches user assets and asset prices from the shop service
  Future<void> _fetchUserAssets() async {
    try {
      final shopService = Provider.of<ShopService>(context, listen: false);
      final userAssets = await shopService.getUserUnlockedAssets();
      final assetPrices = await shopService.getAssetPrices(); // Fetch asset prices from Firestore

      setState(() {
        _userAssets = userAssets;
        _assetPrices = assetPrices;
        _isLoading = false; // Set loading state to false after fetching data
      });
    } catch (e) {
      // Show an error message if data fetching fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
      setState(() {
        _isLoading = false; // Ensure loading state is updated even on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while data is being fetched
    return _isLoading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(), // Loading spinner
                SizedBox(height: 16),
                Text('Fetching prices', style: TextStyle(fontSize: 18)),
              ],
            ),
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Build sections for different asset categories
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

  // Builds a section for displaying assets in the shop
  Widget _buildSection(String title, Map<String, dynamic> assets, String assetType) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Grid view for displaying assets
          GridView.builder(
            shrinkWrap: true, // Use the minimum space required
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this grid
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Number of columns
              crossAxisSpacing: 8.0, // Space between columns
              mainAxisSpacing: 8.0, // Space between rows
            ),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final assetId = assets.keys.elementAt(index); // Get asset ID
              final assetValue = assets.values.elementAt(index); // Get asset value (path)
              final isBought = _userAssets[assetType]?.contains(assetId) ?? false; // Check if the asset is already bought

              if (isBought) return const SizedBox.shrink(); // Skip displaying if already bought

              final price = _assetPrices[assetId] ?? 0; // Fetch price for the asset

              // Build the card for each asset
              return GestureDetector(
                onTap: () {
                  _confirmPurchase(context, assetType, assetId, price); // Confirm purchase on tap
                },
                child: Card(
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: assetType == 'backgrounds'
                            ? Image.asset(assetValue as String, fit: BoxFit.cover)
                            : Image.asset(assetValue as String, fit: BoxFit.cover),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('$assetId - \$${price}'), // Display asset ID and price
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Display message if no assets are bought
          if ((assets.isEmpty || assets.entries.where((entry) => !_userAssets[assetType]!.contains(entry.key)).isEmpty)) 
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'None bought',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  // Show a confirmation dialog for purchasing an asset
  Future<void> _confirmPurchase(BuildContext context, String assetType, String assetId, int price) async {
    final shopService = Provider.of<ShopService>(context, listen: false);

    try {
      await shopService.purchaseAsset(assetType, assetId, price); // Attempt to purchase the asset
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase successful')));
      _fetchUserAssets(); // Refresh the asset list to reflect the purchase
    } catch (e) {
      // Show an error message if the purchase fails
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
    }
  }
}

// Bottom navigation bar displaying Enviro-Coins
class BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<int>(
          future: Provider.of<UserService>(context, listen: false).getUserEnviroCoins(
            Provider.of<FirebaseAuth>(context, listen: false).currentUser!.uid,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show a loading indicator while fetching the user's coins
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // Display an error message if fetching the coins fails
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final enviroCoins = snapshot.data ?? 0; // Get the number of Enviro-Coins
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco, color: Colors.green),
                  const SizedBox(width: 8.0),
                  Text('Enviro-Coins: $enviroCoins', style: const TextStyle(fontSize: 16)),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
