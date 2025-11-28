import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';

/// Tela de Abertura (Splash Screen).
/// Responsabilidades:
/// 1. Apresentar a identidade visual da marca (Logo e Nome).
/// 2. Realizar carregamento inicial.
/// 3. Gerenciar a transição segura para a tela principal (sem empilhar histórico).

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Configura um temporizador de 3 segundos para exibição da logo.
    Timer(const Duration(seconds: 3), () {
      // pushReplacement: Remove a Splash da pilha de navegação.
      // Isso impede que o usuário clique em "Voltar" na Home e retorne à abertura.
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/icon.png', width: 250),
            const SizedBox(height: 20),
            const Text(
              'Sistema de Controle',
              style: TextStyle(fontFamily: 'Sans-serif', fontSize: 18, color: Color(0xFF4A4A4A), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
