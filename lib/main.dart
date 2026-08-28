import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const KinetixApp());
}

class KinetixApp extends StatelessWidget {
  const KinetixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kinetix - Talpa Systems',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.obsidianPitch,
        primaryColor: AppColors.talpaLava,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.talpaLava,
          secondary: AppColors.cyberCyan,
          surface: AppColors.charcoalGlass,
          background: AppColors.obsidianPitch,
        ),
        fontFamily: 'Plus Jakarta Sans',
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
      },
    );
  }
}
