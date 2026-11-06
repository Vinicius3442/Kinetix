import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/cargo_box.dart';
import '../theme/app_colors.dart';
import '../widgets/web_3d_viewer.dart';
import 'admin_panel_screen.dart';
import 'profile_screen.dart';
import 'qr_scanner_screen.dart';
import 'timeline_screen.dart';

class MainTabContainer extends StatefulWidget {
  final String userRole;
  final int initialIndex;
  final int initialCargoIndex;
  const MainTabContainer({
    super.key,
    this.userRole = 'op',
    this.initialIndex = 0,
    this.initialCargoIndex = 0,
  });

  @override
  State<MainTabContainer> createState() => _MainTabContainerState();
}

class _MainTabContainerState extends State<MainTabContainer> {
  late int _currentIndex;
  late int _selectedCargoIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _selectedCargoIndex = widget.initialCargoIndex;
  }

  void _onOpenCargoIn3D(int cargoIndex) {
    setState(() {
      _selectedCargoIndex = cargoIndex;
      _currentIndex = 0; // Alterna para a visualização do Gêmeo 3D
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        userRole: widget.userRole,
        selectedCargoIndex: _selectedCargoIndex,
        onCargoChanged: (idx) => setState(() => _selectedCargoIndex = idx),
        onGoToAdmin: () => setState(() => _currentIndex = 3),
      ),
      const TimelineScreen(),
      const QrScannerScreen(),
      widget.userRole == 'admin'
          ? AdminPanelScreen(
              onOpenCargoIn3D: _onOpenCargoIn3D,
            )
          : const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.obsidianPitch,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xF20B0E14),
          border: Border(top: BorderSide(color: AppColors.borderSlate)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.cyberCyan,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'Gêmeo 3D',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.access_time),
              label: 'Auditoria',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'QR Code',
            ),
            BottomNavigationBarItem(
              icon: Icon(widget.userRole == 'admin'
                  ? Icons.admin_panel_settings
                  : Icons.person_outline),
              label: widget.userRole == 'admin' ? 'Painel Admin' : 'Meu Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final String userRole;
  final int selectedCargoIndex;
  final ValueChanged<int>? onCargoChanged;
  final VoidCallback? onGoToAdmin;

  const DashboardScreen({
    super.key,
    this.userRole = 'op',
    this.selectedCargoIndex = 0,
    this.onCargoChanged,
    this.onGoToAdmin,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Lista de todas as cargas da frota TransCargo Express
  List<CargoBox> get _cargos => CargoFleetRepository.fleet;

  late int _selectedCargoIndex;

  // Telemetry State
  late double score;
  late double impactG;
  late int lux;
  late double temp;
  late int humidity;
  late double roll;
  late double pitch;

  bool isImpactAlert = false;
  bool isLdrViolated = false;
  bool isTempAlert = false;

  @override
  void initState() {
    super.initState();
    _selectedCargoIndex = (widget.selectedCargoIndex < _cargos.length)
        ? widget.selectedCargoIndex
        : 0;
    _loadCargoData(_selectedCargoIndex);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCargoIndex != widget.selectedCargoIndex) {
      if (widget.selectedCargoIndex >= 0 &&
          widget.selectedCargoIndex < _cargos.length) {
        _loadCargoData(widget.selectedCargoIndex);
      }
    }
  }

  void _loadCargoData(int index) {
    final cargo = _cargos[index];
    setState(() {
      _selectedCargoIndex = index;
      score = cargo.score;
      impactG = cargo.impactG;
      lux = cargo.lux;
      temp = cargo.temp;
      humidity = cargo.humidity;
      roll = cargo.roll;
      pitch = cargo.pitch;
      isImpactAlert = impactG > 1.0;
      isLdrViolated = lux > 1;
      isTempAlert = temp > 28.0;
    });
  }

  void _openCargoSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Color(0xF70E141E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: AppColors.borderSlate)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Pill Indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.borderSlate,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.swap_horizontal_circle_outlined,
                          color: AppColors.cyberCyan, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'SELECIONAR CARGA ATIVA',
                        style: TextStyle(
                          color: AppColors.textDisplay,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Escolha o volume em trânsito para monitorar a telemetria e o Gêmeo 3D:',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _cargos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cargo = _cargos[index];
                    final isSelected = index == _selectedCargoIndex;
                    return InkWell(
                      onTap: () {
                        _loadCargoData(index);
                        widget.onCargoChanged?.call(index);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.cyberCyan.withValues(alpha: 0.12)
                              : AppColors.charcoalGlass,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.cyberCyan
                                : AppColors.borderSlate,
                            width: isSelected ? 1.2 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.cyberCyan.withValues(alpha: 0.2)
                                    : AppColors.obsidianPitch,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.cyberCyan
                                      : AppColors.borderSlate,
                                ),
                              ),
                              child: Icon(
                                isSelected
                                    ? Icons.check_rounded
                                    : Icons.inventory_2_outlined,
                                color: isSelected
                                    ? AppColors.cyberCyan
                                    : AppColors.textMuted,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${cargo.code} • ${cargo.title}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.cyberCyan
                                          : AppColors.textDisplay,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${cargo.origin} → ${cargo.dest}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: cargo.isAlert
                                    ? AppColors.tagOrangeBg
                                    : AppColors.tagGreenBg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: cargo.isAlert
                                        ? AppColors.kinetixOrange.withValues(alpha: 0.4)
                                        : AppColors.electricLime.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${cargo.score.toInt()}%',
                                style: TextStyle(
                                  color: cargo.isAlert
                                      ? AppColors.kinetixOrange
                                      : AppColors.electricLime,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _logout() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final currentCargo = _cargos[_selectedCargoIndex];

    return SafeArea(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              // Header Superior
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xF20B0E14),
                  border:
                      Border(bottom: BorderSide(color: AppColors.borderSlate)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Image.asset(
                            'Imagens/logo sem fundo.webp',
                            height: 38,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KINETIX',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textDisplay,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'TransCargo Express • Telemetria IIoT',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      children: [
                        if (widget.userRole == 'admin' && widget.onGoToAdmin != null)
                          InkWell(
                            onTap: widget.onGoToAdmin,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.tagCyanBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.cyberCyan
                                        .withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.admin_panel_settings_outlined,
                                      color: AppColors.cyberCyan, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: AppColors.cyberCyan,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.tagCyanBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.cyberCyan.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            currentCargo.nodeId,
                            style: const TextStyle(
                              color: AppColors.cyberCyan,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _logout,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.tagOrangeBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.kinetixOrange
                                      .withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.logout,
                                    color: AppColors.kinetixOrange, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Sair',
                                  style: TextStyle(
                                    color: AppColors.kinetixOrange,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Slogan Banner suave
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppColors.charcoalGlass,
                child: const Text(
                  '"Do escuro do transporte ao Gêmeo Digital na sua tela."',
                  style: TextStyle(
                    color: AppColors.textSection,
                    fontSize: 9.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // Scrollable Dashboard Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    // Route Info Card com botão de troca de carga
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.charcoalGlass,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSlate),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentCargo.code,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textDisplay,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${currentCargo.title} • ${currentCargo.category}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.cyberCyan,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _openCargoSelector,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.cyberCyan
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppColors.cyberCyan
                                            .withValues(alpha: 0.6)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.swap_horiz,
                                          color: AppColors.cyberCyan, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'TROCAR CARGA',
                                        style: TextStyle(
                                          color: AppColors.cyberCyan,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Origem: ${currentCargo.origin}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textSection,
                                      fontSize: 10.5),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('→',
                                    style: TextStyle(
                                        color: AppColors.cyberCyan,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: Text(
                                  'Destino: ${currentCargo.dest}',
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textSection,
                                      fontSize: 10.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3D Canvas Viewport (Gêmeo Digital)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0E14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isImpactAlert || isLdrViolated)
                              ? AppColors.kinetixOrange.withValues(alpha: 0.7)
                              : AppColors.borderSlate,
                        ),
                        boxShadow: (isImpactAlert || isLdrViolated)
                            ? [
                                BoxShadow(
                                  color: AppColors.kinetixOrange
                                      .withValues(alpha: 0.2),
                                  blurRadius: 12,
                                )
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          build3DGlbViewer(),
                          Positioned(
                            top: 8,
                            left: 10,
                            right: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xE60B0E14),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: AppColors.cyberCyan
                                            .withValues(alpha: 0.25)),
                                  ),
                                  child: Text(
                                    'R: ${roll.toStringAsFixed(1)}° | P: ${pitch.toStringAsFixed(1)}°',
                                    style: const TextStyle(
                                      color: AppColors.cyberCyan,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isImpactAlert
                                        ? AppColors.tagOrangeBg
                                        : AppColors.tagGreenBg,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isImpactAlert
                                          ? AppColors.kinetixOrange
                                          : AppColors.electricLime,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.view_in_ar,
                                        color: isImpactAlert
                                            ? AppColors.kinetixOrange
                                            : AppColors.electricLime,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isImpactAlert
                                            ? 'Impacto Detectado'
                                            : 'GLB: bio_crate.glb • Sincronizado',
                                        style: TextStyle(
                                          color: isImpactAlert
                                              ? AppColors.kinetixOrange
                                              : AppColors.electricLime,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Score Card Gauge
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.charcoalGlass,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSlate),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 62,
                                height: 62,
                                child: CircularProgressIndicator(
                                  value: score / 100,
                                  strokeWidth: 5.5,
                                  backgroundColor: AppColors.borderSlate,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    score > 80
                                        ? AppColors.electricLime
                                        : (score > 50
                                            ? AppColors.telemetryAmber
                                            : AppColors.kinetixOrange),
                                  ),
                                ),
                              ),
                              Text(
                                '${score.toInt()}',
                                style: const TextStyle(
                                  color: AppColors.textDisplay,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Score ${score.toInt()}% • ${score > 80 ? 'Carga Intacta' : 'Alerta Registrado'}',
                                  style: const TextStyle(
                                    color: AppColors.textDisplay,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Algoritmo Kinetix: Monitoramento contínuo de aceleração, temperatura e luz.',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10.5,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Metrics Grid (MPU6050 & LDR)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.charcoalGlass,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isImpactAlert
                                    ? AppColors.kinetixOrange
                                    : AppColors.borderSlate,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MPU6050',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${impactG.toStringAsFixed(2)} G',
                                  style: const TextStyle(
                                      color: AppColors.cyberCyan,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text('Impacto Espacial (g)',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.charcoalGlass,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isLdrViolated
                                    ? AppColors.kinetixOrange
                                    : AppColors.borderSlate,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LDR LACRE',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$lux LUX',
                                  style: TextStyle(
                                      color: isLdrViolated
                                          ? AppColors.kinetixOrange
                                          : AppColors.electricLime,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text('Infiltração de Luz',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // DHT22 Full Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.charcoalGlass,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTempAlert
                              ? AppColors.telemetryAmber
                              : AppColors.borderSlate,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DHT22 • AMBIÊNCIA',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${temp.toStringAsFixed(1)} °C / $humidity% UR',
                                style: const TextStyle(
                                    color: AppColors.cyberCyan,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Text('Max: 30.0°C',
                                  style: TextStyle(
                                      color: AppColors.textMuted, fontSize: 9.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3D Cube Painter for Gêmeo Digital
class Cube3DPainter extends CustomPainter {
  final double rotationY;
  final double roll;
  final double pitch;
  final bool isAlert;

  Cube3DPainter({
    required this.rotationY,
    required this.roll,
    required this.pitch,
    required this.isAlert,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const scale = 45.0;

    final vertices = [
      [-1.0, -1.0, -1.0],
      [1.0, -1.0, -1.0],
      [1.0, 1.0, -1.0],
      [-1.0, 1.0, -1.0],
      [-1.0, -1.0, 1.0],
      [1.0, -1.0, 1.0],
      [1.0, 1.0, 1.0],
      [-1.0, 1.0, 1.0]
    ];

    final edges = [
      [0, 1], [1, 2], [2, 3], [3, 0],
      [4, 5], [5, 6], [6, 7], [7, 4],
      [0, 4], [1, 5], [2, 6], [3, 7]
    ];

    final radX = 0.3 + (pitch * math.pi / 180);
    final radY = rotationY + (roll * math.pi / 180);

    final projected = vertices.map((v) {
      final x = v[0] * math.cos(radY) + v[2] * math.sin(radY);
      final y = v[1];
      final z = -v[0] * math.sin(radY) + v[2] * math.cos(radY);

      final y2 = y * math.cos(radX) - z * math.sin(radX);
      final z2 = y * math.sin(radX) + z * math.cos(radX);

      final pz = 1 / (4 - z2);
      final px = x * pz * scale * 3.5 + center.dx;
      final py = y2 * pz * scale * 3.5 + center.dy;

      return Offset(px, py);
    }).toList();

    final linePaint = Paint()
      ..color = isAlert ? AppColors.kinetixOrange : AppColors.cyberCyan
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = isAlert ? AppColors.kinetixOrange : AppColors.electricLime
      ..style = PaintingStyle.fill;

    for (final edge in edges) {
      canvas.drawLine(projected[edge[0]], projected[edge[1]], linePaint);
    }

    for (final p in projected) {
      canvas.drawCircle(p, 4.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant Cube3DPainter oldDelegate) => true;
}
