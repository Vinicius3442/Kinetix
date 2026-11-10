import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Lê variáveis do ambiente e, se existir, do arquivo `.env` desta pasta.
class Env {
  Env._(this._values);

  final Map<String, String> _values;

  static Env load([String path = '.env']) {
    final values = <String, String>{};
    final f = File(path);
    if (f.existsSync()) {
      for (final line in f.readAsLinesSync()) {
        final l = line.trim();
        if (l.isEmpty || l.startsWith('#') || !l.contains('=')) continue;
        final i = l.indexOf('=');
        values[l.substring(0, i).trim()] = l.substring(i + 1).trim();
      }
    }
    values.addAll(Platform.environment);
    return Env._(values);
  }

  String? operator [](String key) {
    final v = _values[key];
    return (v == null || v.isEmpty) ? null : v;
  }

  String require(String key) {
    final v = this[key];
    if (v == null) {
      stderr.writeln('Faltou configurar $key (veja bridge/.env.example).');
      exit(64);
    }
    return v;
  }
}

/// Conecta no broker MQTT com reconexão automática.
Future<MqttServerClient> connectMqtt(
  Env env, {
  required String clientId,
  String? willTopic,
  String? willMessage,
}) async {
  final host = env['MQTT_HOST'] ?? 'broker.hivemq.com';
  final port = int.tryParse(env['MQTT_PORT'] ?? '') ?? 1883;
  final client = MqttServerClient.withPort(host, clientId, port)
    ..logging(on: false)
    ..keepAlivePeriod = 20
    ..autoReconnect = true
    ..resubscribeOnAutoReconnect = true
    ..secure = env['MQTT_TLS'] == 'true';
  final msg = MqttConnectMessage().withClientIdentifier(clientId).startClean();
  if (willTopic != null) {
    msg.withWillTopic(willTopic).withWillMessage(willMessage ?? 'offline').withWillRetain().withWillQos(MqttQos.atLeastOnce);
  }
  client.connectionMessage = msg;
  client.onAutoReconnect = () => stdout.writeln('[MQTT] reconectando...');
  client.onAutoReconnected = () => stdout.writeln('[MQTT] reconectado');
  await client.connect(env['MQTT_USER'], env['MQTT_PASS']);
  stdout.writeln('[MQTT] conectado em $host:$port');
  return client;
}
