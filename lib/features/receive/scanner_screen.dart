import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/kx_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../shipment_detail/qr_sheet.dart';

/// Leitor do QR Code da etiqueta (RF 07). Também aceita digitar o código.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key, this.standalone = false});

  /// `true` quando aberto sem login (destinatário).
  final bool standalone;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _code = TextEditingController();
  MobileScannerController? _camera;
  bool _cameraOn = false;
  bool _handled = false;
  String? _error;

  @override
  void dispose() {
    _camera?.dispose();
    _code.dispose();
    super.dispose();
  }

  void _open(String raw) {
    final token = tokenFromScan(raw);
    if (token == null) {
      setState(() => _error = 'Esse código não é de uma etiqueta Kinetix. Confira e tente de novo.');
      return;
    }
    _handled = true;
    _camera?.stop();
    context.push(Routes.receipt(token)).then((_) {
      _handled = false;
      if (_cameraOn) _camera?.start();
    });
  }

  void _startCamera() {
    setState(() {
      _camera ??= MobileScannerController(formats: const [BarcodeFormat.qrCode]);
      _cameraOn = true;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final samples = repo.isDemo && !widget.standalone
        ? (ref.watch(shipmentsProvider).value ?? const <Shipment>[]).where((s) => s.status.isActive).toList()
        : const <Shipment>[];

    final body = ContentWidth(
      max: 560,
      child: ListView(padding: const EdgeInsets.all(KxSpace.lg), children: [
        if (!widget.standalone) Text('Receber carga', style: KxText.h1),
        const SizedBox(height: KxSpace.xs),
        Text('Aponte a câmera para o QR Code da etiqueta da caixa para ver o histórico e assinar o recebimento.', style: KxText.body),
        const SizedBox(height: KxSpace.lg),
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(KxRadius.card),
            child: Container(
              color: KxColors.charcoalSolid,
              child: _cameraOn
                  ? Stack(fit: StackFit.expand, children: [
                      MobileScanner(
                        controller: _camera,
                        onDetect: (capture) {
                          if (_handled) return;
                          final v = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
                          if (v != null) _open(v);
                        },
                        errorBuilder: (context, error) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(KxSpace.xl),
                            child: Text(
                              'Não foi possível usar a câmera. Permita o acesso à câmera no navegador ou digite o código abaixo.',
                              style: KxText.body,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const _ScanFrame(),
                    ])
                  : Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.qr_code_scanner_rounded, size: 64, color: KxColors.cyberCyan),
                        const SizedBox(height: KxSpace.lg),
                        FilledButton.icon(
                            onPressed: _startCamera, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Abrir câmera')),
                      ]),
                    ),
            ),
          ),
        ),
        const SizedBox(height: KxSpace.xl),
        Text('Sem câmera? Digite o código da etiqueta', style: KxText.h3),
        const SizedBox(height: KxSpace.sm),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextField(
              controller: _code,
              decoration: InputDecoration(labelText: 'Código ou link do QR', errorText: _error),
              onChanged: (_) => _error == null ? null : setState(() => _error = null),
              onSubmitted: _open,
            ),
          ),
          const SizedBox(width: KxSpace.sm),
          SizedBox(height: 52, child: FilledButton(onPressed: () => _open(_code.text), child: const Text('Abrir'))),
        ]),
        if (samples.isNotEmpty) ...[
          const SizedBox(height: KxSpace.xl),
          const SectionTitle('Modo demonstração: simular leitura de'),
          Wrap(spacing: KxSpace.sm, runSpacing: KxSpace.sm, children: [
            for (final s in samples)
              ActionChip(avatar: const Icon(Icons.qr_code_2_rounded, size: 18), label: Text(s.code), onPressed: () => _open(s.qrToken)),
          ]),
        ],
      ]),
    );

    if (!widget.standalone) return Scaffold(backgroundColor: Colors.transparent, body: SafeArea(child: body));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler QR Code da carga'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.login),
        ),
      ),
      body: KxBackground(child: body),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.65,
            heightFactor: 0.65,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: KxColors.cyberCyan, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
}
