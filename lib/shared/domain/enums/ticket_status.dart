enum TicketStatus {
  open('open', 'Aberto'),
  inAnalysis('in_analysis', 'Em análise'),
  waitingInfo('waiting_info', 'Aguardando informações'),
  convertedToOs('converted_to_os', 'Convertido em OS'),
  resolved('resolved', 'Resolvido'),
  cancelled('cancelled', 'Cancelado');

  const TicketStatus(this.value, this.label);
  final String value;
  final String label;

  static TicketStatus fromValue(String value) {
    return TicketStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketStatus.open,
    );
  }
}
