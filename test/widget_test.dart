// Prueba de humo: la app abre en la pantalla de bienvenida.
// Reemplaza el test del contador que trae Flutter por defecto, que no
// correspondia a esta app y siempre fallaba.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_nieto_virtual/main.dart';

void main() {
  testWidgets('La app abre en la bienvenida con sus dos botones',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MiNietoVirtual());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Empezar'), findsOneWidget);
    expect(find.text('Ya tengo mi cuenta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
