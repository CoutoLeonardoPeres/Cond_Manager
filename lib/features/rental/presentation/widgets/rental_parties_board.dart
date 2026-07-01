import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/shared/domain/enums/rental_party_category.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';

/// Ordem das colunas na tela Pessoas (esquerda → direita).
const rentalPartyBoardColumnOrder = <RentalPartyCategory>[
  RentalPartyCategory.guest,
  RentalPartyCategory.occupant,
  RentalPartyCategory.tenant,
  RentalPartyCategory.landlord,
];

IconData partyCategoryIcon(RentalPartyCategory category) => switch (category) {
      RentalPartyCategory.guest => Icons.hotel_rounded,
      RentalPartyCategory.occupant => Icons.key_rounded,
      RentalPartyCategory.tenant => Icons.assignment_ind_rounded,
      RentalPartyCategory.landlord => Icons.home_work_rounded,
    };

Color partyCategoryColor(RentalPartyCategory category) => switch (category) {
      RentalPartyCategory.guest => ClayTokens.accentAlt,
      RentalPartyCategory.occupant => ClayTokens.accent,
      RentalPartyCategory.tenant => ClayTokens.primaryDark,
      RentalPartyCategory.landlord => ClayTokens.success,
    };

Map<RentalPartyCategory, List<RentalParty>> groupRentalPartiesByCategory(
  List<RentalParty> parties,
) {
  final grouped = {
    for (final c in rentalPartyBoardColumnOrder) c: <RentalParty>[],
  };
  for (final party in parties) {
    grouped[party.category]?.add(party);
  }
  for (final list in grouped.values) {
    list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  }
  return grouped;
}

class RentalPartiesBoard extends StatelessWidget {
  const RentalPartiesBoard({
    super.key,
    required this.parties,
    required this.onOpenParty,
  });

  final List<RentalParty> parties;
  final void Function(RentalParty party) onOpenParty;

  @override
  Widget build(BuildContext context) {
    final grouped = groupRentalPartiesByCategory(parties);

    return LayoutBuilder(
      builder: (context, constraints) {
        const minColumnWidth = 220.0;
        final useRow = constraints.maxWidth >= minColumnWidth * 4 + 36;

        final columns = rentalPartyBoardColumnOrder
            .map(
              (category) => _PartiesBoardColumn(
                category: category,
                parties: grouped[category]!,
                onOpenParty: onOpenParty,
                width: useRow ? null : minColumnWidth,
              ),
            )
            .toList();

        if (useRow) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < columns.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: columns[i]),
              ],
            ],
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < columns.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                columns[i],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PartiesBoardColumn extends StatelessWidget {
  const _PartiesBoardColumn({
    required this.category,
    required this.parties,
    required this.onOpenParty,
    this.width,
  });

  final RentalPartyCategory category;
  final List<RentalParty> parties;
  final void Function(RentalParty party) onOpenParty;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final color = partyCategoryColor(category);
    final icon = partyCategoryIcon(category);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClaySurface(
          depth: ClayDepth.pressed,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.label,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              Text(
                '${parties.length}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (parties.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nenhuma pessoa',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ClayTokens.muted.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          )
        else
          ...parties.map(
            (party) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PartyBoardCard(
                party: party,
                icon: icon,
                iconColor: color,
                onTap: () => onOpenParty(party),
              ),
            ),
          ),
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: content);
    }
    return content;
  }
}

class _PartyBoardCard extends StatelessWidget {
  const _PartyBoardCard({
    required this.party,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final RentalParty party;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (party.phone != null) party.phone,
      if (party.email != null) party.email,
      if (party.documentNumber != null) party.documentNumber,
      if (party.status != 'active') 'Inativo',
      if (party.isRentalRestricted) 'Restrito',
    ].whereType<String>().join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
        child: ClaySurface(
          depth: ClayDepth.raised,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ClayTokens.textSecondary,
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
