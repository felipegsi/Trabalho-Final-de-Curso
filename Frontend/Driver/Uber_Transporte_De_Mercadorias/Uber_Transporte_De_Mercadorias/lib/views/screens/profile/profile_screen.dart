import 'package:flutter/material.dart';
import '../../../models/driver.dart';
import '../../../services/network_service.dart';
import 'dart:io'; // Necessary for File

import '../auth/login_screen.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NetworkService _networkService = NetworkService();
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
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
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white), // Certifique-se de que há contraste suficiente
        ),
        backgroundColor: Colors.black, // Exemplo de cor de fundo
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Cor do ícone
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: FutureBuilder<Driver?>(
          future: _networkService.viewProfile(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('An error occurred'));
            } else if (snapshot.data == null) {
              return Center(child: Text('No profile data available'));
            }

            var driver = snapshot.data!;
            return ListView(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _image == null
                        ? NetworkImage('https://via.placeholder.com/150') as ImageProvider<Object>
                        : FileImage(File(_image!.path)) as ImageProvider<Object>,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  driver.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  driver.email,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.phone),
                  title: Text('Phone Number'),
                  subtitle: Text(driver.phoneNumber),
                ),
                ListTile(
                  leading: Icon(Icons.location_city),
                  title: Text('City'),
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
      leading: Icon(Icons.exit_to_app),
      title: Text('Logout'),
      onTap: () => showLogoutConfirmationDialog(),
    );
  }

  Widget deleteAccountButton() {
    return ListTile(
      leading: Icon(Icons.delete_forever),
      title: Text('Delete Account'),
      onTap: () => showDeleteConfirmationDialog(),
    );
  }

  void showLogoutConfirmationDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Logout'),
            content: Text('Are you sure you want to logout?'),
            actions: <Widget>[
              TextButton(
                child: Text('No'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                  child: Text('Yes'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white,
                    backgroundColor: Colors
                    .red,),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _networkService.logout();
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => LoginScreen())
                    );
                  }
              ),
            ],
          );
        }
    );
  }

  void showDeleteConfirmationDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Delete Account'),
            content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
            actions: <Widget>[
              TextButton(
                child: Text('No'),

                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                  child: Text('Yes'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors
                        .red, // Define a cor de fundo como vermelho
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close the dialog
                    await _networkService.deleteAccount(context);
                  }
              ),
            ],
          );
        }
    );
  }
}
