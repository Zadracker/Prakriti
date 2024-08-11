import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/models/profile_assets.dart';

class ShopService {
  // Singleton pattern
  ShopService._privateConstructor();
  static final ShopService _instance = ShopService._privateConstructor();
  factory ShopService() => _instance;
  static ShopService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize the 'shop' collection with actual data
  Future<void> initializeShopCollection() async {
    try {
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
          final price = _determinePriceBasedOnType(assetId);
          await docRef.update({'price': price});
        }
      }

    } catch (e) {
    }
  }

  // Determine the asset type based on its ID
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

  // Determine the price for an asset based on its type
  int _determinePriceBasedOnType(String assetId) {
    if (ProfileAssets.normalProfileImages.containsKey(assetId)) {
      return 50;
    }else if (ProfileAssets.normalBackgrounds.containsKey(assetId)) {
      return 100; 
    }else if (ProfileAssets.premiumProfileImages.containsKey(assetId)) {
    return 300; 
    } else if (ProfileAssets.premiumBackgrounds.containsKey(assetId)) {
      return 500;
    } else if (ProfileAssets.specialProfileImages.containsKey(assetId)) {
    return 2000; 
    } else if (ProfileAssets.specialBackgrounds.containsKey(assetId)) {
      return 3000;
    }
    return 0;
  }

  // Retrieve the user's unlocked assets
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

  // Purchase an asset
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

  // Retrieve asset prices with discount applied for Terra Knights
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

  // Check if an asset is premium
  bool _isPremiumAsset(String assetId) {
    return ProfileAssets.premiumProfileImages.containsKey(assetId) ||
           ProfileAssets.premiumBackgrounds.containsKey(assetId);
  }

  // Fetch the user's role
  Future<String> _getUserRole(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    return userData?['role'] ?? 'normal'; // Adjust default role as needed
  }

  // Capitalize the first letter of a string
  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}
