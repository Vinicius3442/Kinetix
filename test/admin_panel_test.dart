import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix/models/cargo_box.dart';
import 'package:kinetix/screens/admin_panel_screen.dart';

void main() {
  test('CargoFleetRepository contains all monitored boxes', () {
    final fleet = CargoFleetRepository.fleet;
    expect(fleet.length, greaterThanOrEqualTo(8));
    expect(fleet.any((b) => b.code == 'TC-8902-SJC'), isTrue);
    expect(fleet.any((b) => b.code == 'TC-3312-PR'), isTrue);
  });

  testWidgets('AdminPanelScreen renders tabs: Dashboard, Caixas, Relatórios, Sistema', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminPanelScreen(),
        ),
      ),
    );

    // Verifica os botões das abas administrativas
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Todas as Caixas'), findsOneWidget);
    expect(find.text('Relatórios'), findsOneWidget);
    expect(find.text('Sistema IIoT'), findsOneWidget);

    // Verifica a presença de indicadores do Dashboard na aba inicial
    expect(find.text('TOTAL CAIXAS'), findsOneWidget);
    expect(find.text('SCORE MÉDIO'), findsOneWidget);
    expect(find.text('EM TRÂNSITO'), findsOneWidget);
    expect(find.text('ALERTAS / RISCO'), findsOneWidget);

    // Navega para a aba 'Todas as Caixas'
    await tester.tap(find.text('Todas as Caixas'));
    await tester.pumpAndSettle();

    // Verifica a listagem de caixas monitoradas
    expect(find.textContaining('Caixas Monitoradas'), findsOneWidget);
    expect(find.text('TC-8902-SJC'), findsOneWidget);
    expect(find.text('TC-3312-PR'), findsOneWidget);

    // Navega para a aba 'Relatórios'
    await tester.tap(find.text('Relatórios'));
    await tester.pumpAndSettle();

    // Verifica os relatórios oficiais disponíveis
    expect(find.text('Relatórios Técnicos e Executivos Oficiais'), findsOneWidget);
    expect(find.text('Relatório de Integridade de Carga e Aceleração'), findsOneWidget);
    expect(find.text('Relatório de Conformidade Térmica (Cadeia de Frio)'), findsOneWidget);
    expect(find.text('Relatório de Violação de Lacre e Intrusão Luminosa'), findsOneWidget);
  });
}

