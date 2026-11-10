import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';

import '../../core/config/env.dart';
import '../models/models.dart';
import 'mqtt_client_factory.dart';

/// Recebe a telemetria ao vivo direto do broker MQTT (via WebSocket), para o
/// gêmeo digital girar com a menor latência possível. O banco recebe uma
/// leitura a cada 5 s; o MQTT entrega todas (1 por segundo).
class MqttLive {
  MqttLive({String? url}) : url = url ?? Env.mqttWsUrl;

  final String url;
  MqttClient? _client;
  Future<bool>? _connecting;
  final _controllers = <String, StreamController<Telemetry>>{};
  final _subscribed = <String>{};
  StreamSubscription? _updates;

  bool get connected => _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<bool> _ensure() {
    if (connected) return Future.value(true);
    return _connecting ??= _connect().whenComplete(() => _connecting = null);
  }

  Future<bool> _connect() async {
    try {
      final id = 'kinetix-app-${DateTime.now().microsecondsSinceEpoch}';
      final c = createMqttClient(url, id)
        ..keepAlivePeriod = 20
        ..autoReconnect = true
        ..resubscribeOnAutoReconnect = true
        ..logging(on: false);
      c.connectionMessage = MqttConnectMessage().withClientIdentifier(id).startClean();
      await c.connect(Env.mqttUser.isEmpty ? null : Env.mqttUser, Env.mqttPass.isEmpty ? null : Env.mqttPass);
      _client = c;
      _updates = c.updates?.listen(_onMessages);
      for (final d in _subscribed) {
        c.subscribe(KinetixTopics.telemetry(d), MqttQos.atMostOnce);
      }
      return true;
    } catch (_) {
      _client = null;
      return false;
    }
  }

  void _onMessages(List<MqttReceivedMessage<MqttMessage>> msgs) {
    for (final m in msgs) {
      final device = KinetixTopics.deviceFrom(m.topic);
      final ctrl = device == null ? null : _controllers[device];
      if (ctrl == null) continue;
      try {
        final pub = m.payload as MqttPublishMessage;
        final t = Telemetry.fromJson(jsonDecode(utf8.decode(pub.payload.message)) as Map<String, dynamic>);
        if (!t.buffered) ctrl.add(t);
      } catch (_) {/* mensagem inválida: ignora */}
    }
  }

  /// Leituras ao vivo de uma caixa. Se o broker não responder, o stream
  /// simplesmente não emite e o app usa a última leitura salva no banco.
  Stream<Telemetry> watch(String deviceId) {
    final ctrl = _controllers.putIfAbsent(deviceId, () => StreamController<Telemetry>.broadcast());
    if (_subscribed.add(deviceId)) {
      _ensure().then((ok) {
        if (ok) _client!.subscribe(KinetixTopics.telemetry(deviceId), MqttQos.atMostOnce);
      });
    }
    return ctrl.stream;
  }

  void dispose() {
    _updates?.cancel();
    _client?.disconnect();
    for (final c in _controllers.values) {
      c.close();
    }
  }
}
