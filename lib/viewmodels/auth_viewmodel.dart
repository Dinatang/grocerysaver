import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthViewModel(this._authService);

  bool _loading = false;
  String? _error;
  UserModel? _user;

  bool get loading => _loading;
  String? get error => _error;
  UserModel? get user => _user;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email.trim());
  }

  Future<bool> login(String email, String password) async {
    _setError(null);

    email = email.trim();
    if (!_isValidEmail(email)) {
      _setError("Correo inválido.");
      return false;
    }
    if (password.length < 4) {
      _setError("La contraseña debe tener al menos 4 caracteres.");
      return false;
    }

    try {
      _setLoading(true);
      _user = await _authService.login(email: email, password: password);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setError(null);

    name = name.trim();
    email = email.trim();

    if (name.length < 2) {
      _setError("Nombre demasiado corto.");
      return false;
    }
    if (!_isValidEmail(email)) {
      _setError("Correo inválido.");
      return false;
    }
    if (password.length < 4) {
      _setError("La contraseña debe tener al menos 4 caracteres.");
      return false;
    }

    try {
      _setLoading(true);
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setError(null);
    _setLoading(true);
    try {
      await _authService.logout();
      _user = null;
    } finally {
      _setLoading(false);
    }
  }
}
