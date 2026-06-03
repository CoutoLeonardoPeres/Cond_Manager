/// Cálculos de custo (compra) e repasse (condomínio) com impostos.
class MaterialPricing {
  MaterialPricing._();

  static double withTax(double base, double taxPercent) {
    if (base <= 0 || taxPercent <= 0) return base;
    return base * (1 + taxPercent / 100);
  }

  static double lineTotal(double unit, double quantity) => unit * quantity;

  static double marginAmount(double resaleWithTax, double costWithTax) =>
      resaleWithTax - costWithTax;

  static double? marginPercent(double resaleWithTax, double costWithTax) {
    if (costWithTax <= 0) return null;
    return ((resaleWithTax - costWithTax) / costWithTax) * 100;
  }
}
