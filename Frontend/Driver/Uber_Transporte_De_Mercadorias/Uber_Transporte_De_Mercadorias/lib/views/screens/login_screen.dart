import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projeto_proj/views/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/network_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _attemptLogin(BuildContext context) async {
    final networkService = NetworkService();
    String? token = await networkService.login(
        _emailController.text, _passwordController.text);
    if (token != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => ProfileScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to login. Please try again.'),
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Image.asset('assets/images/logo.png', height: 150),
            SizedBox(height: 30),
            _buildTextField(_emailController, 'E-mail', Icons.email),
            SizedBox(height: 16),
            _buildTextField(_passwordController, 'Password', Icons.lock, isObscure: true),
            SizedBox(height: 24),
            _buildLoginButton(context),
            _buildRegisterButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _attemptLogin(context),
        child: Text('Entrar'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pushNamed('/register'),
      child: Text('Não tem uma conta? Registe-se aqui.', style: TextStyle(color: Colors.black54)),
    );
  }
}
