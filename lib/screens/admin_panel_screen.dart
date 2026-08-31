import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/sweet_alert.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _activeTab = 0; // 0: Users, 1: Sensors, 2: Params

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

  final _sensorIdController =
      TextEditingController(text: 'ESP32-TK89-SJC');
  final _sensorMacController =
      TextEditingController(text: '24:0A:C4:9E:81:B0');
  final _sensorTopicController =
      TextEditingController(text: 'kinetix/cargo/tc8902/telemetry');

  final _paramGController = TextEditingController(text: '1.5 G');
  final _paramTempController = TextEditingController(text: '30.0 °C');
  final _paramLuxController = TextEditingController(text: '10 LUX');

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

  @override
  Widget build(BuildContext context) {
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KINETIX ADMIN',
                              style: TextStyle(
                                color: AppColors.textDisplay,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Painel de Gestão Completo',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.kinetixOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.kinetixOrange.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'Acesso Restrito',
                        style: TextStyle(
                          color: AppColors.kinetixOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Admin Subnav
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
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
              ),

              // Tab Section Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    if (_activeTab == 0) _buildUsersSection(),
                    if (_activeTab == 1) _buildSensorsSection(),
                    if (_activeTab == 2) _buildParamsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubnavBtn(String label, int index) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.cyberCyan.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? AppColors.cyberCyan : Colors.transparent,
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
                  color: AppColors.cyberCyan.withValues(alpha: 0.12),
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
                                ? AppColors.electricLime.withValues(alpha: 0.12)
                                : AppColors.kinetixOrange.withValues(alpha: 0.15),
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
                                  ? AppColors.kinetixOrange.withValues(alpha: 0.15)
                                  : AppColors.electricLime.withValues(alpha: 0.15),
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
                  color: AppColors.cyberCyan.withValues(alpha: 0.12),
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
