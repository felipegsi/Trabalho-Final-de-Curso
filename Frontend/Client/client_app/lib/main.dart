import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teste_2/api/location_api.dart';
import 'package:teste_2/views/screens/splash_screen.dart';

import 'api/auth_api.dart';
import 'api/order_api.dart';
import 'api/profile_api.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthApi>(
          create: (_) => AuthApi(),
        ),
        ChangeNotifierProvider<ProfileApi>(
          create: (_) => ProfileApi(),
        ),
        ChangeNotifierProvider<OrderApi>(
          create: (_) => OrderApi(),
        ),
        ChangeNotifierProvider<LocationApi>(
          create: (_) => LocationApi(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      //theme: ,
      //darkTheme: ,
      home: SplashScreen(),
    );
  }
}
