import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/google_auth_service.dart';
import '../../providers/app_providers.dart';
import 'auth_ui.dart';
import 'google_web_sign_in_button_stub.dart'
    if (dart.library.html) 'google_web_sign_in_button_web.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  StreamSubscription<String>? _googleIdTokenSubscription;
  bool _googleListenerAttached = false;
  bool _obscurePassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_googleListenerAttached || !kIsWeb) return;
    _googleListenerAttached = true;
    final googleAuthService = context.read<GoogleAuthService>();
    _googleIdTokenSubscription = googleAuthService.idTokenChanges.listen((idToken) async {
      if (!mounted) return;
      final provider = context.read<AuthProvider>();
      final navigator = Navigator.of(context);
      final success = await provider.loginWithGoogleIdToken(idToken);
      if (!mounted || !success) return;
      navigator.pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
    });
  }

  @override
  void dispose() {
    _googleIdTokenSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    final provider = context.read<AuthProvider>();
    final success = await provider.loginWithGoogle();
    if (!mounted || !success) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final success = await provider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted || !success) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return AuthGradientScaffold(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 650),
                    tween: Tween(begin: 0, end: 1),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 24 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo_grocesy.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 38,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Bienvenido',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Inicia sesion para continuar',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4C6B50),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (auth.errorMessage != null) ...[
                                _AuthErrorBox(message: auth.errorMessage!),
                                const SizedBox(height: 16),
                              ],
                              _LoginField(
                                label: 'Email',
                                hintText: '',
                                icon: Icons.email_outlined,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) return 'Ingresa tu correo';
                                  if (!text.contains('@')) return 'Correo invalido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _LoginField(
                                label: 'Password',
                                hintText: '',
                                icon: Icons.lock_outline_rounded,
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF4C6B50),
                                  ),
                                ),
                                validator: (value) => (value ?? '').length >= 6
                                    ? null
                                    : 'Minimo 6 caracteres',
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: auth.isSubmitting ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    auth.isSubmitting ? 'Ingresando...' : 'Iniciar sesion',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (kIsWeb) ...[
                                const GoogleWebSignInButton(),
                                const SizedBox(height: 12),
                              ] else ...[
                                OutlinedButton.icon(
                                  onPressed: auth.isSubmitting ? null : _loginWithGoogle,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    side: const BorderSide(color: Color(0xFFB2CBB4)),
                                    foregroundColor: const Color(0xFF1B5E20),
                                  ),
                                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                                  label: const Text('Continuar con Google'),
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                                child: const Text('¿No tienes cuenta? Registrate'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.hintText,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFDCE6DD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFDCE6DD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.3),
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}

class _AuthErrorBox extends StatelessWidget {
  const _AuthErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3BDD0)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB1305D),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}





