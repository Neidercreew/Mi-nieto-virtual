import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// Modelo de una lección dentro del mapa
class LeccionMapa {
  final String leccionId;
  final String titulo;
  final String emoji;
  final Widget Function() builder; // qué pantalla abre
  final Widget Function(int paso)? builderDesde; // para continuar desde un paso específico
  
  LeccionMapa({
    required this.leccionId,
    required this.titulo,
    required this.emoji,
    required this.builder,
    this.builderDesde,
  });
  //si existe builderDesde lo usa, si no arranca desde 0
  Widget builderConPaso(int paso) {
    return builderDesde != null ? builderDesde!(paso) : builder();
  }
}

class MapaLeccionesScreen extends StatefulWidget {
  final String moduloTitulo;
  final List<LeccionMapa> lecciones;

  const MapaLeccionesScreen({
    super.key,
    required this.moduloTitulo,
    required this.lecciones,
  });

  @override
  State<MapaLeccionesScreen> createState() => _MapaLeccionesScreenState();
}

class _MapaLeccionesScreenState extends State<MapaLeccionesScreen> {
  // Para cada leccionId guarda si está completada
  Map<String, bool> _completadas = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
  }

  Future<void> _cargarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');

    if (userId != null) {
      final progreso = await ApiService.obtenerProgreso(userId);
      final lista = progreso?['progreso'] as List<dynamic>? ?? [];
    
      final Map<String, bool> map = {};
      for (var item in lista) {
        map[item['leccionId']] = item['completada'] ?? false;
      }
      if (mounted) setState(() { _completadas = map; _cargando = false; });
    } else {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Una lección está desbloqueada si es la primera, 
  // o si la anterior ya está completada
  bool _estaDesbloqueada(int index) {
    if (index == 0) return true;
    final idAnterior = widget.lecciones[index - 1].leccionId;
    return _completadas[idAnterior] == true;
  }

  String _estadoLeccion(int index) {
    final id = widget.lecciones[index].leccionId;
    if (_completadas[id] == true) return 'completada';
    if (_estaDesbloqueada(index)) return 'disponible';
    return 'bloqueada';
  }

  Future<void> _abrirLeccion(int index) async {
  final estado = _estadoLeccion(index);
  final leccion = widget.lecciones[index];

  if (estado == 'bloqueada') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔒 Completa la lección anterior primero'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF534AB7),
      ),
    );
    return;
  }

  // Busca el progreso guardado para esta lección específica
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('usuario_id');
  int pasoGuardado = -1;

  if (userId != null) {
    final progreso = await ApiService.obtenerProgreso(userId);
    final lista = progreso?['progreso'] as List<dynamic>? ?? [];
    final item = lista.firstWhere(
      (p) => p['leccionId'] == leccion.leccionId,
      orElse: () => null,
    );
    pasoGuardado = item?['paso'] ?? -1;
  }

  if (!mounted) return;

  // Caso 1: ya completada → ofrecer practicar de nuevo
  if (estado == 'completada') {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 ¡Ya completaste esta lección!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: const Text('¿Quieres practicar de nuevo?',
            style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF9999BB), fontSize: 15)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => leccion.builder(),
              ));
              _cargarProgreso();
            },
            child: const Text('Practicar de nuevo 🚀',
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );
    return;
  }

  // Caso 2: a medias → continuar o empezar de nuevo
  if (pasoGuardado > 0) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('👋 ¡Bienvenido de vuelta!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text(
            'Quedaste en el paso ${pasoGuardado + 1}.\n¿Qué quieres hacer?',
            style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => leccion.builder(),
              ));
              _cargarProgreso();
            },
            child: const Text('Empezar de nuevo',
                style: TextStyle(color: Color(0xFF9999BB), fontSize: 15)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => leccion.builderConPaso(pasoGuardado),
              ));
              _cargarProgreso();
            },
            child: const Text('Continuar 🚀',
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );
    return;
  }

  // Caso 3: sin progreso → entra directo
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => leccion.builder()),
  );
  _cargarProgreso();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EFFE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF534AB7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.moduloTitulo,
          style: const TextStyle(
            color: Color(0xFF3C3489),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7F77DD)))
          : _buildMapa(),
    );
  }

  Widget _buildMapa() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Text(
            'Tu camino de aprendizaje',
            style: TextStyle(
              color: Color(0xFF7F77DD),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(widget.lecciones.length, (i) {
            return _buildNodoConConector(i);
          }),
          const SizedBox(height: 16),
          _buildTrofeo(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNodoConConector(int index) {
    // Alterna izquierda/derecha como Duolingo
    final bool isLeft = index.isEven;
    final estado = _estadoLeccion(index);
    final leccion = widget.lecciones[index];

    return Column(
      children: [
        // El nodo en sí
        Row(
          mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: isLeft ? 40 : 0,
                right: isLeft ? 0 : 40,
              ),
              child: GestureDetector(
                onTap: () => _abrirLeccion(index),
                child: _buildNodo(leccion, estado, index),
              ),
            ),
          ],
        ),
        // Conector hacia el siguiente nodo
        if (index < widget.lecciones.length - 1)
          _buildConector(isLeft, estado),
      ],
    );
  }

  Widget _buildNodo(LeccionMapa leccion, String estado, int index) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    Color subColor;

    switch (estado) {
      case 'completada':
        bgColor = const Color(0xFFEEEDFE);
        borderColor = const Color(0xFFAFA9EC);
        textColor = const Color(0xFF3C3489);
        subColor = const Color(0xFF534AB7);
        break;
      case 'disponible':
        bgColor = const Color(0xFF7F77DD);
        borderColor = const Color(0xFF534AB7);
        textColor = Colors.white;
        subColor = Colors.white70;
        break;
      default: // bloqueada
        bgColor = Colors.white;
        borderColor = const Color(0xFFD3D1C7);
        textColor = const Color(0xFF888780);
        subColor = const Color(0xFFB4B2A9);
    }

    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: estado == 'disponible'
            ? [BoxShadow(color: const Color(0xFF7F77DD).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Row(
        children: [
          // Círculo con emoji
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: estado == 'disponible'
                  ? Colors.white.withOpacity(0.2)
                  : estado == 'completada'
                      ? const Color(0xFFAFA9EC)
                      : const Color(0xFFF1EFE8),
            ),
            child: Center(
              child: estado == 'bloqueada'
                  ? const Icon(Icons.lock, color: Color(0xFFB4B2A9), size: 22)
                  : Text(leccion.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leccion.titulo,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  estado == 'completada' ? '✓ Completada' : estado == 'disponible' ? '¡Disponible!' : 'Bloqueada',
                  style: TextStyle(color: subColor, fontSize: 11),
                ),
              ],
            ),
          ),
          if (estado == 'completada')
            const Icon(Icons.check_circle, color: Color(0xFF534AB7), size: 20),
          if (estado == 'disponible')
            const Icon(Icons.play_circle_filled, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildConector(bool isLeft, String estadoActual) {
    // Si la lección actual está completada, el conector es morado
    final bool activo = estadoActual == 'completada';
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: CustomPaint(
        painter: _ConectorPainter(isLeft: isLeft, activo: activo),
      ),
    );
  }

  Widget _buildTrofeo() {
    final bool moduloCompleto = widget.lecciones
        .every((l) => _completadas[l.leccionId] == true);

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: moduloCompleto ? const Color(0xFFFAEEDA) : Colors.white,
            border: Border.all(
              color: moduloCompleto ? const Color(0xFFEF9F27) : const Color(0xFFD3D1C7),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '🏆',
              style: TextStyle(
                fontSize: 28,
                color: moduloCompleto ? null : const Color(0xFFB4B2A9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          moduloCompleto ? '¡Módulo completado!' : 'Completa el módulo',
          style: TextStyle(
            color: moduloCompleto ? const Color(0xFF854F0B) : const Color(0xFFB4B2A9),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// Dibuja la curva que conecta dos nodos
class _ConectorPainter extends CustomPainter {
  final bool isLeft;
  final bool activo;
  _ConectorPainter({required this.isLeft, required this.activo});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = activo ? const Color(0xFFAFA9EC) : const Color(0xFFD3D1C7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (!activo) {
      paint.strokeWidth = 2;
    }

    final path = Path();
    if (isLeft) {
      // viene de izquierda, va a derecha
      path.moveTo(size.width * 0.35, 0);
      path.quadraticBezierTo(size.width * 0.5, size.height, size.width * 0.65, size.height);
    } else {
      // viene de derecha, va a izquierda
      path.moveTo(size.width * 0.65, 0);
      path.quadraticBezierTo(size.width * 0.5, size.height, size.width * 0.35, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConectorPainter old) => old.activo != activo;
}