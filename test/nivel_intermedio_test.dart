// Pruebas del nivel intermedio.
// Correr con: flutter test test/nivel_intermedio_test.dart
//
// 1. Cada leccion se abre en CADA paso (simula retomar desde el paso
//    guardado) en una pantalla de celular de 360x780 sin errores ni
//    desbordes (RenderFlex overflowed).
// 2. Algunos recorridos: accion correcta -> boton verde; accion
//    incorrecta -> guia amarilla y el boton sigue gris.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_nieto_virtual/tutorial_whatsapp_conociendo.dart';
import 'package:mi_nieto_virtual/tutorial_whatsapp_responder.dart';
import 'package:mi_nieto_virtual/tutorial_whatsapp_audios.dart';
import 'package:mi_nieto_virtual/tutorial_whatsapp_fotos.dart';
import 'package:mi_nieto_virtual/tutorial_whatsapp_seguro.dart';
import 'package:mi_nieto_virtual/tutorial_correo_bandeja.dart';
import 'package:mi_nieto_virtual/tutorial_correo_adjuntos.dart';
import 'package:mi_nieto_virtual/tutorial_correo_responder.dart';
import 'package:mi_nieto_virtual/tutorial_correo_redactar.dart';
import 'package:mi_nieto_virtual/tutorial_mensajes_codigos.dart';
import 'package:mi_nieto_virtual/tutorial_mensajes_nuevo.dart';
import 'package:mi_nieto_virtual/tutorial_mensajes_organizar.dart';
import 'package:mi_nieto_virtual/tutorial_calendario_conociendo.dart';
import 'package:mi_nieto_virtual/tutorial_calendario_crear_evento.dart';
import 'package:mi_nieto_virtual/tutorial_calendario_recordatorios.dart';
import 'package:mi_nieto_virtual/tutorial_calendario_editar.dart';

class _Leccion {
  final String id;
  final int pasos;
  final Widget Function(int paso) desde;
  const _Leccion(this.id, this.pasos, this.desde);
}

final List<_Leccion> _lecciones = [
  _Leccion('whatsapp_conociendo', 10,
      (p) => TutorialWhatsappConociendoScreen(pasoInicial: p)),
  _Leccion('whatsapp_responder', 11,
      (p) => TutorialWhatsappResponderScreen(pasoInicial: p)),
  _Leccion('whatsapp_audios', 8,
      (p) => TutorialWhatsappAudiosScreen(pasoInicial: p)),
  _Leccion('whatsapp_fotos', 11,
      (p) => TutorialWhatsappFotosScreen(pasoInicial: p)),
  _Leccion('whatsapp_seguro', 9,
      (p) => TutorialWhatsappSeguroScreen(pasoInicial: p)),
  _Leccion('correo_bandeja', 11,
      (p) => TutorialCorreoBandejaScreen(pasoInicial: p)),
  _Leccion('correo_adjuntos', 10,
      (p) => TutorialCorreoAdjuntosScreen(pasoInicial: p)),
  _Leccion('correo_responder', 10,
      (p) => TutorialCorreoResponderScreen(pasoInicial: p)),
  _Leccion('correo_redactar', 10,
      (p) => TutorialCorreoRedactarScreen(pasoInicial: p)),
  _Leccion('mensajes_codigos', 9,
      (p) => TutorialMensajesCodigosScreen(pasoInicial: p)),
  _Leccion('mensajes_nuevo', 9,
      (p) => TutorialMensajesNuevoScreen(pasoInicial: p)),
  _Leccion('mensajes_organizar', 9,
      (p) => TutorialMensajesOrganizarScreen(pasoInicial: p)),
  _Leccion('calendario_conociendo', 10,
      (p) => TutorialCalendarioConociendoScreen(pasoInicial: p)),
  _Leccion('calendario_crear_evento', 10,
      (p) => TutorialCalendarioCrearEventoScreen(pasoInicial: p)),
  _Leccion('calendario_recordatorios', 10,
      (p) => TutorialCalendarioRecordatoriosScreen(pasoInicial: p)),
  _Leccion('calendario_editar', 10,
      (p) => TutorialCalendarioEditarScreen(pasoInicial: p)),
];

