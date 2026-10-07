// Pruebas del nivel avanzado (Nequi).
// Correr con: flutter test test/nivel_avanzado_test.dart
//
// Cada leccion se abre en CADA paso (como al retomar desde el paso
// guardado) en una pantalla de celular de 360x780, sin errores ni
// desbordes (RenderFlex overflowed).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_nieto_virtual/tutorial_nequi_conociendo.dart';
import 'package:mi_nieto_virtual/tutorial_nequi_meter_plata.dart';
import 'package:mi_nieto_virtual/tutorial_nequi_enviar_plata.dart';
import 'package:mi_nieto_virtual/tutorial_nequi_pedir_plata.dart';
import 'package:mi_nieto_virtual/tutorial_nequi_pagar_qr.dart';
import 'package:mi_nieto_virtual/tutorial_nequi_sacar_plata.dart';
import 'package:mi_nieto_virtual/tutorial_nequi_anti_estafas.dart';

class _Leccion {
  final String id;
  final int pasos;
  final Widget Function(int paso) desde;
  const _Leccion(this.id, this.pasos, this.desde);
}

final List<_Leccion> _lecciones = [
  _Leccion('nequi_conociendo', 12,
      (p) => TutorialNequiConociendoScreen(pasoInicial: p)),
  _Leccion('nequi_meter_plata', 13,
      (p) => TutorialNequiMeterPlataScreen(pasoInicial: p)),
  _Leccion('nequi_enviar_plata', 14,
      (p) => TutorialNequiEnviarPlataScreen(pasoInicial: p)),
  _Leccion('nequi_pedir_plata', 14,
      (p) => TutorialNequiPedirPlataScreen(pasoInicial: p)),
  _Leccion('nequi_pagar_qr', 13,
      (p) => TutorialNequiPagarQrScreen(pasoInicial: p)),
  _Leccion('nequi_sacar_plata', 18,
      (p) => TutorialNequiSacarPlataScreen(pasoInicial: p)),
  _Leccion('nequi_anti_estafas', 15,
      (p) => TutorialNequiAntiEstafasScreen(pasoInicial: p)),
];

void _tamanoCelular(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Nequi: cada leccion se puede retomar en cualquier paso', () {
    for (final l in _lecciones) {
      testWidgets('${l.id}: ${l.pasos} pasos sin errores', (tester) async {
        _tamanoCelular(tester);
        for (int paso = 0; paso < l.pasos; paso++) {
          await tester.pumpWidget(
              MaterialApp(key: UniqueKey(), home: l.desde(paso)));
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull,
              reason: '${l.id} fallo en el paso ${paso + 1}');
          expect(find.text('Paso ${paso + 1} de ${l.pasos}'), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 6));
      });
    }
  });
}
