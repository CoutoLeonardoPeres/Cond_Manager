import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/core/utils/invite_link.dart';
import 'package:cond_manager/features/rental/config/tenant_intake_form_config.dart';
import 'package:cond_manager/features/rental/presentation/pages/public_tenant_intake_page.dart';
import 'package:cond_manager/features/rental/presentation/widgets/dynamic_tenant_intake_form.dart';
import 'package:cond_manager/shared/domain/enums/rental_party_category.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RentalTenantIntakeLinkPage extends ConsumerStatefulWidget {
  const RentalTenantIntakeLinkPage({super.key});

  @override
  ConsumerState<RentalTenantIntakeLinkPage> createState() => _RentalTenantIntakeLinkPageState();
}

class _RentalTenantIntakeLinkPageState extends ConsumerState<RentalTenantIntakeLinkPage> {
  final _definition = defaultTenantIntakeFormDefinition;
  RentalPartyCategory _category = RentalPartyCategory.tenant;
  bool _loading = false;
  String? _error;
  String? _generatedLink;
  String? _generatedToken;
  DateTime? _expiresAt;

  Future<void> _generateLink() async {
    final profile = ref.read(currentProfileProvider).value;
    final companyId = profile?.companyId;
    final profileId = profile?.id;
    if (companyId == null || profileId == null) {
      setState(() => _error = 'Empresa não identificada.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref.read(tenantIntakeRepositoryProvider).createLink(
          companyId: companyId,
          category: _category,
          createdByProfileId: profileId,
          expirationHours: _definition.linkExpirationHours,
        );

    if (!mounted) return;

    result.when(
      success: (link) {
        final publicUrl = buildTenantIntakeLink(link.token);
        setState(() {
          _loading = false;
          _generatedLink = publicUrl;
          _generatedToken = link.token;
          _expiresAt = link.expiresAt;
        });
        _showLinkDialog(publicUrl);
      },
      failure: (e) => setState(() {
        _loading = false;
        _error = e.message;
      }),
    );
  }

  Future<void> _showLinkDialog(String link) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link gerado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_expiresAt != null)
              Text(
                'Válido até ${DateFormat('dd/MM/yyyy HH:mm').format(_expiresAt!.toLocal())}',
                style: const TextStyle(fontSize: 13, color: ClayTokens.textSecondary),
              ),
            const SizedBox(height: 12),
            SelectableText(link),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Link copiado!')),
                );
              }
            },
            child: const Text('Copiar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _shareWhatsApp(link);
            },
            child: const Text('WhatsApp'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareWhatsApp(String link) async {
    final message = buildTenantIntakeWhatsappMessage(
      definition: _definition,
      link: link,
    );
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = ref.watch(currentProfileProvider).value?.permissions.canManageRental ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClaySurface(
                depth: ClayDepth.raised,
                radius: ClayTokens.radiusFull,
                padding: EdgeInsets.zero,
                child: IconButton(
                  onPressed: () => context.go('/rental/parties'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Link de cadastro',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _definition.description,
            style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: ClayTokens.error)),
          ],
          const SizedBox(height: 20),
          ClaySurface(
            depth: ClayDepth.raised,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClayDropdownField<RentalPartyCategory>(
                  label: 'Tipo de cadastro *',
                  value: _category,
                  items: const [
                    RentalPartyCategory.tenant,
                    RentalPartyCategory.occupant,
                    RentalPartyCategory.guest,
                  ],
                  itemLabel: (c) => c.label,
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'O link expira em ${_definition.linkExpirationHours} horas e pode ser acessado sem login.',
                  style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary),
                ),
                const SizedBox(height: 16),
                ClayButton(
                  label: 'Gerar link',
                  icon: Icons.link_rounded,
                  isLoading: _loading,
                  onPressed: !canManage || _loading ? null : _generateLink,
                ),
              ],
            ),
          ),
          if (_generatedLink != null) ...[
            const SizedBox(height: 16),
            ClaySurface(
              depth: ClayDepth.pressed,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Último link gerado', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SelectableText(_generatedLink!),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => Clipboard.setData(ClipboardData(text: _generatedLink!)),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copiar'),
                      ),
                      TextButton.icon(
                        onPressed: () => _shareWhatsApp(_generatedLink!),
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: const Text('WhatsApp'),
                      ),
                      if (_generatedToken != null)
                        TextButton.icon(
                          onPressed: () => context.go('/cadastro-locatario/$_generatedToken'),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Pré-visualizar'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
