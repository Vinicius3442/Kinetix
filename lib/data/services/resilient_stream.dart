import 'dart:async';

/// Envolve um stream de tempo real que pode falhar (ex.: canal do Supabase
/// Realtime caindo ou tabela fora da publicação).
///
/// - Depois que já chegou algum dado, um erro **não** é repassado: a tela
///   continua mostrando os últimos dados e o stream é recriado em silêncio,
///   com espera crescente ([minDelay] → [maxDelay]).
/// - Antes do primeiro dado, o erro é repassado (a tela mostra "Tentar de novo").
///
/// Sem isso, cada falha do canal virava erro na tela, o Riverpod recarregava o
/// provider e a lista ficava "piscando".
Stream<T> resilientStream<T>(
  Stream<T> Function() connect, {
  Duration minDelay = const Duration(seconds: 2),
  Duration maxDelay = const Duration(seconds: 30),
  bool Function(Object error)? isFatal,
}) {
  late final StreamController<T> out;
  StreamSubscription<T>? sub;
  Timer? timer;
  var hasData = false;
  var closed = false;
  var delay = minDelay;

  void open() {
    if (closed) return;
    sub = connect().listen(
      (v) {
        hasData = true;
        delay = minDelay;
        out.add(v);
      },
      onError: (Object e, StackTrace st) {
        sub?.cancel();
        sub = null;
        if (!hasData || (isFatal?.call(e) ?? false)) out.addError(e, st);
        if (closed) return;
        timer = Timer(delay, open);
        final next = delay * 2;
        delay = next > maxDelay ? maxDelay : next;
      },
      onDone: () {
        sub = null;
        if (!closed) timer = Timer(delay, open);
      },
      cancelOnError: false,
    );
  }

  out = StreamController<T>(
    onListen: open,
    onCancel: () async {
      closed = true;
      timer?.cancel();
      await sub?.cancel();
    },
  );
  return out.stream;
}
