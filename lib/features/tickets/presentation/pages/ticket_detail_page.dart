import 'package:cached_network_image/cached_network_image.dart';
import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/work_orders/presentation/utils/work_order_permissions.dart';
import 'package:cond_manager/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:cond_manager/features/tickets/presentation/utils/ticket_permissions.dart';
import 'package:cond_manager/features/tickets/presentation/widgets/ticket_status_chip.dart';
import 'package:cond_manager/shared/domain/enums/ticket_status.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TicketDetailPage extends ConsumerStatefulWidget {
  const TicketDetailPage({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
  final _messageController = TextEditingController();
  bool _isInternal = false;
  bool _sending = false;
  bool _updatingStatus = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(bool canManage) async {
    final text = _messageController.text.trim();
    if (text.length < 2) return;

    setState(() => _sending = true);
    final repo = ref.read(ticketRepositoryProvider);
    final result = await repo.addInteraction(
      ticketId: widget.ticketId,
      message: text,
      isInternal: canManage && _isInternal,
    );

    if (!mounted) return;
    setState(() => _sending = false);

    result.when(
      success: (_) {
        _messageController.clear();
        ref.invalidate(ticketInteractionsProvider(widget.ticketId));
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }

  Future<void> _updateStatus(TicketStatus status) async {
    setState(() => _updatingStatus = true);
    final repo = ref.read(ticketRepositoryProvider);
    final result = await repo.updateStatus(widget.ticketId, status);

    if (!mounted) return;
    setState(() => _updatingStatus = false);

    result.when(
      success: (_) {
        ref.invalidate(ticketDetailProvider(widget.ticketId));
        ref.invalidate(ticketsListProvider);
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }

  void _goBack(BuildContext context) {
    context.go(resolveReturnPath(context, fallback: '/tickets'));
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    final interactionsAsync = ref.watch(ticketInteractionsProvider(widget.ticketId));
    final attachmentsAsync = ref.watch(ticketAttachmentsProvider(widget.ticketId));
    final profileAsync = ref.watch(currentProfileProvider);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return ticketAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString()),
              const SizedBox(height: 12),
              ClayButton(
                label: 'Voltar',
                variant: ClayButtonVariant.secondary,
                onPressed: () => _goBack(context),
              ),
            ],
          ),
        ),
      ),
      data: (ticket) {
        final profile = profileAsync.value;
        final canManage = profile?.canManageTicketIn(ticket.condominiumId) ?? false;
        final canCreateOs = profile?.canCreateWorkOrdersAnywhere ?? false;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _goBack(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      ticket.displayNumber,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  TicketStatusChip(status: ticket.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TicketPriorityBadge(priority: ticket.priority),
                  const SizedBox(width: 16),
                  Text(
                    ticket.serviceType.label,
                    style: const TextStyle(color: ClayTokens.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClaySurface(
                depth: ClayDepth.raised,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow('ID do chamado', ticket.displayNumber),
                    _InfoRow('Condomínio', ticket.condominiumName ?? '—'),
                    _InfoRow('Solicitante', ticket.requesterName ?? '—'),
                    _InfoRow('Local', ticket.locationType.label),
                    if (ticket.locationDescription?.isNotEmpty == true)
                      _InfoRow('Detalhes', ticket.locationDescription!),
                    _InfoRow('Abertura', dateFmt.format(ticket.createdAt.toLocal())),
                    if (ticket.resolvedAt != null)
                      _InfoRow('Resolvido', dateFmt.format(ticket.resolvedAt!.toLocal())),
                    const SizedBox(height: 12),
                    const Text(
                      'Descrição',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ClayTokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(ticket.description, style: const TextStyle(height: 1.45)),
                  ],
                ),
              ),
              if (canManage || canCreateOs) ...[
                const SizedBox(height: 16),
                ClaySurface(
                  depth: ClayDepth.raised,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ordem de serviço',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      if (ticket.workOrderId != null)
                        ClayButton(
                          label: 'Ver ordem de serviço',
                          variant: ClayButtonVariant.secondary,
                          icon: Icons.assignment_rounded,
                          onPressed: () =>
                              context.go('/work-orders/${ticket.workOrderId}'),
                        )
                      else if (canCreateOs)
                        ClayButton(
                          label: 'Gerar ordem de serviço',
                          icon: Icons.assignment_rounded,
                          onPressed: () => context.go(
                            Uri(
                              path: '/work-orders/new',
                              queryParameters: {
                                'ticketId': ticket.id,
                                'condominiumId': ticket.condominiumId,
                                'returnTo': '/tickets/${ticket.id}',
                              },
                            ).toString(),
                          ),
                        )
                      else
                        const Text(
                          'Sem permissão para gerar OS.',
                          style: TextStyle(color: ClayTokens.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
              if (canManage) ...[
                const SizedBox(height: 16),
                ClaySurface(
                  depth: ClayDepth.raised,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Atualizar status',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TicketStatus.values
                            .where((s) => s != ticket.status)
                            .map(
                              (status) => ActionChip(
                                label: Text(status.label),
                                onPressed: _updatingStatus
                                    ? null
                                    : () => _updateStatus(status),
                              ),
                            )
                            .toList(),
                      ),
                      if (_updatingStatus)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ],
              attachmentsAsync.when(
                data: (files) {
                  if (files.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Anexos',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: files.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final file = files[i];
                            final isImage = file.mimeType?.startsWith('image/') ?? true;
                            if (!isImage) {
                              return ClaySurface(
                                depth: ClayDepth.raised,
                                padding: const EdgeInsets.all(12),
                                child: Text(file.fileName),
                              );
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                              child: CachedNetworkImage(
                                imageUrl: file.fileUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => const SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (_, _, _) => const Icon(Icons.broken_image_outlined),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Histórico',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              interactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erro: $e'),
                data: (items) {
                  if (items.isEmpty) {
                    return const Text(
                      'Nenhuma mensagem ainda.',
                      style: TextStyle(color: ClayTokens.textSecondary),
                    );
                  }
                  return Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ClaySurface(
                              depth: ClayDepth.pressed,
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.authorName ?? 'Usuário',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      if (item.isInternal) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ClayTokens.warning.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Interno',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      Text(
                                        dateFmt.format(item.createdAt.toLocal()),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: ClayTokens.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(item.message),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              ClayTextField(
                controller: _messageController,
                label: 'Nova mensagem',
                hint: 'Escreva uma atualização ou pergunta',
                maxLines: 3,
              ),
              if (canManage) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Nota interna (visível só para gestão)',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: _isInternal,
                  onChanged: _sending
                      ? null
                      : (v) => setState(() => _isInternal = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
              const SizedBox(height: 12),
              ClayButton(
                label: _sending ? 'Enviando...' : 'Enviar mensagem',
                icon: Icons.send_rounded,
                onPressed: _sending ? null : () => _sendMessage(canManage),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: ClayTokens.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
