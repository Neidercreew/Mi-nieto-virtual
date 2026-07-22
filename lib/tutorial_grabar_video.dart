import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'camara_video';

class TutorialGrabarVideoScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialGrabarVideoScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialGrabarVideoScreen> createState() =>
      _TutorialGrabarVideoScreenState();
}

class _TutorialGrabarVideoScreenState extends State<TutorialGrabarVideoScreen>
    with TickerProviderStateMixin {
  int _pasoActual = 0;

  // ─────────────────────────────────────────────────────────
  // ESTADO DEL SIMULADOR
  // modo: 'foto' | 'video'
  // grabacion: 'detenido' | 'grabando' | 'pausado' | 'guardado'
  // reproduciendo: si el adulto le dio play al video guardado
  // ─────────────────────────────────────────────────────────
  String _modo = 'foto';
  String _grabacion = 'detenido';
  bool _reproduciendo = false;

  int _segundos = 0;        // cronometro de grabacion
  Timer? _timer;            // el que cuenta los segundos

  bool _objetivoCumplido = false;
  String? _mensajeGuia;

  late AnimationController _pulsoController;
  late Animation<double> _pulsoAnimation;

  // Anima el perrito (cola/rebote) cuando el video se reproduce
  late AnimationController _perritoController;
  late Animation<double> _perritoAnimation;

  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Grabar un\nvideo 🎥',
      'instruccion':
          'Ya sabes tomar fotos.\n\nHoy vas a aprender a grabar videos: como una foto, pero que guarda el movimiento y el sonido.',
      'icono': Icons.videocam_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'analogia',
      'titulo': '¿Foto o video? 🤔',
      'instruccion':
          'Una FOTO congela un instante.\n\nUn VIDEO graba todo lo que pasa: el movimiento, las voces, los sonidos.\n\nPerfecto para guardar a los nietos jugando o un cumpleaños.',
      'icono': Icons.compare_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'sim_info',
      'titulo': 'Mira aquí abajo 👇',
      'instruccion':
          '¿Ves donde dice FOTO y VIDEO?\n\nAhora está en modo FOTO. Para grabar, primero hay que cambiar a modo VIDEO.',
      'objetivo': null,
      'resalta': 'selector_modo',
    },
    {
      'tipo': 'sim_cambiar_modo',
      'titulo': 'PRÁCTICA 1\nCambia a VIDEO 🎥',
      'instruccion':
          'Toca la palabra VIDEO para cambiar de modo.\n\nVas a ver que el botón de abajo cambia de blanco a ROJO.',
      'objetivo': 'modo_video',
      'resalta': 'chip_video',
      'ayuda': 'Toca la palabra VIDEO',
    },
    {
      'tipo': 'info_control',
      'titulo': 'Tú tienes el control 🎮',
      'instruccion':
          'El botón ROJO es para grabar.\n\nRecuerda esto: TÚ decides cuándo empezar, cuándo pausar, y cuándo parar.\n\nNada pasa sin que tú lo toques.',
      'icono': Icons.touch_app_rounded,
      'colorIcono': Color(0xFFE53E3E),
    },
    {
      'tipo': 'sim_grabar',
      'titulo': 'PRÁCTICA 2\n¡Empieza a grabar! 🔴',
      'instruccion':
          'Toca el botón rojo para empezar a grabar.\n\nVas a ver un reloj que cuenta el tiempo, y el perrito moviéndose.',
      'objetivo': 'grabando',
      'resalta': 'boton_grabar',
      'ayuda': 'Toca el botón rojo grande',
    },
    {
      'tipo': 'sim_pausar',
      'titulo': 'PRÁCTICA 3\nPausa un momento ⏸️',
      'instruccion':
          'Estás grabando (mira el reloj).\n\nAhora toca el botón de PAUSA ⏸️.\n\nEl reloj se detiene, pero NO pierdes lo grabado.',
      'objetivo': 'pausado',
      'resalta': 'boton_pausa',
      'ayuda': 'Toca el botón de pausa ⏸️',
    },
    {
      'tipo': 'sim_reanudar',
      'titulo': 'PRÁCTICA 4\nSigue grabando ▶️',
      'instruccion':
          'La grabación está en pausa.\n\nToca REANUDAR ▶️ para seguir grabando.\n\nEl reloj continúa donde quedó — todo va en el mismo video.',
      'objetivo': 'grabando',
      'resalta': 'boton_reanudar',
      'ayuda': 'Toca el botón de reanudar ▶️',
    },
    {
      'tipo': 'sim_parar',
      'titulo': 'PRÁCTICA 5\nTermina el video ⏹️',
      'instruccion':
          'Cuando ya grabaste lo que querías, toca el botón CUADRADO ROJO ⏹️ para parar.\n\nEsto termina y guarda tu video.',
      'objetivo': 'guardado',
      'resalta': 'boton_parar',
      'ayuda': 'Toca el botón cuadrado rojo ⏹️',
    },
    {
      'tipo': 'sim_reproducir',
      'titulo': 'PRÁCTICA 6\n¡Mira tu video! ▶️',
      'instruccion':
          'Tu video quedó guardado.\n\nToca el botón de play ▶️ para verlo. ¡Mira cómo el perrito se mueve!',
      'objetivo': 'reproducido',
      'resalta': 'boton_play',
      'ayuda': 'Toca el botón de play ▶️ sobre el video',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Un consejo',
      'instruccion':
          'Los videos ocupan más espacio que las fotos.\n\nGraba lo que necesites, sin preocuparte — pero no dejes grabando por horas sin querer.\n\nRevisa de vez en cuando tu espacio (como aprendiste antes).',
      'icono': Icons.sd_storage_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Abre tu cámara, cambia a modo VIDEO, y graba algo cortito: tu mascota, una planta, o salúdate a ti mismo.\n\nLuego búscalo en tu galería y míralo.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste! 🏆',
      'instruccion':
          'Ya sabes grabar videos, pausar, reanudar y verlos.\n\n¡Ahora puedes guardar los momentos con movimiento y sonido! 🎥',
      'icono': Icons.emoji_events_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial.clamp(0, _pasos.length - 1);

    _pulsoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulsoAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulsoController, curve: Curves.easeInOut),
    );

    _perritoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _perritoAnimation = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _perritoController, curve: Curves.easeInOut),
    );

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    _prepararPaso();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulsoController.dispose();
    _perritoController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;
    _reproduciendo = false;
    _perritoController.stop();

    switch (paso['tipo']) {
      case 'sim_info':
        _modo = 'foto';
        _grabacion = 'detenido';
        _segundos = 0;
        break;
      case 'sim_cambiar_modo':
        _modo = 'foto';
        _grabacion = 'detenido';
        _segundos = 0;
        break;
      case 'sim_grabar':
        _modo = 'video';
        _grabacion = 'detenido';
        _segundos = 0;
        break;
      case 'sim_pausar':
        _modo = 'video';
        _grabacion = 'grabando';
        _segundos = 3;
        _iniciarCronometro();
        break;
      case 'sim_reanudar':
        _modo = 'video';
        _grabacion = 'pausado';
        _segundos = 5;
        break;
      case 'sim_parar':
        _modo = 'video';
        _grabacion = 'grabando';
        _segundos = 7;
        _iniciarCronometro();
        break;
      case 'sim_reproducir':
        _modo = 'video';
        _grabacion = 'guardado';
        break;
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;

    bool cumple = false;
    switch (objetivo) {
      case 'modo_video':
        cumple = _modo == 'video';
        break;
      case 'grabando':
        cumple = _grabacion == 'grabando';
        break;
      case 'pausado':
        cumple = _grabacion == 'pausado';
        break;
      case 'guardado':
        cumple = _grabacion == 'guardado';
        break;
      case 'reproducido':
        cumple = _reproduciendo;
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // ─────────────────────────────────────────────────────────
  // EL CRONOMETRO: cuenta 1 segundo cada segundo
  // ─────────────────────────────────────────────────────────
  void _iniciarCronometro() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _segundos++);
    });
  }

  void _detenerCronometro() {
    _timer?.cancel();
    _timer = null;
  }

  // Convierte segundos a formato 00:00
  String _tiempoFormato(int seg) {
    final m = (seg ~/ 60).toString().padLeft(2, '0');
    final s = (seg % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─────────────────────────────────────────────────────────
  // EL CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────────────────
  void _tocarEnSimulador(String accion) {
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'chip_video':
          _modo = 'video';
          break;

        case 'chip_foto':
          if (_grabacion == 'detenido') _modo = 'foto';
          break;

        case 'boton_grabar':
          if (_modo == 'video' && _grabacion == 'detenido') {
            _grabacion = 'grabando';
            _iniciarCronometro();
          }
          break;

        case 'boton_pausa':
          if (_grabacion == 'grabando') {
            _grabacion = 'pausado';
            _detenerCronometro();
          }
          break;

        case 'boton_reanudar':
          if (_grabacion == 'pausado') {
            _grabacion = 'grabando';
            _iniciarCronometro();
          }
          break;

        case 'boton_parar':
          if (_grabacion == 'grabando' || _grabacion == 'pausado') {
            _grabacion = 'guardado';
            _detenerCronometro();
          }
          break;

        case 'boton_play':
          if (_grabacion == 'guardado') {
            _reproduciendo = true;
            _perritoController.repeat(reverse: true);
          }
          break;
      }

      _revisarObjetivo();
    });
  }

  Future<void> _avanzar() async {
    if (!_objetivoCumplido) return;

    _detenerCronometro();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    final esUltimo = _pasoActual == _pasos.length - 1;

    if (userId != null) {
      await ApiService.guardarPaso(
        userId,
        _leccionId,
        _pasoActual + 1,
        completada: esUltimo,
      );
    }

    if (esUltimo) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _pasoActual++;
      _prepararPaso();
    });

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF6B4EFF)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Grabar un video',
            style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              _buildProgreso(),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCajaInstruccion(paso),
              ),
              const SizedBox(height: 12),
              Expanded(child: Center(child: _buildIlustracion(paso))),
              if (_mensajeGuia != null) _buildMensajeGuia(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _buildBoton(paso),
              ),
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            gravity: 0.1,
            colors: const [
              Color(0xFF6B4EFF),
              Color(0xFFFFB300),
              Color(0xFF059669),
              Color(0xFF8B5CF6),
              Color(0xFFE53E3E),
            ],
          ),
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
              style: const TextStyle(
                  color: Color(0xFF6B4EFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_pasoActual + 1) / _pasos.length,
              backgroundColor: const Color(0xFFDED8FF),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4EFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(paso['titulo'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3)),
          const SizedBox(height: 8),
          Text(paso['instruccion'],
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 14,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildMensajeGuia() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_rounded,
              color: Color(0xFFFFB300), size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(_mensajeGuia!,
                style: const TextStyle(
                    color: Color(0xFF854F0B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildIlustracion(Map<String, dynamic> paso) {
    final tipo = paso['tipo'] as String;

    if (tipo.startsWith('sim_')) {
      return _buildSimuladorCamara(paso['resalta'] as String?);
    } else if (tipo == 'celebracion') {
      return _buildTrofeo();
    } else {
      final icono = paso['icono'] as IconData;
      final color = paso['colorIcono'] as Color;
      return Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.3), width: 3),
        ),
        child: Center(child: Icon(icono, size: 70, color: color)),
      );
    }
  }

  // ═════════════════════════════════════════════════════════
  // EL SIMULADOR DE CAMARA DE VIDEO
  // ═════════════════════════════════════════════════════════
  Widget _buildSimuladorCamara(String? resalta) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('📱 Cámara de práctica — toca sin miedo',
              style: TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 340,
              child: _grabacion == 'guardado'
                  ? _buildVideoGuardado(resalta)
                  : _buildVisorVideo(resalta),
            ),
          ),
        ),
      ],
    );
  }

  // El visor mientras grabas
  Widget _buildVisorVideo(String? resalta) {
    return Stack(
      children: [
        // La escena: el perrito
        Positioned.fill(child: _buildEscenaPerrito(moviendose: false)),

        // Barra superior: indicador REC + cronometro
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.black.withOpacity(0.25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_grabacion == 'grabando' || _grabacion == 'pausado') ...[
                  // Punto rojo (parpadea si graba)
                  AnimatedBuilder(
                    animation: _pulsoAnimation,
                    builder: (_, __) => Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _grabacion == 'grabando'
                            ? Color.lerp(const Color(0xFFE53E3E), Colors.white,
                                _grabacion == 'grabando'
                                    ? (_pulsoAnimation.value - 1) * 6
                                    : 0)
                            : Colors.white54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_tiempoFormato(_segundos),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  if (_grabacion == 'pausado')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('EN PAUSA',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ],
            ),
          ),
        ),

        // Selector FOTO / VIDEO (solo cuando esta detenido)
        if (_grabacion == 'detenido')
          Positioned(
            bottom: 92,
            left: 0,
            right: 0,
            child: _buildSelectorModo(resalta),
          ),

        // Mensaje tranquilizador durante grabacion/pausa
        if (_grabacion == 'grabando' || _grabacion == 'pausado')
          Positioned(
            bottom: 92,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _grabacion == 'grabando'
                    ? 'Grabando... toca ⏸️ o ⏹️ cuando quieras'
                    : 'En pausa. Toca ▶️ para seguir',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),

        // Barra inferior con los botones segun el estado
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: Colors.black.withOpacity(0.3),
            child: _buildControlesGrabacion(resalta),
          ),
        ),
      ],
    );
  }

  // Los botones cambian segun el estado de la grabacion
  Widget _buildControlesGrabacion(String? resalta) {
    // Detenido en modo video: boton rojo de grabar
    if (_grabacion == 'detenido') {
      if (_modo == 'foto') {
        // En modo foto, boton blanco (no es el foco de esta leccion)
        return Center(child: _circuloBlanco());
      }
      return Center(child: _botonGrabar(resalta == 'boton_grabar'));
    }

    // Grabando: pausa + parar
    if (_grabacion == 'grabando') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _botonControl(
            id: 'boton_pausa',
            icono: Icons.pause_rounded,
            color: const Color(0xFFFFB300),
            resaltado: resalta == 'boton_pausa',
          ),
          _botonParar(resalta == 'boton_parar'),
          const SizedBox(width: 44), // equilibrio visual
        ],
      );
    }

    // Pausado: reanudar + parar
    if (_grabacion == 'pausado') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _botonControl(
            id: 'boton_reanudar',
            icono: Icons.play_arrow_rounded,
            color: const Color(0xFF059669),
            resaltado: resalta == 'boton_reanudar',
          ),
          _botonParar(resalta == 'boton_parar'),
          const SizedBox(width: 44),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildSelectorModo(String? resalta) {
    final resaltarSelector = resalta == 'selector_modo';
    return Container(
      padding: resaltarSelector
          ? const EdgeInsets.symmetric(vertical: 4)
          : EdgeInsets.zero,
      decoration: resaltarSelector
          ? BoxDecoration(
              border: Border.all(color: const Color(0xFFFFB300), width: 2),
              borderRadius: BorderRadius.circular(20),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _tocarEnSimulador('chip_foto'),
            child: _chipModo('FOTO', activo: _modo == 'foto'),
          ),
          const SizedBox(width: 16),
          AnimatedBuilder(
            animation: _pulsoAnimation,
            builder: (_, __) {
              final resaltarVideo = resalta == 'chip_video';
              return Transform.scale(
                scale: resaltarVideo ? _pulsoAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: () => _tocarEnSimulador('chip_video'),
                  child: _chipModo('VIDEO',
                      activo: _modo == 'video', resaltado: resaltarVideo),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _chipModo(String texto, {required bool activo, bool resaltado = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: activo
            ? (texto == 'VIDEO' ? const Color(0xFFE53E3E) : const Color(0xFFFFB300))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: resaltado ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Text(texto,
          style: TextStyle(
              color: activo ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: activo ? FontWeight.bold : FontWeight.normal)),
    );
  }

  // Boton rojo de empezar a grabar
  Widget _botonGrabar(bool resaltado) {
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        return Transform.scale(
          scale: resaltado ? _pulsoAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador('boton_grabar'),
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                    color: resaltado ? Colors.white : Colors.white54,
                    width: 4),
                boxShadow: resaltado
                    ? [
                        BoxShadow(
                            color: const Color(0xFFE53E3E).withOpacity(0.7),
                            blurRadius: 18,
                            spreadRadius: 2)
                      ]
                    : null,
              ),
              child: Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE53E3E),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Boton cuadrado rojo de parar
  Widget _botonParar(bool resaltado) {
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        return Transform.scale(
          scale: resaltado ? _pulsoAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador('boton_parar'),
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                    color: resaltado ? Colors.white : Colors.white54,
                    width: 4),
                boxShadow: resaltado
                    ? [
                        BoxShadow(
                            color: const Color(0xFFE53E3E).withOpacity(0.7),
                            blurRadius: 18,
                            spreadRadius: 2)
                      ]
                    : null,
              ),
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Botones de pausa / reanudar (mas pequenos, a un lado)
  Widget _botonControl({
    required String id,
    required IconData icono,
    required Color color,
    required bool resaltado,
  }) {
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        return Transform.scale(
          scale: resaltado ? _pulsoAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador(id),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: resaltado
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: resaltado
                    ? [
                        BoxShadow(
                            color: color.withOpacity(0.7),
                            blurRadius: 16,
                            spreadRadius: 1)
                      ]
                    : null,
              ),
              child: Icon(icono, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }

  Widget _circuloBlanco() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white54, width: 4),
      ),
    );
  }

  // La escena del perrito (se mueve si el video se reproduce)
  Widget _buildEscenaPerrito({required bool moviendose}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBFE3FF), Color(0xFFD6F5D6)],
        ),
      ),
      child: Stack(
        children: [
          // Sol
          const Positioned(
            top: 20,
            right: 24,
            child: Text('☀️', style: TextStyle(fontSize: 28)),
          ),
          // Pasto abajo
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF7BC47F),
              ),
            ),
          ),
          // El perrito
          Center(
            child: moviendose
                ? AnimatedBuilder(
                    animation: _perritoAnimation,
                    builder: (_, __) {
                      return Transform.translate(
                        offset: Offset(0, _perritoAnimation.value * 40),
                        child: Transform.rotate(
                          angle: _perritoAnimation.value,
                          child: const Text('🐕',
                              style: TextStyle(fontSize: 70)),
                        ),
                      );
                    },
                  )
                : const Text('🐕', style: TextStyle(fontSize: 70)),
          ),
        ],
      ),
    );
  }

  // Pantalla del video guardado, con boton de play
  Widget _buildVideoGuardado(String? resalta) {
    final esResaltado = resalta == 'boton_play';

    return Stack(
      children: [
        // La escena (se mueve solo si le dio play)
        Positioned.fill(
            child: _buildEscenaPerrito(moviendose: _reproduciendo)),

        // Capa oscura + boton play (solo si NO se esta reproduciendo)
        if (!_reproduciendo)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulsoAnimation,
                  builder: (_, __) {
                    return Transform.scale(
                      scale: esResaltado ? _pulsoAnimation.value : 1.0,
                      child: GestureDetector(
                        onTap: () => _tocarEnSimulador('boton_play'),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.9),
                            boxShadow: esResaltado
                                ? [
                                    BoxShadow(
                                        color: Colors.white.withOpacity(0.8),
                                        blurRadius: 20,
                                        spreadRadius: 3)
                                  ]
                                : null,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Color(0xFF1A1A2E), size: 40),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        // Etiqueta de "tu video" arriba
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black.withOpacity(0.3),
            child: Text(
              _reproduciendo ? '▶️ Reproduciendo tu video' : 'Tu video 🎥',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Barrita de progreso de reproduccion (decorativa)
        if (_reproduciendo)
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    value: null,
                    backgroundColor: Colors.white24,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTrofeo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFAEEDA),
            border: Border.all(color: const Color(0xFFEF9F27), width: 3),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFFFB300).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 4)
            ],
          ),
          child: const Center(
              child: Text('🎥', style: TextStyle(fontSize: 60))),
        ),
        const SizedBox(height: 16),
        const Text('¡Ya sabes grabar videos!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF854F0B),
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBoton(Map<String, dynamic> paso) {
    final tipo = paso['tipo'] as String;
    final esUltimo = _pasoActual == _pasos.length - 1;
    final esSimulador = tipo.startsWith('sim_');

    String texto;
    Color color;

    if (esUltimo) {
      texto = '¡Terminé! 🎉';
      color = const Color(0xFF059669);
    } else if (esSimulador && !_objetivoCumplido) {
      texto = paso['ayuda'] as String? ?? 'Practica en la cámara de arriba';
      color = const Color(0xFFBBBBCC);
    } else if (esSimulador) {
      texto = '¡Lo lograste! Siguiente →';
      color = const Color(0xFF059669);
    } else if (tipo == 'accion_real') {
      texto = 'Ya practiqué, siguiente →';
      color = const Color(0xFF6B4EFF);
    } else {
      texto = 'Entendido, siguiente →';
      color = const Color(0xFF6B4EFF);
    }

    final habilitado = !esSimulador || _objetivoCumplido;

    return GestureDetector(
      onTap: habilitado ? _avanzar : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: habilitado
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5))
                ]
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}