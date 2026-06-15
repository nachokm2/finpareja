import 'package:flutter/material.dart';
import 'package:flutter_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:go_router/go_router.dart';

/// Recuperación de contraseña en dos pasos dentro de la misma pantalla:
///   Paso 1: pedir el correo → backend envía un código OTP.
///   Paso 2: ingresar código + nueva contraseña.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _requestCode() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _snack('Ingresa tu correo');
      return;
    }
    setState(() => _loading = true);
    final repo = await ref.read(authRepositoryProvider.future);
    final result = await repo.forgotPassword(_emailCtrl.text.trim().toLowerCase());
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (f) => _snack(f.message),
      (_) {
        setState(() => _codeSent = true);
        _snack('Si el correo existe, te enviamos un código.');
      },
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final repo = await ref.read(authRepositoryProvider.future);
    final result = await repo.resetPassword(
      email: _emailCtrl.text.trim().toLowerCase(),
      code: _codeCtrl.text.trim(),
      newPassword: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (f) => _snack(f.message),
      (_) {
        _snack('Contraseña actualizada. Inicia sesión.');
        context.go('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _codeSent
                    ? 'Ingresa el código que enviamos a tu correo y tu nueva contraseña.'
                    : 'Ingresa tu correo y te enviaremos un código para restablecer tu contraseña.',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                enabled: !_codeSent,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Código de 6 dígitos',
                  ),
                  validator: RequiredValidator(errorText: 'Requerido'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                  validator: MultiValidator([
                    MinLengthValidator(8, errorText: 'Mínimo 8 caracteres'),
                    PatternValidator(
                      r'(?=.*[A-Za-z])(?=.*\d)',
                      errorText: 'Debe incluir letras y números',
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _codeSent ? _resetPassword : _requestCode,
                  child: Text(_codeSent ? 'Cambiar contraseña' : 'Enviar código'),
                ),
              if (_codeSent)
                TextButton(
                  onPressed: _loading ? null : _requestCode,
                  child: const Text('Reenviar código'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
