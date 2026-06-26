import 'package:cond_manager/core/theme/app_typography.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    result.when(
      success: (_) => context.go('/'),
      failure: (error) => setState(() => _errorMessage = error.message),
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 900;

    return ClayScaffold(
      showOrbs: true,
      body: Row(
        children: [
          if (isWide) const Expanded(child: _BrandingPanel()),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ClaySurface(
                    depth: ClayDepth.floating,
                    radius: ClayTokens.radiusHero,
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isWide) ...[
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: ClayTokens.primaryGradient,
                                  borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
                                ),
                                child: const Icon(
                                  Icons.apartment_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  ClayTokens.textGradient.createShader(bounds),
                              child: Text(
                                'Cond Manager',
                                textAlign: TextAlign.center,
                                style: AppTypography.heading(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                          Text(
                            'Bem-vindo de volta',
                            style: AppTypography.heading(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Gestão de manutenção para condomínios',
                            style: TextStyle(color: ClayTokens.textSecondary),
                          ),
                          const SizedBox(height: 28),
                          if (_errorMessage != null) ...[
                            ClaySurface(
                              depth: ClayDepth.pressed,
                              color: ClayTokens.error.withValues(alpha: 0.08),
                              radius: ClayTokens.radiusSm,
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: ClayTokens.error, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: ClayTokens.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          ClayTextField(
                            controller: _emailController,
                            label: 'E-mail',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined, color: ClayTokens.textMuted),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Informe o e-mail';
                              if (!v.contains('@')) return 'E-mail inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          ClayTextField(
                            controller: _passwordController,
                            label: 'Senha',
                            obscureText: _obscurePassword,
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: ClayTokens.textMuted),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: ClayTokens.textMuted,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Informe a senha' : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: const Text('Esqueci minha senha'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClayButton(
                            label: 'Entrar',
                            isLoading: _isLoading,
                            onPressed: _signIn,
                            icon: Icons.login_rounded,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Não tem conta?',
                                style: TextStyle(color: ClayTokens.textSecondary),
                              ),
                              TextButton(
                                onPressed: () => context.push('/register'),
                                child: const Text('Cadastre-se'),
                              ),
                            ],
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

class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: ClaySurface(
        gradient: ClayTokens.brandPanelGradient,
        borderless: true,
        radius: ClayTokens.radiusHero,
        depth: ClayDepth.floating,
        padding: const EdgeInsets.all(48),
        glass: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BrandIcon(),
              const SizedBox(height: 28),
              Text(
                'Cond Manager',
                style: AppTypography.heading(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Gestão de manutenção para condomínios — interface clay premium, tátil e acolhedora.',
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ClayTokens.radiusCard),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
      ),
      child: const Icon(Icons.apartment_rounded, size: 52, color: Colors.white),
    );
  }
}
