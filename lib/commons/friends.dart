import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prakriti/commons/profile_card.dart';
import '../services/friends_service.dart';
import '../services/user_service.dart';
import '../services/profile_service.dart';

// The FriendsPage class displays and manages friend requests and friend lists.
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  // Services for handling friend requests and user information
  final FriendsService _friendsService = FriendsService();
  final UserService _userService = UserService();
  final TextEditingController _userIdController = TextEditingController(); // Controller for user ID input
  late TabController _tabController; // Controller for managing tabs in the AppBar

  @override
  void initState() {
    super.initState();
    // Initialize TabController with 2 tabs (Outgoing Requests, Incoming Requests)
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose of the TabController
    _userIdController.dispose(); // Dispose of the TextEditingController
    super.dispose();
  }

  // Shows a dialog with a profile card for a given user ID
  void _showProfileCard(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: ProfileCard(userId: userId), // Display profile card with user details
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Fetches user details for a given user ID
  Future<Map<String, dynamic>> _fetchUserDetails(String userId) async {
    DocumentSnapshot userDoc = await _userService.getUser(userId);
    if (userDoc.exists) {
      String username = userDoc.get('username') ?? 'Unknown User';
      // Fetch profile image URL for the user
      String profileImage = await ProfileService(userId: userId).getProfileImage(userId);
      return {'username': username, 'profileImage': profileImage};
    }
    // Default values if user details are not available
    return {'username': 'Unknown User', 'profileImage': ProfileService.defaultProfileImage};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planet Pals'), // AppBar title
        bottom: TabBar(
          controller: _tabController, // Attach TabController to manage tabs
          tabs: const [
            Tab(text: 'Outgoing Requests'), // First tab for outgoing requests
            Tab(text: 'Incoming Requests'), // Second tab for incoming requests
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input field and button for sending friend requests
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      hintText: 'Enter User ID to send request',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final userId = _userIdController.text.trim(); // Get user ID from input
                    if (userId.isNotEmpty) {
                      await _friendsService.sendFriendRequest(userId); // Send friend request
                      _userIdController.clear(); // Clear the input field
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _friendsService.getFriendRequestsStream(), // Stream to listen for friend request updates
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator()); // Show loading indicator if data is not available
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;

                  if (data == null) {
                    return const Center(child: Text('No pals found... No worries!')); // Message if no data is available
                  }

                  // Extract lists of outgoing requests, incoming requests, and planet pals from the data
                  final outgoingRequests = List<String>.from(data['outgoing_requests'] ?? []);
                  final incomingRequests = List<String>.from(data['incoming_requests'] ?? []);
                  final planetPals = List<String>.from(data['planet_pals'] ?? []);

                  return Column(
                    children: [
                      Expanded(
                        child: TabBarView(
                          controller: _tabController, // Attach TabController to manage tab views
                          children: [
                            // View for outgoing friend requests
                            if (outgoingRequests.isNotEmpty)
                              ListView(
                                children: outgoingRequests.map((userId) {
                                  return ListTile(
                                    title: Text('Outgoing request to $userId'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.cancel),
                                      onPressed: () async {
                                        await _friendsService.cancelFriendRequest(userId); // Cancel the friend request
                                      },
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              const Center(child: Text('No outgoing requests found...')), // Message if no outgoing requests are found

                            // View for incoming friend requests
                            if (incomingRequests.isNotEmpty)
                              ListView(
                                children: incomingRequests.map((userId) {
                                  return ListTile(
                                    title: Text('Incoming request from $userId'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.person),
                                          onPressed: () {
                                            _showProfileCard(userId); // Show profile card for the sender
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.check),
                                          onPressed: () async {
                                            await _friendsService.acceptFriendRequest(userId); // Accept the friend request
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () async {
                                            await _friendsService.declineFriendRequest(userId); // Decline the friend request
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              const Center(child: Text('No incoming requests found...')), // Message if no incoming requests are found
                          ],
                        ),
                      ),
                      const Divider(),
                      const Text('Planet Pals:', style: TextStyle(fontWeight: FontWeight.bold)), // Label for Planet Pals section
                      Expanded(
                        child: ListView.builder(
                          itemCount: planetPals.length,
                          itemBuilder: (context, index) {
                            final palId = planetPals[index];
                            return FutureBuilder<Map<String, dynamic>>(
                              future: _fetchUserDetails(palId), // Fetch user details for each planet pal
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) {
                                  return const ListTile(
                                    title: Text('Loading...'), // Show loading text while fetching user data
                                  );
                                }

                                final userData = userSnapshot.data!;
                                final username = userData['username'];

                                return ListTile(
                                  title: Row(
                                    children: [
                                      Text(username),
                                      IconButton(
                                        icon: const Icon(Icons.person),
                                        onPressed: () {
                                          _showProfileCard(palId); // Show profile card for the planet pal
                                        },
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle),
                                    onPressed: () async {
                                      await _friendsService.removeFriend(palId); // Remove the friend from the list
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
