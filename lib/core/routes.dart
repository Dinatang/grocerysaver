import 'package:flutter/material.dart';
import '../presentation/login/login_screen.dart';
import '../presentation/login/register_screen.dart';
import '../presentation/home/home_screen.dart';

class Routes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';

  static Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    home: (_) => const HomeScreen(),
  };
}
