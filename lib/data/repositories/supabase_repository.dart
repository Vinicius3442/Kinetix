import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../services/mqtt_live.dart';
import 'kinetix_repository.dart';

/// Implementação real: Supabase (banco, login, tempo real) + MQTT ao vivo.
class SupabaseRepository extends KinetixRepository {
  SupabaseRepository(this.db, {MqttLive? live}) : _live = live ?? MqttLive();

  final SupabaseClient db;
  final MqttLive _live;

  @override
  bool get isDemo => false;

  /// Converte erros técnicos em mensagens para o usuário.
  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on AuthException catch (e) {
      throw KxException(_authMessage(e));
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const KxException('Já existe um registro com esses dados (código ou caixa repetidos).');
      if (e.code == '42501') throw const KxException('Você não tem permissão para fazer isso.');
      throw KxException(e.message.isNotEmpty ? e.message : 'Não foi possível salvar. Tente de novo.');
    } on KxException {
      rethrow;
    } catch (_) {
      throw const KxException('Sem conexão com o servidor. Verifique a internet e tente de novo.');
    }
  }

  String _authMessage(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login')) return 'E-mail ou senha incorretos.';
    if (m.contains('email not confirmed')) return 'Confirme o seu e-mail pelo link que enviamos antes de entrar.';
    if (m.contains('already registered')) return 'Já existe uma conta com este e-mail. Tente entrar.';
    if (m.contains('password')) return 'A senha precisa ter pelo menos 6 caracteres.';
    if (m.contains('rate limit')) return 'Muitas tentativas seguidas. Aguarde um minuto e tente de novo.';
    return e.message;
  }

  // ======================================================================= sessão

  final _reload = StreamController<void>.broadcast();

  @override
  Stream<Profile?> watchSession() {
    Future<Profile?> load() async {
      final s = db.auth.currentSession;
      if (s == null) return null;
      try {
        final row = await db.from('profiles').select().eq('id', s.user.id).maybeSingle();
        if (row != null) return Profile.fromJson(row);
      } catch (_) {/* sem rede: usa o básico da sessão */}
      return Profile(id: s.user.id, fullName: '', email: s.user.email ?? '', role: UserRole.motorista);
    }

    final ctrl = StreamController<Profile?>();
    Future<void> emit() async {
      final p = await load();
      if (!ctrl.isClosed) ctrl.add(p);
    }

    final subs = <StreamSubscription>[
      db.auth.onAuthStateChange.where((s) => s.event != AuthChangeEvent.tokenRefreshed).listen((_) => emit()),
      _reload.stream.listen((_) => emit()),
    ];
    emit();
    ctrl.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
    return ctrl.stream;
  }

  @override
  Future<void> signIn(String email, String password) =>
      _guard(() => db.auth.signInWithPassword(email: email.trim(), password: password));

  @override
  Future<void> signUp(String name, String email, String password) => _guard(() async {
        final r = await db.auth.signUp(email: email.trim(), password: password, data: {'full_name': name.trim()});
        if (r.session == null) {
          throw const KxException('Conta criada! Abra o e-mail que enviamos e confirme para poder entrar.');
        }
      });

  @override
  Future<void> sendPasswordReset(String email) => _guard(() => db.auth.resetPasswordForEmail(email.trim()));

  @override
  Future<void> signOut() => _guard(() => db.auth.signOut());

  Future<void> _refreshSession() async => _reload.add(null);

  @override
  Future<void> updateMyProfile({required String fullName, String? phone, String? company}) => _guard(() async {
        await db.from('profiles').update({'full_name': fullName.trim(), 'phone': phone, 'company': company}).eq('id', db.auth.currentUser!.id);
        await _refreshSession();
      });

  @override
  Future<void> markOnboarded() => _guard(() async {
        await db.from('profiles').update({'onboarded': true}).eq('id', db.auth.currentUser!.id);
        await _refreshSession();
      });

  // ======================================================================= cargas

  @override
  Stream<List<Shipment>> watchShipments() => db
      .from('shipments')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((rows) => rows.map(Shipment.fromJson).toList());

  @override
  Future<Shipment> createShipment(ShipmentDraft d) => _guard(() async {
        final row = await db.from('shipments').insert({...d.toJson(), 'created_by': db.auth.currentUser?.id}).select().single();
        return Shipment.fromJson(row);
      });

  @override
  Future<void> updateShipment(String id, ShipmentDraft d) => _guard(() => db.from('shipments').update(d.toJson()).eq('id', id));

  @override
  Future<void> deleteShipment(String id) => _guard(() => db.from('shipments').delete().eq('id', id));

  @override
  Future<void> startShipment(String id) => _guard(() => db.rpc('start_shipment', params: {'sid': id}));

  // ======================================================================= ocorrências

  @override
  Stream<List<CargoEvent>> watchEvents(String shipmentId) => db
      .from('events')
      .stream(primaryKey: ['id'])
      .eq('shipment_id', shipmentId)
      .order('ts')
      .map((rows) => rows.map(CargoEvent.fromJson).toList());

  @override
  Stream<List<CargoEvent>> watchAlerts() => db
      .from('events')
      .stream(primaryKey: ['id'])
      .order('ts')
      .limit(200)
      .map((rows) => rows
          .map(CargoEvent.fromJson)
          .where((e) => !e.isAcknowledged && e.severity != Severity.info)
          .toList());

  @override
  Future<void> acknowledge(int eventId) => _guard(() => db.rpc('acknowledge_event', params: {'eid': eventId}));

  @override
  Future<List<Telemetry>> fetchReadings(String shipmentId, {int limit = 400}) => _guard(() async {
        final rows = await db.from('readings').select().eq('shipment_id', shipmentId).order('ts', ascending: false).limit(limit);
        return rows.map(Telemetry.fromJson).toList().reversed.toList();
      });

  // ======================================================================= caixas

  @override
  Stream<List<Device>> watchDevices() =>
      db.from('devices').stream(primaryKey: ['id']).order('id', ascending: true).map((rows) => rows.map(Device.fromJson).toList());

  @override
  Future<void> saveDevice(String id, String name) => _guard(() async {
        final key = id.trim().toLowerCase();
        if (key.isEmpty) throw const KxException('Informe o código da caixa (o DEVICE_ID do firmware).');
        await db.from('devices').upsert({'id': key, 'name': name.trim().isEmpty ? 'Caixa $key' : name.trim()});
      });

  @override
  Future<void> deleteDevice(String id) => _guard(() => db.from('devices').delete().eq('id', id));

  @override
  Stream<Telemetry> liveTelemetry(String deviceId) {
    // MQTT ao vivo + última leitura gravada no banco (se o MQTT não conectar)
    final fromDb = db
        .from('devices')
        .stream(primaryKey: ['id'])
        .eq('id', deviceId)
        .map((rows) => rows.isEmpty ? null : Device.fromJson(rows.first).lastTelemetry)
        .where((t) => t != null)
        .cast<Telemetry>();
    final ctrl = StreamController<Telemetry>();
    DateTime? lastMqtt;
    final subs = <StreamSubscription>[
      _live.watch(deviceId).listen((t) {
        lastMqtt = DateTime.now();
        ctrl.add(t);
      }),
      fromDb.listen((t) {
        if (lastMqtt == null || DateTime.now().difference(lastMqtt!).inSeconds > 4) ctrl.add(t);
      }),
    ];
    ctrl.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
    return ctrl.stream;
  }

  // ======================================================================= usuários

  @override
  Stream<List<Profile>> watchProfiles() =>
      db.from('profiles').stream(primaryKey: ['id']).order('full_name', ascending: true).map((rows) => rows.map(Profile.fromJson).toList());

  @override
  Future<void> setRole(String userId, UserRole role) =>
      _guard(() => db.rpc('set_user_role', params: {'target': userId, 'new_role': role.code}));

  // ======================================================================= recebimento

  @override
  Future<ReceiptSummary?> receiptSummary(String token) => _guard(() async {
        final r = await db.rpc('get_receipt_summary', params: {'token': token});
        return r == null ? null : ReceiptSummary.fromJson(Map<String, dynamic>.from(r as Map));
      });

  @override
  Future<ReceiptSummary> confirmReceipt({
    required String token,
    required String signer,
    required String? signatureSvg,
    required bool approved,
    String? notes,
  }) =>
      _guard(() async {
        final r = await db.rpc('confirm_receipt', params: {
          'token': token,
          'signer': signer,
          'signature': signatureSvg,
          'is_approved': approved,
          'note': notes,
        });
        return ReceiptSummary.fromJson(Map<String, dynamic>.from(r as Map));
      });

  @override
  void dispose() => _live.dispose();
}
