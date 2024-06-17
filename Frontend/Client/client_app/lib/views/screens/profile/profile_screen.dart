import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../api/auth_api.dart';
import '../../../api/profile_api.dart';
import '../../../themes/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
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
      appBar: AppBar(title: Text('Profile')),
      body: Container(
        color: Colors.white,
        child: Consumer<ProfileApi>(
          builder: (context, profileApi, child) {
            if (profileApi.client == null) {
              return Center(child: CircularProgressIndicator());
            } else {
              return Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                    ),
                    SizedBox(height: 20),
                    Card(
                      color: cardBackgroundColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: Icon(Icons.person),
                            title: Text('Name'),
                            subtitle: Text('${profileApi.client!.name}'),
                          ),
                          ListTile(
                            leading: Icon(Icons.email),
                            title: Text('Email'),
                            subtitle: Text('${profileApi.client!.email}'),
                          ),
                          ListTile(
                            leading: Icon(Icons.phone),
                            title: Text('Phone Number'),
                            subtitle: Text('${profileApi.client!.phoneNumber}'),
                          ),
                          ListTile(
                            leading: Icon(Icons.location_city),
                            title: Text('City'),
                            subtitle: Text('${profileApi.client!.city}'),
                          ),
                          ListTile(
                            leading: Icon(Icons.logout),
                            title: Text('Logout'),
                            onTap: () => _showLogoutDialog(context),
                          ),
                          ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Delete Account'),
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
                Container(
                  width: 100,
                  child: TextButton(
                    child: Text('No'),
                    style: TextButton.styleFrom(
                      foregroundColor: textColor,
                      backgroundColor: iconBackgroundColor,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 100,
                  child: TextButton(
                    child: Text('Yes'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      final authApi = Provider.of<AuthApi>(context, listen: false);
                      await authApi.logout();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    },
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
                Container(
                  width: 100,
                  child: TextButton(
                    child: Text('No'),
                    style: TextButton.styleFrom(
                      foregroundColor: textColor,
                      backgroundColor: iconBackgroundColor,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 100,
                  child: TextButton(
                    child: Text('Yes'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      final authApi = Provider.of<AuthApi>(context, listen: false);
                      bool success = await authApi.deleteAccount();
                      if (success) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                      } else {
                        Navigator.of(context).pop();
                        _showErrorDialog(context, 'Error deleting account. Please try again.');
                      }
                    },
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
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
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
