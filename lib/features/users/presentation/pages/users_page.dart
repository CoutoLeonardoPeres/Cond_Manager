import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/users/domain/entities/organization_user.dart';
import 'package:cond_manager/features/users/presentation/providers/users_providers.dart';
import 'package:cond_manager/features/users/presentation/utils/user_management_permissions.dart';
import 'package:cond_manager/shared/domain/enums/organization_role.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final perms = profile.permissions;

    if (!perms.canAccessUsersModule) {
      return const Center(
        child: Text(
          'Sem permissão para gerenciar usuários.',
          style: TextStyle(color: ClayTokens.textSecondary),
        ),
      );
    }

    final usersAsync = ref.watch(organizationUsersListProvider);
    final filter = ref.watch(organizationUserListFilterProvider);
    final companiesAsync = ref.watch(managementCompaniesProvider);

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
                    'Usuários',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Admin, gerente, analista, equipe de campo e clientes dos condomínios.',
                    style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
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
                          ref.read(organizationUserListFilterProvider.notifier).state =
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
                                ref.read(organizationUserListFilterProvider.notifier).state =
                                    filter.copyWith(companyId: v.id);
                              }
                            : null,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),
                  ClayDropdownField<OrganizationRole?>(
                    label: 'Papel',
                    value: filter.role,
                    items: [null, ...OrganizationRole.values],
                    itemLabel: (r) => r?.label ?? 'Todos',
                    onChanged: (v) {
                      ref.read(organizationUserListFilterProvider.notifier).state =
                          filter.copyWith(role: v, clearRole: v == null);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: usersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (users) {
                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum usuário cadastrado nesta empresa.',
                        style: TextStyle(color: ClayTokens.textSecondary),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(organizationUsersListProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final u = users[index];
                        final canEdit = perms.canManageOrganizationUser(u);
                        return ClayListTileCard(
                          icon: _roleIcon(u),
                          iconColor: ClayTokens.primary,
                          title: u.fullName,
                          subtitle: [
                            u.roleLabel,
                            u.email,
                            if (u.condominiumNames.isNotEmpty)
                              u.condominiumNames.join(', '),
                            if (u.status != 'active') 'Inativo',
                            if (!canEdit) 'Somente admin edita',
                          ].join(' · '),
                          onTap: canEdit
                              ? () => context.go('/users/${u.profileId}/edit')
                              : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: ClayButton(
            label: 'Novo usuário',
            expand: false,
            icon: Icons.person_add_rounded,
            onPressed: () => context.go('/users/new'),
          ),
        ),
      ],
    );
  }

  IconData _roleIcon(OrganizationUser user) {
    if (user.isPlatformAdmin) return Icons.admin_panel_settings_rounded;
    return switch (user.organizationRole) {
        OrganizationRole.manager => Icons.supervisor_account_rounded,
        OrganizationRole.analyst => Icons.analytics_rounded,
        OrganizationRole.fieldTeam => Icons.engineering_rounded,
        OrganizationRole.client => Icons.apartment_rounded,
        null => Icons.person_rounded,
      };
  }
}
