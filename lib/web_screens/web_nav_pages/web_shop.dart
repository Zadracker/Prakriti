import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prakriti/models/profile_assets.dart';
import 'package:prakriti/services/shop_service.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:provider/provider.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
      ),
      body: ShopContent(),
      bottomNavigationBar: BottomBar(),
    );
  }
}

class ShopContent extends StatefulWidget {
  const ShopContent({super.key});

  @override
  _ShopContentState createState() => _ShopContentState();
}

class _ShopContentState extends State<ShopContent> {
  Map<String, List<String>> _userAssets = {
    'profileImages': [],
    'backgrounds': [],
  };

  Map<String, int> _assetPrices = {}; // To store asset prices
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _initializeShop();
  }

  Future<void> _initializeShop() async {
    final shopService = Provider.of<ShopService>(context, listen: false);

    // Ensure the shop collection is initialized
    await shopService.initializeShopCollection();

    // Fetch user assets and asset prices
    _fetchUserAssets();
  }

  Future<void> _fetchUserAssets() async {
    try {
      final shopService = Provider.of<ShopService>(context, listen: false);
      final userAssets = await shopService.getUserUnlockedAssets();
      final assetPrices = await shopService.getAssetPrices(); // Fetch prices from Firestore
      setState(() {
        _userAssets = userAssets;
        _assetPrices = assetPrices;
        _isLoading = false; // Set loading to false when data is fetched
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
      setState(() {
        _isLoading = false; // Ensure loading is set to false on error as well
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
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching prices', style: TextStyle(fontSize: 18)),
              ],
            ),
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

  Widget _buildSection(String title, Map<String, dynamic> assets, String assetType) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final assetId = assets.keys.elementAt(index);
              final assetValue = assets.values.elementAt(index);
              final isBought = _userAssets[assetType]?.contains(assetId) ?? false;

              if (isBought) return const SizedBox.shrink(); // Skip if already bought

              final price = _assetPrices[assetId] ?? 0; // Fetch price for the asset

              return GestureDetector(
                onTap: () {
                  _confirmPurchase(context, assetType, assetId, price);
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
                        child: Text('$assetId - \$${price}'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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

  Future<void> _confirmPurchase(BuildContext context, String assetType, String assetId, int price) async {
    final shopService = Provider.of<ShopService>(context, listen: false);

    try {
      await shopService.purchaseAsset(assetType, assetId, price);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase successful')));
      _fetchUserAssets(); // Refresh the asset list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
    }
  }
}

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
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final enviroCoins = snapshot.data ?? 0;
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
