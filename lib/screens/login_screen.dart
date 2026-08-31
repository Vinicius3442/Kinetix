import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'forgot_password_screen.dart';
import 'onboarding_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'op'; // 'op' or 'admin'
  final _emailController =
      TextEditingController(text: 'operador@transcargo.com.br');
  final _passController = TextEditingController(text: 'kinetix2026');

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'admin') {
        _emailController.text = 'admin@transcargo.com.br';
      } else {
        _emailController.text = 'operador@transcargo.com.br';
      }
    });
  }

  void _handleLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(userRole: _selectedRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianPitch,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hero Brand Header
                  Column(
                    children: [
                      Image.asset(
                        'Imagens/logo sem fundo.webp',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'KINETIX',
                        style: TextStyle(
                          color: AppColors.textDisplay,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '"Sensibilidade total onde os olhos não alcançam."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.cyberCyan,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'TransCargo Express • Kinetix Cargo Intelligence',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Glass Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.charcoalGlass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSlate),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role Selector Toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B0E14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderSlate),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectRole('op'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'op'
                                          ? AppColors.cyberCyan.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _selectedRole == 'op'
                                            ? AppColors.cyberCyan
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Text(
                                      'Operador',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _selectedRole == 'op'
                                            ? AppColors.cyberCyan
                                            : AppColors.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectRole('admin'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'admin'
                                          ? AppColors.cyberCyan.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _selectedRole == 'admin'
                                            ? AppColors.cyberCyan
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Text(
                                      'Gestor Admin',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _selectedRole == 'admin'
                                            ? AppColors.cyberCyan
                                            : AppColors.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        const Text(
                          'E-MAIL / MATRÍCULA',
                          style: TextStyle(
                            color: AppColors.textSection,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(
                              color: AppColors.textDisplay, fontSize: 13),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_outline,
                                color: AppColors.textMuted, size: 18),
                            filled: true,
                            fillColor: const Color(0xFF0B0E14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.borderSlate),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.borderSlate),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.cyberCyan),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        const Text(
                          'SENHA DE ACESSO',
                          style: TextStyle(
                            color: AppColors.textSection,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passController,
                          obscureText: true,
                          style: const TextStyle(
                              color: AppColors.textDisplay, fontSize: 13),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: AppColors.textMuted, size: 18),
                            filled: true,
                            fillColor: const Color(0xFF0B0E14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.borderSlate),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.borderSlate),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.cyberCyan),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Esqueceu a senha?',
                              style: TextStyle(
                                color: AppColors.cyberCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Submit Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kinetixOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _handleLogin,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'ENTRAR NO SISTEMA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Register Footer Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Não possui conta? ',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Cadastre-se',
                          style: TextStyle(
                            color: AppColors.cyberCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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
}
