import 'package:eaglesteelfurniture/main.dart';
import 'package:eaglesteelfurniture/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAnonymous = user?.isAnonymous ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false, // hides back arrow
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: Text(
                isAnonymous
                    ? 'G'
                    : (user?.email != null && user!.email!.isNotEmpty
                          ? user.email![0].toUpperCase()
                          : 'U'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User Info
            Text(
              isAnonymous ? 'Guest User' : user?.displayName ?? 'User Name',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isAnonymous ? 'Not logged in' : user?.email ?? 'user@example.com',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Profile options for logged-in users
            if (!isAnonymous) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.shopping_bag,
                        color: Colors.green,
                      ),
                      title: const Text('My Orders'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to orders
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                      title: const Text('Shipping Address'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to address
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.green),
                      title: const Text('Settings'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to settings
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.help_outline,
                        color: Colors.green,
                      ),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to support
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Centered Login/Logout button + guest message
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (isAnonymous) {
                        // Navigate to login screen and remove back stack
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      } else {
                        FirebaseAuth.instance.signOut().then((_) {
                          // After logout go back to HomeScreen and remove back stack
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                            (route) => false,
                          );
                        });
                      }
                    },
                    icon: Icon(
                      isAnonymous ? Icons.login : Icons.logout,
                      color: Colors.white,
                    ),
                    label: Text(
                      isAnonymous ? 'Login' : 'Logout',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),

                  if (isAnonymous) ...[
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'You are in guest mode. Login to access all features.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
