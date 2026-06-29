import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/rental/config/tenant_intake_form_config.dart';
import 'package:cond_manager/features/rental/data/repositories/tenant_intake_repository_impl.dart';
import 'package:cond_manager/features/rental/domain/repositories/tenant_intake_repository.dart';
import 'package:cond_manager/features/rental/domain/entities/tenant_intake_form_models.dart';
import 'package:cond_manager/features/rental/presentation/widgets/dynamic_tenant_intake_form.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final tenantIntakeRepositoryProvider = Provider<TenantIntakeRepository>((ref) {
  return TenantIntakeRepositoryImpl(ref.watch(supabaseClientProvider));
});

final tenantIntakePreviewProvider =
    FutureProvider.autoDispose.family<TenantIntakeLinkPreview, String>((ref, token) async {
  final result = await ref.watch(tenantIntakeRepositoryProvider).getLinkPreview(token);
  return result.when(success: (p) => p, failure: (e) => throw e);
});

class PublicTenantIntakePage extends ConsumerStatefulWidget {
  const PublicTenantIntakePage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<PublicTenantIntakePage> createState() => _PublicTenantIntakePageState();
}

class _PublicTenantIntakePageState extends ConsumerState<PublicTenantIntakePage> {
  final _definition = defaultTenantIntakeFormDefinition;
  String? _submissionId;
  String? _protocol;
  bool _submitting = false;
  String? _error;

  Future<void> _submit(Map<String, String> values) async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final repo = ref.read(tenantIntakeRepositoryProvider);
    final formData = tenantIntakeValuesToJsonMap(values);

    final result = await repo.submit(
      token: widget.token,
      formData: formData,
      submissionId: _submissionId,
      userAgent: 'CondManager/${Theme.of(context).platform.name}',
    );

    if (!mounted) return;

    result.when(
      success: (r) => setState(() {
        _submitting = false;
        _protocol = r.protocol;
        _submissionId = r.submissionId;
      }),
      failure: (e) => setState(() {
        _submitting = false;
        _error = e.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref.watch(tenantIntakePreviewProvider(widget.token));
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      body: SafeArea(
        child: previewAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('$e', textAlign: TextAlign.center),
            ),
          ),
          data: (preview) {
            if (_protocol != null) {
              return _SuccessView(
                message: _definition.successMessage,
                protocol: _protocol!,
              );
            }

            if (!preview.isValid) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link_off_rounded, size: 48, color: ClayTokens.error),
                      const SizedBox(height: 12),
                      const Text(
                        'Link inválido ou expirado',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preview.expiresAt != null
                            ? 'Validade: ${dateFmt.format(preview.expiresAt!.toLocal())}'
                            : 'Solicite um novo link à imobiliária.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: ClayTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _definition.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (preview.companyName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview.companyName!,
                      style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _definition.description,
                    style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Link válido até ${dateFmt.format(preview.expiresAt!.toLocal())}',
                    style: const TextStyle(fontSize: 12, color: ClayTokens.textMuted),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    ClaySurface(
                      depth: ClayDepth.pressed,
                      color: ClayTokens.error.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!, style: const TextStyle(color: ClayTokens.error)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  DynamicTenantIntakeForm(
                    definition: _definition,
                    loading: _submitting,
                    onSubmit: _submit,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.message, required this.protocol});

  final String message;
  final String protocol;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 64, color: ClayTokens.success),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ClaySurface(
              depth: ClayDepth.pressed,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Protocolo', style: TextStyle(color: ClayTokens.textSecondary)),
                  const SizedBox(height: 4),
                  SelectableText(
                    protocol,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
