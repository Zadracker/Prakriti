import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prakriti/services/user_service.dart';
import 'dart:math'; // Import the math package for the log function

class PointsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // Constants for points calculation
  static const int basePoints = 50;
  static const int increment = 30;
  static const String secretCode = 'coin123'; // Replace with your actual secret code

  // Check if the user is an eco-advocate
  Future<bool> _isEcoAdvocate(String userId) async {
    return await _userService.isEcoAdvocate(); // Pass userId to the method
  }

  // Check if the user is a terra_knight
  Future<bool> _isTerraKnight(String userId) async {
    final role = await _userService.getUserRole(userId);
    return role == UserService.TERRA_KNIGHT;
  }

  // Initialize user points and enviro-coins if not present
  Future<void> _initializeUserFields(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final data = userDoc.data()!;
    if (data['points'] == null || data['enviroCoins'] == null) {
      await _firestore.collection('users').doc(userId).update({
        'points': data['points'] ?? 0,
        'enviroCoins': data['enviroCoins'] ?? 0,
      });
    }
  }

  // Award points to a user for completing a task
  Future<void> awardPoints(String userId, String taskId) async {
    if (await _isEcoAdvocate(userId)) return;

    await _initializeUserFields(userId);

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final currentPoints = userDoc.data()?['points'] ?? 0;
    final taskDoc = await _firestore.collection('eco_tasks').doc(taskId).get();
    if (!taskDoc.exists) {
      throw Exception('Task not found');
    }

    final taskPoints = taskDoc.data()?['points'] ?? 0;
    final updatedPoints = currentPoints + taskPoints;

    await _firestore.collection('users').doc(userId).update({
      'points': updatedPoints,
    });

    // Update the points collection
    await _firestore.collection('points').doc(userId).set({
      'userId': userId,
      'points': updatedPoints,
    }, SetOptions(merge: true));

    // Check if the user leveled up and award Enviro-Coins
    await _handleLevelUp(userId, currentPoints, updatedPoints);
  }

  // Award points to a user for completing a daily task
  Future<void> awardDailyTaskPoints(String userId, String date, String taskId) async {
    if (await _isEcoAdvocate(userId)) return;

    await _initializeUserFields(userId);

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final currentPoints = userDoc.data()?['points'] ?? 0;
    final taskDoc = await _firestore
        .collection('daily_tasks')
        .doc(date)
        .collection('tasks')
        .doc(taskId)
        .get();

    if (!taskDoc.exists) {
      throw Exception('Task not found');
    }

    final taskPoints = taskDoc.data()?['points'] ?? 0;
    final updatedPoints = currentPoints + taskPoints;

    await _firestore.collection('users').doc(userId).update({
      'points': updatedPoints,
    });

    // Update the points collection
    await _firestore.collection('points').doc(userId).set({
      'userId': userId,
      'points': updatedPoints,
    }, SetOptions(merge: true));

    // Check if the user leveled up and award Enviro-Coins
    await _handleLevelUp(userId, currentPoints, updatedPoints);
  }

  // Award points to a user for completing a quiz
  Future<void> awardQuizPoints(String userId, int points) async {
    if (await _isEcoAdvocate(userId)) return;

    await _initializeUserFields(userId);

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final currentPoints = userDoc.data()?['points'] ?? 0;
    final updatedPoints = currentPoints + points;

    await _firestore.collection('users').doc(userId).update({
      'points': updatedPoints,
    });

    // Update the points collection
    await _firestore.collection('points').doc(userId).set({
      'userId': userId,
      'points': updatedPoints,
    }, SetOptions(merge: true));

    // Check if the user leveled up and award Enviro-Coins
    await _handleLevelUp(userId, currentPoints, updatedPoints);
  }

  // Retrieve the current points of a user
  Future<int> getUserPoints(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }
    return userDoc.data()?['points'] ?? 0;
  }

  // Retrieve the current enviro-coins of a user
  Future<int> getUserEnviroCoins(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }
    return userDoc.data()?['enviroCoins'] ?? 0;
  }

  // Retrieve the current level of a user based on points
  Future<int> getUserLevel(String userId) async {
    int points = await getUserPoints(userId);
    return calculateLevel(points);
  }

  // Retrieve the points needed to reach the next level
  Future<int> getPointsToNextLevel(String userId) async {
    int points = await getUserPoints(userId);
    int currentLevel = calculateLevel(points);
    int pointsRequiredForNextLevel = calculatePointsForLevel(currentLevel + 1);
    return pointsRequiredForNextLevel - points;
  }

  // Retrieve the Enviro-Coins awarded for reaching the next level
  Future<int> getNextLevelEnviroCoins(String userId) async {
    int currentLevel = await getUserLevel(userId);
    return (currentLevel + 1) * 10; // Example formula for Enviro-Coins
  }

  // Calculate the level based on points
  int calculateLevel(int points) {
    int level = 0;
    int requiredPoints = basePoints;
    while (points >= requiredPoints) {
      points -= requiredPoints;
      level++;
      requiredPoints = basePoints + (increment * log(level + 1)).toInt();
    }
    return level;
  }

  // Calculate the points required for a given level
  int calculatePointsForLevel(int level) {
    int points = 0;
    for (int i = 0; i < level; i++) {
      points += basePoints + (increment * log(i + 1)).toInt();
    }
    return points;
  }

  // Reset points for a user
  Future<void> resetPoints(String userId) async {
    if (await _isEcoAdvocate(userId)) return;

    await _firestore.collection('users').doc(userId).update({
      'points': 0,
    });

    // Remove the points collection if not needed
    await _firestore.collection('points').doc(userId).delete();
  }

  // Handle level up and award Enviro-Coins
  Future<void> _handleLevelUp(String userId, int oldPoints, int newPoints) async {
    final currentLevel = calculateLevel(newPoints);
    final nextLevelEnviroCoins = (currentLevel + 1) * 10; // Example formula for Enviro-Coins for the next level

    // Check if the user is a terra_knight and adjust the Enviro-Coins reward
    bool isTerraKnight = await _isTerraKnight(userId);
    final enviroCoinsToAward = isTerraKnight ? nextLevelEnviroCoins * 2 : nextLevelEnviroCoins;

    // Award Enviro-Coins for leveling up
    await _firestore.collection('users').doc(userId).update({
      'enviroCoins': FieldValue.increment(enviroCoinsToAward),
    });

    // Update the enviro-coins collection
    await _firestore.collection('enviroCoins').doc(userId).set({
      'userId': userId,
      'enviroCoins': FieldValue.increment(enviroCoinsToAward),
    }, SetOptions(merge: true));

    // Record the transaction
    // TODO: Implement the transaction recording
  }

  // Award Enviro-Coins purchased with real money
  Future<void> awardEnviroCoinsPay(String userId, int coins) async {
    if (await _isEcoAdvocate(userId)) return;

    await _initializeUserFields(userId);

    // Check if the user is a terra_knight and adjust the Enviro-Coins reward
    bool isTerraKnight = await _isTerraKnight(userId);
    final enviroCoinsToAward = isTerraKnight ? coins * 2 : coins;

    await _firestore.collection('users').doc(userId).update({
      'enviroCoins': FieldValue.increment(enviroCoinsToAward),
    });

    // Update the enviro-coins collection
    await _firestore.collection('enviroCoins').doc(userId).set({
      'userId': userId,
      'enviroCoins': FieldValue.increment(enviroCoinsToAward),
    }, SetOptions(merge: true));

    // Record the transaction
    // TODO: Implement the transaction recording
  }

  // Redeem a secret code for Enviro-Coins
  Future<void> redeemSecretCode(String userId, String code) async {
    if (await _isEcoAdvocate(userId)) return;

    if (code == secretCode) {
      await _initializeUserFields(userId);

      // Award 1000 Enviro-Coins
      await _firestore.collection('users').doc(userId).update({
        'enviroCoins': FieldValue.increment(1000),
      });

      // Update the enviro-coins collection
      await _firestore.collection('enviroCoins').doc(userId).set({
        'userId': userId,
        'enviroCoins': FieldValue.increment(1000),
      }, SetOptions(merge: true));

      // Record the transaction
      // TODO: Implement the transaction recording
      } else {
      throw Exception('Invalid code');
    }
  }
}
