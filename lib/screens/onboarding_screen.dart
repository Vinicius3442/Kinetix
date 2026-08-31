import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String userRole;
  const OnboardingScreen({super.key, this.userRole = 'op'});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Gêmeo Digital 3D em Tempo Real',
      'desc':
          'Acompanhe a movimentação espacial da caixa selada através do sensor MPU6050, registrando inclinação e impactos em 3D.',
      'icon': Icons.view_in_ar,
      'color': AppColors.cyberCyan,
    },
    {
      'title': 'Rigor Telemétrico (RTC & GPS)',
      'desc':
          'Cada medição possui carimbo temporal auditável e localização por satélite com suporte a retenção de memória no Buffer Offline.',
      'icon': Icons.access_time_outlined,
      'color': AppColors.telemetryAmber,
    },
    {
      'title': 'Certificado Digital no Destino',
      'desc':
          'Escaneie a etiqueta vinílica QR #KINETIX ao entregar a carga e colha a assinatura digital do destinatário com validação via Webhook.',
      'icon': Icons.qr_code_scanner,
      'color': AppColors.electricLime,
    },
  ];

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainTabContainer(userRole: widget.userRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianPitch,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                // Top Header Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'Imagens/logo sem fundo.webp',
                            height: 44,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'KINETIX',
                            style: TextStyle(
                              color: AppColors.textDisplay,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _finish,
                        child: const Text(
                          'Pular Tutorial',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page View Slider
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: AppColors.charcoalGlass,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.borderSlate),
                                boxShadow: [
                                  BoxShadow(
                                    color: (slide['color'] as Color)
                                        .withValues(alpha: 0.15),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                slide['icon'] as IconData,
                                size: 84,
                                color: slide['color'] as Color,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              slide['title'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textDisplay,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              slide['desc'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (idx) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: idx == _currentPage ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: idx == _currentPage
                                  ? AppColors.cyberCyan
                                  : AppColors.borderSlate,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: idx == _currentPage
                                  ? [
                                      BoxShadow(
                                        color:
                                            AppColors.cyberCyan.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Next Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kinetixOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () {
                            if (_currentPage < _slides.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _finish();
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _slides.length - 1
                                    ? 'COMEÇAR USAR O APP'
                                    : 'AVANÇAR',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
