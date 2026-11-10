import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/models.dart';
import 'repositories/kinetix_repository.dart';

/// Repositório ativo (Supabase ou demonstração). Definido no `main.dart`.
final repositoryProvider = Provider<KinetixRepository>((ref) => throw UnimplementedError('defina no main'));

/// Usuário logado (`null` = ninguém logado).
final sessionProvider = StreamProvider<Profile?>((ref) => ref.watch(repositoryProvider).watchSession());

/// Id do usuário logado — as listas recarregam quando a pessoa troca.
final _uidProvider = Provider<String?>((ref) => ref.watch(sessionProvider).value?.id);

final shipmentsProvider = StreamProvider<List<Shipment>>((ref) {
  ref.watch(_uidProvider);
  return ref.watch(repositoryProvider).watchShipments();
});

final shipmentProvider = Provider.autoDispose.family<AsyncValue<Shipment?>, String>(
  (ref, id) => ref.watch(shipmentsProvider).whenData((l) => l.where((s) => s.id == id).firstOrNull),
);

final eventsProvider = StreamProvider.autoDispose.family<List<CargoEvent>, String>(
  (ref, shipmentId) => ref.watch(repositoryProvider).watchEvents(shipmentId),
);

final alertsProvider = StreamProvider<List<CargoEvent>>((ref) {
  ref.watch(_uidProvider);
  return ref.watch(repositoryProvider).watchAlerts();
});

final devicesProvider = StreamProvider<List<Device>>((ref) {
  ref.watch(_uidProvider);
  return ref.watch(repositoryProvider).watchDevices();
});

final profilesProvider = StreamProvider.autoDispose<List<Profile>>((ref) {
  ref.watch(_uidProvider);
  return ref.watch(repositoryProvider).watchProfiles();
});

final liveTelemetryProvider = StreamProvider.autoDispose.family<Telemetry, String>(
  (ref, deviceId) => ref.watch(repositoryProvider).liveTelemetry(deviceId),
);

final readingsProvider = FutureProvider.autoDispose.family<List<Telemetry>, String>(
  (ref, shipmentId) => ref.watch(repositoryProvider).fetchReadings(shipmentId),
);

final receiptProvider = FutureProvider.autoDispose.family<ReceiptSummary?, String>(
  (ref, token) => ref.watch(repositoryProvider).receiptSummary(token),
);
