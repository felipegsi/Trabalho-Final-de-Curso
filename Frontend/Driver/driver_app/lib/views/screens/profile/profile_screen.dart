import 'package:flutter/material.dart';
import 'dart:io'; // Necessary for File
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../api/auth_api.dart';
import '../../../api/profile_api.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profileProvider = Provider.of<ProfileApi>(context, listen: false);
    await profileProvider.fetchProfile();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _image = pickedFile;
      });
    } catch (e) {
      // Handle errors or cancelation
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Consumer<ProfileApi>(
          builder: (context, profileApi, _) {
            if (profileApi.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (profileApi.hasError) {
              return Center(child: Text('An error occurred: ${profileApi.errorMessage}'));
            } else if (profileApi.driver == null) {
              return const Center(child: Text('No profile data available'));
            }

            var driver = profileApi.driver!;
            return ListView(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child:  CircleAvatar(
                    backgroundColor: Colors.black,
                    radius: 50,
                    child: Text(
                      '${driver.name[0]}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  driver.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  driver.email,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone Number'),
                  subtitle: Text(driver.phoneNumber),
                ),
                ListTile(
                  leading: const Icon(Icons.location_city),
                  title: const Text('City'),
                  subtitle: Text(driver.city),
                ),
                logoutButton(),
                deleteAccountButton(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget logoutButton() {
    return ListTile(
      leading: const Icon(Icons.exit_to_app),
      title: const Text('Logout'),
      onTap: () => showLogoutConfirmationDialog(),
    );
  }

  Widget deleteAccountButton() {
    return ListTile(
      leading: const Icon(Icons.delete_forever),
      title: const Text('Delete Account'),
      onTap: () => showDeleteConfirmationDialog(),
    );
  }

  void showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                final authProvider = Provider.of<AuthApi>(context, listen: false);
                await authProvider.logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete Account'),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                final authProvider = Provider.of<AuthApi>(context, listen: false);
                await authProvider.deleteAccount();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
