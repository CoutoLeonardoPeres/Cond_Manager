import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompanyModulesPage extends ConsumerStatefulWidget {
  const CompanyModulesPage({super.key});

  @override
  ConsumerState<CompanyModulesPage> createState() => _CompanyModulesPageState();
}

class _CompanyModulesPageState extends ConsumerState<CompanyModulesPage> {
  final _toggling = <String>{};

  String _toggleKey(String companyId, AppModule module) => '$companyId:${module.value}';

  Future<void> _setModule({
    required CompanyModuleRow row,
    required AppModule module,
    required bool enabled,
  }) async {
    final key = _toggleKey(row.companyId, module);
    setState(() => _toggling.add(key));

    final result = await ref.read(companyModulesRepositoryProvider).setModuleEnabled(
          companyId: row.companyId,
          module: module,
          enabled: enabled,
        );

    if (!mounted) return;
    setState(() => _toggling.remove(key));

    result.when(
      success: (_) {
        ref.invalidate(companyModulesListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Módulo atualizado. Usuários afetados podem precisar fazer login novamente.',
            ),
          ),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar módulo: $error')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final isAdmin = profile?.isPlatformAdmin == true;

    if (!isAdmin) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Apenas administradores da plataforma podem gerenciar módulos das empresas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ClayTokens.textSecondary),
          ),
        ),
      );
    }

    final companiesAsync = ref.watch(companyModulesListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Módulos por empresa',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ative ou desative Manutenção e Locação para cada empresa gestora.',
                style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: companiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
            error: (e, _) => Center(child: Text('$e')),
            data: (companies) {
              if (companies.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhuma empresa cadastrada.',
                    style: TextStyle(color: ClayTokens.textSecondary),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(companyModulesListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: companies.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final row = companies[i];
                    return ClayCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.companyName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          _ModuleSwitchRow(
                            label: AppModule.maintenance.label,
                            value: row.maintenanceEnabled,
                            loading: _toggling.contains(
                              _toggleKey(row.companyId, AppModule.maintenance),
                            ),
                            onChanged: (v) => _setModule(
                              row: row,
                              module: AppModule.maintenance,
                              enabled: v,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _ModuleSwitchRow(
                            label: AppModule.rental.label,
                            value: row.rentalEnabled,
                            loading: _toggling.contains(
                              _toggleKey(row.companyId, AppModule.rental),
                            ),
                            onChanged: (v) => _setModule(
                              row: row,
                              module: AppModule.rental,
                              enabled: v,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModuleSwitchRow extends StatelessWidget {
  const _ModuleSwitchRow({
    required this.label,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: ClayTokens.textSecondary),
          ),
        ),
        if (loading)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Switch.adaptive(
            value: value,
            activeTrackColor: ClayTokens.primary.withValues(alpha: 0.5),
            activeThumbColor: ClayTokens.primary,
            onChanged: onChanged,
          ),
      ],
    );
  }
}
