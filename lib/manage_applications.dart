import 'package:flutter/material.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageApplicationsPage extends StatefulWidget {
  const ManageApplicationsPage({super.key});

  @override
  _ManageApplicationsPageState createState() => _ManageApplicationsPageState();
}

class _ManageApplicationsPageState extends State<ManageApplicationsPage> {
  final UserService _userService = UserService();

  // Function to handle logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login'); // Redirect to login page after logout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _userService.getEcoAdvocateApplications(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No applications found.'));
          }
          var applications = snapshot.data!.docs;
          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              var application = applications[index];
              return ListTile(
                title: Text(application['username']),
                subtitle: Text(application['email']),
                trailing: Text(application['status']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApplicationDetailPage(application: application),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ApplicationDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot application;

  const ApplicationDetailPage({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${application['username']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Email: ${application['email']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Application Text: ${application['application_text']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final url = application['document_url'];
                await userService.downloadApplicationDocument(url);
              },
              child: const Text('Download Document'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await userService.acceptApplication(application.id, application['uid']);
                    Navigator.pop(context);
                  },
                  child: const Text('Approve'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await userService.rejectApplication(application.id);
                    Navigator.pop(context);
                  },
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
