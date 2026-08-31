import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'admin_panel_screen.dart';
import 'profile_screen.dart';
import 'qr_scanner_screen.dart';
import 'timeline_screen.dart';

class MainTabContainer extends StatefulWidget {
  final String userRole;
  const MainTabContainer({super.key, this.userRole = 'op'});

  @override
  State<MainTabContainer> createState() => _MainTabContainerState();
}

class _MainTabContainerState extends State<MainTabContainer> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(userRole: widget.userRole),
      const TimelineScreen(),
      const QrScannerScreen(),
      widget.userRole == 'admin'
          ? const AdminPanelScreen()
          : const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianPitch,
      body: _screens[_currentIndex],
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
  const DashboardScreen({super.key, this.userRole = 'op'});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Lista de Cargas Ativas da TransCargo Express
  final List<Map<String, dynamic>> _cargos = [
    {
      'code': 'Carga #TC-8902-SJC',
      'title': 'Vacinas Termossensíveis',
      'origin': 'SJC Logística',
      'dest': 'Caçapava-SP',
      'status': 'Em Trânsito',
      'nodeId': 'Kinetix Node #01',
      'score': 100.0,
      'impactG': 0.12,
      'lux': 0,
      'temp': 22.4,
      'humidity': 54,
      'roll': 1.2,
      'pitch': 0.5,
    },
    {
      'code': 'Carga #TC-4410-SP',
      'title': 'Componentes Eletrônicos',
      'origin': 'Terminal Guarulhos',
      'dest': 'São José dos Campos-SP',
      'status': 'Em Trânsito',
      'nodeId': 'Kinetix Node #02',
      'score': 94.0,
      'impactG': 0.38,
      'lux': 0,
      'temp': 19.8,
      'humidity': 46,
      'roll': -0.5,
      'pitch': 0.8,
    },
    {
      'code': 'Carga #TC-1092-RJ',
      'title': 'Equipamentos Ópticos',
      'origin': 'Porto de Santos',
      'dest': 'Resende-RJ',
      'status': 'Em Trânsito',
      'nodeId': 'Kinetix Node #03',
      'score': 88.0,
      'impactG': 0.72,
      'lux': 2,
      'temp': 24.5,
      'humidity': 58,
      'roll': 2.1,
      'pitch': -1.4,
    },
  ];

  int _selectedCargoIndex = 0;

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
    _loadCargoData(_selectedCargoIndex);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  void _loadCargoData(int index) {
    final cargo = _cargos[index];
    setState(() {
      _selectedCargoIndex = index;
      score = (cargo['score'] as num).toDouble();
      impactG = (cargo['impactG'] as num).toDouble();
      lux = cargo['lux'] as int;
      temp = (cargo['temp'] as num).toDouble();
      humidity = cargo['humidity'] as int;
      roll = (cargo['roll'] as num).toDouble();
      pitch = (cargo['pitch'] as num).toDouble();
      isImpactAlert = false;
      isLdrViolated = false;
      isTempAlert = false;
    });
  }

  void _openCargoSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xF70D121B),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.cyberCyan.withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyberCyan.withValues(alpha: 0.15),
                blurRadius: 25,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Pill Indicator
              Center(
                child: Container(
                  width: 38,
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
                          color: AppColors.cyberCyan, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'SELECIONAR CARGA ATIVA',
                        style: TextStyle(
                          color: AppColors.textDisplay,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Escolha o volume em trânsito para monitorar a telemetria e o Gêmeo 3D:',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 14),
              ListView.separated(
                shrinkWrap: true,
                itemCount: _cargos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final cargo = _cargos[index];
                  final isSelected = index == _selectedCargoIndex;
                  return InkWell(
                    onTap: () {
                      _loadCargoData(index);
                      Navigator.of(ctx).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.cyberCyan.withValues(alpha: 0.12)
                            : AppColors.charcoalGlass,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.cyberCyan
                              : AppColors.borderSlate,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
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
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${cargo['code']} • ${cargo['title']}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.cyberCyan
                                        : AppColors.textDisplay,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${cargo['origin']} → ${cargo['dest']}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.electricLime.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.electricLime.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${(cargo['score'] as num).toInt()}% Score',
                              style: const TextStyle(
                                color: AppColors.electricLime,
                                fontSize: 10,
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
              const SizedBox(height: 12),
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
              // Header
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
                    Row(
                      children: [
                        Image.asset(
                          'Imagens/logo sem fundo.webp',
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'KINETIX',
                              style: TextStyle(
                                color: AppColors.textDisplay,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'TransCargo Express • IIoT',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.cyberCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.cyberCyan.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            currentCargo['nodeId'] as String,
                            style: const TextStyle(
                              color: AppColors.cyberCyan,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _logout,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.kinetixOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.kinetixOrange.withValues(alpha: 0.4)),
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
                                    fontSize: 10,
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

              // Slogan Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppColors.charcoalGlass,
                child: const Text(
                  '"Do escuro do transporte ao Gêmeo Digital na sua tela."',
                  style: TextStyle(
                    color: AppColors.cyberCyan,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // Scrollable Dashboard Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    // Route Info Card with Cargo Switcher
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.charcoalGlass,
                        borderRadius: BorderRadius.circular(14),
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
                                      currentCargo['code'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textDisplay,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      currentCargo['title'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.cyberCyan,
                                        fontSize: 10,
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
                                    color: AppColors.cyberCyan.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppColors.cyberCyan),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.swap_horiz,
                                          color: AppColors.cyberCyan,
                                          size: 14),
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
                                  'Origem: ${currentCargo['origin']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textSection,
                                      fontSize: 11),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('→',
                                    style: TextStyle(
                                        color: AppColors.cyberCyan,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: Text(
                                  'Destino: ${currentCargo['dest']}',
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textSection,
                                      fontSize: 11),
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
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (isImpactAlert || isLdrViolated)
                              ? AppColors.kinetixOrange
                              : AppColors.borderSlate,
                        ),
                        boxShadow: (isImpactAlert || isLdrViolated)
                            ? [
                                BoxShadow(
                                  color: AppColors.kinetixOrange.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                )
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: const Size(double.infinity, 200),
                                painter: Cube3DPainter(
                                  rotationY:
                                      _animController.value * 2 * math.pi,
                                  roll: roll,
                                  pitch: pitch,
                                  isAlert: isImpactAlert || isLdrViolated,
                                ),
                              );
                            },
                          ),
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
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isImpactAlert
                                        ? AppColors.kinetixOrange.withValues(alpha: 0.15)
                                        : AppColors.electricLime.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isImpactAlert
                                          ? AppColors.kinetixOrange
                                          : AppColors.electricLime,
                                    ),
                                  ),
                                  child: Text(
                                    isImpactAlert
                                        ? 'Impacto Detectado'
                                        : 'Gêmeo Sincronizado',
                                    style: TextStyle(
                                      color: isImpactAlert
                                          ? AppColors.kinetixOrange
                                          : AppColors.electricLime,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSlate),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: CircularProgressIndicator(
                                  value: score / 100,
                                  strokeWidth: 6,
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
                                  fontSize: 18,
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Algoritmo Kinetix: Monitoramento contínuo de aceleração, temperatura e luz.',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
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
                              borderRadius: BorderRadius.circular(14),
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
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${impactG.toStringAsFixed(2)} G',
                                  style: const TextStyle(
                                      color: AppColors.cyberCyan,
                                      fontSize: 20,
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
                              borderRadius: BorderRadius.circular(14),
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
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$lux LUX',
                                  style: TextStyle(
                                      color: isLdrViolated
                                          ? AppColors.kinetixOrange
                                          : AppColors.electricLime,
                                      fontSize: 20,
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
                        borderRadius: BorderRadius.circular(14),
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
                                fontSize: 10,
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Text('Max: 30.0°C',
                                  style: TextStyle(
                                      color: AppColors.textMuted, fontSize: 10)),
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
