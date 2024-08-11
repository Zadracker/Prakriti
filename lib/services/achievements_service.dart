import 'package:cloud_firestore/cloud_firestore.dart';
import 'points_service.dart';
import 'friends_service.dart';

class AchievementsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PointsService _pointsService = PointsService();
  final FriendsService _friendsService = FriendsService();

  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      await _firestore
          .collection('achievements')
          .doc(userId)
          .set({achievementId: true}, SetOptions(merge: true));
    } catch (e) {
    }
  }

  Future<bool> isAchievementUnlocked(String userId, String achievementId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('achievements')
          .doc(userId)
          .get();
      return doc.exists && doc.data()?[achievementId] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> checkAndUnlockLevelAchievements(String userId) async {
    int level = await _pointsService.getUserLevel(userId);

    if (level >= 1) {
      await unlockAchievement(userId, 'level_1');
    }
    if (level >= 5) {
      await unlockAchievement(userId, 'level_5');
    }
    if (level >= 10) {
      await unlockAchievement(userId, 'level_10');
    }
    if (level >= 20) {
      await unlockAchievement(userId, 'level_20');
    }
    if (level >= 50) {
      await unlockAchievement(userId, 'level_50');
    }
  }

  Future<void> checkAndUnlockFriendAchievements(String userId) async {
    try {
      int palsCount = await _friendsService.getPalsCount(userId);

      if (palsCount >= 1) {
        await unlockAchievement(userId, 'made_1_pal');
      }
      if (palsCount >= 10) {
        await unlockAchievement(userId, 'made_10_pals');
      }
    } catch (e) {
    }
  }
}
