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
  final UserService _userService = UserService(); // Service to handle user-related operations

  // Function to handle user logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut(); // Sign out the user
    Navigator.of(context).pushReplacementNamed('/login'); // Redirect to login page after logout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Applications'), // Title for the AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // Call logout function when the button is pressed
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _userService.getEcoAdvocateApplications(), // Stream of eco-advocate applications from the service
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading spinner while data is being fetched
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Show a message if no applications are found
            return const Center(child: Text('No applications found.'));
          }
          var applications = snapshot.data!.docs; // List of application documents
          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              var application = applications[index];
              return ListTile(
                title: Text(application['username']), // Display the username of the applicant
                subtitle: Text(application['email']), // Display the email of the applicant
                trailing: Text(application['status']), // Display the status of the application
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApplicationDetailPage(application: application), // Navigate to detail page
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
  final QueryDocumentSnapshot application; // Application document to be displayed

  const ApplicationDetailPage({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService(); // Service to handle user-related operations

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'), // Title for the AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding around the content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display application details
            Text('Username: ${application['username']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Email: ${application['email']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Application Text: ${application['application_text']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            
            // Button to download the application document
            ElevatedButton(
              onPressed: () async {
                final url = application['document_url']; // Get the document URL
                await userService.downloadApplicationDocument(url); // Call service to download the document
              },
              child: const Text('Download Document'),
            ),
            const SizedBox(height: 16),
            
            // Buttons to approve or reject the application
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await userService.acceptApplication(application.id, application['uid']); // Call service to accept the application
                    Navigator.pop(context); // Return to the previous page
                  },
                  child: const Text('Approve'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await userService.rejectApplication(application.id); // Call service to reject the application
                    Navigator.pop(context); // Return to the previous page
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
