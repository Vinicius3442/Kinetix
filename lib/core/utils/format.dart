import 'package:intl/intl.dart';

/// Formatação em português do Brasil, no horário do aparelho.
abstract final class Fmt {
  static final _time = DateFormat('HH:mm:ss', 'pt_BR');
  static final _hm = DateFormat('HH:mm', 'pt_BR');
  static final _dayTime = DateFormat("dd/MM 'às' HH:mm", 'pt_BR');
  static final _full = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');

  static String time(DateTime d) => _time.format(d.toLocal());
  static String hm(DateTime d) => _hm.format(d.toLocal());
  static String dayTime(DateTime d) => _dayTime.format(d.toLocal());
  static String full(DateTime d) => _full.format(d.toLocal());

  /// "agora", "há 2 min", "há 3 h", "ontem às 14:32", "05/11 às 09:10".
  static String ago(DateTime d, {DateTime? now}) {
    final n = (now ?? DateTime.now()).toLocal();
    final l = d.toLocal();
    final diff = n.difference(l);
    if (diff.inSeconds < 10) return 'agora';
    if (diff.inSeconds < 60) return 'há ${diff.inSeconds} s';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 12 && n.day == l.day) return 'há ${diff.inHours} h';
    final yesterday = DateTime(n.year, n.month, n.day).subtract(const Duration(days: 1));
    if (l.isAfter(yesterday) && l.isBefore(DateTime(n.year, n.month, n.day))) return 'ontem às ${hm(l)}';
    if (n.day == l.day && n.month == l.month && n.year == l.year) return 'hoje às ${hm(l)}';
    return dayTime(l);
  }

  /// Duração legível: "45 min", "2 h 10 min".
  static String duration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds} s';
    if (d.inHours < 1) return '${d.inMinutes} min';
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m min';
  }

  static String num(double? v, [int places = 1]) =>
      v == null ? '—' : v.toStringAsFixed(places).replaceAll('.', ',');

  static String coords(double? lat, double? lng) =>
      lat == null || lng == null ? 'sem localização' : '${num(lat, 4)}, ${num(lng, 4)}';
}
