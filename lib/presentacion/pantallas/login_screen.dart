import 'dart:io';
import 'package:flutter/material.dart';
import 'login_screen_android.dart' as android;
import 'login_screen_ios.dart' as ios;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Carga la pantalla correcta según la plataforma
    if (Platform.isAndroid) {
      return android.LoginScreen();
    } else {
      return ios.LoginScreen();
    }
  }
}
