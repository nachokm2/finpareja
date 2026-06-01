import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  String _avatarUrl = '';
  bool _loading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);

    try {
      final useCase = await ref.read(registerUseCaseProvider.future);
      final result = await useCase.call(
        fullName: _fullName,
        email: _email,
        phoneNumber: _phone,
        password: _password,
        avatarUrl: _avatarUrl.isEmpty ? null : _avatarUrl,
      );

      if (!mounted) return;
      result.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        ),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta creada. Por favor inicia sesión.')),
          );
          context.pop();
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Nombre completo'),
                  textCapitalization: TextCapitalization.words,
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Requerido'),
                    MinLengthValidator(3, errorText: 'Mínimo 3 caracteres'),
                  ]),
                  onSaved: (v) => _fullName = (v ?? '').trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Correo'),
                  keyboardType: TextInputType.emailAddress,
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Requerido'),
                    EmailValidator(errorText: 'Correo no válido'),
                  ]),
                  onSaved: (v) => _email = (v ?? '').trim().toLowerCase(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Requerido'),
                    PatternValidator(
                      r'^[0-9+\s\-]{7,16}$',
                      errorText: 'Ingresa un teléfono válido',
                    ),
                  ]),
                  onSaved: (v) => _phone = (v ?? '').trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: MultiValidator([
                    MinLengthValidator(8, errorText: 'Mínimo 8 caracteres'),
                    PatternValidator(
                      r'(?=.*[A-Za-z])(?=.*\d)',
                      errorText: 'Debe incluir letras y números',
                    ),
                  ]),
                  onSaved: (v) => _password = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'URL de avatar (opcional)',
                  ),
                  keyboardType: TextInputType.url,
                  onSaved: (v) => _avatarUrl = (v ?? '').trim(),
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Crear cuenta'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
