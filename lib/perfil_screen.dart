import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'main.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // Paleta oficial del proyecto (la misma de las lecciones)
  static const Color _morado = Color(0xFF6B4EFF);
  static const Color _morado2 = Color(0xFF8B5CF6);
  static const Color _verde = Color(0xFF059669);
  static const Color _amarillo = Color(0xFFFFB300);
  static const Color _azul = Color(0xFF0EA5E9);
  static const Color _rojo = Color(0xFFE53E3E);
  static const Color _fondo = Color(0xFFF0EEFF);
  static const Color _texto = Color(0xFF1A1A2E);
  static const Color _suave = Color(0xFF777799);
  static const Color _borde = Color(0xFFDED8FF);

  String _nombre = "Usuario";
  String _telefono = "";
  String _nivel = "";
  String? _usuarioId;

  int _completadas = 0;
  int _enProgreso = 0;
  bool _progresoDisponible = false;

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  // Primero lee lo local, luego intenta traer el progreso del servidor
  Future<void> _cargarTodo() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('usuario_id');

    if (!mounted) return;
    setState(() {
      _nombre = prefs.getString('nombre_usuario') ?? "Usuario";
      _telefono = prefs.getString('telefono_usuario') ?? "";
      _nivel = prefs.getString('nivel_usuario') ?? "";
      _usuarioId = id;
    });

    if (id != null && id.isNotEmpty) {
      final data = await ApiService.obtenerProgreso(id);
      if (data != null) {
        _contarProgreso(data);
      }
    }

    if (!mounted) return;
    setState(() => _cargando = false);
  }

  // Cuenta lecciones completadas y en progreso.
  // Acepta varias formas de respuesta para no romperse si el backend cambia.
  void _contarProgreso(Map<String, dynamic> data) {
    // Diagnostico: muestra que llaves trae la respuesta real
    print('🔎 progreso keys: ${data.keys.toList()}');

    dynamic bruto = data['progreso'] ?? data['lecciones'] ?? data;

    int completadas = 0;
    int enProgreso = 0;

    void revisar(dynamic item) {
      if (item is Map) {
        final completada = item['completada'] == true;
        final paso = item['paso'];
        if (completada) {
          completadas++;
        } else if (paso is num && paso > 0) {
          enProgreso++;
        }
      }
    }

    if (bruto is Map) {
      bruto.forEach((_, valor) => revisar(valor));
    } else if (bruto is List) {
      for (final valor in bruto) {
        revisar(valor);
      }
    }

    if (!mounted) return;
    setState(() {
      _completadas = completadas;
      _enProgreso = enProgreso;
      _progresoDisponible = true;
    });
  }

  // Convierte 3005551234 en 300 555 1234 para que sea mas facil de leer
  String get _telefonoBonito {
    final digitos = _telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.length != 10) {
      return _telefono.isEmpty ? "No registrado" : _telefono;
    }
    return '${digitos.substring(0, 3)} ${digitos.substring(3, 6)} ${digitos.substring(6)}';
  }

  // Convierte basico en Basico para mostrarlo bonito
  String get _nivelBonito {
    switch (_nivel.toLowerCase()) {
      case 'basico':
        return 'Básico';
      case 'intermedio':
        return 'Intermedio';
      case 'avanzado':
        return 'Avanzado';
      default:
        return _nivel.isEmpty ? 'Básico' : _nivel;
    }
  }

  // Primera letra del nombre para el circulo grande
  String get _inicial =>
      _nombre.trim().isEmpty ? "U" : _nombre.trim()[0].toUpperCase();

  // Pregunta antes de salir para evitar cierres de sesion por accidente
  Future<void> _confirmarCambioDeCuenta() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        title: const Text(
          "¿Cambiar de cuenta?",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: _texto,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Vas a salir de tu cuenta.\n\nTu progreso queda guardado. Puedes volver a entrar con tu teléfono y tu PIN.",
              style: TextStyle(fontSize: 19, color: _texto, height: 1.4),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _morado,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "No, quedarme aquí",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Sí, cambiar de cuenta",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _rojo,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmado == true) {
      await _cerrarSesion();
    }
  }

  // Borra solo las llaves de la sesion, no el resto de preferencias
  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuario_id');
    await prefs.remove('nombre_usuario');
    await prefs.remove('nivel_usuario');
    await prefs.remove('telefono_usuario');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(color: _morado),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildTarjetaProgreso(),
                      const SizedBox(height: 4),
                      _buildDatoCard(
                        Icons.phone_rounded,
                        "Tu teléfono",
                        _telefonoBonito,
                        _azul,
                      ),
                      _buildDatoCard(
                        Icons.school_rounded,
                        "Tu nivel",
                        _nivelBonito,
                        _verde,
                      ),
                      const SizedBox(height: 16),
                      _buildBotonCambiarCuenta(),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_morado, _morado2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boton para volver, grande y facil de tocar
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Volver",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      _inicial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta destacada con el avance del usuario
  Widget _buildTarjetaProgreso() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _borde, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _amarillo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 34,
                  color: _amarillo,
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Text(
                  "Tu avance",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _texto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!_progresoDisponible)
            const Text(
              "No pudimos consultar tu avance ahora. Revisa tu conexión e intenta más tarde.",
              style: TextStyle(fontSize: 18, color: _suave, height: 1.35),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildContador(
                    "$_completadas",
                    _completadas == 1
                        ? "lección\ncompletada"
                        : "lecciones\ncompletadas",
                    _verde,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildContador(
                    "$_enProgreso",
                    _enProgreso == 1 ? "lección\nempezada" : "lecciones\nempezadas",
                    _azul,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _completadas == 0
                  ? "Empieza cuando quieras. Vas a tu ritmo."
                  : "Vas muy bien. Sigue a tu ritmo.",
              style: const TextStyle(fontSize: 18, color: _suave),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContador(String numero, String etiqueta, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            numero,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: _texto,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatoCard(
    IconData icono,
    String etiqueta,
    String valor,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _borde, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icono, size: 34, color: color),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(fontSize: 17, color: _suave),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _texto,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonCambiarCuenta() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _confirmarCambioDeCuenta,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _rojo,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: _rojo, width: 2),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 28),
            SizedBox(width: 12),
            Text(
              "Cambiar de cuenta",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}