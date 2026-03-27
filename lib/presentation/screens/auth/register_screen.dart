import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../providers/app_providers.dart';
import 'auth_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _addressController = TextEditingController(text: '');
  final _birthDateController = TextEditingController(text: '');

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  double _strengthValue = 0;
  String _strengthLabel = 'Debil';
  Color _strengthColor = const Color(0xFFD84315);
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_handlePasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_handlePasswordChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _handlePasswordChanged() {
    final strength = _evaluatePasswordStrength(_passwordController.text);
    if (strength.value == _strengthValue && strength.label == _strengthLabel) return;
    setState(() {
      _strengthValue = strength.value;
      _strengthLabel = strength.label;
      _strengthColor = strength.color;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<AuthProvider>();
    final success = await provider.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
      address: _addressController.text.trim(),
      birthDate: _birthDateController.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      final message = provider.errorMessage;
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuenta creada. Revisa tu correo para verificarla.')),
    );
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return AuthGradientScaffold(
          showBack: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 520;
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
                        Center(
                          child: Container(
                            width: 84,
                            height: 84,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(22),
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
                                  Icons.person_add_alt_1_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 38,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Crear cuenta',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Completa tus datos',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4C6B50),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 20,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (auth.errorMessage != null) ...[
                                  _AuthErrorBox(message: auth.errorMessage!),
                                  const SizedBox(height: 14),
                                ],
                                Text(
                                  'Nombre completo',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (isWide)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _RegisterField(
                                          label: 'Nombre',
                                          hintText: 'Tu nombre',
                                          icon: Icons.person_outline_rounded,
                                          controller: _firstNameController,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r"[A-Za-z\s]"),
                                            ),
                                            LengthLimitingTextInputFormatter(15),
                                          ],
                                          validator: (value) {
                                            final text = (value ?? '').trim();
                                            if (text.isEmpty) return 'Ingresa tu nombre';
                                            if (text.length > 15) return 'Maximo 15 caracteres';
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _RegisterField(
                                          label: 'Apellido',
                                          hintText: 'Tu apellido',
                                          icon: Icons.badge_outlined,
                                          controller: _lastNameController,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r"[A-Za-z\s]"),
                                            ),
                                            LengthLimitingTextInputFormatter(15),
                                          ],
                                          validator: (value) {
                                            final text = (value ?? '').trim();
                                            if (text.isEmpty) return 'Ingresa tu apellido';
                                            if (text.length > 15) return 'Maximo 15 caracteres';
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _RegisterField(
                                    label: 'Nombre',
                                    hintText: 'Tu nombre',
                                    icon: Icons.person_outline_rounded,
                                    controller: _firstNameController,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r"[A-Za-z\s]"),
                                      ),
                                      LengthLimitingTextInputFormatter(15),
                                    ],
                                    validator: (value) {
                                      final text = (value ?? '').trim();
                                      if (text.isEmpty) return 'Ingresa tu nombre';
                                      if (text.length > 15) return 'Maximo 15 caracteres';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _RegisterField(
                                    label: 'Apellido',
                                    hintText: 'Tu apellido',
                                    icon: Icons.badge_outlined,
                                    controller: _lastNameController,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r"[A-Za-z\s]"),
                                      ),
                                      LengthLimitingTextInputFormatter(15),
                                    ],
                                    validator: (value) {
                                      final text = (value ?? '').trim();
                                      if (text.isEmpty) return 'Ingresa tu apellido';
                                      if (text.length > 15) return 'Maximo 15 caracteres';
                                      return null;
                                    },
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _RegisterField(
                                  label: 'Email',
                                  hintText: 'tu@email.com',
                                  icon: Icons.mail_outline_rounded,
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    final text = (value ?? '').trim();
                                    if (text.isEmpty) return 'Ingresa tu correo';
                                    if (!text.contains('@')) return 'Correo invalido';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _RegisterField(
                                  label: 'Password',
                                  hintText: 'Crea una contrasena',
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
                                  validator: (value) {
                                    final text = value ?? '';
                                    if (text.length < 8) return 'Minimo 8 caracteres';
                                    if (!RegExp(r"[^A-Za-z0-9]").hasMatch(text)) {
                                      return 'Agrega un caracter especial';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                _PasswordStrength(
                                  value: _strengthValue,
                                  label: _strengthLabel,
                                  color: _strengthColor,
                                ),
                                const SizedBox(height: 12),
                                _RegisterField(
                                  label: 'Confirmar password',
                                  hintText: 'Repite tu contrasena',
                                  icon: Icons.verified_user_outlined,
                                  controller: _confirmController,
                                  obscureText: _obscureConfirm,
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF4C6B50),
                                    ),
                                  ),
                                  validator: (value) => value == _passwordController.text
                                      ? null
                                      : 'Las contrasenas no coinciden',
                                ),
                                const SizedBox(height: 12),
                                _RegisterField(
                                  label: 'Direccion',
                                  hintText: 'Ingresa tu direccion',
                                  icon: Icons.location_on_outlined,
                                  controller: _addressController,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(15),
                                  ],
                                  validator: (value) {
                                    final text = (value ?? '').trim();
                                    if (text.isEmpty) return 'Ingresa una direccion';
                                    if (text.length > 15) return 'Maximo 15 caracteres';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _RegisterField(
                                  label: 'Fecha de nacimiento',
                                  hintText: '1995-01-01',
                                  icon: Icons.calendar_month_outlined,
                                  controller: _birthDateController,
                                  validator: (value) {
                                    final text = (value ?? '').trim();
                                    if (text.isEmpty) return 'Ingresa una fecha';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                CheckboxListTile(
                                  value: _acceptedTerms,
                                  onChanged: (value) {
                                    setState(() => _acceptedTerms = value ?? false);
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: Text(
                                    'Acepto terminos y condiciones',
                                    style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF4C6B50)),
                                  ),
                                ),
                                const SizedBox(height: 12),
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
                                    ),
                                    child: auth.isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Registrarse',
                                            style: TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: auth.isSubmitting
                                      ? null
                                      : () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                                  child: const Text('Ya tengo cuenta'),
                                ),
                              ],
                            ),
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

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.label,
    required this.hintText,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.inputFormatters,
    this.validator,
  });

  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
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
            inputFormatters: inputFormatters,
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

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({
    required this.value,
    required this.label,
    required this.color,
  });

  final double value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            color: color,
            backgroundColor: const Color(0xFFE6ECE6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fuerza: $label',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: color,
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

class _PasswordStrengthResult {
  const _PasswordStrengthResult({
    required this.value,
    required this.label,
    required this.color,
  });

  final double value;
  final String label;
  final Color color;
}

_PasswordStrengthResult _evaluatePasswordStrength(String value) {
  int score = 0;
  if (value.length >= 8) score++;
  if (RegExp(r"[A-Z]").hasMatch(value) && RegExp(r"[a-z]").hasMatch(value)) {
    score++;
  }
  if (RegExp(r"[0-9]").hasMatch(value)) score++;
  if (RegExp(r"[^A-Za-z0-9]").hasMatch(value)) score++;
  if (value.length >= 12) score++;

  final strength = score / 5;
  if (strength <= 0.2) {
    return const _PasswordStrengthResult(
      value: 0.2,
      label: 'Debil',
      color: Color(0xFFD84315),
    );
  }
  if (strength <= 0.4) {
    return const _PasswordStrengthResult(
      value: 0.4,
      label: 'Media',
      color: Color(0xFFF9A825),
    );
  }
  if (strength <= 0.6) {
    return const _PasswordStrengthResult(
      value: 0.6,
      label: 'Buena',
      color: Color(0xFF7CB342),
    );
  }
  return const _PasswordStrengthResult(
    value: 1,
    label: 'Fuerte',
    color: Color(0xFF2E7D32),
  );
}
