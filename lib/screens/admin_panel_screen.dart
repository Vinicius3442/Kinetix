import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/cargo_box.dart';
import '../theme/app_colors.dart';
import '../widgets/sweet_alert.dart';

class AdminPanelScreen extends StatefulWidget {
  final void Function(int cargoIndex)? onOpenCargoIn3D;
  const AdminPanelScreen({super.key, this.onOpenCargoIn3D});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  // 0: Dashboard & Indicadores, 1: Monitorar Todas as Caixas, 2: Relatórios, 3: Sistema IIoT
  int _activeTab = 0;

  // Filtro de Caixas
  String _selectedBoxFilter = 'Todas';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filtro de Relatório
  String _selectedReportPeriod = 'Hoje';

  // Sub-aba do Sistema IIoT (0: Usuários, 1: Pareamento Sensores, 2: Parâmetros)
  int _systemSubTab = 0;

  final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'name': 'Carlos Silva',
      'email': 'operador@transcargo.com.br',
      'code': 'TC-8902',
      'role': 'Operador',
      'isActive': true,
    },
    {
      'id': 2,
      'name': 'Ana Souza',
      'email': 'ana.souza@transcargo.com.br',
      'code': 'TC-4410',
      'role': 'Fiscal de Pátio',
      'isActive': true,
    },
    {
      'id': 3,
      'name': 'Roberto Lima',
      'email': 'roberto.lima@transcargo.com.br',
      'code': 'TC-1092',
      'role': 'Motorista',
      'isActive': true,
    },
    {
      'id': 4,
      'name': 'Admin TransCargo',
      'email': 'admin@transcargo.com.br',
      'code': 'TC-0001',
      'role': 'Gestor Admin',
      'isActive': true,
      'isMaster': true,
    },
  ];

  final _sensorIdController = TextEditingController(text: 'ESP32-TK89-SJC');
  final _sensorMacController = TextEditingController(text: '24:0A:C4:9E:81:B0');
  final _sensorTopicController =
      TextEditingController(text: 'kinetix/cargo/tc8902/telemetry');

  final _paramGController = TextEditingController(text: '1.5 G');
  final _paramTempController = TextEditingController(text: '30.0 °C');
  final _paramLuxController = TextEditingController(text: '10 LUX');

  @override
  void dispose() {
    _searchController.dispose();
    _sensorIdController.dispose();
    _sensorMacController.dispose();
    _sensorTopicController.dispose();
    _paramGController.dispose();
    _paramTempController.dispose();
    _paramLuxController.dispose();
    super.dispose();
  }

  void _toggleUserStatus(int index) {
    setState(() {
      _users[index]['isActive'] = !_users[index]['isActive'];
    });

    final user = _users[index];
    final isActive = user['isActive'] as bool;
    final name = user['name'] as String;

    showKinetixSweetAlert(
      context,
      title: isActive ? 'Perfil Reativado!' : 'Perfil Desativado!',
      message: isActive
          ? 'O acesso do usuário $name foi restabelecido.'
          : 'O acesso do usuário $name foi suspenso com sucesso.',
      type: isActive ? SweetAlertType.success : SweetAlertType.alert,
    );
  }

  void _changeRole(int index, String? newRole) {
    if (newRole == null) return;
    setState(() {
      _users[index]['role'] = newRole;
    });

    final name = _users[index]['name'] as String;
    showKinetixSweetAlert(
      context,
      title: 'Função Atualizada!',
      message: 'As permissões do usuário $name foram alteradas para: $newRole.',
      type: SweetAlertType.success,
    );
  }

  void _saveSensorPairing() {
    final devId = _sensorIdController.text;
    showKinetixSweetAlert(
      context,
      title: 'Dispositivo Pareado!',
      message:
          'Sensor Embarcado $devId cadastrado e sincronizado via MQTT com a API Kinetix.',
      type: SweetAlertType.success,
    );
  }

  void _saveParams() {
    showKinetixSweetAlert(
      context,
      title: 'Parâmetros Atualizados!',
      message:
          'Os limites operacionais de alerta IIoT foram atualizados com sucesso.',
      type: SweetAlertType.success,
    );
  }

  // Filtragem da lista de caixas
  List<CargoBox> get _filteredBoxes {
    return CargoFleetRepository.fleet.where((box) {
      // Filtro de status
      if (_selectedBoxFilter == 'Em Risco' &&
          !box.isAlert &&
          box.status != 'Alerta' &&
          box.status != 'Atenção') {
        return false;
      }
      if (_selectedBoxFilter == 'Em Trânsito' && box.status != 'Em Trânsito') {
        return false;
      }
      if (_selectedBoxFilter == 'Pátio/Entregue' &&
          box.status != 'No Pátio' &&
          box.status != 'Entregue') {
        return false;
      }

      // Filtro de busca
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCode = box.code.toLowerCase().contains(q);
        final matchTitle = box.title.toLowerCase().contains(q);
        final matchDest = box.dest.toLowerCase().contains(q);
        final matchOrigin = box.origin.toLowerCase().contains(q);
        final matchCategory = box.category.toLowerCase().contains(q);
        return matchCode || matchTitle || matchDest || matchOrigin || matchCategory;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              // Header Administrativo
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
                                  'KINETIX ADMIN',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textDisplay,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Gestão Integrada de Cargas',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 8.5,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onOpenCargoIn3D != null)
                          InkWell(
                            onTap: () => widget.onOpenCargoIn3D!(0),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: AppColors.cyberCyan.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.cyberCyan
                                        .withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.view_in_ar,
                                      color: AppColors.cyberCyan, size: 11),
                                  SizedBox(width: 3),
                                  Text(
                                    'Gêmeo 3D',
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
                              horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.tagOrangeBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.kinetixOrange
                                    .withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Gestor Master',
                            style: TextStyle(
                              color: AppColors.kinetixOrange,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Barra de Navegação das 4 Seções Administrativas
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.charcoalGlass,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSlate),
                  ),
                  child: Row(
                    children: [
                      _buildTopNavBtn('Dashboard', Icons.dashboard_outlined, 0),
                      _buildTopNavBtn('Todas as Caixas', Icons.inventory_2_outlined, 1),
                      _buildTopNavBtn('Relatórios', Icons.assessment_outlined, 2),
                      _buildTopNavBtn('Sistema IIoT', Icons.settings_outlined, 3),
                    ],
                  ),
                ),
              ),

              // Conteúdo da Aba Selecionada
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  children: [
                    if (_activeTab == 0) _buildDashboardAndIndicatorsTab(),
                    if (_activeTab == 1) _buildMonitorAllBoxesTab(),
                    if (_activeTab == 2) _buildReportsTab(),
                    if (_activeTab == 3) _buildSystemAndParamsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavBtn(String label, IconData icon, int index) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.cyberCyan.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? AppColors.cyberCyan.withValues(alpha: 0.7)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive ? AppColors.cyberCyan : AppColors.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? AppColors.textDisplay : AppColors.textMuted,
                  fontSize: 9.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // ABA 0: DASHBOARD & INDICADORES GLOBAIS
  // =========================================================================
  Widget _buildDashboardAndIndicatorsTab() {
    final fleet = CargoFleetRepository.fleet;
    final total = fleet.length;
    final inTransit = fleet.where((b) => b.status == 'Em Trânsito').length;
    final inAlert = fleet.where((b) => b.isAlert || b.status == 'Alerta' || b.status == 'Atenção').length;
    final deliveredOrYard = fleet.where((b) => b.status == 'Entregue' || b.status == 'No Pátio').length;
    final avgScore = fleet.map((b) => b.score).reduce((a, b) => a + b) / total;
    final avgTemp = fleet.map((b) => b.temp).reduce((a, b) => a + b) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner de Status da Operação IIoT
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.charcoalGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.electricLime.withValues(alpha: 0.12),
                  border: Border.all(
                      color: AppColors.electricLime.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.sensors,
                    color: AppColors.electricLime, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rede de Telemetria IIoT Online',
                      style: TextStyle(
                        color: AppColors.textDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Broker MQTT: kinetix.broker.transcargo:1883 • 8 Nós Sincronizados',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tagGreenBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.electricLime.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '100% ATIVA',
                  style: TextStyle(
                    color: AppColors.electricLime,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Grid de Indicadores Principais (KPIs da Frota)
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'TOTAL CAIXAS',
                value: '$total',
                subtitle: '8 rastreadores ativos',
                icon: Icons.inventory_2_outlined,
                accentColor: AppColors.cyberCyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'SCORE MÉDIO',
                value: '${avgScore.toStringAsFixed(1)}%',
                subtitle: 'Alta conformidade',
                icon: Icons.verified_outlined,
                accentColor: AppColors.electricLime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'EM TRÂNSITO',
                value: '$inTransit',
                subtitle: 'Malha rodoviária ativa',
                icon: Icons.local_shipping_outlined,
                accentColor: AppColors.cyberCyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'ALERTAS / RISCO',
                value: '$inAlert',
                subtitle: inAlert > 0 ? '1 Impacto + 1 Lacre' : 'Nenhuma anomalia',
                icon: Icons.warning_amber_rounded,
                accentColor: inAlert > 0 ? AppColors.kinetixOrange : AppColors.electricLime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'MÉDIA TÉRMICA',
                value: '${avgTemp.toStringAsFixed(1)} °C',
                subtitle: 'Cadeia de frio estável',
                icon: Icons.thermostat_outlined,
                accentColor: AppColors.cyberCyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'PÁTIO / ENTREGUE',
                value: '$deliveredOrYard',
                subtitle: '1 Entregue • 1 No Pátio',
                icon: Icons.task_alt_outlined,
                accentColor: AppColors.textSection,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Distribuição da Frota (Barra Visual Segmentada)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.charcoalGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Distribuição da Frota',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tempo Real',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (inTransit * 100 ~/ total),
                        child: Container(color: AppColors.cyberCyan),
                      ),
                      Expanded(
                        flex: (inAlert * 100 ~/ total),
                        child: Container(color: AppColors.kinetixOrange),
                      ),
                      Expanded(
                        flex: (deliveredOrYard * 100 ~/ total),
                        child: Container(color: AppColors.electricLime),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _buildLegendItem('Em Rota', inTransit, AppColors.cyberCyan),
                  _buildLegendItem('Alertas', inAlert, AppColors.kinetixOrange),
                  _buildLegendItem('Pátio/Final', deliveredOrYard, AppColors.electricLime),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Painel de Alertas Recentes Críticos
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.charcoalGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Ocorrências e Alertas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() {
                      _activeTab = 1;
                      _selectedBoxFilter = 'Em Risco';
                    }),
                    child: const Text(
                      'Filtrar Caixas →',
                      style: TextStyle(
                        color: AppColors.cyberCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildAlertFeedItem(
                boxCode: 'TC-3312-PR',
                title: 'Impacto de 1.45G Detectado',
                location: 'Rod. Pres. Dutra km 134 - Taubaté-SP',
                time: 'Há 3 min',
                typeColor: AppColors.kinetixOrange,
                icon: Icons.vibration,
                onTap: () => _openBoxDetailModal(fleet.firstWhere((b) => b.code == 'TC-3312-PR')),
              ),
              const SizedBox(height: 8),
              _buildAlertFeedItem(
                boxCode: 'TC-1092-RJ',
                title: 'Infiltração de Luz 2 LUX (Lacre)',
                location: 'Posto Resende-RJ • LDR Violated',
                time: 'Há 12 min',
                typeColor: AppColors.telemetryAmber,
                icon: Icons.lock_open,
                onTap: () => _openBoxDetailModal(fleet.firstWhere((b) => b.code == 'TC-1092-RJ')),
              ),
              const SizedBox(height: 8),
              _buildAlertFeedItem(
                boxCode: 'TC-8902-SJC',
                title: 'Cadeia de Frio Mantida em 22.4°C',
                location: 'SJC Logística • Checkpoint Validado',
                time: 'Há 25 min',
                typeColor: AppColors.electricLime,
                icon: Icons.check_circle_outline,
                onTap: () => _openBoxDetailModal(fleet.firstWhere((b) => b.code == 'TC-8902-SJC')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Atalhos de Ação Rápida
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyberCyan.withValues(alpha: 0.14),
                  foregroundColor: AppColors.cyberCyan,
                  side: const BorderSide(color: AppColors.cyberCyan, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => setState(() => _activeTab = 1),
                icon: const Icon(Icons.manage_search, size: 16),
                label: const Text('Ver Todas as Caixas',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kinetixOrange.withValues(alpha: 0.14),
                  foregroundColor: AppColors.kinetixOrange,
                  side: const BorderSide(color: AppColors.kinetixOrange, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => setState(() => _activeTab = 2),
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('Acessar Relatórios',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.charcoalGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 15, color: accentColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: $count',
          style: const TextStyle(
            color: AppColors.textSection,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertFeedItem({
    required String boxCode,
    required String title,
    required String location,
    required String time,
    required Color typeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSlate),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: typeColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          boxCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // ABA 1: MONITORAR TODAS AS CAIXAS (SMART CRATES)
  // =========================================================================
  Widget _buildMonitorAllBoxesTab() {
    final boxes = _filteredBoxes;
    final totalFleet = CargoFleetRepository.fleet.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra de Pesquisa de Caixas
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.charcoalGlass,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textMuted, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: AppColors.textDisplay, fontSize: 11.5),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por código, carga, destino ou tipo...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Filtros Rápidos em Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Todas ($totalFleet)', 'Todas'),
              const SizedBox(width: 6),
              _buildFilterChip('Em Risco (2)', 'Em Risco', isAlert: true),
              const SizedBox(width: 6),
              _buildFilterChip('Em Trânsito (5)', 'Em Trânsito'),
              const SizedBox(width: 6),
              _buildFilterChip('Pátio/Entregue (2)', 'Pátio/Entregue'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Contagem de Caixas Filtradas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${boxes.length} Caixas Monitoradas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Sincronização Contínua IIoT',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Lista das Caixas Monitoradas
        if (boxes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.charcoalGlass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSlate),
            ),
            child: const Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: AppColors.textMuted, size: 36),
                SizedBox(height: 8),
                Text(
                  'Nenhuma caixa encontrada para este filtro.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: boxes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final box = boxes[index];
              return _buildBoxCard(box, index);
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String filterKey, {bool isAlert = false}) {
    final isSelected = _selectedBoxFilter == filterKey;
    final activeColor = isAlert ? AppColors.kinetixOrange : AppColors.cyberCyan;

    return InkWell(
      onTap: () => setState(() => _selectedBoxFilter = filterKey),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.16)
              : AppColors.charcoalGlass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.borderSlate,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : AppColors.textMuted,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBoxCard(CargoBox box, int index) {
    Color statusColor = AppColors.electricLime;
    String statusLabel = 'NORMAL';
    if (box.status == 'Alerta' || box.isCritical) {
      statusColor = AppColors.kinetixOrange;
      statusLabel = 'ALERTA';
    } else if (box.status == 'Atenção' || box.isAlert) {
      statusColor = AppColors.telemetryAmber;
      statusLabel = 'ATENÇÃO';
    } else if (box.status == 'No Pátio') {
      statusColor = AppColors.textSection;
      statusLabel = 'NO PÁTIO';
    } else if (box.status == 'Entregue') {
      statusColor = AppColors.cyberCyan;
      statusLabel = 'ENTREGUE';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.charcoalGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (box.isAlert || box.status == 'Alerta')
              ? statusColor.withValues(alpha: 0.5)
              : AppColors.borderSlate,
          width: (box.isAlert || box.status == 'Alerta') ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.inventory_2_outlined,
                          color: statusColor, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            box.code,
                            style: const TextStyle(
                              color: AppColors.textDisplay,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${box.title} • ${box.category}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rota e Motorista
          Row(
            children: [
              const Icon(Icons.route, color: AppColors.textMuted, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${box.origin} → ${box.dest}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSection,
                    fontSize: 10,
                  ),
                ),
              ),
              Text(
                'Nó: ${box.nodeId}',
                style: const TextStyle(
                  color: AppColors.cyberCyan,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Grid de Métricas da Caixa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0E14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSlate),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBoxMetricItem('Temp', '${box.temp}°C',
                    box.temp > 28 ? AppColors.kinetixOrange : AppColors.cyberCyan),
                _buildDivider(),
                _buildBoxMetricItem('Impacto', '${box.impactG}G',
                    box.impactG > 1.0 ? AppColors.kinetixOrange : AppColors.textDisplay),
                _buildDivider(),
                _buildBoxMetricItem('Lacre LDR', '${box.lux} LUX',
                    box.lux > 1 ? AppColors.kinetixOrange : AppColors.electricLime),
                _buildDivider(),
                _buildBoxMetricItem('Bateria', '${box.battery}%',
                    box.battery < 20 ? AppColors.kinetixOrange : AppColors.electricLime),
                _buildDivider(),
                _buildBoxMetricItem('Score', '${box.score.toInt()}%',
                    box.score > 85 ? AppColors.electricLime : AppColors.kinetixOrange),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Rodapé com Última Atualização e Botões de Ação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: AppColors.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        box.lastUpdate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onOpenCargoIn3D != null)
                    InkWell(
                      onTap: () {
                        // Achar o índice da frota
                        final fleetIndex = CargoFleetRepository.fleet
                            .indexWhere((b) => b.code == box.code);
                        widget.onOpenCargoIn3D!(fleetIndex >= 0 ? fleetIndex : 0);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3.5),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cyberCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.cyberCyan.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.view_in_ar,
                                color: AppColors.cyberCyan, size: 11),
                            SizedBox(width: 3),
                            Text(
                              'Gêmeo 3D',
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardSurfaceElevated,
                      foregroundColor: AppColors.textDisplay,
                      side: const BorderSide(color: AppColors.borderSlate),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => _openBoxDetailModal(box),
                    child: const Text('Inspecionar',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoxMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 8),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 18,
      color: AppColors.borderSlate,
    );
  }

  // Modal com detalhes profundos da caixa
  void _openBoxDetailModal(CargoBox box) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xF70E141E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: AppColors.borderSlate)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.borderSlate,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        box.code,
                        style: const TextStyle(
                          color: AppColors.textDisplay,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        box.title,
                        style: const TextStyle(
                          color: AppColors.cyberCyan,
                          fontSize: 11,
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
              const SizedBox(height: 12),

              // Rota & Motorista
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.charcoalGlass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSlate),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Origem / Partida', box.origin),
                    _buildDetailRow('Destino Final', box.dest),
                    _buildDetailRow('Motorista Responsável', box.driver),
                    _buildDetailRow('Placa do Veículo', box.vehiclePlate),
                    _buildDetailRow('Dispositivo Embarcado', box.nodeId),
                    _buildDetailRow('Última Sincronização', box.lastUpdate),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Telemetria Detalhada
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.charcoalGlass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSlate),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sensores Embarcados (MPU6050, DHT22, LDR)',
                      style: TextStyle(
                        color: AppColors.textDisplay,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Aceleração Resultante', '${box.impactG} G'),
                    _buildDetailRow('Infiltração de Luz (Lacre)', '${box.lux} LUX (${box.lux <= 1 ? 'Lacre Íntegro' : 'Violação'})'),
                    _buildDetailRow('Temperatura Interna', '${box.temp} °C'),
                    _buildDetailRow('Umidade Relativa', '${box.humidity}% UR'),
                    _buildDetailRow('Inclinação Espacial (Roll/Pitch)', 'R: ${box.roll}° | P: ${box.pitch}°'),
                    _buildDetailRow('Nível de Bateria do Nó', '${box.battery}%'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botões de Ação
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyberCyan.withValues(alpha: 0.15),
                        foregroundColor: AppColors.cyberCyan,
                        side: const BorderSide(color: AppColors.cyberCyan),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (widget.onOpenCargoIn3D != null) {
                          final idx = CargoFleetRepository.fleet
                              .indexWhere((b) => b.code == box.code);
                          widget.onOpenCargoIn3D!(idx >= 0 ? idx : 0);
                        }
                      },
                      icon: const Icon(Icons.view_in_ar, size: 16),
                      label: const Text('Abrir no Gêmeo 3D',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kinetixOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openReportPreviewModal(
                          reportTitle: 'Laudo Técnico da Caixa ${box.code}',
                          reportType: 'Auditoria de Unidade Específica',
                          summary:
                              'Avaliação de conformidade para ${box.title} durante transporte de ${box.origin} para ${box.dest}. Score final: ${box.score.toInt()}%.',
                          primaryMetric: 'Score: ${box.score.toInt()}%',
                          secondaryMetric: 'Impacto: ${box.impactG}G | Temp: ${box.temp}°C',
                        );
                      },
                      icon: const Icon(Icons.description_outlined, size: 16),
                      label: const Text('Gerar Laudo',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textDisplay,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // =========================================================================
  // ABA 2: CENTRAL DE RELATÓRIOS ADMINISTRATIVOS
  // =========================================================================
  Widget _buildReportsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Seletor de Período
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.charcoalGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Período de Consolidação dos Dados',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPeriodBtn('Hoje', 'Hoje'),
                  const SizedBox(width: 6),
                  _buildPeriodBtn('7 Dias', '7 Dias'),
                  const SizedBox(width: 6),
                  _buildPeriodBtn('30 Dias', '30 Dias'),
                  const SizedBox(width: 6),
                  _buildPeriodBtn('Mês Vigente', 'Mês Vigente'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Catálogo de Relatórios Disponíveis
        const Text(
          'Relatórios Técnicos e Executivos Oficiais',
          style: TextStyle(
            color: AppColors.textDisplay,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        _buildReportCard(
          title: 'Relatório de Integridade de Carga e Aceleração',
          category: 'Norma Técnica • Aceleração MPU6050',
          summary:
              'Auditoria completa de vibrações, forças G e registros de impactos espaciais durante toda a rota das 8 caixas inteligentes.',
          period: _selectedReportPeriod,
          metrics: 'Impacto máx registrado: 1.45G • 7 caixas intactas',
          icon: Icons.speed,
          accentColor: AppColors.cyberCyan,
          onTap: () => _openReportPreviewModal(
            reportTitle: 'Relatório de Integridade de Carga e Aceleração',
            reportType: 'Auditoria de Impactos Espaciais MPU6050',
            summary:
                'Monitoramento vetorial de 3 eixos (X, Y, Z). 87.5% das caixas mantiveram impacto abaixo do limite de tolerância de 1.0G.',
            primaryMetric: 'Impacto Médio: 0.38G',
            secondaryMetric: 'Pico Máximo: 1.45G (TC-3312-PR)',
          ),
        ),
        const SizedBox(height: 10),

        _buildReportCard(
          title: 'Relatório de Conformidade Térmica (Cadeia de Frio)',
          category: 'Regulatório ANVISA • Sensor DHT22',
          summary:
              'Controle contínuo de temperatura e umidade relativa para vacinas, medicamentos oncológicos e amostras biológicas.',
          period: _selectedReportPeriod,
          metrics: 'Média: 19.6°C • Faixa permitida: 2°C a 28°C',
          icon: Icons.ac_unit,
          accentColor: AppColors.electricLime,
          onTap: () => _openReportPreviewModal(
            reportTitle: 'Relatório de Conformidade Térmica (Cadeia de Frio)',
            reportType: 'Certificação DHT22 ANVISA / Cadeia Farmacêutica',
            summary:
                'Validação das cargas de Vacinas Termossensíveis (#TC-8902) e Amostras Biológicas (#TC-7741). Zero excursões fora da faixa crítica.',
            primaryMetric: '100% Conformidade Térmica',
            secondaryMetric: 'Temp Min: 4.2°C • Temp Max: 24.5°C',
          ),
        ),
        const SizedBox(height: 10),

        _buildReportCard(
          title: 'Relatório de Violação de Lacre e Intrusão Luminosa',
          category: 'Segurança Patrimonial • Sensor LDR',
          summary:
              'Histórico de aberturas de tampa em trânsito, violações de lacres QR vinílicos e integridade do compartimento fechado.',
          period: _selectedReportPeriod,
          metrics: '1 violação leve detectada (TC-1092-RJ • 2 LUX)',
          icon: Icons.security,
          accentColor: AppColors.telemetryAmber,
          onTap: () => _openReportPreviewModal(
            reportTitle: 'Relatório de Violação de Lacre e Intrusão Luminosa',
            reportType: 'Segurança de Lacre e Auditoria LDR',
            summary:
                'Identificação de micro-aberturas de caixa em paradas rodoviárias. Ocorrência única na carga de Equipamentos Ópticos em Resende-RJ.',
            primaryMetric: '98.8% Lacres Preservados',
            secondaryMetric: '1 Alerta de Infiltração em Pátio',
          ),
        ),
        const SizedBox(height: 10),

        _buildReportCard(
          title: 'Relatório Executivo Consolidado de SLA e Frota',
          category: 'Gestão Executiva • Indicadores Globais',
          summary:
              'Visão macro de pontualidade, rotas concluídas, índice médio de integridade e eficiência operacional das transportadoras.',
          period: _selectedReportPeriod,
          metrics: 'Score Geral: 94.8% • 8 Caixas Monitoradas',
          icon: Icons.analytics_outlined,
          accentColor: AppColors.kinetixOrange,
          onTap: () => _openReportPreviewModal(
            reportTitle: 'Relatório Executivo Consolidado de SLA e Frota',
            reportType: 'Resumo Gerencial TransCargo Express',
            summary:
                'Consolidação de 8 remessas industriais com telemetria contínua. 100% dos pacotes MQTT recebidos sem perda no buffer offline.',
            primaryMetric: 'Score Global: 94.8%',
            secondaryMetric: 'Rotas Concluídas no Prazo: 96%',
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodBtn(String label, String value) {
    final isSelected = _selectedReportPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedReportPeriod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.cyberCyan.withValues(alpha: 0.16)
                : const Color(0xFF0B0E14),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.cyberCyan : AppColors.borderSlate,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.cyberCyan : AppColors.textMuted,
              fontSize: 9.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String category,
    required String summary,
    required String period,
    required String metrics,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.charcoalGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      category,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0E14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    metrics,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSection,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Período: $period',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: onTap,
                icon: const Icon(Icons.visibility_outlined, size: 13),
                label: const Text('Visualizar & Exportar',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Modal com Laudo Oficial e Botão de Exportação
  void _openReportPreviewModal({
    required String reportTitle,
    required String reportType,
    required String summary,
    required String primaryMetric,
    required String secondaryMetric,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xF70E141E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSlate),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho Oficial
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'Imagens/logo sem fundo.webp',
                            height: 32,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KINETIX CARGO REPORT',
                                style: TextStyle(
                                  color: AppColors.textDisplay,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'TransCargo Express Logística',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 8.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderSlate, height: 16),

                  // Título do Laudo
                  Text(
                    reportTitle,
                    style: const TextStyle(
                      color: AppColors.textDisplay,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    reportType,
                    style: const TextStyle(
                      color: AppColors.cyberCyan,
                      fontSize: 9.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Metadados do Laudo
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.charcoalGlass,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSlate),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Protocolo Oficial', 'KTX-${DateTime.now().year}-8902-AUD'),
                        _buildDetailRow('Data de Emissão', '06/11/2026 - 12:00 BRT'),
                        _buildDetailRow('Responsável', 'Admin TransCargo Express'),
                        _buildDetailRow('Período Avaliado', _selectedReportPeriod),
                        _buildDetailRow('Hash Auditoria', 'SHA256: 7f83b165...9d12a'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Resumo Executivo
                  Text(
                    summary,
                    style: const TextStyle(
                      color: AppColors.textSection,
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Métricas em Destaque
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0E14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.cyberCyan.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('INDICADOR PRINCIPAL',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 8)),
                            const SizedBox(height: 2),
                            Text(primaryMetric,
                                style: const TextStyle(
                                    color: AppColors.electricLime,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(width: 1, height: 24, color: AppColors.borderSlate),
                        Column(
                          children: [
                            const Text('PARÂMETROS DE CONTROLE',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 8)),
                            const SizedBox(height: 2),
                            Text(secondaryMetric,
                                style: const TextStyle(
                                    color: AppColors.cyberCyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botões de Exportação
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textDisplay,
                            side: const BorderSide(color: AppColors.borderSlate),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            showKinetixSweetAlert(
                              context,
                              title: 'CSV Exportado!',
                              message:
                                  'A planilha de telemetria bruta foi gerada e enviada para o seu dispositivo.',
                              type: SweetAlertType.success,
                            );
                          },
                          icon: const Icon(Icons.table_chart_outlined, size: 14),
                          label: const Text('Exportar CSV',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kinetixOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            showKinetixSweetAlert(
                              context,
                              title: 'Laudo PDF Gerado!',
                              message:
                                  'O relatório oficial com carimbo criptográfico foi salvo com sucesso.',
                              type: SweetAlertType.success,
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 14),
                          label: const Text('Baixar Laudo PDF',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // ABA 3: SISTEMA IIOT, USUÁRIOS & PARÂMETROS
  // =========================================================================
  Widget _buildSystemAndParamsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sub-navegação do Sistema IIoT
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.charcoalGlass,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Row(
            children: [
              _buildSubnavBtn('Gestão Usuários', 0),
              _buildSubnavBtn('Parear Sensores', 1),
              _buildSubnavBtn('Parâmetros IIoT', 2),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_systemSubTab == 0) _buildUsersSection(),
        if (_systemSubTab == 1) _buildSensorsSection(),
        if (_systemSubTab == 2) _buildParamsSection(),
      ],
    );
  }

  Widget _buildSubnavBtn(String label, int index) {
    final isActive = _systemSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _systemSubTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.cyberCyan.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? AppColors.cyberCyan.withValues(alpha: 0.6)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? AppColors.cyberCyan : AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.charcoalGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Usuários Ativos TransCargo Express',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.tagCyanBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: AppColors.cyberCyan.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${_users.length} Usuários',
                  style: const TextStyle(
                    color: AppColors.cyberCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = _users[index];
              final isActive = user['isActive'] as bool;
              final isMaster = user['isMaster'] == true;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0E14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? AppColors.borderSlate
                        : AppColors.kinetixOrange.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'] as String,
                              style: const TextStyle(
                                color: AppColors.textDisplay,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${user['email']} • ${user['code']}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.tagGreenBg
                                : AppColors.tagOrangeBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.electricLime
                                  : AppColors.kinetixOrange,
                            ),
                          ),
                          child: Text(
                            isActive ? (isMaster ? 'ADMIN' : 'ATIVO') : 'SUSPENSO',
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.electricLime
                                  : AppColors.kinetixOrange,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!isMaster)
                          DropdownButton<String>(
                            value: user['role'] as String,
                            dropdownColor: const Color(0xFF161C26),
                            style: const TextStyle(
                                color: AppColors.cyberCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Operador', child: Text('Operador')),
                              DropdownMenuItem(
                                  value: 'Fiscal de Pátio',
                                  child: Text('Fiscal de Pátio')),
                              DropdownMenuItem(
                                  value: 'Motorista', child: Text('Motorista')),
                              DropdownMenuItem(
                                  value: 'Gestor Admin',
                                  child: Text('Gestor Admin')),
                            ],
                            onChanged: (val) => _changeRole(index, val),
                          )
                        else
                          const Text('Perfil Master',
                              style: TextStyle(
                                  color: AppColors.textLog, fontSize: 10)),
                        if (!isMaster)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive
                                  ? AppColors.tagOrangeBg
                                  : AppColors.tagGreenBg,
                              foregroundColor: isActive
                                  ? AppColors.kinetixOrange
                                  : AppColors.electricLime,
                              side: BorderSide(
                                  color: isActive
                                      ? AppColors.kinetixOrange
                                      : AppColors.electricLime),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _toggleUserStatus(index),
                            child: Text(
                              isActive ? 'Desativar Perfil' : 'Ativar Perfil',
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSensorsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.charcoalGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cadastrar Hardware Embarcado',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.tagCyanBg,
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: AppColors.cyberCyan.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'ESP32 Principal',
                  style: TextStyle(
                    color: AppColors.cyberCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('ID DO DISPOSITIVO EMBARCADO',
              style: TextStyle(color: AppColors.textSection, fontSize: 10)),
          const SizedBox(height: 4),
          TextField(
            controller: _sensorIdController,
            style: const TextStyle(color: AppColors.textDisplay, fontSize: 12),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0B0E14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderSlate),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 10),
          const Text('ENDEREÇO MAC BLUETOOTH / WIFI',
              style: TextStyle(color: AppColors.textSection, fontSize: 10)),
          const SizedBox(height: 4),
          TextField(
            controller: _sensorMacController,
            style: const TextStyle(color: AppColors.textDisplay, fontSize: 12),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0B0E14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderSlate),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 10),
          const Text('TÓPICO MQTT KINETIX BROKER',
              style: TextStyle(color: AppColors.textSection, fontSize: 10)),
          const SizedBox(height: 4),
          TextField(
            controller: _sensorTopicController,
            style: const TextStyle(color: AppColors.textDisplay, fontSize: 12),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0B0E14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderSlate),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kinetixOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _saveSensorPairing,
            child: const Text(
              'PAREAR & SINCRONIZAR DISPOSITIVO',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.charcoalGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Limites de Tolerância de Alerta IIoT',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text('IMPACTO MÁXIMO PERMITIDO (ACELERÔMETRO G)',
              style: TextStyle(color: AppColors.textSection, fontSize: 10)),
          const SizedBox(height: 4),
          TextField(
            controller: _paramGController,
            style: const TextStyle(color: AppColors.textDisplay, fontSize: 12),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0B0E14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderSlate),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 10),
          const Text('TEMPERATURA OPERACIONAL LIMITE (°C)',
              style: TextStyle(color: AppColors.textSection, fontSize: 10)),
          const SizedBox(height: 4),
          TextField(
            controller: _paramTempController,
            style: const TextStyle(color: AppColors.textDisplay, fontSize: 12),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0B0E14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderSlate),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 10),
          const Text('INFILTRAÇÃO MÁXIMA DE LUZ LDR (LUX)',
              style: TextStyle(color: AppColors.textSection, fontSize: 10)),
          const SizedBox(height: 4),
          TextField(
            controller: _paramLuxController,
            style: const TextStyle(color: AppColors.textDisplay, fontSize: 12),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0B0E14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderSlate),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kinetixOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _saveParams,
            child: const Text(
              'ATUALIZAR PARÂMETROS IIOT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
