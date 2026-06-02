enum UserRole {
  platformAdmin('platform_admin', 'Administrador da plataforma'),
  condominiumAdmin('condominium_admin', 'Administrador do condomínio'),
  syndic('syndic', 'Síndico'),
  caretaker('caretaker', 'Zelador'),
  maintenanceManager('maintenance_manager', 'Gestor de manutenção'),
  internalEmployee('internal_employee', 'Funcionário interno'),
  serviceProvider('service_provider', 'Prestador de serviço'),
  supplier('supplier', 'Fornecedor'),
  resident('resident', 'Morador'),
  financial('financial', 'Financeiro'),
  auditor('auditor', 'Auditor');

  const UserRole(this.value, this.label);
  final String value;
  final String label;

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.resident,
    );
  }

  bool get canManageCondominium => switch (this) {
        UserRole.platformAdmin ||
        UserRole.condominiumAdmin ||
        UserRole.syndic ||
        UserRole.maintenanceManager ||
        UserRole.caretaker =>
          true,
        _ => false,
      };

  bool get canApproveWorkOrders => switch (this) {
        UserRole.platformAdmin ||
        UserRole.condominiumAdmin ||
        UserRole.syndic ||
        UserRole.financial ||
        UserRole.maintenanceManager =>
          true,
        _ => false,
      };

  bool get canViewFinancial => switch (this) {
        UserRole.platformAdmin ||
        UserRole.condominiumAdmin ||
        UserRole.syndic ||
        UserRole.financial ||
        UserRole.maintenanceManager ||
        UserRole.auditor =>
          true,
        _ => false,
      };
}
