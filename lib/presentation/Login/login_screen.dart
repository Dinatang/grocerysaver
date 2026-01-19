import 'package:flutter/material.dart';
import '../../core/routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Email')),
            TextField(
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, Routes.home);
              },
              child: const Text('Ingresar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.register);
              },
              child: const Text('Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}
