// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cobrador_app/main.dart';
import 'package:cobrador_app/presentacion/cobrador/cobrador_dashboard_screen.dart';

void main() {
  group('Dashboard Layout Tests', () {
    testWidgets('Cobrador dashboard should render without overflow', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: CobradorDashboardScreen()),
        ),
      );

      // Verify that the dashboard renders without overflow errors
      expect(find.text('Panel de Cobrador'), findsOneWidget);
      expect(find.text('Mis Estadísticas'), findsOneWidget);
      expect(find.text('Acciones Rápidas'), findsOneWidget);

      // Verify that stat cards are present
      expect(find.text('Clientes Asignados'), findsOneWidget);
      expect(find.text('Préstamos Activos'), findsOneWidget);
      expect(find.text('Cobros del Día'), findsOneWidget);
      expect(find.text('Visitas Pendientes'), findsOneWidget);

      // Verify that action cards are present
      expect(find.text('Gestionar Clientes'), findsOneWidget);
      expect(find.text('Gestionar Préstamos'), findsOneWidget);
      expect(find.text('Ruta del Día'), findsOneWidget);
    });

    testWidgets('App should start without errors', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const ProviderScope(child: MyApp()));

      // Verify that the app starts without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
