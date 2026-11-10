import 'package:flutter/material.dart';
import 'package:kinetix_core/kinetix_core.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../shell/app_shell.dart';

/// Uma ocorrência em forma de item de lista: hora, ícone, título e lugar.
class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event, this.onTap, this.trailing, this.showLine = false, this.subtitle});

  final CargoEvent event;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showLine;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final c = KxColors.forSeverity(e.severity);
    final place = e.lat == null ? null : DemoRoute.dutra.nearest(e.lat!, e.lng!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KxRadius.input),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KxSpace.sm, horizontal: KxSpace.xs),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 62,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Fmt.time(e.ts), style: KxText.log.copyWith(color: KxColors.textSection)),
                Text(_day(e.ts), style: KxText.log.copyWith(fontSize: 10)),
              ]),
            ),
            Column(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.12), shape: BoxShape.circle, border: Border.all(color: c.withValues(alpha: 0.5))),
                child: Icon(eventIcon(e.type), size: 17, color: c),
              ),
              if (showLine) Expanded(child: Container(width: 1, color: KxColors.borderSlate)),
            ]),
            const SizedBox(width: KxSpace.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: KxSpace.sm),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(e.title, style: KxText.h3.copyWith(fontSize: 15, color: e.severity == Severity.info ? KxColors.textDisplay : c))),
                    if (e.penalty > 0) ...[
                      const SizedBox(width: 6),
                      Text('−${e.penalty.round()}', style: KxText.log.copyWith(color: c, fontWeight: FontWeight.w700)),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(subtitle ?? e.detail, style: KxText.body.copyWith(fontSize: 13)),
                  if (place != null || e.buffered) ...[
                    const SizedBox(height: 4),
                    Wrap(spacing: 10, children: [
                      if (place != null)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.place_outlined, size: 13, color: KxColors.textLog),
                          const SizedBox(width: 3),
                          Text(place, style: KxText.log.copyWith(fontSize: 11)),
                        ]),
                      if (e.buffered)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.sd_card_outlined, size: 13, color: KxColors.telemetryAmber),
                          const SizedBox(width: 3),
                          Text('registrado sem sinal', style: KxText.log.copyWith(fontSize: 11, color: KxColors.telemetryAmber)),
                        ]),
                    ]),
                  ],
                ]),
              ),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
      ),
    );
  }

  static String _day(DateTime d) {
    final l = d.toLocal(), n = DateTime.now();
    if (l.year == n.year && l.month == n.month && l.day == n.day) return 'hoje';
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}';
  }
}
