import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/access_logs/domain/entities/access_session_log.dart';
import 'package:cond_manager/features/access_logs/presentation/providers/access_log_providers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/users/domain/entities/organization_user.dart';
import 'package:cond_manager/features/users/presentation/providers/users_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AccessLogsPage extends ConsumerWidget {
  const AccessLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final perms = profile.permissions;

    if (!perms.canViewAccessLogs) {
      return const Center(
        child: Text(
          'Somente administrador ou gerente pode consultar o log de acesso.',
          style: TextStyle(color: ClayTokens.textSecondary),
        ),
      );
    }

    final logsAsync = ref.watch(accessSessionsListProvider);
    final summaryAsync = ref.watch(accessLogSummaryProvider);
    final filter = ref.watch(accessLogFilterProvider);
    final companiesAsync = ref.watch(managementCompaniesProvider);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log de acesso',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tempo de uso, data/hora e contexto por sessão de acesso.',
                style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              summaryAsync.when(
                data: (summary) => Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _SummaryChip('Acessos', '${summary.sessionCount}'),
                    _SummaryChip('Usuários', '${summary.uniqueUsers}'),
                    _SummaryChip(
                      'Tempo total',
                      _formatDuration(summary.totalDurationSeconds),
                    ),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              companiesAsync.when(
                data: (companies) {
                  if (companies.isEmpty) return const SizedBox.shrink();

                  final targetId = filter.companyId ?? profile?.companyId;
                  final selected = companies.firstWhere(
                    (c) => c.id == targetId,
                    orElse: () => companies.first,
                  );
                  if (filter.companyId == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.read(accessLogFilterProvider.notifier).state =
                          filter.copyWith(companyId: selected.id);
                    });
                  }
                  return ClayDropdownField<ManagementCompany>(
                    label: 'Empresa gestora',
                    value: selected,
                    items: companies,
                    itemLabel: (c) => c.displayName,
                    onChanged: perms.isAdmin
                        ? (v) {
                            if (v == null) return;
                            ref.read(accessLogFilterProvider.notifier).state =
                                filter.copyWith(companyId: v.id);
                          }
                        : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClayDropdownField<int?>(
                      label: 'Ano',
                      value: filter.year,
                      items: _yearOptions(),
                      itemLabel: (y) => y?.toString() ?? 'Todos',
                      onChanged: (v) => ref.read(accessLogFilterProvider.notifier).state =
                          filter.copyWith(year: v, clearYear: v == null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClayDropdownField<int?>(
                      label: 'Mês',
                      value: filter.month,
                      items: [null, ...List.generate(12, (i) => i + 1)],
                      itemLabel: (m) => m == null ? 'Todos' : m.toString().padLeft(2, '0'),
                      onChanged: (v) => ref.read(accessLogFilterProvider.notifier).state =
                          filter.copyWith(month: v, clearMonth: v == null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClayDropdownField<int?>(
                      label: 'Dia',
                      value: filter.day,
                      items: [null, ...List.generate(31, (i) => i + 1)],
                      itemLabel: (d) => d == null ? 'Todos' : d.toString().padLeft(2, '0'),
                      onChanged: (v) => ref.read(accessLogFilterProvider.notifier).state =
                          filter.copyWith(day: v, clearDay: v == null),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _formatLoadError('$e'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ClayTokens.textSecondary),
                ),
              ),
            ),
            data: (logs) {
              if (logs.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum registro de acesso no período.',
                    style: TextStyle(color: ClayTokens.textSecondary),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(accessSessionsListProvider);
                  ref.invalidate(accessLogSummaryProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _AccessLogTile(log: log, dateFmt: dateFmt);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _formatLoadError(String message) {
    if (message.contains('user_access_sessions')) {
      return 'A tabela de log de acesso ainda não foi criada no Supabase. '
          'Aplique a migration 00025_user_access_sessions.sql e atualize a página.';
    }
    return message;
  }

  static List<int?> _yearOptions() {
    final current = DateTime.now().year;
    return [null, ...List.generate(5, (i) => current - i)];
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) return '—';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}min';
    if (m > 0) return '${m}min ${s}s';
    return '${s}s';
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _AccessLogTile extends StatelessWidget {
  const _AccessLogTile({required this.log, required this.dateFmt});

  final AccessSessionLog log;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final duration = log.durationSeconds != null
        ? AccessLogsPage._formatDuration(log.durationSeconds!)
        : (log.isActive ? 'Em andamento' : '—');

    return ClaySurface(
      depth: ClayDepth.raised,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  log.userFullName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              Text(
                duration,
                style: const TextStyle(fontWeight: FontWeight.w700, color: ClayTokens.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _MetaRow('Entrada', dateFmt.format(log.startedAt.toLocal())),
          if (log.endedAt != null)
            _MetaRow('Saída', dateFmt.format(log.endedAt!.toLocal())),
          _MetaRow('Data', '${log.accessDay.toString().padLeft(2, '0')}/'
              '${log.accessMonth.toString().padLeft(2, '0')}/${log.accessYear}'),
          _MetaRow('Empresa', log.companyName ?? '—'),
          _MetaRow('Condomínio', log.condominiumName ?? '—'),
          _MetaRow('Gerente do contrato', log.contractManagerName ?? '—'),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: ClayTokens.textMuted),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
