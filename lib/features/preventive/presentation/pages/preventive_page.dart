import 'package:cond_manager/features/preventive/presentation/pages/preventive_backlog_tab.dart';
import 'package:cond_manager/features/preventive/presentation/pages/preventive_plans_tab.dart';
import 'package:cond_manager/features/preventive/presentation/providers/preventive_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreventivePage extends ConsumerStatefulWidget {
  const PreventivePage({super.key});

  @override
  ConsumerState<PreventivePage> createState() => _PreventivePageState();
}

class _PreventivePageState extends ConsumerState<PreventivePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(preventivePlanListFilterProvider);
    final backlogCount =
        ref.watch(preventiveBacklogCountProvider(filter.condominiumId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manutenção preventiva',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Planos periódicos, alertas antecipados e backlog de OS para equipe ou prestadores.',
                style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabs,
                tabs: [
                  const Tab(text: 'Planos'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Backlog OS'),
                        backlogCount.when(
                          data: (n) => n > 0
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ClayTokens.warning,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$n',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              const PreventivePlansTab(),
              PreventiveBacklogTab(condominiumId: filter.condominiumId),
            ],
          ),
        ),
      ],
    );
  }
}
