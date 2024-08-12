import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a friend request to another user
  Future<void> sendFriendRequest(String receiverUserId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return; // Exit if no user is logged in

    final senderUserId = currentUser.uid;

    // Reference to the sender's friends document
    final senderDocRef = _firestore.collection('friends').doc(senderUserId);
    final senderDocSnapshot = await senderDocRef.get();

    // Create the sender's document if it doesn't exist
    if (!senderDocSnapshot.exists) {
      await senderDocRef.set({
        'outgoing_requests': [], // List of users to whom the sender has sent requests
        'incoming_requests': [], // List of users who have sent requests to the sender
        'planet_pals': [], // List of users who are friends with the sender
      });
    }

    // Reference to the receiver's friends document
    final receiverDocRef = _firestore.collection('friends').doc(receiverUserId);
    final receiverDocSnapshot = await receiverDocRef.get();

    // Create the receiver's document if it doesn't exist
    if (!receiverDocSnapshot.exists) {
      await receiverDocRef.set({
        'outgoing_requests': [], // List of users to whom the receiver has sent requests
        'incoming_requests': [], // List of users who have sent requests to the receiver
        'planet_pals': [], // List of users who are friends with the receiver
      });
    }

    // Add the receiver to the sender's outgoing requests
    await senderDocRef.update({
      'outgoing_requests': FieldValue.arrayUnion([receiverUserId]),
    });

    // Add the sender to the receiver's incoming requests
    await receiverDocRef.update({
      'incoming_requests': FieldValue.arrayUnion([senderUserId]),
    });
  }

  // Accept a friend request from another user
  Future<void> acceptFriendRequest(String senderUserId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return; // Exit if no user is logged in

    final receiverUserId = currentUser.uid;

    // Remove the sender from the receiver's incoming requests and add to planet_pals
    await _firestore.collection('friends').doc(receiverUserId).update({
      'incoming_requests': FieldValue.arrayRemove([senderUserId]),
      'planet_pals': FieldValue.arrayUnion([senderUserId]),
    });

    // Remove the receiver from the sender's outgoing requests and add to planet_pals
    await _firestore.collection('friends').doc(senderUserId).update({
      'outgoing_requests': FieldValue.arrayRemove([receiverUserId]),
      'planet_pals': FieldValue.arrayUnion([receiverUserId]),
    });
  }

  // Decline a friend request from another user
  Future<void> declineFriendRequest(String senderUserId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return; // Exit if no user is logged in

    final receiverUserId = currentUser.uid;

    // Remove the sender from the receiver's incoming requests
    await _firestore.collection('friends').doc(receiverUserId).update({
      'incoming_requests': FieldValue.arrayRemove([senderUserId]),
    });

    // Remove the receiver from the sender's outgoing requests
    await _firestore.collection('friends').doc(senderUserId).update({
      'outgoing_requests': FieldValue.arrayRemove([receiverUserId]),
    });
  }

  // Remove a friend from the user's list of friends
  Future<void> removeFriend(String friendUserId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return; // Exit if no user is logged in

    final userId = currentUser.uid;

    // Remove the friend from the user's planet_pals list
    await _firestore.collection('friends').doc(userId).update({
      'planet_pals': FieldValue.arrayRemove([friendUserId]),
    });

    // Remove the user from the friend's planet_pals list
    await _firestore.collection('friends').doc(friendUserId).update({
      'planet_pals': FieldValue.arrayRemove([userId]),
    });
  }

  // Cancel a friend request that was previously sent
  Future<void> cancelFriendRequest(String receiverUserId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return; // Exit if no user is logged in

    final senderUserId = currentUser.uid;

    // Remove the receiver from the sender's outgoing requests
    await _firestore.collection('friends').doc(senderUserId).update({
      'outgoing_requests': FieldValue.arrayRemove([receiverUserId]),
    });

    // Remove the sender from the receiver's incoming requests
    await _firestore.collection('friends').doc(receiverUserId).update({
      'incoming_requests': FieldValue.arrayRemove([senderUserId]),
    });
  }

  // Get the count of friends (planet_pals) for a specific user
  Future<int> getPalsCount(String userId) async {
    try {
      // Fetch the user's friends document
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('friends')
          .doc(userId)
          .get();
      // Return the count of planet_pals or 0 if not found
      return (doc.data()?['planet_pals'] as List<dynamic>?)?.length ?? 0;
    } catch (e) {
      // Return 0 in case of error
      return 0;
    }
  }

  // Stream to listen for updates to the current user's friend requests
  Stream<DocumentSnapshot> getFriendRequestsStream() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Stream.empty(); // Return empty stream if no user is logged in

    // Return a stream of snapshots for the current user's friends document
    return _firestore.collection('friends').doc(currentUser.uid).snapshots();
  }
}
