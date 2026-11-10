import 'dart:async';
import 'dart:math' as math;

import '../models/models.dart';
import 'kinetix_repository.dart';

/// Modo demonstração: tudo acontece dentro do app.
///
/// As caixas são simuladas pelo mesmo [TelemetrySimulator] e o score pelo
/// mesmo [ScoreEngine] usados pelo serviço ponte, então o comportamento é
/// igual ao do sistema real. Útil para apresentar sem internet, sem banco e
/// sem placa — e para os testes automatizados.
class DemoRepository extends KinetixRepository {
  DemoRepository({bool autoTick = true, DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _seed();
    if (autoTick) _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  final DateTime Function() _clock;
  Timer? _timer;
  final _changes = StreamController<void>.broadcast();
  final _live = <String, StreamController<Telemetry>>{};

  Profile? _me;
  final _profiles = <String, Profile>{};
  final _devices = <String, Device>{};
  final _shipments = <String, Shipment>{};
  final _events = <CargoEvent>[];
  final _readings = <String, List<Telemetry>>{};
  final _receipts = <String, Receipt>{};
  final _sims = <String, TelemetrySimulator>{};
  final _engines = <String, ScoreEngine>{};
  final _lastTelemetry = <String, Telemetry>{};
  final _offline = <String>{};
  final _buffered = <String, int>{};
  int _eventId = 100;
  int _idSeq = 10;

  @override
  bool get isDemo => true;

  DateTime get _now => _clock().toUtc();

  // ======================================================================= dados iniciais

  static const demoUsers = {
    'admin@kinetix.app': ('Vinícius Montuani', UserRole.admin),
    'gestor@kinetix.app': ('Luiz Felipe', UserRole.gestor),
    'motorista@kinetix.app': ('Samuel Mioni', UserRole.motorista),
    'destinatario@kinetix.app': ('Pietro Rennó', UserRole.destinatario),
  };

  void _seed() {
    for (final (i, e) in demoUsers.entries.indexed) {
      final id = 'u$i';
      _profiles[id] = Profile(id: id, fullName: e.value.$1, email: e.key, role: e.value.$2, company: 'TransCargo Express', onboarded: true);
    }
    final driver = _profiles.values.firstWhere((p) => p.role == UserRole.motorista).id;

    for (final (i, id) in ['kx-01', 'kx-02', 'kx-03'].indexed) {
      _devices[id] = Device(id: id, name: 'Caixa Kinetix 0${i + 1}', firmware: 'esp32-wokwi 2.0');
      _sims[id] = TelemetrySimulator(deviceId: id, scripted: false, seed: 11 + i, baseTemp: 21.5 + i * 1.5, start: _now);
    }

    Shipment s(String id, String code, String desc, String cat, String from, String to, String? device, ShipmentStatus status, double score,
            String plate, String recipient,
            {Duration? started, Duration? delivered, CargoLimits limits = const CargoLimits(), String? driverId}) =>
        Shipment(
          id: id,
          code: code,
          description: desc,
          category: cat,
          origin: from,
          destination: to,
          status: status,
          score: score,
          limits: limits,
          qrToken: 'demo-${code.toLowerCase().replaceAll('-', '')}',
          deviceId: device,
          driverId: driverId,
          vehiclePlate: plate,
          recipientName: recipient,
          startedAt: started == null ? null : _now.subtract(started),
          deliveredAt: delivered == null ? null : _now.subtract(delivered),
          createdAt: _now.subtract((started ?? Duration.zero) + const Duration(hours: 1)),
        );

    final list = [
      s('s1', 'TC-8902', 'Vacinas termossensíveis', 'Farmacêutico', 'São José dos Campos-SP', 'Taubaté-SP', 'kx-01',
          ShipmentStatus.inTransit, 100, 'FKT-3B21', 'Hospital Regional de Taubaté',
          started: const Duration(minutes: 12), driverId: driver),
      s('s2', 'TC-7741', 'Servidores e placas eletrônicas', 'Eletrônicos', 'São José dos Campos-SP', 'Taubaté-SP', 'kx-02',
          ShipmentStatus.inTransit, 100, 'GHT-9A10', 'Data Center Vale',
          started: const Duration(minutes: 20), limits: CargoCategory.all[3].limits),
      s('s3', 'TC-6610', 'Lentes ópticas de precisão', 'Óptico', 'São José dos Campos-SP', 'Taubaté-SP', 'kx-03', ShipmentStatus.preparing,
          100, 'BRA-2E19', 'Óptica Paulista',
          limits: CargoCategory.all[4].limits),
      s('s4', 'TC-5120', 'Medicamentos controlados', 'Farmacêutico', 'São José dos Campos-SP', 'Caçapava-SP', null,
          ShipmentStatus.delivered, 87, 'FKT-3B21', 'Farmácia Central',
          started: const Duration(hours: 28), delivered: const Duration(hours: 26), driverId: driver),
    ];
    for (final sh in list) {
      _shipments[sh.id] = sh;
    }

    // histórico: o caminhão da s1 saiu há 12 min e o da s2 há 20 min (na mesma estrada)
    _prefillReadings('s1', 'kx-01', const Duration(minutes: 12));
    _prefillReadings('s2', 'kx-02', const Duration(minutes: 20));
    _sims['kx-03']!.driving = false; // carga s3 ainda não saiu
    final s1 = _shipments['s1']!;
    final pastImpact = _readings['s1']![(_readings['s1']!.length * 0.35).round()];
    final pastHum = _readings['s1']![(_readings['s1']!.length * 0.7).round()];
    _addPastEvent(
        s1, pastImpact, EventType.impact, Severity.warning, 'Impacto forte', 'A caixa sofreu um solavanco de 3,2 G.', 3.2, 10, 90);
    _addPastEvent(s1, pastHum, EventType.humidity, Severity.warning, 'Umidade alta',
        'O ar dentro da caixa chegou a 84% de umidade (máximo 80%).', 84, 3, 87);
    _shipments['s1'] = s1.copyWith(score: 87);

    // carga entregue
    final s4 = _shipments['s4']!;
    final t4 = s4.startedAt!;
    _addPastEvent(s4, Telemetry(deviceId: 'kx-01', ts: t4.add(const Duration(minutes: 20)), lat: -23.1712, lng: -45.8392, roll: 6, yaw: 72),
        EventType.impact, Severity.warning, 'Impacto forte', 'A caixa sofreu um solavanco de 3,2 G.', 3.2, 10, 90);
    _addPastEvent(s4, Telemetry(deviceId: 'kx-01', ts: t4.add(const Duration(minutes: 55)), lat: -23.1418, lng: -45.7896, yaw: 70),
        EventType.humidity, Severity.warning, 'Umidade alta', 'O ar dentro da caixa chegou a 84% de umidade (máximo 80%).', 84, 3, 87);
    _receipts['s4'] = Receipt(signerName: 'Ana Souza', approved: true, signedAt: s4.deliveredAt!, notes: 'Conferido, embalagem íntegra.');
    _events.add(CargoEvent(
      id: _eventId++,
      shipmentId: 's4',
      deviceId: 'kx-01',
      ts: s4.deliveredAt!,
      type: EventType.delivery,
      severity: Severity.info,
      title: 'Recebimento aprovado',
      detail: 'Ana Souza conferiu e aprovou a entrega. Observação: Conferido, embalagem íntegra.',
      scoreAfter: 87,
      acknowledgedAt: s4.deliveredAt,
    ));
    _events.where((e) => e.shipmentId == 's4').toList().forEach((e) {
      final i = _events.indexOf(e);
      _events[i] = e.copyWith(acknowledgedAt: s4.deliveredAt);
    });

    for (final sh in _shipments.values.where((x) => x.status == ShipmentStatus.inTransit)) {
      _engines[sh.id] = ScoreEngine(limits: sh.limits, score: sh.score);
    }
  }

  /// Roda o simulador da caixa [back] para trás no tempo, guardando o histórico.
  /// O mesmo simulador continua ao vivo depois, então o trajeto não dá saltos.
  void _prefillReadings(String shipmentId, String deviceId, Duration back) {
    final old = _sims[deviceId]!;
    final sim =
        TelemetrySimulator(deviceId: deviceId, scripted: false, seed: old.hashCode, baseTemp: old.baseTemp, start: _now.subtract(back));
    _sims[deviceId] = sim;
    final list = <Telemetry>[];
    for (var i = 0; i < back.inSeconds; i++) {
      final t = sim.next();
      if (i % 5 == 0) list.add(t);
    }
    _readings[shipmentId] = list;
  }

  void _addPastEvent(
      Shipment s, Telemetry at, EventType type, Severity sev, String title, String detail, double value, double penalty, double after) {
    _events.add(CargoEvent(
      id: _eventId++,
      shipmentId: s.id,
      deviceId: s.deviceId ?? 'kx-01',
      ts: at.ts,
      type: type,
      severity: sev,
      title: title,
      detail: detail,
      value: value,
      penalty: penalty,
      scoreAfter: after,
      lat: at.lat,
      lng: at.lng,
      roll: at.roll + (type == EventType.impact ? 6 : 0),
      pitch: at.pitch,
      yaw: at.yaw,
    ));
  }

  // ======================================================================= relógio da simulação

  /// Avança a simulação em 1 segundo (chamado a cada segundo; público para testes).
  void tick() {
    for (final entry in _sims.entries) {
      final id = entry.key;
      final t = entry.value.next().copyWith(ts: _now);
      final online = !_offline.contains(id);
      _lastTelemetry[id] = t;
      final d = _devices[id]!;
      _devices[id] = Device(
        id: id,
        name: d.name,
        firmware: d.firmware,
        online: online && !t.buffered,
        lastSeen: t.buffered ? d.lastSeen : _now,
        battery: t.battery,
        rssi: t.rssi,
        lastTelemetry: t.buffered ? d.lastTelemetry : t,
      );
      if (!t.buffered) _live[id]?.add(t);
      _process(t);
    }
    _changes.add(null);
  }

  void _process(Telemetry t) {
    final sh = _shipments.values.where((s) => s.deviceId == t.deviceId && s.status == ShipmentStatus.inTransit).firstOrNull;
    if (sh == null) return;
    final engine = _engines.putIfAbsent(sh.id, () => ScoreEngine(limits: sh.limits, score: sh.score));
    final events = engine.process(t);
    for (final e in events) {
      _events.add(e.copyWith(id: _eventId++, shipmentId: sh.id));
    }
    if (t.buffered) {
      _buffered[t.deviceId] = (_buffered[t.deviceId] ?? 0) + 1;
    } else if ((_buffered[t.deviceId] ?? 0) > 0) {
      _events.add(CargoEvent(
        id: _eventId++,
        shipmentId: sh.id,
        deviceId: t.deviceId,
        ts: t.ts,
        type: EventType.connection,
        severity: Severity.info,
        title: 'Sinal restabelecido',
        detail: 'A caixa ficou sem internet e enviou ${_buffered[t.deviceId]} leituras guardadas na memória. Nenhum dado foi perdido.',
        value: _buffered[t.deviceId]!.toDouble(),
        scoreAfter: engine.score,
        lat: t.lat,
        lng: t.lng,
      ));
      _buffered[t.deviceId] = 0;
    }
    final list = _readings.putIfAbsent(sh.id, () => []);
    if (events.isNotEmpty || list.isEmpty || t.ts.difference(list.last.ts).inSeconds >= 5) {
      list.add(t);
      if (list.length > 1500) list.removeAt(0);
    }
    if (engine.score != sh.score) _shipments[sh.id] = sh.copyWith(score: engine.score);
  }

  @override
  void simulate(String deviceId, SimIncident incident) {
    _sims[deviceId]?.trigger(incident);
  }

  // ======================================================================= util

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  void _emit() => _changes.add(null);

  Profile _requireMe() => _me ?? (throw const KxException('Entre na sua conta para continuar.'));

  bool _canSee(Shipment s) => _me != null && (_me!.role.isStaff || s.driverId == _me!.id);

  // ======================================================================= sessão

  @override
  Stream<Profile?> watchSession() => _watch(() => _me);

  @override
  Future<void> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final e = email.trim().toLowerCase();
    if (!e.contains('@')) throw const KxException('Digite um e-mail válido, como nome@empresa.com.');
    if (password.length < 6) throw const KxException('A senha precisa ter pelo menos 6 caracteres.');
    _me = _profiles.values.where((p) => p.email == e).firstOrNull ?? _register(e.split('@').first, e, UserRole.gestor);
    _emit();
  }

  Profile _register(String name, String email, UserRole role) {
    final id = 'u${_idSeq++}';
    final p = Profile(id: id, fullName: name, email: email, role: role, company: 'TransCargo Express');
    _profiles[id] = p;
    return p;
  }

  @override
  Future<void> signUp(String name, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final e = email.trim().toLowerCase();
    if (_profiles.values.any((p) => p.email == e)) {
      throw const KxException('Já existe uma conta com este e-mail. Tente entrar.');
    }
    // no modo demonstração quem se cadastra vira gestor, para poder explorar tudo
    _me = _register(name.trim(), e, UserRole.gestor);
    _emit();
  }

  @override
  Future<void> sendPasswordReset(String email) async => Future<void>.delayed(const Duration(milliseconds: 350));

  @override
  Future<void> signOut() async {
    _me = null;
    _emit();
  }

  @override
  Future<void> updateMyProfile({required String fullName, String? phone, String? company}) async {
    final me = _requireMe();
    _me = me.copyWith(fullName: fullName.trim(), phone: phone, company: company);
    _profiles[me.id] = _me!;
    _emit();
  }

  @override
  Future<void> markOnboarded() async {
    final me = _requireMe();
    _me = me.copyWith(onboarded: true);
    _profiles[me.id] = _me!;
    _emit();
  }

  // ======================================================================= cargas

  @override
  Stream<List<Shipment>> watchShipments() => _watch(() {
        final l = _shipments.values.where(_canSee).toList()..sort((a, b) => (b.createdAt ?? _now).compareTo(a.createdAt ?? _now));
        return l;
      });

  void _validate(ShipmentDraft d, {String? editingId}) {
    if (d.code.trim().isEmpty || d.description.trim().isEmpty || d.origin.trim().isEmpty || d.destination.trim().isEmpty) {
      throw const KxException('Preencha código, descrição, origem e destino.');
    }
    final code = d.code.trim().toUpperCase();
    if (_shipments.values.any((s) => s.code == code && s.id != editingId)) {
      throw KxException('Já existe uma carga com o código $code.');
    }
    if (d.deviceId != null && _shipments.values.any((s) => s.deviceId == d.deviceId && s.status.isActive && s.id != editingId)) {
      throw KxException('A ${_devices[d.deviceId]?.name ?? d.deviceId} já está em outra carga ativa.');
    }
  }

  @override
  Future<Shipment> createShipment(ShipmentDraft d) async {
    if (!_requireMe().role.isStaff) throw const KxException('Apenas gestores podem cadastrar cargas.');
    _validate(d);
    final id = 's${_idSeq++}';
    final s = Shipment.fromJson({
      ...d.toJson(),
      'id': id,
      'status': 'preparando',
      'score': 100,
      'qr_token': 'demo-${id}x${math.Random().nextInt(99999)}',
      'created_at': _now.toIso8601String(),
    });
    _shipments[id] = s;
    _emit();
    return s;
  }

  @override
  Future<void> updateShipment(String id, ShipmentDraft d) async {
    _validate(d, editingId: id);
    final old = _shipments[id]!;
    _shipments[id] = Shipment.fromJson({
      ...d.toJson(),
      'id': id,
      'status': old.status.code,
      'score': old.score,
      'qr_token': old.qrToken,
      'started_at': old.startedAt?.toIso8601String(),
      'delivered_at': old.deliveredAt?.toIso8601String(),
      'created_at': old.createdAt?.toIso8601String(),
    });
    _emit();
  }

  @override
  Future<void> deleteShipment(String id) async {
    _shipments.remove(id);
    _events.removeWhere((e) => e.shipmentId == id);
    _readings.remove(id);
    _emit();
  }

  @override
  Future<void> startShipment(String id) async {
    final s = _shipments[id]!;
    if (s.status != ShipmentStatus.preparing) return;
    _shipments[id] = s.copyWith(status: ShipmentStatus.inTransit, startedAt: _now);
    if (s.deviceId != null) _sims[s.deviceId!]?.startTrip();
    _engines[id] = ScoreEngine(limits: s.limits, score: s.score);
    _emit();
  }

  // ======================================================================= ocorrências

  @override
  Stream<List<CargoEvent>> watchEvents(String shipmentId) => _watch(() {
        final l = _events.where((e) => e.shipmentId == shipmentId).toList()..sort((a, b) => b.ts.compareTo(a.ts));
        return l;
      });

  @override
  Stream<List<CargoEvent>> watchAlerts() => _watch(() {
        final visible = _shipments.values.where(_canSee).map((s) => s.id).toSet();
        final l = _events.where((e) => visible.contains(e.shipmentId) && !e.isAcknowledged && e.severity != Severity.info).toList()
          ..sort((a, b) => b.ts.compareTo(a.ts));
        return l;
      });

  @override
  Future<void> acknowledge(int eventId) async {
    final i = _events.indexWhere((e) => e.id == eventId);
    if (i < 0) return;
    _events[i] = _events[i].copyWith(acknowledgedAt: _now, acknowledgedBy: _me?.id);
    _emit();
  }

  @override
  Future<List<Telemetry>> fetchReadings(String shipmentId, {int limit = 400}) async {
    final l = _readings[shipmentId] ?? const [];
    return l.length <= limit ? List.of(l) : l.sublist(l.length - limit);
  }

  // ======================================================================= caixas

  @override
  Stream<List<Device>> watchDevices() => _watch(() => _devices.values.toList()..sort((a, b) => a.id.compareTo(b.id)));

  @override
  Future<void> saveDevice(String id, String name) async {
    final key = id.trim().toLowerCase();
    if (key.isEmpty) throw const KxException('Informe o código da caixa (o DEVICE_ID do firmware).');
    final old = _devices[key];
    _devices[key] = Device(id: key, name: name.trim().isEmpty ? 'Caixa $key' : name.trim(), firmware: old?.firmware);
    _sims.putIfAbsent(key, () => TelemetrySimulator(deviceId: key, scripted: false, start: _now));
    _emit();
  }

  @override
  Future<void> deleteDevice(String id) async {
    if (_shipments.values.any((s) => s.deviceId == id && s.status.isActive)) {
      throw const KxException('Esta caixa está em uma carga ativa. Finalize a carga antes de remover.');
    }
    _devices.remove(id);
    _sims.remove(id);
    _emit();
  }

  @override
  Stream<Telemetry> liveTelemetry(String deviceId) async* {
    final last = _lastTelemetry[deviceId];
    if (last != null) yield last;
    yield* _live.putIfAbsent(deviceId, () => StreamController<Telemetry>.broadcast()).stream;
  }

  // ======================================================================= usuários

  @override
  Stream<List<Profile>> watchProfiles() => _watch(() => _profiles.values.toList()..sort((a, b) => a.fullName.compareTo(b.fullName)));

  @override
  Future<void> setRole(String userId, UserRole role) async {
    if (_me?.role != UserRole.admin) throw const KxException('Apenas administradores podem mudar perfis.');
    if (userId == _me!.id && role != UserRole.admin) {
      throw const KxException('Você não pode remover o seu próprio acesso de administrador.');
    }
    _profiles[userId] = _profiles[userId]!.copyWith(role: role);
    _emit();
  }

  // ======================================================================= recebimento

  @override
  Future<ReceiptSummary?> receiptSummary(String token) async {
    final s = _shipments.values.where((x) => x.qrToken == token).firstOrNull;
    if (s == null) return null;
    final r = _readings[s.id] ?? const <Telemetry>[];
    final temps = r.map((e) => e.temp).whereType<double>();
    return ReceiptSummary(
      shipment: s,
      events: _events.where((e) => e.shipmentId == s.id).toList()..sort((a, b) => a.ts.compareTo(b.ts)),
      receipt: _receipts[s.id],
      tempMin: temps.isEmpty ? null : temps.reduce(math.min),
      tempMax: temps.isEmpty ? null : temps.reduce(math.max),
      peakG: r.isEmpty ? null : r.map((e) => e.peakG).reduce(math.max),
      readings: r.length,
    );
  }

  @override
  Future<ReceiptSummary> confirmReceipt({
    required String token,
    required String signer,
    required String? signatureSvg,
    required bool approved,
    String? notes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final s = _shipments.values.where((x) => x.qrToken == token).firstOrNull;
    if (s == null) throw const KxException('QR Code não encontrado.');
    if (s.status.isClosed) throw const KxException('Esta carga já foi recebida.');
    if (signer.trim().isEmpty) throw const KxException('Informe o nome de quem está recebendo.');
    final note = (notes ?? '').trim();
    _receipts[s.id] = Receipt(
        signerName: signer.trim(), approved: approved, signedAt: _now, signatureSvg: signatureSvg, notes: note.isEmpty ? null : note);
    _shipments[s.id] = s.copyWith(status: approved ? ShipmentStatus.delivered : ShipmentStatus.refused, deliveredAt: _now);
    _engines.remove(s.id);
    _events.add(CargoEvent(
      id: _eventId++,
      shipmentId: s.id,
      deviceId: s.deviceId ?? '-',
      ts: _now,
      type: EventType.delivery,
      severity: approved ? Severity.info : Severity.critical,
      title: approved ? 'Recebimento aprovado' : 'Recebimento recusado',
      detail: '${signer.trim()} ${approved ? 'conferiu e aprovou a entrega.' : 'recusou a entrega.'}'
          '${note.isEmpty ? '' : ' Observação: $note'}',
      scoreAfter: s.score,
    ));
    _emit();
    return (await receiptSummary(token))!;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _changes.close();
    for (final c in _live.values) {
      c.close();
    }
  }
}
