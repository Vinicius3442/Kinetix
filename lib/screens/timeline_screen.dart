import 'dart:ui';
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
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xF70D121B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.kinetixOrange.withValues(alpha: 0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.kinetixOrange.withValues(alpha: 0.2),
                  blurRadius: 25,
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
                const SizedBox(height: 4),
                Text(
                  'Registro auditável: $note.',
                  style: const TextStyle(color: AppColors.textSection, fontSize: 11),
                ),
                const SizedBox(height: 14),

                // Detail Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.charcoalGlass,
                    borderRadius: BorderRadius.circular(10),
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
                                        color: AppColors.textLog, fontSize: 9, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
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
                                        color: AppColors.textLog, fontSize: 9, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('MÉTRICA / VALOR',
                                    style: TextStyle(
                                        color: AppColors.textLog, fontSize: 9, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(val,
                                    style: const TextStyle(
                                        color: AppColors.kinetixOrange,
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
                                        color: AppColors.textLog, fontSize: 9, fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text('ALERTA REGISTRADO',
                                    style: TextStyle(
                                        color: AppColors.kinetixOrange,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GEOLOCALIZAÇÃO GPS',
                              style: TextStyle(
                                  color: AppColors.textLog, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
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
                const SizedBox(height: 16),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kinetixOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      showKinetixSweetAlert(
                        context,
                        title: 'Alerta Reconhecido!',
                        message:
                            'Ciência do operador gravada no registro de auditoria.',
                        type: SweetAlertType.success,
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text(
                      'Reconhecer Alerta / Marcar Ciente',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
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
                        color: AppColors.cyberCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.cyberCyan.withValues(alpha: 0.3)),
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
                        color: AppColors.telemetryAmber.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.telemetryAmber.withValues(alpha: 0.3)),
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
                                  '18 pacotes retidos na memória interna • Sincronização automática via API Kinetix',
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
        ? AppColors.kinetixOrange.withValues(alpha: 0.5)
        : (isWarn
            ? AppColors.telemetryAmber.withValues(alpha: 0.5)
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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gps,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLog,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDisplay,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Expanded(
                  child: Text(
                    '→ Toque para abrir detalhes e ações operacionais',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.cyberCyan,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
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
