import 'package:kinetix_core/kinetix_core.dart';

export 'package:kinetix_core/kinetix_core.dart';

// ---------------------------------------------------------------- perfis

enum UserRole {
  admin('admin', 'Administrador', 'Gerencia tudo: cargas, caixas e usuários.'),
  gestor('gestor', 'Gestor logístico', 'Acompanha todas as cargas e cadastra viagens.'),
  motorista('motorista', 'Motorista', 'Acompanha as cargas que está levando.'),
  destinatario('destinatario', 'Destinatário', 'Recebe cargas e confere pelo QR Code.');

  const UserRole(this.code, this.label, this.description);
  final String code;
  final String label;
  final String description;

  bool get isStaff => this == admin || this == gestor;

  static UserRole fromCode(String? c) => UserRole.values.firstWhere((r) => r.code == c, orElse: () => motorista);
}

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.company,
    this.phone,
    this.onboarded = false,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? company;
  final String? phone;
  final bool onboarded;

  String get firstName => fullName.trim().isEmpty ? email.split('@').first : fullName.trim().split(' ').first;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'].toString(),
        fullName: (j['full_name'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        role: UserRole.fromCode(j['role']?.toString()),
        company: j['company']?.toString(),
        phone: j['phone']?.toString(),
        onboarded: j['onboarded'] == true,
      );

  Profile copyWith({String? fullName, String? company, String? phone, UserRole? role, bool? onboarded}) => Profile(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        role: role ?? this.role,
        company: company ?? this.company,
        phone: phone ?? this.phone,
        onboarded: onboarded ?? this.onboarded,
      );
}

// ---------------------------------------------------------------- caixas

class Device {
  const Device({
    required this.id,
    required this.name,
    this.online = false,
    this.lastSeen,
    this.battery,
    this.rssi,
    this.firmware,
    this.lastTelemetry,
  });

  final String id;
  final String name;
  final bool online;
  final DateTime? lastSeen;
  final int? battery;
  final int? rssi;
  final String? firmware;
  final Telemetry? lastTelemetry;

  factory Device.fromJson(Map<String, dynamic> j) {
    final lt = j['last_telemetry'];
    return Device(
      id: j['id'].toString(),
      name: (j['name'] ?? j['id']).toString(),
      online: j['status'] == 'online',
      lastSeen: j['last_seen'] == null ? null : DateTime.tryParse(j['last_seen'].toString()),
      battery: (j['battery'] as num?)?.toInt(),
      rssi: (j['rssi'] as num?)?.toInt(),
      firmware: j['firmware']?.toString(),
      lastTelemetry: lt is Map<String, dynamic> ? Telemetry.fromJson(lt) : null,
    );
  }
}

// ---------------------------------------------------------------- cargas

enum ShipmentStatus {
  preparing('preparando', 'Aguardando saída'),
  inTransit('em_transito', 'Em viagem'),
  delivered('entregue', 'Entregue'),
  refused('recusada', 'Recusada');

  const ShipmentStatus(this.code, this.label);
  final String code;
  final String label;

  bool get isActive => this == preparing || this == inTransit;
  bool get isClosed => !isActive;

  static ShipmentStatus fromCode(String? c) => ShipmentStatus.values.firstWhere((s) => s.code == c, orElse: () => ShipmentStatus.preparing);
}

/// Categorias com faixas seguras sugeridas.
class CargoCategory {
  const CargoCategory(this.name, this.limits);
  final String name;
  final CargoLimits limits;

  static const all = [
    CargoCategory('Geral', CargoLimits()),
    CargoCategory('Farmacêutico', CargoLimits(tempMin: 2, tempMax: 8, humMax: 70)),
    CargoCategory('Alimentos refrigerados', CargoLimits(tempMin: 0, tempMax: 5, humMax: 90)),
    CargoCategory('Eletrônicos', CargoLimits(tempMin: 10, tempMax: 35, humMax: 70, impactG: 1.8)),
    CargoCategory('Óptico', CargoLimits(tempMin: 15, tempMax: 30, humMax: 75, impactG: 1.5, tiltDeg: 20)),
  ];
}

class Shipment {
  const Shipment({
    required this.id,
    required this.code,
    required this.description,
    required this.category,
    required this.origin,
    required this.destination,
    required this.status,
    required this.score,
    required this.limits,
    required this.qrToken,
    this.deviceId,
    this.driverId,
    this.vehiclePlate,
    this.recipientName,
    this.startedAt,
    this.deliveredAt,
    this.createdAt,
  });

  final String id;
  final String code;
  final String description;
  final String category;
  final String origin;
  final String destination;
  final ShipmentStatus status;
  final double score;
  final CargoLimits limits;
  final String qrToken;
  final String? deviceId;
  final String? driverId;
  final String? vehiclePlate;
  final String? recipientName;
  final DateTime? startedAt;
  final DateTime? deliveredAt;
  final DateTime? createdAt;

  Integrity get integrity => Integrity.fromScore(score);

