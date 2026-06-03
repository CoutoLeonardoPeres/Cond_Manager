import 'package:cond_manager/features/materials/presentation/pages/material_balance_tab.dart';
import 'package:cond_manager/features/materials/presentation/pages/material_suppliers_tab.dart';
import 'package:cond_manager/features/materials/presentation/pages/materials_list_tab.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MaterialsPage extends ConsumerStatefulWidget {
  const MaterialsPage({super.key});

  @override
  ConsumerState<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends ConsumerState<MaterialsPage>
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
                'Materiais e equipamentos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Custos de compra, repasse aos condomínios, estoque e balanço operacional.',
                style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Cadastro'),
                  Tab(text: 'Fornecedores'),
                  Tab(text: 'Balanço'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              const MaterialsListTab(),
              const MaterialSuppliersTab(),
              Consumer(
                builder: (context, ref, _) {
                  final filter = ref.watch(materialListFilterProvider);
                  return MaterialBalanceTab(condominiumId: filter.condominiumId);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
