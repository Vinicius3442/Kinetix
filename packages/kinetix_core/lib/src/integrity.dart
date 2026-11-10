/// Situação da carga em linguagem simples, derivada do score.
enum Integrity {
  ok('Carga OK', 'Nada de errado até agora.'),
  attention('Atenção', 'Confira a carga na entrega.'),
  problem('Problema', 'A carga pode ter sido danificada.');

  const Integrity(this.label, this.hint);
  final String label;
  final String hint;

  static Integrity fromScore(double score) {
    if (score >= 90) return Integrity.ok;
    if (score >= 70) return Integrity.attention;
    return Integrity.problem;
  }
}
