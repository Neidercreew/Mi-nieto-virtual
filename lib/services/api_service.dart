import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //static const String _base = 'http://10.0.2.2:3000/api';

  // Celular físico Android → ip local de el cel
static const String _base = 'https://mnv-backend-production.up.railway.app/api';

  // ── CREAR USUARIO ──────────────────────────────────────────
  static Future<String?> crearUsuario(String nombre, String nivel) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/usuarios'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nombre': nombre, 'nivel': nivel}),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['usuarioId'];
      }
    } catch (e) {
      print('❌ crearUsuario error: $e');
    }
    return null; // Si falla, la app sigue funcionando offline
  }

  // ── GUARDAR PASO INDIVIDUAL ────────────────────────────────
  static Future<void> guardarPaso(
    String usuarioId, String leccionId, int paso,
    {bool completada = false}) async {
  try {
    await http
        .post(
          Uri.parse('$_base/usuarios/$usuarioId/paso'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'leccionId': leccionId,
            'paso': paso,
            'completada': completada,
          }),
        )
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    print('❌ guardarPaso error: $e');
  }
}

  // ── OBTENER PROGRESO ───────────────────────────────────────
  static Future<Map<String, dynamic>?> obtenerProgreso(
      String usuarioId) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/usuarios/$usuarioId/progreso'))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('❌ obtenerProgreso error: $e');
    }
    return null; // Si falla, el dashboard muestra progreso local
  }
}