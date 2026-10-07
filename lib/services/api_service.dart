import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  //static const String _base = 'http://10.0.2.2:3000/api';

  // Celular físico Android → ip local de el cel
  static const String _base = 'https://mnv-backend-production.up.railway.app/api';

  // Railway y Atlas M0 se duermen: el primer request puede tardar varios
  // segundos. Con 5 s se perdian pasos y las lecciones salian bloqueadas.
  static const Duration _espera = Duration(seconds: 12);
  // Si ya hay copia local del progreso no hace falta esperar tanto
  static const Duration _esperaConCopia = Duration(seconds: 6);

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
          .timeout(_espera);

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
      debugPrint('crearUsuario error: $e');
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
          .timeout(_espera);

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
      debugPrint('login error: $e');
      return {'ok': false, 'mensaje': 'Sin conexión a internet'};
    }
  }

  // ── GUARDAR PASO INDIVIDUAL ────────────────────────────────
  // Se guarda primero en el celular (rapido, nunca se pierde) y se envia
  // al servidor por detras, sin hacer esperar al usuario en la leccion.
  // Si el servidor no responde, el paso queda pendiente y se reenvia
  // la proxima vez que se consulte el progreso.
  static Future<void> guardarPaso(
      String usuarioId, String leccionId, int paso,
      {bool completada = false}) async {
    await _enCola(
        () => _guardarEnCopiaLocal(usuarioId, leccionId, paso, completada));
    unawaited(_enviarORecordar(usuarioId, leccionId, paso, completada));
  }

  // ── ACTUALIZAR NIVEL ───────────────────────────────────────
  static Future<bool> actualizarNivel(String usuarioId, String nivel) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_base/usuarios/$usuarioId/nivel'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nivel': nivel}),
          )
          .timeout(_espera);

      // Cualquier 2xx significa que el servidor acepto el cambio
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('actualizarNivel error: $e');
      return false;
    }
  }

  // ── OBTENER PROGRESO ───────────────────────────────────────
  // Devuelve {'progreso': [{leccionId, paso, completada}, ...]} igual que
  // antes. Si el servidor falla, devuelve la copia local en vez de null,
  // asi el mapa no muestra todo bloqueado por un problema de señal.
  static Future<Map<String, dynamic>?> obtenerProgreso(
      String usuarioId) async {
    // Los pendientes se reenvian por detras; la mezcla de abajo ya los tiene
    unawaited(_reenviarPendientes(usuarioId));

    final local = await _leerCopiaLocal(usuarioId);
    Map<String, dynamic>? remoto;
    try {
      final res = await http
          .get(Uri.parse('$_base/usuarios/$usuarioId/progreso'))
          .timeout(local.isEmpty ? _espera : _esperaConCopia);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) remoto = data;
      }
    } catch (e) {
      debugPrint('obtenerProgreso error: $e');
    }

    if (remoto == null) {
      if (local.isEmpty) return null;
      return {'progreso': local.values.toList(), 'sinConexion': true};
    }

    // Mezcla: lo del servidor manda, pero una leccion completada en el
    // celular sigue completada y los pasos aun no enviados se respetan
    final mezcla = <String, Map<String, dynamic>>{};
    final lista = remoto['progreso'];
    if (lista is List) {
      for (final item in lista) {
        if (item is Map && item['leccionId'] is String) {
          mezcla[item['leccionId'] as String] = Map<String, dynamic>.from(item);
        }
      }
    }
    final pendientes = await _leerPendientes(usuarioId);
    local.forEach((id, item) {
      final actual = mezcla[id];
      if (actual == null) {
        mezcla[id] = item;
        return;
      }
      if (item['completada'] == true) actual['completada'] = true;
      if (pendientes.containsKey(id)) actual['paso'] = item['paso'];
    });

    await _enCola(() => _escribirCopiaLocal(usuarioId, mezcla));
    final resultado = Map<String, dynamic>.from(remoto);
    resultado['progreso'] = mezcla.values.toList();
    return resultado;
  }

  // ── COPIA LOCAL Y PENDIENTES (privado) ─────────────────────
  static String _llaveCopia(String usuarioId) => 'progreso_copia_$usuarioId';
  static String _llavePendientes(String usuarioId) =>
      'progreso_pendiente_$usuarioId';

  // Las lecturas y escrituras locales van una detras de otra para que
  // dos guardados seguidos no se pisen
  static Future<void> _cola = Future.value();
  static Future<void> _enCola(Future<void> Function() tarea) {
    final siguiente = _cola.then((_) async {
      try {
        await tarea();
      } catch (e) {
        debugPrint('progreso local error: $e');
      }
    });
    _cola = siguiente;
    return siguiente;
  }

  static Future<void> _enviarORecordar(
      String usuarioId, String leccionId, int paso, bool completada) async {
    final ok = await _enviarPaso(usuarioId, leccionId, paso, completada);
    await _enCola(() => ok
        ? _quitarPendiente(usuarioId, leccionId, paso)
        : _agregarPendiente(usuarioId, leccionId, paso, completada));
  }

  static Future<bool> _enviarPaso(
      String usuarioId, String leccionId, int paso, bool completada) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/usuarios/$usuarioId/paso'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'leccionId': leccionId,
              'paso': paso,
              'completada': completada,
            }),
          )
          .timeout(_espera);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('guardarPaso error: $e');
      return false;
    }
  }

  static Future<Map<String, Map<String, dynamic>>> _leerMapa(
      String llave) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(llave);
      if (texto == null) return {};
      final data = jsonDecode(texto);
      if (data is! Map) return {};
      final out = <String, Map<String, dynamic>>{};
      data.forEach((k, v) {
        if (k is String && v is Map) out[k] = Map<String, dynamic>.from(v);
      });
      return out;
    } catch (e) {
      debugPrint('progreso local ilegible: $e');
      return {};
    }
  }

  static Future<void> _escribirMapa(
      String llave, Map<String, Map<String, dynamic>> mapa) async {
    final prefs = await SharedPreferences.getInstance();
    if (mapa.isEmpty) {
      await prefs.remove(llave);
    } else {
      await prefs.setString(llave, jsonEncode(mapa));
    }
  }

  static Future<Map<String, Map<String, dynamic>>> _leerCopiaLocal(
          String usuarioId) =>
      _leerMapa(_llaveCopia(usuarioId));

  static Future<void> _escribirCopiaLocal(
          String usuarioId, Map<String, Map<String, dynamic>> mapa) =>
      _escribirMapa(_llaveCopia(usuarioId), mapa);

  static Future<Map<String, Map<String, dynamic>>> _leerPendientes(
          String usuarioId) =>
      _leerMapa(_llavePendientes(usuarioId));

  static Future<void> _guardarEnCopiaLocal(String usuarioId, String leccionId,
      int paso, bool completada) async {
    final copia = await _leerCopiaLocal(usuarioId);
    final antes = copia[leccionId];
    copia[leccionId] = {
      'leccionId': leccionId,
      'paso': paso,
      // Una leccion completada no vuelve a quedar incompleta al repetirla
      'completada': completada || antes?['completada'] == true,
    };
    await _escribirCopiaLocal(usuarioId, copia);
  }

  static Future<void> _agregarPendiente(String usuarioId, String leccionId,
      int paso, bool completada) async {
    // Si despues de este paso ya se guardo otro, este quedo viejo
    final copia = await _leerCopiaLocal(usuarioId);
    final ultimo = copia[leccionId]?['paso'];
    if (ultimo is int && ultimo != paso) return;
    final pendientes = await _leerPendientes(usuarioId);
    final antes = pendientes[leccionId];
    pendientes[leccionId] = {
      'leccionId': leccionId,
      'paso': paso,
      'completada': completada || antes?['completada'] == true,
    };
    await _escribirMapa(_llavePendientes(usuarioId), pendientes);
  }

  static Future<void> _quitarPendiente(
      String usuarioId, String leccionId, int paso) async {
    final pendientes = await _leerPendientes(usuarioId);
    // Solo se quita si lo pendiente es justo lo que acaba de llegar
    if (pendientes[leccionId]?['paso'] != paso) return;
    pendientes.remove(leccionId);
    await _escribirMapa(_llavePendientes(usuarioId), pendientes);
  }

  // Reenvia los pasos que no alcanzaron a llegar al servidor
  static Future<void> _reenviarPendientes(String usuarioId) async {
    final pendientes = await _leerPendientes(usuarioId);
    if (pendientes.isEmpty) return;
    final enviados = <String>[];
    for (final item in pendientes.values) {
      final id = item['leccionId'];
      final paso = item['paso'];
      if (id is! String || paso is! int) {
        if (id is String) enviados.add(id);
        continue;
      }
      final ok = await _enviarPaso(
          usuarioId, id, paso, item['completada'] == true);
      if (!ok) break; // sin servidor: se intenta la proxima vez
      enviados.add(id);
    }
    if (enviados.isEmpty) return;
    await _enCola(() async {
      // Se relee por si mientras tanto se guardo un paso nuevo
      final actuales = await _leerPendientes(usuarioId);
      for (final id in enviados) {
        if (actuales[id]?['paso'] == pendientes[id]?['paso']) {
          actuales.remove(id);
        }
      }
      await _escribirMapa(_llavePendientes(usuarioId), actuales);
    });
  }
}
