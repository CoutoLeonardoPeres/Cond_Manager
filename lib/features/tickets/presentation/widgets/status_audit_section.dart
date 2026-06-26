import 'package:cond_manager/features/tickets/domain/entities/status_change_log.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatusAuditSection extends StatelessWidget {
  const StatusAuditSection({
    super.key,
    required this.changes,
    this.title = 'Auditoria de status',
    this.newestFirst = true,
    this.embedded = false,
  });

  final List<StatusChangeLog> changes;
  final String title;
  final bool newestFirst;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    if (changes.isEmpty) return const SizedBox.shrink();

    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final sorted = newestFirst
        ? (List<StatusChangeLog>.from(changes)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        : changes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!embedded) const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...sorted.map(
          (log) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClaySurface(
              depth: ClayDepth.pressed,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.fromStatus != null
                              ? '${log.fromStatus} → ${log.toStatus}'
                              : log.toStatus,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      Text(
                        dateFmt.format(log.createdAt.toLocal()),
                        style: const TextStyle(
                          fontSize: 11,
                          color: ClayTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.changedByName,
                    style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary),
                  ),
                  if (log.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(log.notes!, style: const TextStyle(fontSize: 12, height: 1.35)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
