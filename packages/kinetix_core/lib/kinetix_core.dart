/// Núcleo compartilhado do Kinetix.
///
/// Usado pelo app Flutter (modo demonstração e telas) e pelo serviço ponte
/// MQTT → Supabase, para que as regras do score sejam as mesmas nos dois.
library;

export 'src/cargo_event.dart';
export 'src/cargo_limits.dart';
export 'src/integrity.dart';
export 'src/route.dart';
export 'src/score_engine.dart';
export 'src/simulator.dart';
export 'src/telemetry.dart';
export 'src/topics.dart';
