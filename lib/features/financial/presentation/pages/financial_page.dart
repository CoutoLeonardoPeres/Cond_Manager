import 'package:cond_manager/features/financial/presentation/pages/financial_company_report_tab.dart';
import 'package:cond_manager/features/financial/presentation/pages/financial_condo_report_tab.dart';
import 'package:cond_manager/features/financial/presentation/pages/financial_records_tab.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinancialPage extends ConsumerStatefulWidget {
  const FinancialPage({super.key});

  @override
  ConsumerState<FinancialPage> createState() => _FinancialPageState();
}

class _FinancialPageState extends ConsumerState<FinancialPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financeiro',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Despesas e receitas da manutenção — mão de obra, materiais, OS, '
                'prestadores e custos da gestora. Receitas de aluguel e locação '
                'ficam em Locação → Cobranças.',
                style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Lançamentos'),
                  Tab(text: 'Relatório condomínios'),
                  Tab(text: 'Relatório gestora'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              FinancialRecordsTab(),
              FinancialCondoReportTab(),
              FinancialCompanyReportTab(),
            ],
          ),
        ),
      ],
    );
  }
}
