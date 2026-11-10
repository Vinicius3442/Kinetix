import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kinetix_core/kinetix_core.dart';

/// Carga ativa de uma caixa, com o que o serviço ponte precisa para o score.
class ActiveShipment {
  ActiveShipment({
    required this.id,
    required this.code,
    required this.limits,
    required this.score,
    this.engineState,
  });

  final String id;
  final String code;
  final CargoLimits limits;
  final double score;
  final Map<String, dynamic>? engineState;

  factory ActiveShipment.fromJson(Map<String, dynamic> j) => ActiveShipment(
        id: j['id'].toString(),
        code: j['code'].toString(),
        limits: CargoLimits.fromJson(j),
        score: (j['score'] as num?)?.toDouble() ?? 100,
        engineState: j['engine_state'] as Map<String, dynamic>?,
      );
}

/// Onde o serviço ponte grava os dados. Interface separada para os testes.
abstract class BridgeStore {
  Future<ActiveShipment?> activeShipment(String deviceId);
  Future<void> upsertDevice(String deviceId, Map<String, dynamic> fields);
  Future<void> insertReadings(List<Map<String, dynamic>> rows);
  Future<List<CargoEvent>> insertEvents(List<CargoEvent> events);
  Future<void> updateShipment(String shipmentId, Map<String, dynamic> fields);
}

/// Grava no Supabase pela API REST (PostgREST) usando a chave service_role.
class SupabaseStore implements BridgeStore {
  SupabaseStore(String url, this.serviceKey, {http.Client? client})
      : base = '${url.replaceAll(RegExp(r'/+$'), '')}/rest/v1',
        _http = client ?? http.Client();

  final String base;
  final String serviceKey;
  final http.Client _http;

  Map<String, String> get _h => {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
      };

  Future<http.Response> _check(Future<http.Response> f) async {
    final r = await f;
    if (r.statusCode >= 300) {
      throw Exception('Supabase ${r.request?.method} ${r.request?.url.path} → ${r.statusCode}: ${r.body}');
    }
    return r;
  }

  @override
  Future<ActiveShipment?> activeShipment(String deviceId) async {
    final r = await _check(_http.get(
      Uri.parse('$base/shipments?device_id=eq.${Uri.encodeComponent(deviceId)}'
          '&status=eq.em_transito&select=id,code,score,engine_state,temp_min,temp_max,hum_max,impact_g,tilt_deg,light_pct&limit=1'),
      headers: _h,
    ));
    final list = jsonDecode(r.body) as List;
    return list.isEmpty ? null : ActiveShipment.fromJson(list.first as Map<String, dynamic>);
  }

  @override
  Future<void> upsertDevice(String deviceId, Map<String, dynamic> fields) async {
    await _check(_http.post(
      Uri.parse('$base/devices?on_conflict=id'),
      headers: {..._h, 'Prefer': 'resolution=merge-duplicates,return=minimal'},
      body: jsonEncode({'id': deviceId, 'name': 'Caixa $deviceId', ...fields}),
    ));
  }

  @override
  Future<void> insertReadings(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _check(_http.post(Uri.parse('$base/readings'),
        headers: {..._h, 'Prefer': 'return=minimal'}, body: jsonEncode(rows)));
  }

  @override
  Future<List<CargoEvent>> insertEvents(List<CargoEvent> events) async {
    if (events.isEmpty) return const [];
    final r = await _check(_http.post(Uri.parse('$base/events'),
        headers: {..._h, 'Prefer': 'return=representation'},
        body: jsonEncode(events.map((e) => e.toJson()).toList())));
    return (jsonDecode(r.body) as List).map((e) => CargoEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> updateShipment(String shipmentId, Map<String, dynamic> fields) async {
    await _check(_http.patch(Uri.parse('$base/shipments?id=eq.$shipmentId'),
        headers: {..._h, 'Prefer': 'return=minimal'}, body: jsonEncode(fields)));
  }
}
