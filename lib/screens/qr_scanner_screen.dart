import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/sweet_alert.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  final List<Offset?> _signaturePoints = [];
  bool _isSigned = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  void _scanQrCode() {
    showKinetixSweetAlert(
      context,
      title: 'QR Code Autenticado!',
      message:
          'Etiqueta Vinílica QR #KINETIX-2026 autenticada. Histórico validado.',
      type: SweetAlertType.success,
    );
  }

  void _confirmReceipt() {
    setState(() {
      _isSigned = true;
    });

    showKinetixSweetAlert(
      context,
      title: 'Recebimento Confirmado!',
      message:
          'Assinatura digital registrada e sincronizada com a API TransCargo Express.',
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
                              'KINETIX',
                              style: TextStyle(
                                color: AppColors.textDisplay,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Scanner de Recebimento',
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
                        'QR #KINETIX',
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

              // Slogan Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppColors.charcoalGlass,
                child: const Text(
                  '"Relatórios rastreáveis na ponta de entrega via QR Code."',
                  style: TextStyle(
                    color: AppColors.cyberCyan,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // Body Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    // Scanner Frame Box
                    Container(
                      height: 190,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.borderSlate, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.kinetixOrange, width: 2),
                          ),
                          child: Stack(
                            children: [
                              AnimatedBuilder(
                                animation: _laserController,
                                builder: (context, child) {
                                  return Positioned(
                                    top: _laserController.value * 128,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 2,
                                      decoration: const BoxDecoration(
                                        color: AppColors.kinetixOrange,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.kinetixOrange,
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vinyl Tag Card
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ETIQUETA TELEMÉTRICA VINÍLICA',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.kinetixOrange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: AppColors.kinetixOrange
                                          .withValues(alpha: 0.4)),
                                ),
                                child: const Text(
                                  'Case ABS 3D Fosco',
                                  style: TextStyle(
                                    color: AppColors.kinetixOrange,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Leitura do QR Code Kinetix Laranja (#FF5500) para conferir a linha do tempo do transporte antes de assinar o recebimento.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.kinetixOrange.withValues(alpha: 0.15),
                                foregroundColor: AppColors.kinetixOrange,
                                side: const BorderSide(
                                    color: AppColors.kinetixOrange),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _scanQrCode,
                              icon: const Icon(Icons.qr_code, size: 16),
                              label: const Text(
                                'Testar Leitura do QR Code',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Certificate & Signature Card
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Certificado Digital de Recebimento',
                                style: TextStyle(
                                  color: AppColors.textDisplay,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.electricLime.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: AppColors.electricLime
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  _isSigned
                                      ? 'Entregue & Assinado'
                                      : 'Aguardando Assinatura',
                                  style: const TextStyle(
                                    color: AppColors.electricLime,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          const Text(
                            'DESTINATÁRIO: TransCargo Express HQ\nSCORE INTEGRIDADE: 100% (CARGA INTACTA)\nGEOLOCALIZAÇÃO: Caçapava-SP (-23.1004, -45.7072)',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),

                          const Text(
                            'Assinatura Digital do Destinatário:',
                            style: TextStyle(
                                color: AppColors.textSection, fontSize: 10),
                          ),
                          const SizedBox(height: 6),

                          // Signature Canvas Area
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderSlate),
                            ),
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  RenderBox renderBox =
                                      context.findRenderObject() as RenderBox;
                                  _signaturePoints.add(renderBox
                                      .globalToLocal(details.globalPosition));
                                });
                              },
                              onPanEnd: (details) {
                                setState(() {
                                  _signaturePoints.add(null);
                                });
                              },
                              child: CustomPaint(
                                painter: SignaturePainter(_signaturePoints),
                                size: Size.infinite,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.electricLime.withValues(alpha: 0.15),
                                foregroundColor: AppColors.electricLime,
                                side: const BorderSide(
                                    color: AppColors.electricLime),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _confirmReceipt,
                              child: const Text(
                                'Confirmar & Assinar Recebimento',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                              ),
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
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyberCyan
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
