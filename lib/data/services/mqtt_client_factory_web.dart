import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

/// Navegador: só existe MQTT por WebSocket.
MqttClient createMqttClient(String url, String clientId) {
  final uri = Uri.parse(url);
  return MqttBrowserClient.withPort('${uri.scheme}://${uri.host}${uri.path}', clientId, uri.port)
    ..websocketProtocols = MqttClientConstants.protocolsSingleDefault;
}
