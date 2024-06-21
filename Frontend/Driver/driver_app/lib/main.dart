import 'package:flutter/material.dart';
import 'package:projeto_proj/api/auth_api.dart';
import 'package:projeto_proj/api/message_api.dart';
import 'package:projeto_proj/api/order_api.dart';
import 'package:projeto_proj/api/profile_api.dart';
import 'package:projeto_proj/themes/app_theme.dart';
import 'package:projeto_proj/views/screens/splash_screen.dart';
import 'package:provider/provider.dart';

void main() => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthApi()),
          ChangeNotifierProvider(create: (_) => ProfileApi()),
          ChangeNotifierProvider(create: (_) => OrderApi()),
          ChangeNotifierProvider(create: (_) => MessageApi()),
        ],
        child: const MyApp(),
      ),
    );

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(),
      theme: buildThemeData(),
    );
  }
}
