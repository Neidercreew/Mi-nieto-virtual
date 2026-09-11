import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //static const String _base = 'http://10.0.2.2:3000/api';

  // Celular físico Android → ip local de el cel
  static const String _base = 'https://mnv-backend-production.up.railway.app/api';

  // ── CREAR USUARIO (ahora con telefono y PIN) ───────────────
  static Future<Map<String, dynamic>> crearUsuario(
      String nombre, String nivel, String telefono, String pin) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/usuarios'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nombre': nombre,
              'nivel': nivel,
              'telefono': telefono,
              'pin': pin,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return {'ok': true, 'usuarioId': data['usuarioId']};
      }

      // 409 = ese telefono ya esta registrado
      if (res.statusCode == 409) {
        return {'ok': false, 'mensaje': 'Ya existe una cuenta con ese número'};
      }

      return {'ok': false, 'mensaje': 'No pudimos crear la cuenta'};
    } catch (e) {
      print('❌ crearUsuario error: $e');
      return {'ok': false, 'mensaje': 'Sin conexión a internet'};
    }
  }

  // ── LOGIN: recuperar cuenta con telefono + PIN ─────────────
  static Future<Map<String, dynamic>> login(
      String telefono, String pin) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/usuarios/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'telefono': telefono, 'pin': pin}),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'ok': true,
          'usuarioId': data['usuarioId'],
          'nombre': data['nombre'],
          'nivel': data['nivel'],
        };
      }

      if (res.statusCode == 404) {
        return {
          'ok': false,
          'mensaje': 'No encontramos una cuenta con ese número'
        };
      }

      if (res.statusCode == 401) {
        return {'ok': false, 'mensaje': 'El PIN no es correcto'};
      }

      return {'ok': false, 'mensaje': 'No pudimos entrar'};
    } catch (e) {
      print('❌ login error: $e');
      return {'ok': false, 'mensaje': 'Sin conexión a internet'};
    }
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