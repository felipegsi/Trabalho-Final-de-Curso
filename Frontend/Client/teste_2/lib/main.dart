import 'package:flutter/material.dart';
import 'package:teste_2/views/screens/main_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(),//++++manda o utilizador para o main screen se ele estiver logado
    );
  }
}
