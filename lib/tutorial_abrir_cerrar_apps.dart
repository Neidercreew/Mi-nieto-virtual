import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'abrir_cerrar_apps';

class TutorialAbrirCerrarAppsScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialAbrirCerrarAppsScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialAbrirCerrarAppsScreen> createState() =>
      _TutorialAbrirCerrarAppsScreenState();
}

class _TutorialAbrirCerrarAppsScreenState
    extends State<TutorialAbrirCerrarAppsScreen>
    with TickerProviderStateMixin {
  int _pasoActual = 0;
  bool _mostrarFelicitacion = false;

  late AnimationController _flechaController;
  late Animation<double> _flechaAnimation;

  late AnimationController _pulsoController;
  late Animation<double> _pulsoAnimation;

  late AnimationController _aperturaController;
  late Animation<double> _aperturaAnimation;

  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Abriendo y cerrando\naplicaciones 📲',
      'instruccion': 'Ya sabes reconocer los íconos.\n\nHoy vas a usarlos por primera vez — ¡y vas a ver que es muy fácil!',
      'icono': Icons.touch_app_rounded,
      'colorIcono': const Color(0xFF6B4EFF),
    },
    {
      'tipo': 'analogia',
      'titulo': '¿Qué es abrir\nuna app? 🏪',
      'instruccion': 'Abrir una app es como entrar a una tienda en un centro comercial.\n\nPuedes entrar, mirar, y salir cuando quieras.\n\n¡El celular nunca se daña por explorar!',
      'icono': Icons.storefront_rounded,
      'colorIcono': const Color(0xFF8B5CF6),
    },
    {
      'tipo': 'pantalla_iconos',
      'titulo': 'Busca este ícono\nen tu celular 📷',
      'instruccion': 'Este es el ícono de la Cámara.\n\nObserva dónde está — ahora lo vas a tocar en tu celular real.',
      'iconoResaltado': 'Cámara',
      'colorIcono': const Color(0xFF8B5CF6),
    },
    {
      'tipo': 'accion',
      'titulo': 'PRÁCTICA 1\nAbre la Cámara 📷',
      'instruccion': 'Busca el ícono de la Cámara en tu celular.\n\nTócalo una vez con el dedo.\n\nEspera a que se abra.',
      'icono': Icons.camera_alt_rounded,
      'colorIcono': const Color(0xFF8B5CF6),
      'confirmacion': '✅ Ya la abrí',
    },
    {
      'tipo': 'app_abierta',
      'titulo': '¡Lo lograste! 🎉',
      'instruccion': '¿Ves la pantalla de la cámara?\n\n¡Entraste a tu primera app!\n\nNo rompiste nada — el celular siempre está bien. 😄',
      'icono': Icons.camera_alt_rounded,
      'colorIcono': const Color(0xFF8B5CF6),
      'nombreApp': 'Cámara',
    },
    {
      'tipo': 'accion',
      'titulo': 'PRÁCTICA 2\nSal con el botón inicio',
      'instruccion': 'Para salir de la Cámara, toca el botón de INICIO ⬤\n\nEs el círculo que está en la barra de abajo de tu celular.\n\n¡Ya lo conoces del módulo anterior!',
      'icono': Icons.circle_outlined,
      'colorIcono': const Color(0xFF6B4EFF),
      'confirmacion': '✅ Ya salí',
    },
    {
      'tipo': 'refuerzo',
      'titulo': '¡Así de fácil! 💪',
      'instruccion': 'Acabas de:\n\n1️⃣ Encontrar una app\n2️⃣ Abrirla\n3️⃣ Salir sin problemas\n\nPuedes hacer esto con CUALQUIER app.\n¡El celular nunca se daña por explorar!',
      'icono': Icons.thumb_up_rounded,
      'colorIcono': const Color(0xFF059669),
    },
    {
      'tipo': 'pantalla_iconos',
      'titulo': 'Ahora este ícono ⚙️',
      'instruccion': 'Este es el ícono de Ajustes — el engranaje.\n\nVamos a abrirlo y a salir, igual que hiciste con la Cámara.',
      'iconoResaltado': 'Ajustes',
      'colorIcono': const Color(0xFF6B4EFF),
    },
    {
      'tipo': 'accion',
      'titulo': 'PRÁCTICA 3\nAbre Ajustes y vuelve ⚙️',
      'instruccion': 'Toca el ícono del engranaje ⚙️ en tu celular.\n\nCuando se abra, toca el botón inicio ⬤ para volver.',
      'icono': Icons.settings_rounded,
      'colorIcono': const Color(0xFF6B4EFF),
      'confirmacion': '✅ Ya lo hice',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 ¿No encuentras\nel ícono?',
      'instruccion': 'Si no ves el ícono en tu pantalla principal, prueba esto:\n\n👉 Desliza el dedo hacia la IZQUIERDA para ver más íconos\n\n👉 O desliza hacia ARRIBA para ver todas las apps',
      'icono': Icons.lightbulb_rounded,
      'colorIcono': const Color(0xFFFFB300),
    },
    {
      'tipo': 'pantalla_iconos',
      'titulo': 'Una más — el Teléfono 📞',
      'instruccion': 'Este es el ícono del Teléfono — el verde con el auricular.\n\nVamos a practicar una última vez.',
      'iconoResaltado': 'Teléfono',
      'colorIcono': const Color(0xFF059669),
    },
    {
      'tipo': 'accion',
      'titulo': 'PRÁCTICA 4\nAbre Teléfono y vuelve 📞',
      'instruccion': 'Toca el ícono del Teléfono 📞 en tu celular.\n\nCuando se abra, toca el botón inicio ⬤ para volver.',
      'icono': Icons.call_rounded,
      'colorIcono': const Color(0xFF059669),
      'confirmacion': '✅ Ya lo hice',
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Eres increíble! 🏆',
      'instruccion': 'Ya sabes abrir y cerrar apps con confianza.\n\nCámara ✅  Ajustes ✅  Teléfono ✅\n\n¡El celular no tiene secretos para ti!',
      'icono': Icons.emoji_events_rounded,
      'colorIcono': const Color(0xFFFFB300),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial;

    _flechaController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _flechaAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _flechaController, curve: Curves.easeInOut),
    );

    _pulsoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulsoAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulsoController, curve: Curves.easeInOut),
    );

    _aperturaController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _aperturaAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _aperturaController, curve: Curves.easeOut),
    );
    _aperturaController.forward();

    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _flechaController.dispose();
    _pulsoController.dispose();
    _aperturaController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _avanzar() async {
    if (_mostrarFelicitacion) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    final esUltimo = _pasoActual == _pasos.length - 1;

    if (userId != null) {
      await ApiService.guardarPaso(userId, _leccionId, _pasoActual + 1, completada: esUltimo);
    }

    if (esUltimo) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final tipo = _pasos[_pasoActual]['tipo'];
    if (tipo == 'accion') {
      setState(() => _mostrarFelicitacion = true);
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      setState(() {
        _mostrarFelicitacion = false;
        _pasoActual++;
      });
    } else {
      setState(() => _pasoActual++);
    }

    if (_pasos[_pasoActual]['tipo'] == 'app_abierta') {
      _aperturaController.reset();
      _aperturaController.forward();
    }

    if (_pasos[_pasoActual]['tipo'] == 'celebracion') {
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_pasoActual];
    return Scaffold(
      backgroundColor: const Color(0xFFF0EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EEFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF6B4EFF)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Abriendo y cerrando apps',
            style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              _buildProgreso(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCajaInstruccion(paso),
              ),
              const SizedBox(height: 16),
              Expanded(child: Center(child: _buildIlustracion(paso))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: _buildBoton(paso),
              ),
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            gravity: 0.1,
            colors: const [Color(0xFF6B4EFF), Color(0xFFFFB300), Color(0xFF059669), Color(0xFF0EA5E9)],
          ),
          if (_mostrarFelicitacion) _buildFelicitacion(),
        ],
      ),
    );
  }

  Widget _buildProgreso() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Text('Paso ${_pasoActual + 1} de ${_pasos.length}',
              style: const TextStyle(color: Color(0xFF6B4EFF), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_pasoActual + 1) / _pasos.length,
              backgroundColor: const Color(0xFFDED8FF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCajaInstruccion(Map<String, dynamic> paso) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF6B4EFF), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(paso['titulo'], textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 8),
          Text(paso['instruccion'], textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildIlustracion(Map<String, dynamic> paso) {
    final tipo = paso['tipo'] as String;
    final icono = paso['icono'] as IconData?;
    final color = paso['colorIcono'] as Color;

    switch (tipo) {
      case 'pantalla_iconos':
        return _buildPantallaIconos(paso['iconoResaltado'] as String, color);
      case 'app_abierta':
        return _buildAppAbierta(paso['nombreApp'] as String, icono!, color);
      case 'celebracion':
        return _buildTrofeo();
      default:
        return Container(
          width: 150, height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.3), width: 3),
          ),
          child: Center(child: Icon(icono, size: 75, color: color)),
        );
    }
  }

  Widget _buildPantallaIconos(String iconoResaltado, Color colorResaltado) {
    final Map<String, Map<String, dynamic>> apps = {
      'Teléfono': {'icono': Icons.call_rounded, 'color': const Color(0xFF059669)},
      'Cámara': {'icono': Icons.camera_alt_rounded, 'color': const Color(0xFF8B5CF6)},
      'Mensajes': {'icono': Icons.chat_bubble_rounded, 'color': const Color(0xFF0EA5E9)},
      'Ajustes': {'icono': Icons.settings_rounded, 'color': const Color(0xFF6B4EFF)},
      'Internet': {'icono': Icons.language_rounded, 'color': const Color(0xFFFFB300)},
      'Galería': {'icono': Icons.photo_rounded, 'color': const Color(0xFFE53E3E)},
    };

    return AnimatedBuilder(
      animation: _flechaAnimation,
      builder: (_, __) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 260,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('10:30', style: TextStyle(color: Colors.white, fontSize: 13)),
                  Row(children: const [
                    Icon(Icons.wifi_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Icon(Icons.battery_full_rounded, color: Colors.white, size: 14),
                  ]),
                ]),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: apps.entries.map((entry) {
                    final esResaltado = entry.key == iconoResaltado;
                    final appColor = entry.value['color'] as Color;
                    return AnimatedBuilder(
                      animation: _pulsoAnimation,
                      builder: (_, __) {
                        return Transform.scale(
                          scale: esResaltado ? _pulsoAnimation.value : 1.0,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: appColor,
                                border: esResaltado ? Border.all(color: Colors.white, width: 3) : null,
                                boxShadow: esResaltado ? [BoxShadow(color: appColor.withOpacity(0.7), blurRadius: 16, spreadRadius: 2)] : null,
                              ),
                              child: Icon(entry.value['icono'] as IconData, color: Colors.white, size: 26),
                            ),
                            const SizedBox(height: 4),
                            Text(entry.key, style: TextStyle(
                              color: esResaltado ? colorResaltado : Colors.white54,
                              fontSize: 9,
                              fontWeight: esResaltado ? FontWeight.bold : FontWeight.normal,
                            )),
                          ]),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  const Icon(Icons.arrow_back_rounded, color: Colors.white54, size: 20),
                  Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white54, width: 1.5))),
                  const Icon(Icons.crop_square_rounded, color: Colors.white54, size: 20),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            Transform.translate(
              offset: Offset(0, _flechaAnimation.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: colorResaltado, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text('Toca $iconoResaltado', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppAbierta(String nombreApp, IconData icono, Color color) {
    return AnimatedBuilder(
      animation: _aperturaAnimation,
      builder: (_, __) {
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Transform.scale(
            scale: _aperturaAnimation.value,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  child: Icon(icono, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(nombreApp, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('App abierta ✓', style: TextStyle(color: color, fontSize: 12)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Opacity(
            opacity: _aperturaAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF059669), width: 1.5),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                SizedBox(width: 8),
                Text('¡No rompiste nada! 😄', style: TextStyle(color: Color(0xFF059669), fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildTrofeo() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 140, height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFAEEDA),
          border: Border.all(color: const Color(0xFFEF9F27), width: 3),
          boxShadow: [BoxShadow(color: const Color(0xFFFFB300).withOpacity(0.4), blurRadius: 20, spreadRadius: 4)],
        ),
        child: const Center(child: Text('🏆', style: TextStyle(fontSize: 70))),
      ),
      const SizedBox(height: 16),
      const Text('¡Ya abres apps con confianza!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF854F0B), fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildBoton(Map<String, dynamic> paso) {
    final tipo = paso['tipo'] as String;
    final esUltimo = _pasoActual == _pasos.length - 1;
    String texto;
    Color color;
    if (esUltimo) {
      texto = '¡Terminé! 🎉';
      color = const Color(0xFF059669);
    } else if (tipo == 'accion') {
      texto = paso['confirmacion'] ?? '✅ Lo hice';
      color = const Color(0xFF059669);
    } else {
      texto = 'Entendido, siguiente →';
      color = const Color(0xFF6B4EFF);
    }
    return GestureDetector(
      onTap: _avanzar,
      child: Container(
        width: double.infinity, height: 60,
        decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Center(child: Text(texto, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildFelicitacion() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40), padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🎉', style: TextStyle(fontSize: 60)),
            SizedBox(height: 16),
            Text('¡Muy bien!', style: TextStyle(color: Color(0xFF059669), fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Lo hiciste perfecto 👏', style: TextStyle(color: Color(0xFF555577), fontSize: 18)),
          ]),
        )),
      ),
    );
  }
}