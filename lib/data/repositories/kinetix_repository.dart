import '../models/models.dart';

/// Erro com mensagem pronta para mostrar ao usuário.
class KxException implements Exception {
  const KxException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Tudo o que o app lê e grava. Duas implementações:
/// - [SupabaseRepository]: banco real + MQTT (apresentação com Wokwi/placa);
/// - [DemoRepository]: tudo simulado no aparelho (sem internet).
abstract class KinetixRepository {
  bool get isDemo;

  // -------- sessão
  Stream<Profile?> watchSession();
  Future<void> signIn(String email, String password);
  Future<void> signUp(String name, String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
  Future<void> updateMyProfile({required String fullName, String? phone, String? company});
  Future<void> markOnboarded();

  // -------- cargas
  Stream<List<Shipment>> watchShipments();
  Future<Shipment> createShipment(ShipmentDraft draft);
  Future<void> updateShipment(String id, ShipmentDraft draft);
  Future<void> deleteShipment(String id);
  Future<void> startShipment(String id);

  // -------- ocorrências e histórico
  Stream<List<CargoEvent>> watchEvents(String shipmentId);

  /// Ocorrências ainda não vistas, de todas as cargas que o usuário acompanha.
  Stream<List<CargoEvent>> watchAlerts();
  Future<void> acknowledge(int eventId);
  Future<List<Telemetry>> fetchReadings(String shipmentId, {int limit = 400});

  // -------- caixas e telemetria ao vivo
  Stream<List<Device>> watchDevices();
  Future<void> saveDevice(String id, String name);
  Future<void> deleteDevice(String id);

  /// Leituras ao vivo da caixa (MQTT, ou simulador no modo demonstração).
  Stream<Telemetry> liveTelemetry(String deviceId);

  // -------- usuários (admin)
  Stream<List<Profile>> watchProfiles();
  Future<void> setRole(String userId, UserRole role);

  // -------- recebimento (público, sem login)
  Future<ReceiptSummary?> receiptSummary(String token);
  Future<ReceiptSummary> confirmReceipt({
    required String token,
    required String signer,
    required String? signatureSvg,
    required bool approved,
    String? notes,
  });

  // -------- modo demonstração
  /// Provoca uma ocorrência na caixa (só no modo demonstração).
  void simulate(String deviceId, SimIncident incident) {}

  void dispose() {}
}
