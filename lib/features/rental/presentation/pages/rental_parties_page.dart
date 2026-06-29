import 'package:cond_manager/core/formatters/brazilian_input_format.dart';
import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RentalPartiesPage extends ConsumerWidget {
  const RentalPartiesPage({super.key});

  List<RentalParty> _filterParties(List<RentalParty> parties, String query) {
    final q = query.trim();
    if (q.isEmpty) return parties;

    final qLower = q.toLowerCase();
    final qDigits = BrazilianInputFormat.digitsOnly(q);

    return parties.where((p) {
      if (p.fullName.toLowerCase().contains(qLower)) return true;

      if (qDigits.isNotEmpty) {
        final docDigits = BrazilianInputFormat.digitsOnly(p.documentNumber);
        if (docDigits.contains(qDigits)) return true;

        final phoneDigits = BrazilianInputFormat.digitsOnly(p.phone);
        if (phoneDigits.contains(qDigits)) return true;
      }

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(rentalPartiesListProvider);
    final searchQuery = ref.watch(rentalPartySearchQueryProvider);
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
                  const SizedBox(height: 12),
                  ClayTextField(
                    label: 'Pesquisar',
                    hint: 'Nome, CPF ou telefone…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    onChanged: (v) =>
                        ref.read(rentalPartySearchQueryProvider.notifier).state = v,
                  ),
                  if (canCreate) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/rental/parties/intake-link'),
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: const Text('Gerar link de cadastro para inquilino'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: partiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (parties) {
                  final filtered = _filterParties(parties, searchQuery);

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

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhuma pessoa encontrada para "$searchQuery".',
                        style: const TextStyle(color: ClayTokens.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(rentalPartiesListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        return ClayListTileCard(
                          icon: Icons.person_rounded,
                          title: p.fullName,
                          subtitle: [
                            p.category.label,
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
