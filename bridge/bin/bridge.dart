// Serviço ponte do Kinetix: MQTT → score → Supabase.
//
// Uso:  cd bridge && dart run bin/bridge.dart
// Configuração em bridge/.env (veja .env.example).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kinetix_bridge/config.dart';
import 'package:kinetix_bridge/processor.dart';
import 'package:kinetix_bridge/store.dart';
import 'package:kinetix_core/kinetix_core.dart';
import 'package:mqtt_client/mqtt_client.dart';

Future<void> main() async {
  final env = Env.load();
  final key = env.require('SUPABASE_SERVICE_KEY');
  final keyProblem = SupabaseStore.checkServiceKey(key);
  if (keyProblem != null) {
    stderr.writeln('[CONFIG] $keyProblem');
    exit(78);
  }
  final store = SupabaseStore(env.require('SUPABASE_URL'), key);
  final client = await connectMqtt(env, clientId: 'kinetix-bridge-${DateTime.now().millisecondsSinceEpoch}');

  void publishScore(String deviceId, double score) {
    final status = Integrity.fromScore(score).label;
    final b = MqttClientPayloadBuilder()..addUTF8String(jsonEncode({'score': score, 'status': status}));
    client.publishMessage(KinetixTopics.score(deviceId), MqttQos.atLeastOnce, b.payload!, retain: true);
  }

  final processor = TelemetryProcessor(store, onScore: publishScore);

  // Uma fila por caixa: as mensagens de cada caixa são processadas em ordem.
  final queues = <String, Future<void>>{};
  void enqueue(String deviceId, Future<void> Function() job) {
    queues[deviceId] = (queues[deviceId] ?? Future.value()).then((_) => job()).catchError((Object e) {
      stderr.writeln('[ERRO] $deviceId: $e');
    });
  }

  client.subscribe(KinetixTopics.allTelemetry, MqttQos.atLeastOnce);
  client.subscribe(KinetixTopics.allStatus, MqttQos.atLeastOnce);
  stdout.writeln('[PONTE] ouvindo ${KinetixTopics.allTelemetry} e ${KinetixTopics.allStatus}');

  client.updates!.listen((messages) {
    for (final m in messages) {
      final device = KinetixTopics.deviceFrom(m.topic);
      if (device == null) continue;
      final pub = m.payload as MqttPublishMessage;
      final text = utf8.decode(pub.payload.message, allowMalformed: true);
      if (KinetixTopics.isStatus(m.topic)) {
        enqueue(device, () => processor.handleStatus(device, text));
      } else if (KinetixTopics.isTelemetry(m.topic)) {
        try {
          final t = Telemetry.fromJson(jsonDecode(text) as Map<String, dynamic>);
          enqueue(device, () => processor.handleTelemetry(t));
        } catch (e) {
          stderr.writeln('[ERRO] JSON inválido de $device: $e');
        }
      }
    }
  });

  ProcessSignal.sigint.watch().listen((_) {
    stdout.writeln('\n[PONTE] encerrando');
    client.disconnect();
    exit(0);
  });
}