  factory Shipment.fromJson(Map<String, dynamic> j) {
    DateTime? dt(String k) => j[k] == null ? null : DateTime.tryParse(j[k].toString());
    return Shipment(
      id: j['id'].toString(),
      code: j['code'].toString(),
      description: (j['description'] ?? '').toString(),
      category: (j['category'] ?? 'Geral').toString(),
      origin: (j['origin'] ?? '').toString(),
      destination: (j['destination'] ?? '').toString(),
      status: ShipmentStatus.fromCode(j['status']?.toString()),
      score: (j['score'] as num?)?.toDouble() ?? 100,
      limits: CargoLimits.fromJson(j),
      qrToken: (j['qr_token'] ?? '').toString(),
      deviceId: j['device_id']?.toString(),
      driverId: j['driver_id']?.toString(),
      vehiclePlate: j['vehicle_plate']?.toString(),
      recipientName: j['recipient_name']?.toString(),
      startedAt: dt('started_at'),
      deliveredAt: dt('delivered_at'),
      createdAt: dt('created_at'),
    );
  }

  Shipment copyWith({ShipmentStatus? status, double? score, DateTime? startedAt, DateTime? deliveredAt}) => Shipment(
        id: id,
        code: code,
        description: description,
        category: category,
        origin: origin,
        destination: destination,
        status: status ?? this.status,
        score: score ?? this.score,
        limits: limits,
        qrToken: qrToken,
        deviceId: deviceId,
        driverId: driverId,
        vehiclePlate: vehiclePlate,
        recipientName: recipientName,
        startedAt: startedAt ?? this.startedAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        createdAt: createdAt,
      );
}

/// Dados para criar ou editar uma carga.
class ShipmentDraft {
  ShipmentDraft({
    this.code = '',
    this.description = '',
    this.category = 'Geral',
    this.origin = '',
    this.destination = '',
    this.deviceId,
    this.driverId,
    this.vehiclePlate,
    this.recipientName,
    this.limits = const CargoLimits(),
  });

  String code;
  String description;
  String category;
  String origin;
  String destination;
  String? deviceId;
  String? driverId;
  String? vehiclePlate;
  String? recipientName;
  CargoLimits limits;

  factory ShipmentDraft.from(Shipment s) => ShipmentDraft(
        code: s.code,
        description: s.description,
        category: s.category,
        origin: s.origin,
        destination: s.destination,
        deviceId: s.deviceId,
        driverId: s.driverId,
        vehiclePlate: s.vehiclePlate,
        recipientName: s.recipientName,
        limits: s.limits,
      );

  Map<String, dynamic> toJson() => {
        'code': code.trim().toUpperCase(),
        'description': description.trim(),
        'category': category,
        'origin': origin.trim(),
        'destination': destination.trim(),
        'device_id': deviceId,
        'driver_id': driverId,
        'vehicle_plate': (vehiclePlate ?? '').trim().isEmpty ? null : vehiclePlate!.trim().toUpperCase(),
        'recipient_name': (recipientName ?? '').trim().isEmpty ? null : recipientName!.trim(),
        ...limits.toJson(),
      };
}

// ---------------------------------------------------------------- recebimento

class Receipt {
  const Receipt({
    required this.signerName,
    required this.approved,
    required this.signedAt,
    this.signatureSvg,
    this.notes,
  });

  final String signerName;
  final bool approved;
  final DateTime signedAt;
  final String? signatureSvg;
  final String? notes;

  factory Receipt.fromJson(Map<String, dynamic> j) => Receipt(
        signerName: (j['signer_name'] ?? '').toString(),
        approved: j['approved'] == true,
        signedAt: DateTime.tryParse(j['signed_at'].toString()) ?? DateTime.now(),
        signatureSvg: j['signature_svg']?.toString(),
        notes: j['notes']?.toString(),
      );
}

/// O que o destinatário vê ao ler o QR Code.
class ReceiptSummary {
  const ReceiptSummary({
    required this.shipment,
    required this.events,
    this.receipt,
    this.tempMin,
    this.tempMax,
    this.peakG,
    this.readings = 0,
  });

  final Shipment shipment;
  final List<CargoEvent> events;
  final Receipt? receipt;
  final double? tempMin;
  final double? tempMax;
  final double? peakG;
  final int readings;

  List<CargoEvent> get incidents => events.where((e) => e.penalty > 0).toList();

  factory ReceiptSummary.fromJson(Map<String, dynamic> j) {
    final stats = (j['stats'] as Map<String, dynamic>?) ?? const {};
    return ReceiptSummary(
      shipment: Shipment.fromJson(j['shipment'] as Map<String, dynamic>),
      events: ((j['events'] as List?) ?? const []).map((e) => CargoEvent.fromJson(e as Map<String, dynamic>)).toList(),
      receipt: j['receipt'] == null ? null : Receipt.fromJson(j['receipt'] as Map<String, dynamic>),
      tempMin: (stats['temp_min'] as num?)?.toDouble(),
      tempMax: (stats['temp_max'] as num?)?.toDouble(),
      peakG: (stats['peak_g'] as num?)?.toDouble(),
      readings: (stats['readings'] as num?)?.toInt() ?? 0,
    );
  }
}
