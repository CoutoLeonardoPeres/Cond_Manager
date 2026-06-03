import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/auth/domain/entities/user_invitation_preview.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final invitationPreviewProvider = FutureProvider.autoDispose
    .family<UserInvitationPreview?, String>((ref, token) async {
  final repo = ref.watch(authRepositoryProvider);
  final result = await repo.getInvitationPreview(token);
  return result.when(success: (p) => p, failure: (e) => throw e);
});

class AcceptInvitePage extends ConsumerStatefulWidget {
  const AcceptInvitePage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<AcceptInvitePage> createState() => _AcceptInvitePageState();
}

class _AcceptInvitePageState extends ConsumerState<AcceptInvitePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = false;
  bool _loading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _acceptAndGoHome() async {
    final result = await ref.read(authRepositoryProvider).acceptInvitation(widget.token);
    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(currentProfileProvider);
        context.go('/');
      },
      failure: (e) => setState(() {
        _message = e.message;
        _isSuccess = false;
        _loading = false;
      }),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });

    final result = await ref.read(authRepositoryProvider).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );

    if (!mounted) return;

    result.when(
      success: (_) async {
        final session = ref.read(authStateProvider).value?.session;
        if (session != null) {
          await _acceptAndGoHome();
        } else {
          setState(() {
            _message =
                'Conta criada! Confirme seu e-mail e depois acesse este link novamente para ativar o convite.';
            _isSuccess = true;
            _loading = false;
          });
        }
      },
      failure: (e) => setState(() {
        _message = e.message;
        _loading = false;
      }),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });

    final result = await ref.read(authRepositoryProvider).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    result.when(
      success: (_) async => await _acceptAndGoHome(),
      failure: (e) => setState(() {
        _message = e.message;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref.watch(invitationPreviewProvider(widget.token));

    return ClayScaffold(
      body: previewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
        error: (e, _) => Center(child: Text('Erro ao carregar convite: $e')),
        data: (preview) {
          if (preview == null || preview.email == null) {
            return _InviteMessage(
              title: 'Convite não encontrado',
              message: 'Verifique se o link está correto ou peça um novo convite.',
              onBack: () => context.go('/login'),
            );
          }

          if (!preview.isValid) {
            return _InviteMessage(
              title: 'Convite expirado ou já utilizado',
              message: 'Solicite um novo convite ao administrador da empresa.',
              onBack: () => context.go('/login'),
            );
          }

          if (_emailController.text.isEmpty) {
            _emailController.text = preview.email!;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ClaySurface(
                  depth: ClayDepth.floating,
                  radius: ClayTokens.radiusXl,
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Aceitar convite',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Você foi convidado para acessar o Cond Manager.',
                          style: TextStyle(color: ClayTokens.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        _InviteSummaryCard(preview: preview),
                        const SizedBox(height: 20),
                        if (_message != null) ...[
                          ClaySurface(
                            depth: ClayDepth.pressed,
                            color: (_isSuccess ? ClayTokens.success : ClayTokens.error)
                                .withValues(alpha: 0.1),
                            radius: ClayTokens.radiusSm,
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _isSuccess ? ClayTokens.success : ClayTokens.error,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: ClayButton(
                                label: 'Criar conta',
                                variant: _isLoginMode
                                    ? ClayButtonVariant.secondary
                                    : ClayButtonVariant.primary,
                                onPressed: _loading ? null : () => setState(() => _isLoginMode = false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClayButton(
                                label: 'Já tenho conta',
                                variant: _isLoginMode
                                    ? ClayButtonVariant.primary
                                    : ClayButtonVariant.secondary,
                                onPressed: _loading ? null : () => setState(() => _isLoginMode = true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!_isLoginMode)
                          ClayTextField(
                            controller: _nameController,
                            label: 'Nome completo',
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                          ),
                        if (!_isLoginMode) const SizedBox(height: 12),
                        ClayTextField(
                          controller: _emailController,
                          label: 'E-mail do convite',
                          readOnly: true,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        ClayTextField(
                          controller: _passwordController,
                          label: 'Senha',
                          obscureText: true,
                          validator: (v) =>
                              v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                        ),
                        const SizedBox(height: 20),
                        ClayButton(
                          label: _isLoginMode ? 'Entrar e aceitar' : 'Cadastrar e aceitar',
                          isLoading: _loading,
                          icon: Icons.check_circle_outline_rounded,
                          onPressed: _loading ? null : (_isLoginMode ? _login : _register),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Voltar ao login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InviteSummaryCard extends StatelessWidget {
  const _InviteSummaryCard({required this.preview});

  final UserInvitationPreview preview;

  @override
  Widget build(BuildContext context) {
    final roleLabel = preview.organizationRole?.label ?? 'Usuário';
    final condos = preview.condominiumNames.isEmpty
        ? null
        : preview.condominiumNames.join(', ');

    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Empresa', preview.companyName ?? '—'),
          _row('Papel', roleLabel),
          if (condos != null) _row('Condomínios', condos),
          if (preview.expiresAt != null)
            _row(
              'Válido até',
              '${preview.expiresAt!.day.toString().padLeft(2, '0')}/'
              '${preview.expiresAt!.month.toString().padLeft(2, '0')}/'
              '${preview.expiresAt!.year}',
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: ClayTokens.textPrimary, height: 1.4),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      );
}

class _InviteMessage extends StatelessWidget {
  const _InviteMessage({
    required this.title,
    required this.message,
    required this.onBack,
  });

  final String title;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClaySurface(
            depth: ClayDepth.floating,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ClayButton(label: 'Ir para login', onPressed: onBack),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
