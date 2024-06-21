import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../api/auth_api.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkIsValidToken();
  }

  Future<void> _checkIsValidToken() async {
    final authProvider = Provider.of<AuthApi>(context, listen: false);
    bool isValid = await authProvider.isValidToken();

    Timer(const Duration(seconds: 3), () async {
      if (isValid) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // Mostra um popup indicando que a sessão expirou
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Sessão Expirada'),
              content: const Text('Sua sessão expirou. Por favor, faça login novamente.'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Fecha o dialog
                  },
                ),
              ],
            );
          },
        );

        // Depois que o usuário fecha o dialog, navegue para a tela de login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SvgPicture.asset('assets/images/logo-svg.svg'),
      ),
    );
  }
}
