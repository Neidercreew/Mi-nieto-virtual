import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'camara_tomar_foto';

class TutorialTomarFotoScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialTomarFotoScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialTomarFotoScreen> createState() =>
      _TutorialTomarFotoScreenState();
}

class _TutorialTomarFotoScreenState extends State<TutorialTomarFotoScreen>
    with TickerProviderStateMixin {
  int _pasoActual = 0;

  // ─────────────────────────────────────────────────────────
  // ESTADO DEL SIMULADOR DE CAMARA
  // inicio -> visor -> (flash) -> foto_tomada -> galeria
  // ─────────────────────────────────────────────────────────
  String _pantalla = 'inicio';
  bool _objetivoCumplido = false;
  String? _mensajeGuia;

  // Controla el destello del flash al tomar la foto
  bool _mostrandoFlash = false;

  late AnimationController _pulsoController;
  late Animation<double> _pulsoAnimation;

  // Anima la foto encogiendose hacia la esquina (como al guardarse)
  late AnimationController _guardarController;
  late Animation<double> _guardarAnimation;

  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _pasos = [
    // ── INTRO ─────────────────────────────────────────────
    {
      'tipo': 'intro',
      'titulo': 'Tu primera\nfoto 📷',
      'instruccion':
          'Hoy vas a aprender a tomar fotos con tu celular.\n\nPracticaremos aquí primero, con una cámara de mentiras. ¡Sin miedo a equivocarte!',
      'icono': Icons.camera_alt_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'analogia',
      'titulo': '¿Qué es la\ncámara? 📸',
      'instruccion':
          'La cámara de tu celular es como una cámara de fotos de las de antes.\n\nPero esta la llevas SIEMPRE contigo, y las fotos quedan guardadas dentro del celular.',
      'icono': Icons.photo_camera_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },

    // ── SIMULADOR: ABRIR LA CAMARA ────────────────────────
    {
      'tipo': 'sim_abrir',
      'titulo': 'PRÁCTICA 1\nAbre la cámara 📷',
      'instruccion':
          'Este es un celular de práctica.\n\nBusca el ícono de la cámara y tócalo para abrirla.',
      'objetivo': 'visor',
      'resalta': 'icono_camara',
      'ayuda': 'Toca el ícono morado de la cámara 📷',
    },

    // ── SIMULADOR: CONOCER EL VISOR ───────────────────────
    {
      'tipo': 'sim_info',
      'titulo': 'Esto es el visor 👀',
      'instruccion':
          'Lo que ves en la pantalla es lo que va a salir en la foto.\n\n¿Ves la florecita 🌸? Vamos a tomarle una foto.\n\nEl botón blanco grande de abajo es para disparar.',
      'objetivo': null,
      'resalta': 'boton_captura',
    },

    // ── SIMULADOR: TOMAR LA FOTO ──────────────────────────
    {
      'tipo': 'sim_disparar',
      'titulo': 'PRÁCTICA 2\n¡Toma la foto! 📸',
      'instruccion':
          'Apunta a la florecita (ya está centrada).\n\nToca el botón blanco grande de abajo para tomar la foto.',
      'objetivo': 'foto_tomada',
      'resalta': 'boton_captura',
      'ayuda': 'Toca el botón blanco grande de abajo',
    },

    // ── SIMULADOR: FOTO TOMADA ────────────────────────────
    {
      'tipo': 'sim_info',
      'titulo': '¡Qué buena foto! 🎉',
      'instruccion':
          'Tomaste tu primera foto.\n\nLa foto se guardó sola en tu celular. No tienes que hacer nada más.',
      'objetivo': null,
      'resalta': null,
    },

    // ── TIP: PULSO FIRME ──────────────────────────────────
    {
      'tipo': 'tip',
      'titulo': '💡 Un consejo',
      'instruccion':
          'Para que la foto no salga borrosa:\n\n✋ Sostén el celular con las dos manos\n\n🧘 Quédate quieto un segundito al disparar\n\n☀️ Busca un lugar con buena luz',
      'icono': Icons.back_hand_rounded,
      'colorIcono': Color(0xFFFFB300),
    },

    // ── ACCION REAL ───────────────────────────────────────
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Ya sabes cómo se hace.\n\nAbre la cámara en tu celular real y toma una foto de algo que te guste: una planta, tu mascota, o lo que quieras.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },

    // ── CELEBRACION ───────────────────────────────────────
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste! 🏆',
      'instruccion':
          'Ya sabes tomar fotos con tu celular.\n\n¡Ahora puedes guardar todos los momentos que quieras!',
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
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulsoAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulsoController, curve: Curves.easeInOut),
    );

    _guardarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _guardarAnimation = CurvedAnimation(
      parent: _guardarController,
      curve: Curves.easeInOut,
    );

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    _prepararPaso();
  }

  @override
  void dispose() {
    _pulsoController.dispose();
    _guardarController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    // Estado del simulador segun el paso
    switch (paso['tipo']) {
      case 'sim_abrir':
        _pantalla = 'inicio';
        break;
      case 'sim_info':
        // El visor si ya tomo foto muestra la foto, sino el visor normal
        if (_pasoActual == 4) {
          _pantalla = 'visor'; // paso "esto es el visor"
        } else {
          _pantalla = 'foto_tomada'; // paso "que buena foto"
        }
        break;
      case 'sim_disparar':
        _pantalla = 'visor';
        break;
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo != null && _pantalla == objetivo) {
      _objetivoCumplido = true;
    }
  }

  // ─────────────────────────────────────────────────────────
  // EL CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────────────────
  void _tocarEnSimulador(String accion) {
    // Abrir la camara desde el inicio
    if (accion == 'icono_camara' && _pantalla == 'inicio') {
      setState(() {
        _pantalla = 'visor';
        _revisarObjetivo();
      });
      return;
    }

    // Disparar la foto (solo funciona en el visor)
    if (accion == 'boton_captura' && _pantalla == 'visor') {
      _dispararFoto();
      return;
    }
  }

  // Secuencia animada de tomar la foto: flash -> guardar -> listo
  Future<void> _dispararFoto() async {
    // 1. Destello de flash
    setState(() => _mostrandoFlash = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _mostrandoFlash = false);

    // 2. La foto aparece y se encoge hacia la esquina
    setState(() => _pantalla = 'foto_tomada');
    _guardarController.forward(from: 0);

    // 3. Marcamos el objetivo cumplido
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _revisarObjetivo());
  }

  Future<void> _avanzar() async {
    if (!_objetivoCumplido) return;

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
        title: const Text('Tomar tu primera foto',
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

    switch (tipo) {
      case 'sim_abrir':
      case 'sim_info':
      case 'sim_disparar':
        return _buildSimuladorCamara(paso['resalta'] as String?);
      case 'celebracion':
        return _buildTrofeo();
      default:
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
  // EL SIMULADOR DE CAMARA
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
        // El celular
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    _buildPantallaCamara(resalta),
                    // Destello de flash encima de todo
                    if (_mostrandoFlash)
                      Positioned.fill(
                        child: Container(color: Colors.white.withOpacity(0.85)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  // Lo que se ve en la pantalla del celular segun el estado
  Widget _buildPantallaCamara(String? resalta) {
    switch (_pantalla) {
      case 'inicio':
        return _buildInicio(resalta);
      case 'visor':
        return _buildVisor(resalta);
      case 'foto_tomada':
        return _buildFotoTomada();
      default:
        return const SizedBox();
    }
  }

  // Pantalla principal con el icono de camara
  Widget _buildInicio(String? resalta) {
    final esResaltado = resalta == 'icono_camara';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulsoAnimation,
          builder: (_, __) {
            return Transform.scale(
              scale: esResaltado ? _pulsoAnimation.value : 1.0,
              child: GestureDetector(
                onTap: () => _tocarEnSimulador('icono_camara'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B5CF6),
                        border: esResaltado
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: esResaltado
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF8B5CF6)
                                        .withOpacity(0.7),
                                    blurRadius: 18,
                                    spreadRadius: 2)
                              ]
                            : null,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 8),
                    const Text('Cámara',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // El visor de la camara con la flor y el boton de captura
  Widget _buildVisor(String? resalta) {
    final esResaltado = resalta == 'boton_captura';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Zona del visor (lo que "ve" la camara)
          Expanded(
            child: Stack(
              children: [
                // Fondo tipo cielo/pared clara
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFBFE3FF), Color(0xFFEAF6E9)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                ),
                // Cuadricula tipo camara
                Positioned.fill(
                  child: CustomPaint(painter: _CuadriculaPainter()),
                ),
                // La flor en el centro (el objeto a fotografiar)
                const Center(
                  child: Text('🌸', style: TextStyle(fontSize: 64)),
                ),
                // Etiqueta arriba
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Apunta a la flor 🌸',
                          style:
                              TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Barra inferior con el boton de captura
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: AnimatedBuilder(
              animation: _pulsoAnimation,
              builder: (_, __) {
                return Transform.scale(
                  scale: esResaltado ? _pulsoAnimation.value : 1.0,
                  child: GestureDetector(
                    onTap: () => _tocarEnSimulador('boton_captura'),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                            color: esResaltado
                                ? const Color(0xFF8B5CF6)
                                : Colors.white54,
                            width: 4),
                        boxShadow: esResaltado
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF8B5CF6)
                                        .withOpacity(0.7),
                                    blurRadius: 18,
                                    spreadRadius: 2)
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Despues de disparar: muestra la foto tomada
  Widget _buildFotoTomada() {
    return AnimatedBuilder(
      animation: _guardarAnimation,
      builder: (_, __) {
        // La foto arranca grande y se encoge hacia la esquina inferior izq
        final escala = 1.0 - (_guardarAnimation.value * 0.55);
        final moverX = -_guardarAnimation.value * 70;
        final moverY = _guardarAnimation.value * 110;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111122),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              // Mensaje de fondo
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: const Color(0xFF059669),
                        size: 40 + _guardarAnimation.value * 8),
                    const SizedBox(height: 8),
                    const Text('¡Foto guardada!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Está en tu galería 🖼️',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              // La foto encogiendose hacia la esquina
              Center(
                child: Transform.translate(
                  offset: Offset(moverX, moverY),
                  child: Transform.scale(
                    scale: escala,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 3),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFBFE3FF), Color(0xFFEAF6E9)],
                        ),
                      ),
                      child: const Center(
                        child: Text('🌸', style: TextStyle(fontSize: 50)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
              child: Text('📸', style: TextStyle(fontSize: 60))),
        ),
        const SizedBox(height: 16),
        const Text('¡Ya sabes tomar fotos!',
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
    final esSimulador = tipo.startsWith('sim_') && tipo != 'sim_info';

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

// Dibuja la cuadricula tipo camara (2 lineas horizontales, 2 verticales)
class _CuadriculaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1;

    // Lineas verticales
    canvas.drawLine(
        Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0),
        Offset(size.width * 2 / 3, size.height), paint);
    // Lineas horizontales
    canvas.drawLine(
        Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3),
        Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}