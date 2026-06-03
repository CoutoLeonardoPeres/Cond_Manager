import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/financial/presentation/utils/financial_permissions.dart';
import 'package:cond_manager/features/financial/presentation/widgets/financial_report_view.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinancialCompanyReportTab extends ConsumerWidget {
  const FinancialCompanyReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final query = ref.watch(financialCompanyReportFilterProvider);
    final summaryAsync = ref.watch(financialReportProvider(query));

    if (profile != null && !profile.canViewManagementFinancial) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sem permissão para visualizar o financeiro da empresa gestora.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ClayTokens.textSecondary),
          ),
        ),
      );
    }

    return FinancialReportView(
      title: 'Relatório da empresa gestora',
      summaryAsync: summaryAsync,
      onRefresh: () async => ref.invalidate(financialReportProvider(query)),
    );
  }
}
