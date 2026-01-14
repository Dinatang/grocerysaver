import '../models/user_model.dart';

class AuthService {
  final Map<String, Map<String, String>> _users = {};
  // email -> { name, password }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (_users.containsKey(email)) {
      throw Exception("El correo ya está registrado.");
    }

    _users[email] = {"name": name, "password": password};
    return UserModel(name: name, email: email);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final data = _users[email];
    if (data == null) {
      throw Exception("Usuario no encontrado.");
    }
    if (data["password"] != password) {
      throw Exception("Contraseña incorrecta.");
    }

    return UserModel(name: data["name"]!, email: email);
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
