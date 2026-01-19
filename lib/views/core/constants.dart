import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._(); // Evita instancias

  // 🌐 API CONFIG
  static const String baseUrl = 'http://10.0.2.2/grocerysaver_backend/api';

  // 🔗 ENDPOINTS
  static const String loginEndpoint = '/login.php';
  static const String registerEndpoint = '/register.php';
  static const String inventoryEndpoint = '/inventario.php';

  // ⏳ TIMEOUT
  static const int requestTimeoutSeconds = 15;

  // 🎨 COLORES
  static const Color primaryColor = Colors.green;
  static const Color secondaryColor = Colors.orange;
  static const Color backgroundColor = Colors.white;

  // 🧾 TEXTOS
  static const String appName = 'GrocerySaver';
  static const String loginTitle = 'Iniciar sesión';
  static const String registerTitle = 'Registro';
  static const String homeTitle = 'Inicio';

  // ⚠️ MENSAJES
  static const String loginError = 'Usuario o contraseña incorrectos';
  static const String networkError = 'Error de conexión. Intente nuevamente';
  static const String emptyFields = 'Por favor complete todos los campos';
}
