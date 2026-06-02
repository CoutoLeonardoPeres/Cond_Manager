import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
      _isSuccess = false;
    });

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
    );

    if (!mounted) return;

    result.when(
      success: (_) => setState(() {
        _message = 'Cadastro realizado! Verifique seu e-mail para confirmar a conta.';
        _isSuccess = true;
      }),
      failure: (error) => setState(() => _message = error.message),
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                ClaySurface(
                  depth: ClayDepth.raised,
                  radius: ClayTokens.radiusFull,
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go('/login'),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Criar conta',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ClaySurface(
                    depth: ClayDepth.floating,
                    radius: ClayTokens.radiusXl,
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_message != null) ...[
                            ClaySurface(
                              depth: ClayDepth.pressed,
                              color: (_isSuccess ? ClayTokens.success : ClayTokens.error)
                                  .withValues(alpha: 0.1),
                              radius: ClayTokens.radiusSm,
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                _message!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isSuccess ? ClayTokens.success : ClayTokens.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          ClayTextField(
                            controller: _nameController,
                            label: 'Nome completo',
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: ClayTokens.textMuted),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Informe o nome' : null,
                          ),
                          const SizedBox(height: 18),
                          ClayTextField(
                            controller: _emailController,
                            label: 'E-mail',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined, color: ClayTokens.textMuted),
                            validator: (v) =>
                                v == null || !v.contains('@') ? 'E-mail inválido' : null,
                          ),
                          const SizedBox(height: 18),
                          ClayTextField(
                            controller: _passwordController,
                            label: 'Senha (mín. 6 caracteres)',
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: ClayTokens.textMuted),
                            validator: (v) =>
                                v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                          ),
                          const SizedBox(height: 28),
                          ClayButton(
                            label: 'Cadastrar',
                            isLoading: _isLoading,
                            onPressed: _register,
                            icon: Icons.person_add_rounded,
                          ),
                          const SizedBox(height: 12),
                          ClayButton(
                            label: 'Já tenho conta',
                            variant: ClayButtonVariant.secondary,
                            onPressed: () => context.go('/login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
