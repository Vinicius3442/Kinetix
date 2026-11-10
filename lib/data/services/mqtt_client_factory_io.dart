import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Android / desktop: MQTT por WebSocket seguro (mesma URL da web).
MqttClient createMqttClient(String url, String clientId) {
  final uri = Uri.parse(url);
  return MqttServerClient.withPort('${uri.scheme}://${uri.host}${uri.path}', clientId, uri.port)
    ..useWebSocket = true
    ..websocketProtocols = MqttClientConstants.protocolsSingleDefault;
}
