import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/kx_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../data/repositories/kinetix_repository.dart';
import '../timeline/event_tile.dart';
import 'signature_pad.dart';

/// Página pública aberta pelo QR Code: resumo da viagem, assinatura e
/// certificado de recebimento. Não precisa de login.
class ReceiveScreen extends ConsumerWidget {
  const ReceiveScreen({super.key, required this.token});
  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(receiptProvider(token));
    final loggedIn = ref.watch(sessionProvider).value != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(loggedIn ? Routes.shipments : Routes.login),
        ),
        title: const KxLogo(height: 24, subtitle: 'Recebimento de carga'),
      ),
      body: KxBackground(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(receiptProvider(token))),
          data: (summary) => summary == null
              ? EmptyState(
                  icon: Icons.qr_code_2_rounded,
                  title: 'QR Code não reconhecido',
                  message: 'Não encontramos uma carga com este código. Confira se a etiqueta é da Kinetix ou peça ajuda ao motorista.',
                  action: OutlinedButton(onPressed: () => context.go(Routes.publicScanner), child: const Text('Ler outro QR Code')),
                )
              : ContentWidth(
                  max: 720,
                  child: ListView(padding: const EdgeInsets.all(KxSpace.lg), children: [
                    _Header(summary: summary),
                    const SizedBox(height: KxSpace.md),
                    if (summary.receipt != null) ...[
                      _Certificate(summary: summary),
                    ] else ...[
                      _Verdict(summary: summary),
                      const SizedBox(height: KxSpace.md),
                      _Journey(summary: summary),
                      const SizedBox(height: KxSpace.md),
                      _ReceiptForm(token: token),
                    ],
                    if (summary.receipt != null) ...[const SizedBox(height: KxSpace.md), _Journey(summary: summary)],
                  ]),
                ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.summary});
  final ReceiptSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary.shipment;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(summary.receipt == null ? 'VOCÊ ESTÁ RECEBENDO' : 'COMPROVANTE DE RECEBIMENTO',
          style: KxText.label.copyWith(color: KxColors.cyberCyan)),
      const SizedBox(height: 4),
      Text(s.description, style: KxText.h1),
      const SizedBox(height: 4),
      Text('Carga ${s.code} · ${s.origin} → ${s.destination}${s.vehiclePlate == null ? '' : ' · Veículo ${s.vehiclePlate}'}',
          style: KxText.body),
      if (s.recipientName != null) Text('Destinatário: ${s.recipientName}', style: KxText.body),
    ]);
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.summary});
  final ReceiptSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary.shipment;
    final n = summary.incidents.length;
    final c = KxColors.forIntegrity(s.integrity);
    final (title, text) = switch (s.integrity) {
      Integrity.ok => (
          'A carga chegou sem problemas',
          n == 0
              ? 'Nada de errado foi registrado na viagem. Confira a embalagem e aprove.'
              : 'Só ocorrências muito leves. Confira a embalagem e aprove.'
        ),
      Integrity.attention => (
          'Confira antes de aprovar',
          'Houve $n ${n == 1 ? 'ocorrência' : 'ocorrências'} na viagem. Veja abaixo e confira a embalagem.'
        ),
      Integrity.problem => ('Atenção: possível dano', 'A carga teve ocorrências graves. Abra e confira o conteúdo antes de aprovar.'),
    };
    return KxCard(
      glow: s.integrity == Integrity.ok ? null : c,
      child: Row(children: [
        ScoreGauge(score: s.score, size: 104),
        const SizedBox(width: KxSpace.lg),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: KxText.h2.copyWith(color: c)),
            const SizedBox(height: 4),
            Text(text, style: KxText.body),
          ]),
        ),
      ]),
    );
  }
}

class _Journey extends StatelessWidget {
  const _Journey({required this.summary});
  final ReceiptSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary.shipment;
    final end = s.deliveredAt ?? DateTime.now();
    Widget stat(IconData i, String label, String value, [Color? c]) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, size: 18, color: c ?? KxColors.cyberCyan),
            const SizedBox(height: 4),
            FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: KxText.metric(c ?? KxColors.textDisplay).copyWith(fontSize: 16), maxLines: 1)),
            Text(label, style: KxText.body.copyWith(fontSize: 12)),
          ]),
        );
    final tempOk = summary.tempMax == null || (summary.tempMax! <= s.limits.tempMax && summary.tempMin! >= s.limits.tempMin);
    return KxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Resumo da viagem'),
        Row(children: [
          stat(Icons.schedule_rounded, 'de viagem', s.startedAt == null ? '—' : Fmt.duration(end.difference(s.startedAt!))),
          stat(
              Icons.thermostat_rounded,
              'faixa ${Fmt.num(s.limits.tempMin, 0)}–${Fmt.num(s.limits.tempMax, 0)} °C',
              summary.tempMin == null ? '—' : '${Fmt.num(summary.tempMin)}–${Fmt.num(summary.tempMax)} °C',
              tempOk ? null : KxColors.talpaLava),
          stat(Icons.vibration_rounded, 'maior solavanco', summary.peakG == null ? '—' : '${Fmt.num(summary.peakG)} G'),
        ]),
        const SizedBox(height: KxSpace.lg),
        const SectionTitle('O que aconteceu'),
        if (summary.events.isEmpty)
          Text('Nenhum registro.', style: KxText.body)
        else
          for (final (i, e) in summary.events.reversed.indexed) EventTile(event: e, showLine: i < summary.events.length - 1),
      ]),
    );
  }
}

