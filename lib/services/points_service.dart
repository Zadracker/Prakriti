import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prakriti/services/user_service.dart';
import 'dart:math'; // Import the math package for the log function

class PointsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance for database operations
  final UserService _userService = UserService(); // Service for user-related operations

  // Constants for points calculation
  static const int basePoints = 50; // Base points for leveling up
  static const int increment = 30; // Increment value for each level
  static const String secretCode = 'coin123'; // Secret code for redeeming Enviro-Coins

  // Check if the user is an eco-advocate
  Future<bool> _isEcoAdvocate(String userId) async {
    return await _userService.isEcoAdvocate(); // Check if the user is an eco-advocate
  }

  // Check if the user is a terra_knight
  Future<bool> _isTerraKnight(String userId) async {
    final role = await _userService.getUserRole(userId); // Fetch the user's role
    return role == UserService.TERRA_KNIGHT; // Check if the role is 'terra_knight'
  }

  // Initialize user points and enviro-coins if not present
  Future<void> _initializeUserFields(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get(); // Get user document
    if (!userDoc.exists) {
      throw Exception('User not found'); // Throw an error if user document doesn't exist
    }

    final data = userDoc.data()!;
    if (data['points'] == null || data['enviroCoins'] == null) {
      // Initialize points and enviroCoins if not present
      await _firestore.collection('users').doc(userId).update({
        'points': data['points'] ?? 0,
        'enviroCoins': data['enviroCoins'] ?? 0,
      });
    }
  }

  // Award points to a user for completing a task
  Future<void> awardPoints(String userId, String taskId) async {
    if (await _isEcoAdvocate(userId)) return; // Skip if user is an eco-advocate

    await _initializeUserFields(userId); // Ensure user fields are initialized

    final userDoc = await _firestore.collection('users').doc(userId).get(); // Get user document
    final currentPoints = userDoc.data()?['points'] ?? 0; // Get current points
    final taskDoc = await _firestore.collection('eco_tasks').doc(taskId).get(); // Get task document
    if (!taskDoc.exists) {
      throw Exception('Task not found'); // Throw an error if task document doesn't exist
    }

    final taskPoints = taskDoc.data()?['points'] ?? 0; // Get points for the task
    final updatedPoints = currentPoints + taskPoints; // Calculate updated points

    await _firestore.collection('users').doc(userId).update({
      'points': updatedPoints, // Update user points
    });

    // Update the points collection
    await _firestore.collection('points').doc(userId).set({
      'userId': userId,
      'points': updatedPoints,
    }, SetOptions(merge: true));

    // Handle level-up and award Enviro-Coins
    await _handleLevelUp(userId, currentPoints, updatedPoints);
  }

  // Award points to a user for completing a daily task
  Future<void> awardDailyTaskPoints(String userId, String date, String taskId) async {
    if (await _isEcoAdvocate(userId)) return; // Skip if user is an eco-advocate

    await _initializeUserFields(userId); // Ensure user fields are initialized

    final userDoc = await _firestore.collection('users').doc(userId).get(); // Get user document
    final currentPoints = userDoc.data()?['points'] ?? 0; // Get current points
    final taskDoc = await _firestore
        .collection('daily_tasks')
        .doc(date)
        .collection('tasks')
        .doc(taskId)
        .get(); // Get daily task document

    if (!taskDoc.exists) {
      throw Exception('Task not found'); // Throw an error if task document doesn't exist
    }

    final taskPoints = taskDoc.data()?['points'] ?? 0; // Get points for the daily task
    final updatedPoints = currentPoints + taskPoints; // Calculate updated points

    await _firestore.collection('users').doc(userId).update({
      'points': updatedPoints, // Update user points
    });

    // Update the points collection
    await _firestore.collection('points').doc(userId).set({
      'userId': userId,
      'points': updatedPoints,
    }, SetOptions(merge: true));

    // Handle level-up and award Enviro-Coins
    await _handleLevelUp(userId, currentPoints, updatedPoints);
  }

  // Award points to a user for completing a quiz
  Future<void> awardQuizPoints(String userId, int points) async {
    if (await _isEcoAdvocate(userId)) return; // Skip if user is an eco-advocate

    await _initializeUserFields(userId); // Ensure user fields are initialized

    final userDoc = await _firestore.collection('users').doc(userId).get(); // Get user document
    final currentPoints = userDoc.data()?['points'] ?? 0; // Get current points
    final updatedPoints = currentPoints + points; // Calculate updated points

    await _firestore.collection('users').doc(userId).update({
      'points': updatedPoints, // Update user points
    });

    // Update the points collection
    await _firestore.collection('points').doc(userId).set({
      'userId': userId,
      'points': updatedPoints,
    }, SetOptions(merge: true));

    // Handle level-up and award Enviro-Coins
    await _handleLevelUp(userId, currentPoints, updatedPoints);
  }

  // Retrieve the current points of a user
  Future<int> getUserPoints(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get(); // Get user document
    if (!userDoc.exists) {
      throw Exception('User not found'); // Throw an error if user document doesn't exist
    }
    return userDoc.data()?['points'] ?? 0; // Return current points
  }

  // Retrieve the current enviro-coins of a user
  Future<int> getUserEnviroCoins(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get(); // Get user document
    if (!userDoc.exists) {
      throw Exception('User not found'); // Throw an error if user document doesn't exist
    }
    return userDoc.data()?['enviroCoins'] ?? 0; // Return current enviro-coins
  }

  // Retrieve the current level of a user based on points
  Future<int> getUserLevel(String userId) async {
    int points = await getUserPoints(userId); // Get current points
    return calculateLevel(points); // Calculate and return user level
  }

  // Retrieve the points needed to reach the next level
  Future<int> getPointsToNextLevel(String userId) async {
    int points = await getUserPoints(userId); // Get current points
    int currentLevel = calculateLevel(points); // Get current level
    int pointsRequiredForNextLevel = calculatePointsForLevel(currentLevel + 1); // Calculate points required for next level
    return pointsRequiredForNextLevel - points; // Return points needed to reach the next level
  }

  // Retrieve the Enviro-Coins awarded for reaching the next level
  Future<int> getNextLevelEnviroCoins(String userId) async {
    int currentLevel = await getUserLevel(userId); // Get current level
    return (currentLevel + 1) * 10; // Example formula for Enviro-Coins for the next level
  }

  // Calculate the level based on points
  int calculateLevel(int points) {
    int level = 0;
    int requiredPoints = basePoints;
    while (points >= requiredPoints) {
      points -= requiredPoints; // Subtract the points required for the current level
      level++;
      requiredPoints = basePoints + (increment * log(level + 1)).toInt(); // Calculate points required for the next level
    }
    return level; // Return the current level
  }

  // Calculate the points required for a given level
  int calculatePointsForLevel(int level) {
    int points = 0;
    for (int i = 0; i < level; i++) {
      points += basePoints + (increment * log(i + 1)).toInt(); // Sum the points required for each level
    }
    return points; // Return total points required for the given level
  }

  // Reset points for a user
  Future<void> resetPoints(String userId) async {
    if (await _isEcoAdvocate(userId)) return; // Skip if user is an eco-advocate

    await _firestore.collection('users').doc(userId).update({
      'points': 0, // Reset user points to zero
    });

    // Remove the points collection if not needed
    await _firestore.collection('points').doc(userId).delete();
  }

  // Handle level up and award Enviro-Coins
  Future<void> _handleLevelUp(String userId, int oldPoints, int newPoints) async {
    final currentLevel = calculateLevel(newPoints); // Get current level based on new points
    final nextLevelEnviroCoins = (currentLevel + 1) * 10; // Example formula for Enviro-Coins for the next level

    // Check if the user is a terra_knight and adjust the Enviro-Coins reward
    bool isTerraKnight = await _isTerraKnight(userId);
    final enviroCoinsToAward = isTerraKnight ? nextLevelEnviroCoins * 2 : nextLevelEnviroCoins; // Adjust reward for terra_knight

    // Award Enviro-Coins for leveling up
    await _firestore.collection('users').doc(userId).update({
      'enviroCoins': FieldValue.increment(enviroCoinsToAward), // Increment Enviro-Coins
    });

    // Update the enviro-coins collection
    await _firestore.collection('enviroCoins').doc(userId).set({
      'userId': userId,
      'enviroCoins': FieldValue.increment(enviroCoinsToAward), // Increment Enviro-Coins
    }, SetOptions(merge: true));

    // Record the transaction
    // TODO: Implement the transaction recording
  }

  // Award Enviro-Coins purchased with real money
  Future<void> awardEnviroCoinsPay(String userId, int coins) async {
    if (await _isEcoAdvocate(userId)) return; // Skip if user is an eco-advocate

    await _initializeUserFields(userId); // Ensure user fields are initialized

    // Check if the user is a terra_knight and adjust the Enviro-Coins reward
    bool isTerraKnight = await _isTerraKnight(userId);
    final enviroCoinsToAward = isTerraKnight ? coins * 2 : coins; // Adjust reward for terra_knight

    await _firestore.collection('users').doc(userId).update({
      'enviroCoins': FieldValue.increment(enviroCoinsToAward), // Increment Enviro-Coins
    });

    // Update the enviro-coins collection
    await _firestore.collection('enviroCoins').doc(userId).set({
      'userId': userId,
      'enviroCoins': FieldValue.increment(enviroCoinsToAward), // Increment Enviro-Coins
    }, SetOptions(merge: true));

    // Record the transaction
    // TODO: Implement the transaction recording
  }

  // Redeem a secret code for Enviro-Coins
  Future<void> redeemSecretCode(String userId, String code) async {
    if (await _isEcoAdvocate(userId)) return; // Skip if user is an eco-advocate

    if (code == secretCode) {
      await _initializeUserFields(userId); // Ensure user fields are initialized

      // Award 1000 Enviro-Coins
      await _firestore.collection('users').doc(userId).update({
        'enviroCoins': FieldValue.increment(1000), // Increment Enviro-Coins
      });

      // Update the enviro-coins collection
      await _firestore.collection('enviroCoins').doc(userId).set({
        'userId': userId,
        'enviroCoins': FieldValue.increment(1000), // Increment Enviro-Coins
      }, SetOptions(merge: true));

      // Record the transaction
      // TODO: Implement the transaction recording (future feature)
    } else {
      throw Exception('Invalid code'); // Throw an error for invalid code
    }
  }
}
