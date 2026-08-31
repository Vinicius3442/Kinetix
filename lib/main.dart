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
      title: 'Kinetix - TransCargo Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.obsidianPitch,
        primaryColor: AppColors.kinetixOrange,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.kinetixOrange,
          secondary: AppColors.cyberCyan,
          surface: AppColors.charcoalGlass,
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
