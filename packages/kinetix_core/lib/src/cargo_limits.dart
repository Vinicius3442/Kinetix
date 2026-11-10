/// Faixas seguras de uma carga. Cada carga pode ter as suas
/// (ex.: vacinas entre 2 °C e 8 °C; eletrônicos entre 10 °C e 35 °C).
class CargoLimits {
  const CargoLimits({
    this.tempMin = 15,
    this.tempMax = 30,
    this.humMax = 80,
    this.impactG = 2.0,
    this.tiltDeg = 30,
    this.lightPct = 20,
  });

  final double tempMin;
  final double tempMax;
  final double humMax;

  /// A partir de quantos G um solavanco vira "impacto".
  final double impactG;

  /// A partir de quantos graus a caixa conta como "inclinada".
  final double tiltDeg;

  /// A partir de quanto de luz (0–100) a caixa conta como "aberta".
  final double lightPct;

  factory CargoLimits.fromJson(Map<String, dynamic> j) {
    double v(String k, double def) => (j[k] as num?)?.toDouble() ?? def;
    const d = CargoLimits();
    return CargoLimits(
      tempMin: v('temp_min', d.tempMin),
      tempMax: v('temp_max', d.tempMax),
      humMax: v('hum_max', d.humMax),
      impactG: v('impact_g', d.impactG),
      tiltDeg: v('tilt_deg', d.tiltDeg),
      lightPct: v('light_pct', d.lightPct),
    );
  }

  Map<String, dynamic> toJson() => {
        'temp_min': tempMin,
        'temp_max': tempMax,
        'hum_max': humMax,
        'impact_g': impactG,
        'tilt_deg': tiltDeg,
        'light_pct': lightPct,
      };
}
