import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prakriti/commons/profile_card.dart';
import '../services/friends_service.dart';
import '../services/user_service.dart';
import '../services/profile_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  final UserService _userService = UserService();
  final TextEditingController _userIdController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  void _showProfileCard(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: ProfileCard(userId: userId),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchUserDetails(String userId) async {
    DocumentSnapshot userDoc = await _userService.getUser(userId);
    if (userDoc.exists) {
      String username = userDoc.get('username') ?? 'Unknown User';
      String profileImage = await ProfileService(userId: userId).getProfileImage(userId);
      return {'username': username, 'profileImage': profileImage};
    }
    return {'username': 'Unknown User', 'profileImage': ProfileService.defaultProfileImage};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planet Pals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Outgoing Requests'),
            Tab(text: 'Incoming Requests'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Textbox and send button to send friend requests
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
                    final userId = _userIdController.text.trim();
                    if (userId.isNotEmpty) {
                      await _friendsService.sendFriendRequest(userId);
                      _userIdController.clear();
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _friendsService.getFriendRequestsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;

                  if (data == null) {
                    return const Center(child: Text('No pals found... No worries!'));
                  }

                  final outgoingRequests = List<String>.from(data['outgoing_requests'] ?? []);
                  final incomingRequests = List<String>.from(data['incoming_requests'] ?? []);
                  final planetPals = List<String>.from(data['planet_pals'] ?? []);

                  return Column(
                    children: [
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Outgoing requests section
                            if (outgoingRequests.isNotEmpty)
                              ListView(
                                children: outgoingRequests.map((userId) {
                                  return ListTile(
                                    title: Text('Outgoing request to $userId'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.cancel),
                                      onPressed: () async {
                                        await _friendsService.cancelFriendRequest(userId);
                                      },
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              const Center(child: Text('No outgoing requests found...')),

                            // Incoming requests section
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
                                            _showProfileCard(userId);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.check),
                                          onPressed: () async {
                                            await _friendsService.acceptFriendRequest(userId);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () async {
                                            await _friendsService.declineFriendRequest(userId);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              const Center(child: Text('No incoming requests found...')),
                          ],
                        ),
                      ),
                      const Divider(),
                      const Text('Planet Pals:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: ListView.builder(
                          itemCount: planetPals.length,
                          itemBuilder: (context, index) {
                            final palId = planetPals[index];
                            return FutureBuilder<Map<String, dynamic>>(
                              future: _fetchUserDetails(palId),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) {
                                  return const ListTile(
                                    title: Text('Loading...'),
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
                                          _showProfileCard(palId);
                                        },
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle),
                                    onPressed: () async {
                                      await _friendsService.removeFriend(palId);
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
