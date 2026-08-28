import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/sweet_alert.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  void _openEventModal(
    BuildContext context, {
    required String title,
    required String time,
    required String gps,
    required String sensor,
    required String val,
    required String note,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF111722),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.talpaLava, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.talpaLava.withOpacity(0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textDisplay,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Leitura de auditabilidade: $note. Transmitida via MQTT da placa ESP32.',
                style: const TextStyle(color: AppColors.textSection, fontSize: 11),
              ),
              const SizedBox(height: 12),

              // Detail Grid
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.charcoalGlass,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSlate),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TIMESTAMP RTC',
                                  style: TextStyle(
                                      color: AppColors.textLog, fontSize: 9)),
                              Text(time,
                                  style: const TextStyle(
                                      color: AppColors.cyberCyan,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SENSOR ORIGEM',
                                  style: TextStyle(
                                      color: AppColors.textLog, fontSize: 9)),
                              Text(sensor,
                                  style: const TextStyle(
                                      color: AppColors.cyberCyan,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MÉTRICA / VALOR',
                                  style: TextStyle(
                                      color: AppColors.textLog, fontSize: 9)),
                              Text(val,
                                  style: const TextStyle(
                                      color: AppColors.talpaLava,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('STATUS',
                                  style: TextStyle(
                                      color: AppColors.textLog, fontSize: 9)),
                              Text('ALERTA ATIVO',
                                  style: TextStyle(
                                      color: AppColors.talpaLava,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GEOLOCALIZAÇÃO GPS SATÉLITE',
                            style: TextStyle(
                                color: AppColors.textLog, fontSize: 9)),
                        Text(gps,
                            style: const TextStyle(
                                color: AppColors.cyberCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.talpaLava,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    showKinetixSweetAlert(
                      context,
                      title: 'Alerta Despachado!',
                      message:
                          'Notificação de emergência disparada via Webhook Wegnology para a central TransCargo.',
                      type: SweetAlertType.success,
                    );
                  },
                  icon: const Icon(Icons.warning_amber_rounded, size: 16),
                  label: const Text(
                    'Despachar Alerta de Emergência',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
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
                      title: 'Alerta Reconhecido!',
                      message:
                          'Carimbo de ciência do operador gravado nos registros de auditoria.',
                      type: SweetAlertType.success,
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text(
                    'Reconhecer Alerta / Marcar Ciente',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
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
                      title: 'Inspeção Solicitada!',
                      message:
                          'Ordem de verificação físico-mecânica enviada para o próximo posto de controle.',
                      type: SweetAlertType.success,
                    );
                  },
                  icon: const Icon(Icons.build_outlined, size: 16),
                  label: const Text(
                    'Solicitar Inspeção Físico-Mecânica',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                              'KINETIX',
                              style: TextStyle(
                                color: AppColors.textDisplay,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Auditoria & Linha do Tempo',
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
                        color: AppColors.cyberCyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.cyberCyan.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'RTC / GPS',
                        style: TextStyle(
                          color: AppColors.cyberCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                  '"Transparência Auditável — Dados com precisão temporal (RTC) e espacial (GPS)"',
                  style: TextStyle(
                    color: AppColors.cyberCyan,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // Content Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    // Buffer Box Strategy
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.telemetryAmber.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.telemetryAmber.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sd_storage_outlined,
                              color: AppColors.telemetryAmber, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estratégia Buffer Offline (Memória ESP32)',
                                  style: TextStyle(
                                    color: AppColors.telemetryAmber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '18 pacotes retidos na memória interna • Sincronização automática via Wegnology',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Timeline Card Container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.charcoalGlass,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSlate),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'HISTÓRICO RASTREÁVEL DO TRANSPORTE',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Timeline Item 1
                          _buildTimelineItem(
                            context,
                            title: 'Alerta de Impacto Dinâmico (2.45G)',
                            time: '14:32:05',
                            gps: 'Caçapava-SP (-23.1004, -45.7072)',
                            sensor: 'MPU6050',
                            val: '2.45 G',
                            sub:
                                'Sensor MPU6050 • Aceleração Brusca & Inclinação Roll +24.5°',
                            note: 'Penalização no Score: -25 pts',
                            isAlert: true,
                          ),
                          const SizedBox(height: 10),

                          // Timeline Item 2
                          _buildTimelineItem(
                            context,
                            title: 'Violação de Lacre Óptico (485 Lux)',
                            time: '14:28:10',
                            gps: 'Caçapava-SP (-23.1004, -45.7072)',
                            sensor: 'LDR Lacre',
                            val: '485 LUX',
                            sub:
                                'Sensor LDR • Entrada Repentina de Luz no Interior da Caixa',
                            note: 'Penalização no Score: -35 pts',
                            isAlert: true,
                          ),
                          const SizedBox(height: 10),

                          // Timeline Item 3
                          _buildTimelineItem(
                            context,
                            title: 'Variação Térmica Acima da Faixa (36.8°C)',
                            time: '14:15:00',
                            gps: 'Rodovia Pres. Dutra km 142',
                            sensor: 'DHT22',
                            val: '36.8 °C',
                            sub:
                                'Sensor DHT22 • Umidade Relativa do Ar: 54% UR',
                            note: 'Penalização no Score: -15 pts',
                            isWarn: true,
                          ),
                          const SizedBox(height: 10),

                          // Timeline Item 4
                          _buildTimelineItem(
                            context,
                            title: 'Lacre Óptico Validado - Intacto (0 LUX)',
                            time: '13:50:00',
                            gps: 'São José dos Campos-SP (-23.1896, -45.8841)',
                            sensor: 'LDR Lacre',
                            val: '0 LUX',
                            sub:
                                'Sensor LDR • Nenhuma Incidência Luminosa Registrada',
                            note: 'Sem penalização',
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
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required String title,
    required String time,
    required String gps,
    required String sensor,
    required String val,
    required String sub,
    required String note,
    bool isAlert = false,
    bool isWarn = false,
  }) {
    final borderColor = isAlert
        ? AppColors.talpaLava.withOpacity(0.5)
        : (isWarn
            ? AppColors.telemetryAmber.withOpacity(0.5)
            : AppColors.borderSlate);

    return InkWell(
      onTap: () => _openEventModal(
        context,
        title: title,
        time: time,
        gps: gps,
        sensor: sensor,
        val: val,
        note: note,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.charcoalGlass,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.cyberCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  gps,
                  style: const TextStyle(
                    color: AppColors.textLog,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textDisplay,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Text(
                  '→ Toque para abrir detalhes e ações operacionais',
                  style: TextStyle(
                    color: AppColors.cyberCyan,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
