// Ayuda compartida por las pruebas de niveles.
//
// Abre una leccion en CADA paso (como al retomar desde el paso guardado)
// en un celular de 360x780 y junta TODOS los errores con su archivo y
// linea, en vez de parar en el primero. Asi una sola corrida muestra
// todo lo que hay que arreglar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Celular de 360 x 780 puntos
void tamanoCelular(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// "A RenderFlex overflowed by 33 pixels on the right. -> lib/x.dart:120"
String _resumen(FlutterErrorDetails detalles) {
  final mensaje = detalles.exceptionAsString().split('\n').first.trim();
  final texto = detalles.toString();
  final lugar = RegExp(r'(lib[/\\][^\s:]+\.dart):(\d+)').firstMatch(texto);
  return lugar == null
      ? mensaje
      : '$mensaje -> ${lugar.group(1)!.replaceAll('\\', '/')}:${lugar.group(2)}';
}

Future<void> revisarTodosLosPasos(
  WidgetTester tester, {
  required String id,
  required int pasos,
  required Widget Function(int paso) desde,
}) async {
  tamanoCelular(tester);
  final problemas = <String>[];
  var pasoActual = 0;
  final original = FlutterError.onError;
  FlutterError.onError = (detalles) {
    final linea = 'paso ${pasoActual + 1}: ${_resumen(detalles)}';
    if (!problemas.contains(linea)) problemas.add(linea);
  };
  try {
    for (int paso = 0; paso < pasos; paso++) {
      pasoActual = paso;
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: desde(paso)));
      // No usar pumpAndSettle: el pulso amarillo se repite sin fin
      await tester.pump(const Duration(milliseconds: 600));
      if (find.text('Paso ${paso + 1} de $pasos').evaluate().length != 1) {
        problemas.add('paso ${paso + 1}: no muestra "Paso ${paso + 1} de $pasos"');
      }
    }
    // Cierra la leccion y deja correr los timers pendientes
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  } finally {
    FlutterError.onError = original;
  }
  if (problemas.isNotEmpty) {
    // ignore: avoid_print
    print('\n=== $id: ${problemas.length} problema(s) ===\n${problemas.join('\n')}\n');
  }
  expect(problemas, isEmpty, reason: '$id tiene problemas (ver lista arriba)');
}
