import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    setState(() {
      _isLoading = true;
      _message = null;
      _isSuccess = false;
    });

    final result = await ref
        .read(authRepositoryProvider)
        .resetPassword(_emailController.text.trim());

    if (!mounted) return;

    result.when(
      success: (_) => setState(() {
        _message = 'Enviamos um link de recuperação para seu e-mail.';
        _isSuccess = true;
      }),
      failure: (e) => setState(() => _message = e.message),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: ClayTokens.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: ClayTokens.primary),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Recuperar senha',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Informe seu e-mail para receber o link de recuperação.',
                          style: TextStyle(color: ClayTokens.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 28),
                        ClayTextField(
                          controller: _emailController,
                          label: 'E-mail',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined, color: ClayTokens.textMuted),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 20),
                          ClaySurface(
                            depth: ClayDepth.pressed,
                            color: (_isSuccess ? ClayTokens.success : ClayTokens.warning)
                                .withValues(alpha: 0.12),
                            radius: ClayTokens.radiusSm,
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _isSuccess ? ClayTokens.success : ClayTokens.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        ClayButton(
                          label: 'Enviar link',
                          isLoading: _isLoading,
                          onPressed: _reset,
                          icon: Icons.send_rounded,
                        ),
                        const SizedBox(height: 12),
                        ClayButton(
                          label: 'Voltar ao login',
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
        ],
      ),
    );
  }
}
