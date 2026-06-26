/// Status do chamado (ordem de exibição e fluxo).
enum TicketStatus {
  open('open', 'Aberto'),
  inAnalysis('in_analysis', 'Em análise'),
  waitingMaterial('waiting_material', 'Aguardando Material'),
  inProgress('in_progress', 'Em execução'),
  completed('completed', 'Concluído'),
  cancelled('cancelled', 'Cancelado');

  const TicketStatus(this.value, this.label);
  final String value;
  final String label;

  /// Ordem fixa para listas e chips.
  static const displayOrder = [
    TicketStatus.open,
    TicketStatus.inAnalysis,
    TicketStatus.waitingMaterial,
    TicketStatus.inProgress,
    TicketStatus.completed,
    TicketStatus.cancelled,
  ];

  bool get isTerminal =>
      this == TicketStatus.completed || this == TicketStatus.cancelled;

  bool get isOpenForMetrics =>
      this == TicketStatus.open ||
      this == TicketStatus.inAnalysis ||
      this == TicketStatus.waitingMaterial ||
      this == TicketStatus.inProgress;

  static TicketStatus fromValue(String value) {
    final normalized = _legacyToCurrent[value] ?? value;
    return TicketStatus.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => TicketStatus.open,
    );
  }

  static const _legacyToCurrent = {
    'waiting_info': 'in_analysis',
    'converted_to_os': 'in_progress',
    'resolved': 'completed',
  };
}
