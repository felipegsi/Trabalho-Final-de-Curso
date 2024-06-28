import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../api/auth_api.dart';
import '../../../api/profile_api.dart';
import '../../../themes/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profileApi = Provider.of<ProfileApi>(context, listen: false);
    await profileApi.viewProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Container(
        color: Colors.white,
        child: Consumer<ProfileApi>(
          builder: (context, profileApi, child) {
            if (profileApi.client == null) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black,
                      radius: 50,
                      child: Text(
                        '${profileApi.client?.name[0]}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 45,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      color: Colors.grey[200],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Name'),
                            subtitle: Text(profileApi.client!.name),
                          ),
                          ListTile(
                            leading: const Icon(Icons.email),
                            title: const Text('Email'),
                            subtitle: Text(profileApi.client!.email),
                          ),
                          ListTile(
                            leading: const Icon(Icons.phone),
                            title: const Text('Phone Number'),
                            subtitle: Text(profileApi.client!.phoneNumber),
                          ),
                          ListTile(
                            leading: const Icon(Icons.location_city),
                            title: const Text('City'),
                            subtitle: Text(profileApi.client!.city),
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Logout'),
                            onTap: () => _showLogoutDialog(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete),
                            title: const Text('Delete Account'),
                            onTap: () => _showDeleteAccountDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text(
            'Do you sure want to sign out?',
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: textColor,
                      backgroundColor: iconBackgroundColor,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('No'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      final authApi = Provider.of<AuthApi>(context, listen: false);
                      await authApi.logout();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('Yes'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text(
            'Do you sure want to delete account?',
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: textColor,
                      backgroundColor: iconBackgroundColor,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('No'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      final authApi = Provider.of<AuthApi>(context, listen: false);
                      bool success = await authApi.deleteAccount();
                      if (success) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      } else {
                        Navigator.of(context).pop();
                        _showErrorDialog(context, 'Error deleting account. Please try again.');
                      }
                    },
                    child: const Text('Yes'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
