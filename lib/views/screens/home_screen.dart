import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../core/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final user = vm.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: vm.loading
                ? null
                : () async {
                    await context.read<AuthViewModel>().logout();
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
          ),
        ],
      ),
      body: Center(
        child: user == null
            ? const Text("No hay usuario en sesión.")
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Bienvenido, ${user.name}",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(user.email),
                ],
              ),
      ),
    );
  }
}
