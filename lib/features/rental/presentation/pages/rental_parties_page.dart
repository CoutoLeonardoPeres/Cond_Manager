import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RentalPartiesPage extends ConsumerWidget {
  const RentalPartiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(rentalPartiesListProvider);
    final canCreate = ref.watch(currentProfileProvider).value?.permissions.canManageRental ?? false;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pessoas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Proprietários, inquilinos, hóspedes, fiadores e contatos de imobiliárias.',
                    style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: partiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (parties) {
                  if (parties.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Nenhuma pessoa cadastrada.',
                            style: TextStyle(color: ClayTokens.textSecondary),
                          ),
                          if (canCreate) ...[
                            const SizedBox(height: 16),
                            ClayButton(
                              label: 'Nova pessoa',
                              expand: false,
                              icon: Icons.add_rounded,
                              onPressed: () => context.go('/rental/parties/new'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(rentalPartiesListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: parties.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = parties[i];
                        return ClayListTileCard(
                          icon: Icons.person_rounded,
                          title: p.fullName,
                          subtitle: [
                            if (p.email != null) p.email,
                            if (p.phone != null) p.phone,
                            if (p.documentNumber != null) p.documentNumber,
                            if (p.status != 'active') 'Inativo',
                          ].whereType<String>().join(' · '),
                          onTap: () => context.go('/rental/parties/${p.id}/edit'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (canCreate)
          Positioned(
            right: 20,
            bottom: 20,
            child: ClayButton(
              label: 'Nova pessoa',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go('/rental/parties/new'),
            ),
          ),
      ],
    );
  }
}
