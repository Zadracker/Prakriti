import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendFriendRequest(String receiverUserId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final senderUserId = currentUser.uid;

    // Check if sender document exists, create if not
    final senderDocRef = _firestore.collection('friends').doc(senderUserId);
    final senderDocSnapshot = await senderDocRef.get();
    if (!senderDocSnapshot.exists) {
      await senderDocRef.set({
        'outgoing_requests': [],
        'incoming_requests': [],
        'planet_pals': [],
      });
    }

    // Check if receiver document exists, create if not
    final receiverDocRef = _firestore.collection('friends').doc(receiverUserId);
    final receiverDocSnapshot = await receiverDocRef.get();
    if (!receiverDocSnapshot.exists) {
      await receiverDocRef.set({
        'outgoing_requests': [],
        'incoming_requests': [],
        'planet_pals': [],
      });
    }

    // Update outgoing and incoming requests
    await senderDocRef.update({
      'outgoing_requests': FieldValue.arrayUnion([receiverUserId]),
    });

    await receiverDocRef.update({
      'incoming_requests': FieldValue.arrayUnion([senderUserId]),
    });
  }

  Future<void> acceptFriendRequest(String senderUserId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final receiverUserId = currentUser.uid;

    await _firestore.collection('friends').doc(receiverUserId).update({
      'incoming_requests': FieldValue.arrayRemove([senderUserId]),
      'planet_pals': FieldValue.arrayUnion([senderUserId]),
    });

    await _firestore.collection('friends').doc(senderUserId).update({
      'outgoing_requests': FieldValue.arrayRemove([receiverUserId]),
      'planet_pals': FieldValue.arrayUnion([receiverUserId]),
    });
  }

  Future<void> declineFriendRequest(String senderUserId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final receiverUserId = currentUser.uid;

    await _firestore.collection('friends').doc(receiverUserId).update({
      'incoming_requests': FieldValue.arrayRemove([senderUserId]),
    });

    await _firestore.collection('friends').doc(senderUserId).update({
      'outgoing_requests': FieldValue.arrayRemove([receiverUserId]),
    });
  }

  Future<void> removeFriend(String friendUserId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userId = currentUser.uid;

    await _firestore.collection('friends').doc(userId).update({
      'planet_pals': FieldValue.arrayRemove([friendUserId]),
    });

    await _firestore.collection('friends').doc(friendUserId).update({
      'planet_pals': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> cancelFriendRequest(String receiverUserId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final senderUserId = currentUser.uid;

    await _firestore.collection('friends').doc(senderUserId).update({
      'outgoing_requests': FieldValue.arrayRemove([receiverUserId]),
    });

    await _firestore.collection('friends').doc(receiverUserId).update({
      'incoming_requests': FieldValue.arrayRemove([senderUserId]),
    });
  }

  Future<int> getPalsCount(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('friends')
          .doc(userId)
          .get();
      return (doc.data()?['planet_pals'] as List<dynamic>?)?.length ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Stream<DocumentSnapshot> getFriendRequestsStream() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore.collection('friends').doc(currentUser.uid).snapshots();
  }
}