class _ReceiptForm extends ConsumerStatefulWidget {
  const _ReceiptForm({required this.token});
  final String token;

  @override
  ConsumerState<_ReceiptForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends ConsumerState<_ReceiptForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _sign = SignatureController();
  bool _busy = false, _signError = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final me = ref.read(sessionProvider).value;
    if (me != null) _name.text = me.fullName;
    _sign.addListener(() {
      if (_signError && !_sign.isEmpty) setState(() => _signError = false);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _sign.dispose();
    super.dispose();
  }

  Future<void> _submit(bool approved) async {
    final okForm = _form.currentState!.validate();
    setState(() => _signError = _sign.isEmpty);
    if (!okForm || _sign.isEmpty) return;
    if (!approved) {
      if (_notes.text.trim().isEmpty) {
        setState(() => _error = 'Para recusar, escreva o motivo no campo de observação.');
        return;
      }
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Recusar esta carga?'),
          content: const Text('A recusa fica registrada no histórico e a transportadora é avisada. Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Recusar carga')),
          ],
        ),
      );
      if (confirm != true) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(repositoryProvider).confirmReceipt(
            token: widget.token,
            signer: _name.text,
            signatureSvg: _sign.toSvg(),
            approved: approved,
            notes: _notes.text,
          );
      ref.invalidate(receiptProvider(widget.token));
    } on KxException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KxCard(
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('Assinar recebimento'),
          Text('Confira a caixa. Se estiver tudo certo, assine e aprove.', style: KxText.body),
          const SizedBox(height: KxSpace.lg),
          if (_error != null) ...[
            Text(_error!, style: KxText.body.copyWith(color: KxColors.talpaLava)),
            const SizedBox(height: KxSpace.md),
          ],
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome de quem está recebendo'),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v ?? '').trim().length < 3 ? 'Digite o seu nome completo.' : null,
          ),
          const SizedBox(height: KxSpace.lg),
          Text('Assinatura', style: KxText.body.copyWith(color: KxColors.textSection)),
          const SizedBox(height: KxSpace.sm),
          SignaturePad(controller: _sign, hasError: _signError),
          const SizedBox(height: KxSpace.sm),
          TextFormField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Observação (opcional)', hintText: 'Ex.: embalagem amassada na lateral'),
            maxLines: 2,
            onChanged: (_) => _error == null ? null : setState(() => _error = null),
          ),
          const SizedBox(height: KxSpace.xl),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: KxColors.electricLime, foregroundColor: KxColors.obsidianPitch),
            onPressed: _busy ? null : () => _submit(true),
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: KxColors.obsidianPitch))
                : const Icon(Icons.verified_rounded),
            label: const Text('Aprovar recebimento'),
          ),
          const SizedBox(height: KxSpace.sm),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: KxColors.talpaLava, side: const BorderSide(color: KxColors.talpaLava)),
            onPressed: _busy ? null : () => _submit(false),
            icon: const Icon(Icons.block_rounded),
            label: const Text('Recusar carga'),
          ),
        ]),
      ),
    );
  }
}

class _Certificate extends StatelessWidget {
  const _Certificate({required this.summary});
  final ReceiptSummary summary;

  @override
  Widget build(BuildContext context) {
    final r = summary.receipt!;
    final s = summary.shipment;
    final c = r.approved ? KxColors.electricLime : KxColors.talpaLava;
    return KxCard(
      glow: c,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(r.approved ? Icons.verified_rounded : Icons.block_rounded, color: c, size: 32),
          const SizedBox(width: KxSpace.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.approved ? 'Recebimento aprovado' : 'Recebimento recusado', style: KxText.h2.copyWith(color: c)),
              Text('por ${r.signerName} em ${Fmt.full(r.signedAt)}', style: KxText.body),
            ]),
          ),
          ScoreGauge(score: s.score, size: 72, stroke: 6),
        ]),
        if (r.notes != null) ...[
          const SizedBox(height: KxSpace.md),
          Text('Observação: ${r.notes}', style: KxText.body.copyWith(color: KxColors.textSection)),
        ],
        if (r.signatureSvg != null) ...[
          const SizedBox(height: KxSpace.md),
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF4F7FA), borderRadius: BorderRadius.circular(KxRadius.input)),
            child: SvgPicture.string(r.signatureSvg!, fit: BoxFit.contain),
          ),
        ],
        const SizedBox(height: KxSpace.md),
        Text('Registro ${s.qrToken} · ${summary.readings} leituras de sensores nesta viagem', style: KxText.log),
      ]),
    );
  }
}
