// Test base para validar que la app abre en onboarding.

import 'package:flutter_test/flutter_test.dart';

import 'package:grocerysaver/main.dart';

void main() {
  // Verifica que el punto de entrada renderiza la primera pantalla esperada.
  testWidgets('Muestra pantalla de onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const GrocerySaverApp());

    expect(find.text('Bienvenido a GrocerySaver'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
  });
}
