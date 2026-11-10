// Simulador de caixas Kinetix: publica telemetria no MQTT como se fosse a placa.
//
// Uso:  dart run bin/simulate.dart                (caixa kx-01)
//       dart run bin/simulate.dart kx-01 kx-02    (várias caixas)
//
// Enquanto roda, digite no terminal para provocar ocorrências:
//   i = impacto   t = inclinação   a = abertura   c = calor   s = sem sinal
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kinetix_bridge/config.dart';
import 'package:kinetix_core/kinetix_core.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

Future<void> main(List<String> args) async {
  final env = Env.load();
  final ids = args.isEmpty ? ['kx-01'] : args;
  final sims = <String, TelemetrySimulator>{};
  final clients = <String, MqttServerClient>{};
  final buffers = <String, List<Telemetry>>{};

  for (final (i, id) in ids.indexed) {
    sims[id] = TelemetrySimulator(deviceId: id, seed: 7 + i, baseTemp: 21 + i.toDouble());
    buffers[id] = [];
    final c = await connectMqtt(env,
        clientId: 'kinetix-sim-$id-${DateTime.now().millisecondsSinceEpoch}',
        willTopic: KinetixTopics.status(id));
    _publish(c, KinetixTopics.status(id), 'online', retain: true);
    clients[id] = c;
  }

  stdout.writeln('Simulando ${ids.join(', ')}. Comandos: i=impacto t=inclinação a=abertura c=calor s=sem sinal q=sair');
  try {
    stdin.echoMode = false;
    stdin.lineMode = false;
  } catch (_) {}
  stdin.listen((bytes) {
    final key = String.fromCharCodes(bytes).trim().toLowerCase();
    final incident = switch (key) {
      'i' => SimIncident.impact,
      't' => SimIncident.tilt,
      'a' => SimIncident.opening,
      'c' => SimIncident.heat,
      's' => SimIncident.signalLoss,
      _ => null,
    };
    if (key == 'q') exit(0);
    if (incident != null) {
      sims.values.first.trigger(incident);
      stdout.writeln('>> ${incident.name} em ${ids.first}');
    }
  });

  Timer.periodic(const Duration(seconds: 1), (_) {
    for (final id in ids) {
      final t = sims[id]!.next().copyWith(ts: DateTime.now().toUtc());
      final c = clients[id]!;
      if (t.buffered) {
        buffers[id]!.add(t);
        stdout.writeln('[$id] sem sinal: ${buffers[id]!.length} leituras guardadas');
        continue;
      }
      for (final old in buffers[id]!) {
        _publish(c, KinetixTopics.telemetry(id), jsonEncode(old.toJson()));
      }
      if (buffers[id]!.isNotEmpty) stdout.writeln('[$id] sinal voltou: ${buffers[id]!.length} leituras enviadas');
      buffers[id]!.clear();
      _publish(c, KinetixTopics.telemetry(id), jsonEncode(t.toJson()));
      stdout.write('\r[$id] inc ${t.tiltDeg.toStringAsFixed(0)}°  pico ${t.peakG.toStringAsFixed(1)} G  '
          '${t.temp?.toStringAsFixed(1)} °C  luz ${t.light.toStringAsFixed(0)}    ');
    }
  });
}

void _publish(MqttServerClient c, String topic, String text, {bool retain = false}) {
  final b = MqttClientPayloadBuilder()..addUTF8String(text);
  c.publishMessage(topic, MqttQos.atMostOnce, b.payload!, retain: retain);
}
