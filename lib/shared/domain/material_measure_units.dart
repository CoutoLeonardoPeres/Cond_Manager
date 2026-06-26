/// Unidades de medida para cadastro e estoque de materiais.
class MaterialMeasureUnit {
  const MaterialMeasureUnit(this.code, this.label);

  final String code;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialMeasureUnit && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

abstract final class MaterialMeasureUnits {
  static const MaterialMeasureUnit un = MaterialMeasureUnit('un', 'Unidade (un)');
  static const MaterialMeasureUnit pc = MaterialMeasureUnit('pc', 'Peça (pc)');
  static const MaterialMeasureUnit par = MaterialMeasureUnit('par', 'Par');
  static const MaterialMeasureUnit dz = MaterialMeasureUnit('dz', 'Dúzia');
  static const MaterialMeasureUnit cento = MaterialMeasureUnit('cento', 'Cento');
  static const MaterialMeasureUnit mil = MaterialMeasureUnit('mil', 'Milheiro');
  static const MaterialMeasureUnit kit = MaterialMeasureUnit('kit', 'Kit');
  static const MaterialMeasureUnit conj = MaterialMeasureUnit('conj', 'Conjunto');
  static const MaterialMeasureUnit jogo = MaterialMeasureUnit('jogo', 'Jogo');

  static const MaterialMeasureUnit cx = MaterialMeasureUnit('cx', 'Caixa (cx)');
  static const MaterialMeasureUnit pct = MaterialMeasureUnit('pct', 'Pacote (pct)');
  static const MaterialMeasureUnit fd = MaterialMeasureUnit('fd', 'Fardo');
  static const MaterialMeasureUnit sac = MaterialMeasureUnit('sac', 'Saco');
  static const MaterialMeasureUnit sc = MaterialMeasureUnit('sc', 'Saca');
  static const MaterialMeasureUnit bob = MaterialMeasureUnit('bob', 'Bobina');
  static const MaterialMeasureUnit rl = MaterialMeasureUnit('rl', 'Rolo');
  static const MaterialMeasureUnit tb = MaterialMeasureUnit('tb', 'Tubo');
  static const MaterialMeasureUnit gal = MaterialMeasureUnit('gal', 'Galão');
  static const MaterialMeasureUnit lata = MaterialMeasureUnit('lata', 'Lata');
  static const MaterialMeasureUnit frasco = MaterialMeasureUnit('frasco', 'Frasco');
  static const MaterialMeasureUnit bisnaga = MaterialMeasureUnit('bisnaga', 'Bisnaga');
  static const MaterialMeasureUnit garrafa = MaterialMeasureUnit('garrafa', 'Garrafa');
  static const MaterialMeasureUnit pote = MaterialMeasureUnit('pote', 'Pote');
  static const MaterialMeasureUnit bar = MaterialMeasureUnit('bar', 'Barra');
  static const MaterialMeasureUnit bloco = MaterialMeasureUnit('bloco', 'Bloco');
  static const MaterialMeasureUnit palete = MaterialMeasureUnit('palete', 'Palete');

  static const MaterialMeasureUnit kg = MaterialMeasureUnit('kg', 'Quilograma (kg)');
  static const MaterialMeasureUnit g = MaterialMeasureUnit('g', 'Grama (g)');
  static const MaterialMeasureUnit mg = MaterialMeasureUnit('mg', 'Miligrama (mg)');
  static const MaterialMeasureUnit t = MaterialMeasureUnit('t', 'Tonelada (t)');

  static const MaterialMeasureUnit L = MaterialMeasureUnit('L', 'Litro (L)');
  static const MaterialMeasureUnit mL = MaterialMeasureUnit('mL', 'Mililitro (mL)');
  static const MaterialMeasureUnit hL = MaterialMeasureUnit('hL', 'Hectolitro (hL)');
  static const MaterialMeasureUnit m3 = MaterialMeasureUnit('m3', 'Metro cúbico (m³)');

  static const MaterialMeasureUnit km = MaterialMeasureUnit('km', 'Quilômetro (km)');
  static const MaterialMeasureUnit m = MaterialMeasureUnit('m', 'Metro (m)');
  static const MaterialMeasureUnit cm = MaterialMeasureUnit('cm', 'Centímetro (cm)');
  static const MaterialMeasureUnit mm = MaterialMeasureUnit('mm', 'Milímetro (mm)');
  static const MaterialMeasureUnit pol = MaterialMeasureUnit('pol', 'Polegada (pol)');

  static const MaterialMeasureUnit m2 = MaterialMeasureUnit('m2', 'Metro quadrado (m²)');
  static const MaterialMeasureUnit cm2 = MaterialMeasureUnit('cm2', 'Centímetro quadrado (cm²)');
  static const MaterialMeasureUnit ha = MaterialMeasureUnit('ha', 'Hectare (ha)');

  static const MaterialMeasureUnit h = MaterialMeasureUnit('h', 'Hora (h)');
  static const MaterialMeasureUnit min = MaterialMeasureUnit('min', 'Minuto (min)');
  static const MaterialMeasureUnit dia = MaterialMeasureUnit('dia', 'Dia');

  static const MaterialMeasureUnit kWh = MaterialMeasureUnit('kWh', 'Quilowatt-hora (kWh)');
  static const MaterialMeasureUnit wattHour = MaterialMeasureUnit('Wh', 'Watt-hora (Wh)');

  static const MaterialMeasureUnit serv = MaterialMeasureUnit('serv', 'Serviço');

  static final List<MaterialMeasureUnit> all = List.unmodifiable([
    un,
    pc,
    par,
    dz,
    cento,
    mil,
    kit,
    conj,
    jogo,
    cx,
    pct,
    fd,
    sac,
    sc,
    bob,
    rl,
    tb,
    gal,
    lata,
    frasco,
    bisnaga,
    garrafa,
    pote,
    bar,
    bloco,
    palete,
    kg,
    g,
    mg,
    t,
    L,
    mL,
    hL,
    m3,
    km,
    m,
    cm,
    mm,
    pol,
    m2,
    cm2,
    ha,
    h,
    min,
    dia,
    kWh,
    wattHour,
    serv,
  ]);

  static MaterialMeasureUnit? findByCode(String code) {
    final normalized = code.trim();
    if (normalized.isEmpty) return null;
    for (final unit in all) {
      if (unit.code == normalized) return unit;
    }
    return null;
  }

  /// Resolve unidade cadastrada; mantém código legado se não estiver na lista.
  static MaterialMeasureUnit resolve(String code) {
    return findByCode(code) ?? MaterialMeasureUnit(code.trim(), '${code.trim()} (outro)');
  }

  static String labelFor(String code) => resolve(code).label;
}
