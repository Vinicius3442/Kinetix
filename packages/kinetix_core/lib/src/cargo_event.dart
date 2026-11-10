/// Tipos de ocorrência que o Kinetix registra.
enum EventType {
  impact('impact', 'Impacto'),
  tilt('tilt', 'Inclinação'),
  opening('opening', 'Abertura'),
  temperature('temperature', 'Temperatura'),
  humidity('humidity', 'Umidade'),
  connection('connection', 'Conexão'),
  delivery('delivery', 'Entrega');

  const EventType(this.code, this.label);
  final String code;
  final String label;

  static EventType fromCode(String? code) => EventType.values.firstWhere((e) => e.code == code, orElse: () => EventType.connection);
}

enum Severity {
  info('info'),
  warning('warning'),
  critical('critical');

  const Severity(this.code);
  final String code;

  static Severity fromCode(String? code) => Severity.values.firstWhere((e) => e.code == code, orElse: () => Severity.info);
}

/// Uma ocorrência na viagem da carga, já com texto pronto para o usuário.
class CargoEvent {
  const CargoEvent({
    this.id,
    this.shipmentId,
    required this.deviceId,
    required this.ts,
    required this.type,
    required this.severity,
    required this.title,
    required this.detail,
    this.value,
    this.penalty = 0,
    this.scoreAfter,
    this.lat,
    this.lng,
    this.roll,
    this.pitch,
    this.yaw,
    this.buffered = false,
    this.acknowledgedAt,
    this.acknowledgedBy,
  });

  final int? id;
  final String? shipmentId;
  final String deviceId;
  final DateTime ts;
  final EventType type;
  final Severity severity;

  /// Frase curta, ex.: "Impacto forte".
  final String title;

  /// Frase explicativa, ex.: "A caixa sofreu um solavanco de 3,4 G."
  final String detail;

  final double? value;
  final double penalty;
  final double? scoreAfter;
  final double? lat;
  final double? lng;

  /// Orientação da caixa no momento da ocorrência (usada no "replay" 3D).
  final double? roll;
  final double? pitch;
  final double? yaw;
  final bool buffered;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;

  bool get isAcknowledged => acknowledgedAt != null;

  factory CargoEvent.fromJson(Map<String, dynamic> j) {
    double? d(String k) => (j[k] as num?)?.toDouble();
    return CargoEvent(
      id: (j['id'] as num?)?.toInt(),
      shipmentId: j['shipment_id']?.toString(),
      deviceId: (j['device_id'] ?? '').toString(),
      ts: DateTime.parse(j['ts'].toString()).toUtc(),
      type: EventType.fromCode(j['type']?.toString()),
      severity: Severity.fromCode(j['severity']?.toString()),
      title: (j['title'] ?? '').toString(),
      detail: (j['detail'] ?? '').toString(),
      value: d('value'),
      penalty: d('penalty') ?? 0,
      scoreAfter: d('score_after'),
      lat: d('lat'),
      lng: d('lng'),
      roll: d('roll'),
      pitch: d('pitch'),
      yaw: d('yaw'),
      buffered: j['buffered'] == true,
      acknowledgedAt: j['acknowledged_at'] == null ? null : DateTime.parse(j['acknowledged_at'].toString()),
      acknowledgedBy: j['acknowledged_by']?.toString(),
    );
  }

  /// JSON para inserir no banco (sem `id`).
  Map<String, dynamic> toJson() => {
        if (shipmentId != null) 'shipment_id': shipmentId,
        'device_id': deviceId,
        'ts': ts.toUtc().toIso8601String(),
        'type': type.code,
        'severity': severity.code,
        'title': title,
        'detail': detail,
        'value': value,
        'penalty': penalty,
        'score_after': scoreAfter,
        'lat': lat,
        'lng': lng,
        'roll': roll,
        'pitch': pitch,
        'yaw': yaw,
        'buffered': buffered,
      };

  CargoEvent copyWith({int? id, String? shipmentId, double? scoreAfter, DateTime? acknowledgedAt, String? acknowledgedBy}) => CargoEvent(
        id: id ?? this.id,
        shipmentId: shipmentId ?? this.shipmentId,
        deviceId: deviceId,
        ts: ts,
        type: type,
        severity: severity,
        title: title,
        detail: detail,
        value: value,
        penalty: penalty,
        scoreAfter: scoreAfter ?? this.scoreAfter,
        lat: lat,
        lng: lng,
        roll: roll,
        pitch: pitch,
        yaw: yaw,
        buffered: buffered,
        acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
        acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      );
}
