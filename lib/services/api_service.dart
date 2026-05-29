import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ── CONFIGURACIÓN DE URL ───────────────────────────────────
  // Emulador Android (VS Code) → usa 10.0.2.2
  //static const String _base = 'http://10.0.2.2:3000/api';

  // Celular físico Android → descomenta esta y comenta la de arriba
  // (corre "ipconfig" en tu terminal y busca tu IPv4)
static const String _base = 'http://localhost:3000/api';

  // Cuando tengas backend en la nube → descomenta esta
  // static const String _base = 'https://tu-dominio.com/api';

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
      String usuarioId, String leccionId, int paso) async {
    try {
      await http
          .post(
            Uri.parse('$_base/usuarios/$usuarioId/paso'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'leccionId': leccionId, 'paso': paso}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('❌ guardarPaso error: $e');
      // Si falla silenciosamente, el usuario no se entera y la app no crashea
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