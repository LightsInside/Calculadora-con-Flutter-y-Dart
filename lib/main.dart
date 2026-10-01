import 'package:flutter/material.dart';
import 'package:flutter_application_1/calculadora_pantalla.dart';
import 'package:flutter_application_1/db_config.dart';

void main() {
  // Configura SQLite según la plataforma (web o Android) antes de arrancar
  configurarBaseDatos();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalculadoraPantalla(),
    );
  }
}