enum WorkOrderStatus {
  open('open', 'Aberta'),
  triage('triage', 'Em triagem'),
  waitingBudget('waiting_budget', 'Aguardando orçamento'),
  budgetReceived('budget_received', 'Orçamento recebido'),
  waitingApproval('waiting_approval', 'Aguardando aprovação'),
  approved('approved', 'Aprovada'),
  inProgress('in_progress', 'Em execução'),
  paused('paused', 'Pausada'),
  waitingMaterial('waiting_material', 'Aguardando material'),
  completed('completed', 'Concluída'),
  rejected('rejected', 'Reprovada'),
  cancelled('cancelled', 'Cancelada'),
  closed('closed', 'Encerrada');

  const WorkOrderStatus(this.value, this.label);
  final String value;
  final String label;

  static WorkOrderStatus fromValue(String value) {
    return WorkOrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkOrderStatus.open,
    );
  }

  bool get isTerminal => switch (this) {
        WorkOrderStatus.completed ||
        WorkOrderStatus.rejected ||
        WorkOrderStatus.cancelled ||
        WorkOrderStatus.closed =>
          true,
        _ => false,
      };
}
