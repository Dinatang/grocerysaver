import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔐 Auth
import 'services/auth_service.dart';
import 'viewmodels/auth_viewmodel.dart';

// 📦 Inventory
import 'services/inventory_service.dart';
import 'viewmodels/inventory_viewmodel.dart';

// 🧭 Rutas y pantallas
import 'views/core/app_routes.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/register_screen.dart';
import 'views/screens/home_screen.dart';

// 🎨 Tema
import 'core/theme.dart';
import 'core/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🔐 Servicios
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<InventoryService>(create: (_) => InventoryService()),

        // 🔐 ViewModels
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(context.read<AuthService>()),
        ),

        ChangeNotifierProvider<InventoryViewModel>(
          create: (context) =>
              InventoryViewModel(context.read<InventoryService>()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
        },
      ),
    );
  }
}
