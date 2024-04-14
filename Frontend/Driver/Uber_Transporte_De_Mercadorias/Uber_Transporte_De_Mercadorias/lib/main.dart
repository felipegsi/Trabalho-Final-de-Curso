import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projeto_proj/views/screens/login_screen.dart';
import 'package:projeto_proj/views/screens/register_screen.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // Função geradora de rotas
  Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case 'login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case 'register':
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      // Adicionar mais casos para outras telas
      default:
        return MaterialPageRoute(
            builder: (_) => LoginScreen()); // Página de login como fallback
    }
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uber Carga',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[800],
        hintColor: Colors.amber,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          color: Colors.black, toolbarTextStyle: GoogleFonts.latoTextTheme(
            Theme.of(context).textTheme,
          ).bodyText2, titleTextStyle: GoogleFonts.latoTextTheme(
            Theme.of(context).textTheme,
          ).headline6,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.symmetric(vertical: 16),
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        // Outras rotas
      },
    );
  }
}
