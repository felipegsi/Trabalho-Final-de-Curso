import 'package:flutter/material.dart';

// Define a cor padrão dos ícones
const Color iconColor = Colors.black;

// Define a cor padrão dos botões
const Color buttonColor = Colors.blue;

// Define a cor padrão do texto
const Color textColor = Colors.black;

// Define a cor padrão do texto secundário
const Color subTextColor = Colors.grey;

// Define a cor padrão do hint text
const Color hintTextColor = Colors.grey;

// Define a cor padrão do fundo do ícone
Color? iconBackgroundColor = Colors.grey[350];

// Define a cor padrão do fundo do card
Color? cardBackgroundColor = Colors.grey[350];

// Define a cor padrão do fundo
const Color backgroundColor = Colors.white;

ThemeData buildThemeData() {
  final baseTheme = ThemeData.light(); // Começa com um tema base claro

  return baseTheme.copyWith(
    colorScheme: baseTheme.colorScheme.copyWith(
      primary: buttonColor,
      secondary: iconColor,
      surface: cardBackgroundColor,
      onPrimary: textColor,
      onSecondary: iconBackgroundColor,
      onSurface: subTextColor,
    ),
    iconTheme: const IconThemeData(
      color: iconColor,
    ),
    textTheme: baseTheme.textTheme.apply(
      bodyColor: textColor,
      displayColor: textColor,
    ),
    hintColor: hintTextColor,
    buttonTheme: const ButtonThemeData(
      buttonColor: buttonColor,
      textTheme: ButtonTextTheme.primary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: buttonColor,
      foregroundColor: textColor,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: buttonColor,
      foregroundColor: textColor,
    ),
    cardTheme: CardTheme(
      color: cardBackgroundColor,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: hintTextColor),
      border: OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: subTextColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: buttonColor),
      ),
    ),
  );
}
