import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/admin/shipment_form_screen.dart';
import '../../features/alerts/alerts_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/receive/receive_screen.dart';
import '../../features/receive/scanner_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shipment_detail/shipment_detail_screen.dart';
import '../../features/shipments/shipments_screen.dart';
import '../../features/timeline/timeline_screen.dart';

/// Rotas nomeadas do app (RNF 02: navegação com GoRouter e parâmetros nomeados).
abstract final class Routes {
  static const splash = '/carregando';
  static const login = '/login';
  static const register = '/cadastro';
  static const forgot = '/recuperar-senha';
  static const onboarding = '/boas-vindas';
  static const publicScanner = '/receber';
  static const shipments = '/cargas';
  static const alerts = '/alertas';
  static const scanner = '/ler-qr';
  static const profile = '/perfil';
  static const admin = '/admin';
  static const newShipment = '/admin/cargas/nova';

  static String shipment(String id) => '/cargas/$id';
  static String timeline(String id, {int? eventId}) => '/cargas/$id/historico${eventId == null ? '' : '?ocorrencia=$eventId'}';
  static String receipt(String token) => '/r/$token';
  static String editShipment(String id) => '/admin/cargas/$id/editar';

  static const _public = [login, register, forgot, publicScanner, '/r/'];
  static bool isPublic(String path) => _public.any((p) => path == p || (p.endsWith('/') && path.startsWith(p)));
}

final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<AsyncValue<Profile?>>(const AsyncLoading());
  ref.listen(sessionProvider, (_, next) => session.value = next, fireImmediately: true);
  ref.onDispose(session.dispose);

  return GoRouter(
    initialLocation: Routes.shipments,
    refreshListenable: session,
    redirect: (context, state) {
      final path = state.uri.path;
      final s = session.value;
      if (Routes.isPublic(path) && !path.startsWith(Routes.login) && !path.startsWith(Routes.register)) {
        return null; // QR Code e recuperação de senha funcionam sem login
      }
      if (s.isLoading && !s.hasValue) return path == Routes.splash ? null : '${Routes.splash}?para=${Uri.encodeComponent(state.uri.toString())}';
      final me = s.value;
      if (me == null) {
        if (Routes.isPublic(path)) return null;
        return Routes.login;
      }
      final target = state.uri.queryParameters['para'];
      if (!me.onboarded && path != Routes.onboarding) return Routes.onboarding;
      if (path == Routes.splash || path == Routes.login || path == Routes.register) {
        return (target != null && target.startsWith('/') && !target.startsWith(Routes.splash)) ? target : Routes.shipments;
      }
      if (path.startsWith(Routes.admin) && !me.role.isStaff) return Routes.shipments;
      return null;
    },
    errorBuilder: (_, __) => const NotFoundScreen(),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: Routes.forgot, builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: Routes.publicScanner, builder: (_, __) => const ScannerScreen(standalone: true)),
      GoRoute(path: '/r/:token', builder: (_, s) => ReceiveScreen(token: s.pathParameters['token']!)),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.shipments,
              builder: (_, __) => const ShipmentsScreen(),
              routes: [
                GoRoute(path: ':id', builder: (_, s) => ShipmentDetailScreen(shipmentId: s.pathParameters['id']!), routes: [
                  GoRoute(
                    path: 'historico',
                    builder: (_, s) => TimelineScreen(
                      shipmentId: s.pathParameters['id']!,
                      focusEventId: int.tryParse(s.uri.queryParameters['ocorrencia'] ?? ''),
                    ),
                  ),
                ]),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.alerts, builder: (_, __) => const AlertsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.scanner, builder: (_, __) => const ScannerScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.profile, builder: (_, __) => const ProfileScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.admin, builder: (_, __) => const AdminScreen(), routes: [
              GoRoute(path: 'cargas/nova', builder: (_, __) => const ShipmentFormScreen()),
              GoRoute(path: 'cargas/:id/editar', builder: (_, s) => ShipmentFormScreen(shipmentId: s.pathParameters['id'])),
            ]),
          ]),
        ],
      ),
    ],
  );
});

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.travel_explore, size: 44),
            const SizedBox(height: 12),
            const Text('Página não encontrada'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => context.go(Routes.shipments), child: const Text('Voltar para as cargas')),
          ]),
        ),
      );
}
