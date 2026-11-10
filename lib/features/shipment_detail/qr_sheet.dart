import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/config/env.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/kx_widgets.dart';
import '../../data/models/models.dart';

/// Link que vai dentro do QR Code. Lido por qualquer câmera de celular, abre a
/// página de recebimento do app (web). O leitor do app também aceita o código puro.
String receiptLink(String token) {
  if (Env.appUrl.isNotEmpty) return '${Env.appUrl.replaceAll(RegExp(r'/+$'), '')}/#/r/$token';
  if (kIsWeb) return '${Uri.base.origin}${Uri.base.path}#/r/$token';
  return 'KINETIX:$token';
}

/// Extrai o código da carga de um texto lido no QR (link ou código puro).
String? tokenFromScan(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final m = RegExp(r'/r/([A-Za-z0-9_-]+)').firstMatch(s);
  if (m != null) return m.group(1);
  if (s.toUpperCase().startsWith('KINETIX:')) return s.substring(8).trim();
  if (RegExp(r'^[A-Za-z0-9_-]{6,}$').hasMatch(s)) return s;
  return null;
}

Future<void> showQrSheet(BuildContext context, Shipment s) {
  final link = receiptLink(s.qrToken);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(KxSpace.xl, 0, KxSpace.xl, KxSpace.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('QR Code de recebimento', style: KxText.h2),
          const SizedBox(height: KxSpace.sm),
          Text(
            'Imprima e cole na etiqueta da caixa. Na entrega, o destinatário lê com a câmera do celular, confere a viagem e assina.',
            style: KxText.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KxSpace.lg),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: QrImageView(data: link, size: 220, backgroundColor: Colors.white),
          ),
          const SizedBox(height: KxSpace.md),
          Text('${s.code} · ${s.description}', style: KxText.h3, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          SelectableText(s.qrToken, style: KxText.log),
          const SizedBox(height: KxSpace.lg),
          Wrap(spacing: KxSpace.sm, runSpacing: KxSpace.sm, alignment: WrapAlignment.center, children: [
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (ctx.mounted) showSnack(ctx, 'Link copiado.');
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copiar link'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push(Routes.receipt(s.qrToken));
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Abrir página de recebimento'),
            ),
          ]),
          const SizedBox(height: KxSpace.sm),
          Text('Dica: na apresentação, abra este QR em outro celular para simular o destinatário.',
              style: KxText.log.copyWith(color: KxColors.textBody), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}
