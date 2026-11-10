import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/kx_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../data/repositories/kinetix_repository.dart';

/// Cadastro e edição de carga.
class ShipmentFormScreen extends ConsumerStatefulWidget {
  const ShipmentFormScreen({super.key, this.shipmentId});
  final String? shipmentId;

  @override
  ConsumerState<ShipmentFormScreen> createState() => _ShipmentFormScreenState();
}

class _ShipmentFormScreenState extends ConsumerState<ShipmentFormScreen> {
  final _form = GlobalKey<FormState>();
  ShipmentDraft? _d;
  Shipment? _editing;
  bool _busy = false, _advanced = false;
  String? _error;

  late final _code = TextEditingController();
  late final _desc = TextEditingController();
  late final _origin = TextEditingController();
  late final _dest = TextEditingController();
  late final _plate = TextEditingController();
  late final _recipient = TextEditingController();
  late final _tMin = TextEditingController();
  late final _tMax = TextEditingController();
  late final _hMax = TextEditingController();
  late final _impact = TextEditingController();
  late final _tilt = TextEditingController();

  void _init(List<Shipment> all) {
    if (_d != null) return;
    _editing = widget.shipmentId == null ? null : all.where((s) => s.id == widget.shipmentId).firstOrNull;
    _d = _editing == null ? ShipmentDraft(code: _suggestCode(all)) : ShipmentDraft.from(_editing!);
    _code.text = _d!.code;
    _desc.text = _d!.description;
    _origin.text = _d!.origin;
    _dest.text = _d!.destination;
    _plate.text = _d!.vehiclePlate ?? '';
    _recipient.text = _d!.recipientName ?? '';
    _setLimits(_d!.limits);
  }

  String _suggestCode(List<Shipment> all) {
    final nums = all.map((s) => int.tryParse(s.code.replaceAll(RegExp(r'\D'), '')) ?? 0);
    return 'TC-${(nums.isEmpty ? 1000 : nums.reduce(math.max)) + 1}';
  }

  void _setLimits(CargoLimits l) {
    _tMin.text = Fmt.num(l.tempMin, 0);
    _tMax.text = Fmt.num(l.tempMax, 0);
    _hMax.text = Fmt.num(l.humMax, 0);
    _impact.text = Fmt.num(l.impactG, 1);
    _tilt.text = Fmt.num(l.tiltDeg, 0);
  }

