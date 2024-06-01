import 'package:flutter/material.dart';
import 'package:projeto_proj/themes/app_theme.dart';
import 'package:projeto_proj/views/screens/splash_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(),
      theme: buildThemeData(),
    );
  }
}
