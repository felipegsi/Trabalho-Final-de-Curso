import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../services/network_service.dart';
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: FutureBuilder<Client?>(
        future: NetworkService().viewProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('An error occurred'));
          } else if (snapshot.data == null) {
            return Center(child: Text('No profile data available'));
          } else {
            return Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${snapshot.data!.name}'),
                  Text('Email: ${snapshot.data!.email}'),
                  Text('Phone Number: ${snapshot.data!.phoneNumber}'),
                  Text('City: ${snapshot.data!.city}'),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}