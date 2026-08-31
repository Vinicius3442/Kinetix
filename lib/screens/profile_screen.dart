import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/sweet_alert.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController(text: 'Carlos Silva');
  final _emailController =
      TextEditingController(text: 'operador@transcargo.com.br');
  final _roleController =
      TextEditingController(text: 'Operador de Logística & Telemetria');
  final _unitController =
      TextEditingController(text: 'Terminal SJC Pres. Dutra');

  void _saveProfile() {
    showKinetixSweetAlert(
      context,
      title: 'Perfil Atualizado!',
      message:
          'As informações de ${_nameController.text} foram salvas e sincronizadas no sistema TransCargo Express.',
      type: SweetAlertType.success,
    );
  }

  void _uploadPhoto() {
    showKinetixSweetAlert(
      context,
      title: 'Foto Carregada!',
      message: 'Sua foto de perfil foi atualizada com sucesso.',
      type: SweetAlertType.success,
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
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
                              'Perfil do Operador',
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
                        color: AppColors.electricLime.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.electricLime.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Operador',
                        style: TextStyle(
                          color: AppColors.electricLime,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Avatar & Hero Info
                    Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.cyberCyan,
                                    AppColors.kinetixOrange
                                  ],
                                ),
                                border: Border.all(
                                    color: AppColors.cyberCyan, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.cyberCyan.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'CS',
                                  style: TextStyle(
                                    color: Color(0xFF0B0E14),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _uploadPhoto,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: AppColors.kinetixOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _nameController.text,
                          style: const TextStyle(
                            color: AppColors.textDisplay,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Matrícula: TC-8902 • TransCargo Express SJC',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Profile Edit Form
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.charcoalGlass,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSlate),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('NOME COMPLETO',
                              style: TextStyle(
                                  color: AppColors.textSection, fontSize: 10)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(
                                color: AppColors.textDisplay, fontSize: 12),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF0B0E14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.borderSlate),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text('E-MAIL CORPORATIVO',
                              style: TextStyle(
                                  color: AppColors.textSection, fontSize: 10)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(
                                color: AppColors.textDisplay, fontSize: 12),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF0B0E14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.borderSlate),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text('FUNÇÃO OPERACIONAL',
                              style: TextStyle(
                                  color: AppColors.textSection, fontSize: 10)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _roleController,
                            style: const TextStyle(
                                color: AppColors.textDisplay, fontSize: 12),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF0B0E14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.borderSlate),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text('UNIDADE / BASE',
                              style: TextStyle(
                                  color: AppColors.textSection, fontSize: 10)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _unitController,
                            style: const TextStyle(
                                color: AppColors.textDisplay, fontSize: 12),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF0B0E14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.borderSlate),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.kinetixOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save_outlined, size: 16),
                            label: const Text(
                              'SALVAR ALTERAÇÕES DO PERFIL',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Logout Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.kinetixOrange.withValues(alpha: 0.12),
                        foregroundColor: AppColors.kinetixOrange,
                        side: BorderSide(
                            color: AppColors.kinetixOrange.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text(
                        'LOGOUT / ENCERRA SESSÃO',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
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
