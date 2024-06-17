import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teste_2/views/screens/splash_screen.dart';

import 'api/auth_api.dart';
import 'api/order_api.dart';
import 'api/profile_api.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthApi>(
          create: (_) => AuthApi(),
        ),
        ChangeNotifierProvider<ProfileApi>(
          create: (_) => ProfileApi(),
        ),
        ChangeNotifierProvider<OrderApi>(
          create: (_) => OrderApi(),
        ),
      ],
      child: MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //theme: ,
      //darkTheme: ,
      home: SplashScreen(),
    );
  }
}
