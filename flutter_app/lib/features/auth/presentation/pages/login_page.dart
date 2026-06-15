import 'package:flutter/material.dart';
import 'package:flutter_app/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    // GoRouter redirige automáticamente a /home cuando auth state
    // cambia a authenticated — no hace falta context.go() aquí.
    await ref.read(authNotifierProvider.notifier).signIn(_email, _password);
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar errores de auth en SnackBar cuando el estado cambia
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenData((authState) {
        if (authState.errorMessage != null && mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(authState.errorMessage!)));
        }
      });
    });

    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                validator: MultiValidator([
                  RequiredValidator(errorText: 'Requerido'),
                  EmailValidator(errorText: 'Correo no válido'),
                ]),
                onSaved: (v) => _email = v?.trim().toLowerCase() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: RequiredValidator(errorText: 'Requerido'),
                onSaved: (v) => _password = v ?? '',
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Ingresar'),
                  ),
                ),
              TextButton(
                onPressed: isLoading ? null : () => context.push('/register'),
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
              TextButton(
                onPressed:
                    isLoading ? null : () => context.push('/recuperar-password'),
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
