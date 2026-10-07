// Pruebas del guardado de progreso cuando el servidor no responde.
// En flutter test todas las peticiones HTTP devuelven 400, asi que esto
// simula exactamente "Railway dormido / sin internet".

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_nieto_virtual/services/api_service.dart';

Map<String, dynamic>? _buscar(Map<String, dynamic>? data, String id) {
  final lista = data?['progreso'] as List<dynamic>? ?? [];
  for (final item in lista) {
    if (item is Map && item['leccionId'] == id) {
      return Map<String, dynamic>.from(item);
    }
  }
  return null;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Sin servidor, el paso guardado no se pierde', (tester) async {
    await tester.runAsync(() async {
      await ApiService.guardarPaso('u1', 'whatsapp_conociendo', 3);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final data = await ApiService.obtenerProgreso('u1');
      final item = _buscar(data, 'whatsapp_conociendo');
      expect(item, isNotNull);
      expect(item!['paso'], 3);
      expect(item['completada'], isFalse);
    });
  });

  testWidgets('Una leccion completada sigue completada al repetirla',
      (tester) async {
    await tester.runAsync(() async {
      await ApiService.guardarPaso('u1', 'correo_bandeja', 11,
          completada: true);
      // "Practicar de nuevo": vuelve a guardar desde el paso 1
      await ApiService.guardarPaso('u1', 'correo_bandeja', 1);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final data = await ApiService.obtenerProgreso('u1');
      final item = _buscar(data, 'correo_bandeja');
      expect(item!['completada'], isTrue);
      expect(item['paso'], 1);
    });
  });

  testWidgets('El progreso de una cuenta no se mezcla con otra',
      (tester) async {
    await tester.runAsync(() async {
      await ApiService.guardarPaso('u1', 'nequi_conociendo', 5);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final otra = await ApiService.obtenerProgreso('u2');
      expect(_buscar(otra, 'nequi_conociendo'), isNull);
    });
  });
}