// Celular de 360 x 780 puntos
void _tamanoCelular(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _abrir(WidgetTester tester, Widget leccion) async {
  await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: leccion));
  // No usar pumpAndSettle: el pulso amarillo se repite sin fin
  await tester.pump(const Duration(milliseconds: 600));
}

// Cierra la leccion y deja correr los timers pendientes
Future<void> _cerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 6));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Cada leccion se puede retomar en cualquier paso', () {
    for (final l in _lecciones) {
      testWidgets('${l.id}: ${l.pasos} pasos sin errores', (tester) async {
        _tamanoCelular(tester);
        for (int paso = 0; paso < l.pasos; paso++) {
          await _abrir(tester, l.desde(paso));
          expect(tester.takeException(), isNull,
              reason: '${l.id} fallo en el paso ${paso + 1}');
          expect(find.text('Paso ${paso + 1} de ${l.pasos}'), findsOneWidget);
        }
        await _cerrar(tester);
      });
    }
  });

  group('Recorridos con toques', () {
    testWidgets('WhatsApp: abrir la app pone el boton verde', (tester) async {
      _tamanoCelular(tester);
      await _abrir(tester, const TutorialWhatsappConociendoScreen(pasoInicial: 1));
      expect(find.text('Toca el cuadro verde de WhatsApp'), findsOneWidget);

      // Toque equivocado: guia y nada avanza
      await tester.ensureVisible(find.text('Cámara'));
      await tester.tap(find.text('Cámara'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Esa es otra app'), findsOneWidget);
      expect(find.text('¡Lo lograste! Siguiente →'), findsNothing);

      // Toque correcto
      await tester.tap(find.text('WhatsApp'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('¡Lo lograste! Siguiente →'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _cerrar(tester);
    });

    testWidgets('WhatsApp: escribir hola con el teclado', (tester) async {
      _tamanoCelular(tester);
      await _abrir(tester, const TutorialWhatsappResponderScreen(pasoInicial: 3));
      for (final letra in ['h', 'o', 'l', 'a']) {
        await tester.ensureVisible(find.text(letra).last);
        await tester.tap(find.text(letra).last);
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.text('¡Lo lograste! Siguiente →'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _cerrar(tester);
    });

    testWidgets('Correo: abrir el de la clinica', (tester) async {
      _tamanoCelular(tester);
      await _abrir(tester, const TutorialCorreoBandejaScreen(pasoInicial: 3));
      await tester.ensureVisible(find.text('Tienda Mundo Ofertas'));
      await tester.tap(find.text('Tienda Mundo Ofertas'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('publicidad'), findsOneWidget);
      await tester.tap(find.text('Clínica Los Andes'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('¡Lo lograste! Siguiente →'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _cerrar(tester);
    });

    testWidgets('Mensajes: escribir el codigo 482913', (tester) async {
      _tamanoCelular(tester);
      await _abrir(tester, const TutorialMensajesCodigosScreen(pasoInicial: 3));
      for (final n in ['4', '8', '2', '9', '1', '3']) {
        await tester.ensureVisible(find.text(n).last);
        await tester.tap(find.text(n).last);
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('¡Entraste a Mi EPS!'), findsOneWidget);
      expect(find.text('¡Lo lograste! Siguiente →'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _cerrar(tester);
    });

    testWidgets('Calendario: tocar el jueves 8', (tester) async {
      _tamanoCelular(tester);
      await _abrir(
          tester, const TutorialCalendarioConociendoScreen(pasoInicial: 3));
      await tester.ensureVisible(find.text('9'));
      await tester.tap(find.text('9'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Ese es el 9'), findsOneWidget);
      expect(find.text('¡Lo lograste! Siguiente →'), findsNothing);
      await tester.tap(find.text('8'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('¡Lo lograste! Siguiente →'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _cerrar(tester);
    });

    testWidgets('Avanzar guarda el paso y cambia de pantalla', (tester) async {
      _tamanoCelular(tester);
      await _abrir(tester, const TutorialCalendarioEditarScreen());
      expect(find.text('Paso 1 de 10'), findsOneWidget);
      await tester.tap(find.text('Entendido, siguiente →'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Paso 2 de 10'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _cerrar(tester);
    });
  });
}
