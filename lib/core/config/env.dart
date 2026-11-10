/// Configuração do app, passada na hora de rodar/compilar:
///
/// ```bash
/// flutter run -d chrome \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
///
/// Sem `SUPABASE_URL` o app abre no **modo demonstração**: dados simulados no
/// próprio aparelho, sem precisar de internet, banco ou placa.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Broker MQTT via WebSocket seguro (o navegador não fala MQTT "puro").
  static const mqttWsUrl = String.fromEnvironment('MQTT_WS_URL', defaultValue: 'wss://broker.hivemq.com:8884/mqtt');
  static const mqttUser = String.fromEnvironment('MQTT_USER');
  static const mqttPass = String.fromEnvironment('MQTT_PASS');

  /// Endereço público do app (usado no link do QR Code). Na web, se vazio,
  /// usa o endereço em que o app está aberto.
  static const appUrl = String.fromEnvironment('APP_URL');

  static const forceDemo = bool.fromEnvironment('DEMO');

  static bool get isDemo => forceDemo || supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;
}