  double? _n(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    for (final c in [_code, _desc, _origin, _dest, _plate, _recipient, _tMin, _tMax, _hMax, _impact, _tilt]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      setState(() => _error = 'Confira os campos destacados.');
      return;
    }
    final d = _d!
      ..code = _code.text
      ..description = _desc.text
      ..origin = _origin.text
      ..destination = _dest.text
      ..vehiclePlate = _plate.text
      ..recipientName = _recipient.text
      ..limits = CargoLimits(
        tempMin: _n(_tMin)!,
        tempMax: _n(_tMax)!,
        humMax: _n(_hMax)!,
        impactG: _n(_impact)!,
        tiltDeg: _n(_tilt)!,
        lightPct: _d!.limits.lightPct,
      );
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(repositoryProvider);
    try {
      if (_editing == null) {
        final s = await repo.createShipment(d);
        if (mounted) {
          showSnack(context, 'Carga ${s.code} cadastrada. Mostre o QR Code na etiqueta da caixa.');
          context.go(Routes.shipment(s.id));
        }
      } else {
        await repo.updateShipment(_editing!.id, d);
        if (mounted) {
          showSnack(context, 'Alterações salvas.');
          context.go(Routes.shipment(_editing!.id));
        }
      }
    } on KxException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final s = _editing!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir a carga ${s.code}?'),
        content: const Text('O histórico, as ocorrências e o comprovante desta carga também serão apagados. Não dá para desfazer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Excluir ${s.code}')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final done = await runAction(context, () => ref.read(repositoryProvider).deleteShipment(s.id), success: 'Carga excluída.');
    if (done && mounted) context.go(Routes.admin);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(shipmentsProvider).value;
    final devices = ref.watch(devicesProvider).value ?? const <Device>[];
    final profiles = ref.watch(profilesProvider).value ?? const <Profile>[];
    if (all == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    _init(all);
    final d = _d!;
    final busyDevices = all.where((s) => s.status.isActive && s.id != _editing?.id).map((s) => s.deviceId).toSet();
    final drivers = profiles.where((p) => p.role == UserRole.motorista).toList();

    String? req(String? v) => (v ?? '').trim().isEmpty ? 'Campo obrigatório.' : null;
    String? num(String? v) => double.tryParse((v ?? '').trim().replaceAll(',', '.')) == null ? 'Número' : null;

    Widget numField(TextEditingController c, String label, String suffix) => SizedBox(
          width: 150,
          child: TextFormField(
            controller: c,
            decoration: InputDecoration(labelText: label, suffixText: suffix),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))],
            validator: num,
          ),
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.admin),
        ),
        title: Text(_editing == null ? 'Nova carga' : 'Editar ${_editing!.code}'),
        actions: [
          if (_editing != null) IconButton(tooltip: 'Excluir carga', icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ContentWidth(
        max: 720,
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(KxSpace.lg, 0, KxSpace.lg, KxSpace.xxl), children: [
            if (_error != null) ...[
              KxCard(glow: KxColors.talpaLava, child: Text(_error!, style: KxText.body.copyWith(color: KxColors.textDisplay))),
              const SizedBox(height: KxSpace.md),
            ],
            KxCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SectionTitle('A carga'),
                TextFormField(
                    controller: _desc,
                    decoration: const InputDecoration(labelText: 'O que está sendo levado', hintText: 'Ex.: Vacinas termossensíveis'),
                    validator: req),
                const SizedBox(height: KxSpace.md),
                Row(children: [
                  Expanded(
                      child: TextFormField(
                          controller: _code,
                          decoration: const InputDecoration(labelText: 'Código'),
                          textCapitalization: TextCapitalization.characters,
                          validator: req)),
                  const SizedBox(width: KxSpace.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: CargoCategory.all.any((c) => c.name == d.category) ? d.category : 'Geral',
                      decoration: const InputDecoration(labelText: 'Tipo de carga'),
                      items: [for (final c in CargoCategory.all) DropdownMenuItem(value: c.name, child: Text(c.name))],
                      onChanged: (v) {
                        final cat = CargoCategory.all.firstWhere((c) => c.name == v);
                        setState(() {
                          d.category = cat.name;
                          d.limits = cat.limits;
                          _setLimits(cat.limits);
                        });
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: KxSpace.sm),
                Text(
                  'Faixa segura: ${_tMin.text}–${_tMax.text} °C, umidade até ${_hMax.text}%, impacto até ${_impact.text} G.',
                  style: KxText.body.copyWith(fontSize: 13),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _advanced = !_advanced),
                    icon: Icon(_advanced ? Icons.expand_less : Icons.tune_rounded, size: 18),
                    label: Text(_advanced ? 'Esconder limites' : 'Ajustar limites'),
                  ),
                ),
                if (_advanced)
                  Wrap(spacing: KxSpace.md, runSpacing: KxSpace.md, children: [
                    numField(_tMin, 'Temp. mínima', '°C'),
                    numField(_tMax, 'Temp. máxima', '°C'),
                    numField(_hMax, 'Umidade máx.', '%'),
                    numField(_impact, 'Impacto', 'G'),
                    numField(_tilt, 'Inclinação', '°'),
                  ]),
              ]),
            ),
            const SizedBox(height: KxSpace.md),
            KxCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SectionTitle('A viagem'),
                TextFormField(
                    controller: _origin, decoration: const InputDecoration(labelText: 'Saindo de', hintText: 'Cidade-UF'), validator: req),
                const SizedBox(height: KxSpace.md),
                TextFormField(
                    controller: _dest, decoration: const InputDecoration(labelText: 'Indo para', hintText: 'Cidade-UF'), validator: req),
                const SizedBox(height: KxSpace.md),
                TextFormField(controller: _recipient, decoration: const InputDecoration(labelText: 'Quem vai receber (opcional)')),
                const SizedBox(height: KxSpace.md),
                TextFormField(
                    controller: _plate,
                    decoration: const InputDecoration(labelText: 'Placa do veículo (opcional)'),
                    textCapitalization: TextCapitalization.characters),
              ]),
            ),
            const SizedBox(height: KxSpace.md),
            KxCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SectionTitle('Monitoramento'),
                DropdownButtonFormField<String?>(
                  initialValue: devices.any((x) => x.id == d.deviceId) ? d.deviceId : null,
                  decoration: const InputDecoration(labelText: 'Caixa Kinetix', helperText: 'Só aparecem as caixas livres.'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Nenhuma por enquanto')),
                    for (final x in devices.where((x) => !busyDevices.contains(x.id) || x.id == d.deviceId))
                      DropdownMenuItem(value: x.id, child: Text('${x.name} (${x.id})${x.online ? ' · online' : ''}')),
                  ],
                  onChanged: (v) => setState(() => d.deviceId = v),
                ),
                const SizedBox(height: KxSpace.lg),
                DropdownButtonFormField<String?>(
                  initialValue: drivers.any((x) => x.id == d.driverId) ? d.driverId : null,
                  decoration: InputDecoration(
                    labelText: 'Motorista',
                    helperText: drivers.isEmpty ? 'Nenhum usuário com perfil Motorista ainda.' : 'O motorista vê esta carga no app dele.',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Sem motorista')),
                    for (final p in drivers) DropdownMenuItem(value: p.id, child: Text(p.fullName.isEmpty ? p.email : p.fullName)),
                  ],
                  onChanged: (v) => setState(() => d.driverId = v),
                ),
              ]),
            ),
            const SizedBox(height: KxSpace.xl),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_editing == null ? 'Cadastrar carga' : 'Salvar alterações'),
            ),
          ]),
        ),
      ),
    );
  }
}
