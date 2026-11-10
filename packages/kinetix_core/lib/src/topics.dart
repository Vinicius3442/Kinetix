/// Tópicos MQTT do contrato Kinetix v1.
///
/// - `kinetix/v1/{device}/telemetry` → leitura JSON (ver [Telemetry]), a cada 1 s.
/// - `kinetix/v1/{device}/status`    → `online` / `offline` (retido; `offline`
///   é a "última vontade" do cliente MQTT, publicada pelo broker se a placa cair).
/// - `kinetix/v1/{device}/score`     → score oficial calculado pelo serviço ponte.
class KinetixTopics {
  static const prefix = 'kinetix/v1';

  static String telemetry(String deviceId) => '$prefix/$deviceId/telemetry';
  static String status(String deviceId) => '$prefix/$deviceId/status';

  /// Publicado pelo serviço ponte (retido) com `{"score": 87, "status": "Atenção"}`,
  /// para o display da caixa mostrar o score oficial.
  static String score(String deviceId) => '$prefix/$deviceId/score';

  static const allTelemetry = '$prefix/+/telemetry';
  static const allStatus = '$prefix/+/status';

  /// Extrai o id da caixa de um tópico, ou `null` se não for do Kinetix.
  static String? deviceFrom(String topic) {
    final parts = topic.split('/');
    if (parts.length != 4 || '${parts[0]}/${parts[1]}' != prefix) return null;
    return parts[2];
  }

  static bool isTelemetry(String topic) => topic.endsWith('/telemetry');
  static bool isStatus(String topic) => topic.endsWith('/status');
}
