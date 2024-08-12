import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/models/profile_assets.dart';

class ShopService {
  // Singleton pattern to ensure a single instance of ShopService
  ShopService._privateConstructor();
  static final ShopService _instance = ShopService._privateConstructor();
  factory ShopService() => _instance;
  static ShopService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initializes the 'shop' collection with asset data.
  Future<void> initializeShopCollection() async {
    try {
      // Combine all assets into one map
      final assets = {
        ...ProfileAssets.normalProfileImages,
        ...ProfileAssets.premiumProfileImages,
        ...ProfileAssets.specialProfileImages,
        ...ProfileAssets.normalBackgrounds,
        ...ProfileAssets.premiumBackgrounds,
        ...ProfileAssets.specialBackgrounds,
      };

      for (final assetId in assets.keys) {
        final docRef = _firestore.collection('shop').doc(assetId);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          // If the asset does not exist, create it
          final price = _determinePriceBasedOnType(assetId);
          final assetType = _determineAssetType(assetId);
          final assetData = {
            'price': price,
            'buyers': [],
            'assetType': assetType,
            if (assetType == 'profileImage' || assetType == 'background') 'path': assets[assetId]!,
          };

          await docRef.set(assetData);
        } else {
          // If the asset exists, update its price
          final price = _determinePriceBasedOnType(assetId);
          await docRef.update({'price': price});
        }
      }

    } catch (e) {
      // Handle errors here
      print('Error initializing shop collection: $e');
    }
  }

  /// Determines the asset type based on its ID.
  String _determineAssetType(String assetId) {
    if (ProfileAssets.normalProfileImages.containsKey(assetId) ||
        ProfileAssets.premiumProfileImages.containsKey(assetId) ||
        ProfileAssets.specialProfileImages.containsKey(assetId)) {
      return 'profileImage';
    } else if (ProfileAssets.normalBackgrounds.containsKey(assetId) ||
               ProfileAssets.premiumBackgrounds.containsKey(assetId) ||
               ProfileAssets.specialBackgrounds.containsKey(assetId)) {
      return 'background';
    }
    return 'unknown';
  }

  /// Determines the price for an asset based on its type.
  int _determinePriceBasedOnType(String assetId) {
    if (ProfileAssets.normalProfileImages.containsKey(assetId)) {
      return 50; // Price for normal profile images
    } else if (ProfileAssets.normalBackgrounds.containsKey(assetId)) {
      return 100; // Price for normal backgrounds
    } else if (ProfileAssets.premiumProfileImages.containsKey(assetId)) {
      return 300; // Price for premium profile images
    } else if (ProfileAssets.premiumBackgrounds.containsKey(assetId)) {
      return 500; // Price for premium backgrounds
    } else if (ProfileAssets.specialProfileImages.containsKey(assetId)) {
      return 2000; // Price for special profile images
    } else if (ProfileAssets.specialBackgrounds.containsKey(assetId)) {
      return 3000; // Price for special backgrounds
    }
    return 0; // Default price if asset type is unknown
  }

  /// Retrieves the user's unlocked assets.
  Future<Map<String, List<String>>> getUserUnlockedAssets() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      final unlockedAssets = {
        'profileImages': <String>[],
        'backgrounds': <String>[],
      };

      final snapshot = await _firestore.collection('shop').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final buyers = List<String>.from(data['buyers'] ?? []);
        
        if (buyers.contains(user.uid)) {
          final assetId = doc.id;
          final assetType = data['assetType'];

          if (assetType == 'profileImage') {
            unlockedAssets['profileImages']!.add(assetId);
          } else if (assetType == 'background') {
            unlockedAssets['backgrounds']!.add(assetId);
          }
        }
      }

      return unlockedAssets;
    } catch (e) {
      throw Exception('Failed to retrieve user unlocked assets');
    }
  }

  /// Handles the purchase of an asset by the user.
  Future<void> purchaseAsset(String assetType, String assetId, int price) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final data = userDoc.data()!;
      final currentCoins = data['enviroCoins'] ?? 0;

      if (currentCoins < price) {
        throw Exception('Not enough Enviro-Coins');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'enviroCoins': currentCoins - price,
      });

      final assetDocRef = _firestore.collection('shop').doc(assetId);
      final assetDoc = await assetDocRef.get();
      if (!assetDoc.exists) {
        throw Exception('Asset not found');
      }

      await assetDocRef.update({
        'buyers': FieldValue.arrayUnion([user.uid]),
      });
    } catch (e) {
      throw Exception('Purchase failed');
    }
  }

  /// Retrieves asset prices with potential discounts applied for Terra Knights.
  Future<Map<String, int>> getAssetPrices() async {
    final assetPrices = <String, int>{};
    final user = _auth.currentUser;

    try {
      final snapshot = await _firestore.collection('shop').get();
      final userRole = await _getUserRole(user!.uid);
      final isTerraKnight = userRole == 'terra_knight';

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final assetId = doc.id;
        int price = data['price'] as int? ?? 0;

        // Apply 30% discount for Terra Knights on premium items
        if (isTerraKnight && _isPremiumAsset(assetId)) {
          price = (price * 0.5).round();
        }

        assetPrices[assetId] = price;
      }
    } catch (e) {
      throw Exception('Failed to retrieve asset prices');
    }

    return assetPrices;
  }

  /// Checks if an asset is classified as premium.
  bool _isPremiumAsset(String assetId) {
    return ProfileAssets.premiumProfileImages.containsKey(assetId) ||
           ProfileAssets.premiumBackgrounds.containsKey(assetId);
  }

  /// Fetches the user's role from Firestore.
  Future<String> _getUserRole(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    return userData?['role'] ?? 'normal'; // Default role if not specified
  }

  /// Capitalizes the first letter of a string.
  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}
