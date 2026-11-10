import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix/data/services/resilient_stream.dart';

void main() {
  test('falha do tempo real depois de chegar dado não vira erro na tela e reconecta', () async {
    var connections = 0;
    Stream<int> connect() {
      connections++;
      final c = StreamController<int>();
      c.add(connections);
      if (connections == 1) Future.microtask(() => c.addError(Exception('channelError')));
      return c.stream;
    }

    final values = <int>[];
    final errors = <Object>[];
    final sub = resilientStream(connect, minDelay: const Duration(milliseconds: 10)).listen(values.add, onError: errors.add);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await sub.cancel();
    expect(errors, isEmpty);
    expect(values, [1, 2]);
    expect(connections, 2);
  });

  test('erro antes do primeiro dado é mostrado', () async {
    final errors = <Object>[];
    final sub = resilientStream<int>(() => Stream.error(Exception('sem rede')), minDelay: const Duration(seconds: 5))
        .listen((_) {}, onError: errors.add);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();
    expect(errors, hasLength(1));
  });
}
