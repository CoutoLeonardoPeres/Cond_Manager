/// Rótulo de unidade com contexto de bloco/torre, ex.: "Bloco A - Apt 101".
String formatUnitDisplayLabel({
  required String identifier,
  String? blockName,
  String? towerName,
}) {
  final structure = <String>[];
  if (blockName != null && blockName.trim().isNotEmpty) {
    structure.add(blockName.trim());
  }
  if (towerName != null &&
      towerName.trim().isNotEmpty &&
      towerName.trim() != blockName?.trim()) {
    structure.add(towerName.trim());
  }
  if (structure.isEmpty) return identifier;
  return '${structure.join(' - ')} - $identifier';
}
