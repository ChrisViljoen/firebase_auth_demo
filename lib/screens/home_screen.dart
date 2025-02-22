import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_demo/screens/login_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth auth;
  final User user;

  const HomeScreen._({
    super.key,
    required this.auth,
    required this.user,
  });

  factory HomeScreen({Key? key}) {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    return HomeScreen._(key: key, auth: auth, user: user);
  }

  static HomeScreen withAuth(FirebaseAuth auth, User user, {Key? key}) {
    return HomeScreen._(key: key, auth: auth, user: user);
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen.withAuth(auth)),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logging out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome ${user.email}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'You are now logged in.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'To logout, click the logout button in the top right corner.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
