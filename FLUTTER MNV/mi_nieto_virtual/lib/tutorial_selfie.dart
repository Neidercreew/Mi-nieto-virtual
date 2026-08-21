import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'camara_selfie';

class TutorialSelfieScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialSelfieScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialSelfieScreen> createState() => _TutorialSelfieScreenState();
}

class _TutorialSelfieScreenState extends State<TutorialSelfieScreen>
    with TickerProviderStateMixin {
  int _pasoActual = 0;

  String _camara = 'trasera';
  int _contadorSelfie = 0;
  String _pantalla = 'visor';
  bool _mostrandoFlash = false;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;

  late AnimationController _pulsoController;
  late Animation<double> _pulsoAnimation;
  late AnimationController _voltearController;
  late Animation<double> _voltearAnimation;
  late AnimationController _guardarController;
  late Animation<double> _guardarAnimation;
  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Tomarte una\nselfie 🤳',
      'instruccion':
          'Ya sabes tomar fotos de lo que ves.\n\nAhora vas a aprender a tomarte una foto a TI MISMO. ¡Se llama "selfie"!',
      'icono': Icons.face_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'analogia',
      'titulo': '¿Qué es una\nselfie? 🪞',
      'instruccion':
          'Una selfie es como mirarte en un espejo... pero este espejo guarda la imagen.\n\nTu celular tiene DOS cámaras: una atrás y una adelante que te apunta a ti.',
      'icono': Icons.flip_camera_ios_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'sim_info',
      'titulo': 'Mira la cámara 👀',
      'instruccion':
          'Ahora mismo la cámara ve hacia AFUERA (la florecita).\n\n¿Ves el botón de voltear 🔄 abajo a la derecha? Ese cambia a la cámara que te apunta a ti.',
      'objetivo': null,
      'resalta': 'boton_voltear',
    },
    {
      'tipo': 'sim_voltear',
      'titulo': 'PRÁCTICA 1\nVoltea la cámara 🔄',
      'instruccion':
          'Toca el botón de voltear 🔄 (abajo a la derecha).\n\nVas a ver cómo la cámara cambia y ahora te apunta a TI.',
      'objetivo': 'frontal',
      'resalta': 'boton_voltear',
      'ayuda': 'Toca el botón redondo con las flechas 🔄',
    },
    {
      'tipo': 'sim_info',
      'titulo': '¡Ahí estás tú! 😊',
      'instruccion':
          'Ahora la cámara te ve a ti.\n\nLo que aparece en la pantalla es lo que saldrá en tu selfie.',
      'objetivo': null,
      'resalta': null,
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Para una\nbuena selfie',
      'instruccion':
          '💪 Estira el brazo un poco\n\n👀 Pon la cámara a la altura de tus ojos\n\n😊 Sonríe\n\n☀️ Busca buena luz de frente',
      'icono': Icons.tips_and_updates_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
    {
      'tipo': 'sim_disparar',
      'titulo': 'PRÁCTICA 2\n¡Tómate la selfie! 📸',
      'instruccion':
          'Ya te ves en la pantalla.\n\nToca el botón blanco grande de abajo para tomarte la selfie.',
      'objetivo': 'foto_tomada',
      'resalta': 'boton_captura',
      'ayuda': 'Toca el botón blanco grande del centro',
    },
    {
      'tipo': 'sim_info',
      'titulo': '¡Te ves genial! 🎉',
      'instruccion':
          'Tu selfie quedó guardada en la galería.\n\nAsí de fácil puedes tomarte fotos cuando quieras: en una reunión, con la familia, o solo porque sí.',
      'objetivo': null,
      'resalta': null,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Abre tu cámara real, busca el botón de voltear 🔄, y tómate una selfie.\n\n¡Mándasela a alguien que quieras!',
      'icono': Icons.smartphone_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste! 🏆',
      'instruccion':
          'Ya sabes tomar fotos Y selfies.\n\n¡Eres todo un fotógrafo! 📸',
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

    _voltearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _voltearAnimation = CurvedAnimation(
      parent: _voltearController,
      curve: Curves.easeInOut,
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
    _voltearController.dispose();
    _guardarController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    switch (paso['tipo']) {
      case 'sim_info':
        if (_pasoActual == 2) {
          _camara = 'trasera';
          _pantalla = 'visor';
        } else if (_pasoActual == 4) {
          _camara = 'frontal';
          _pantalla = 'visor';
        } else if (_pasoActual == 7) {
          _pantalla = 'foto_tomada';
        }
        break;
      case 'sim_voltear':
        _camara = 'trasera';
        _pantalla = 'visor';
        break;
      case 'sim_disparar':
        _camara = 'frontal';
        _pantalla = 'visor';
        break;
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    if (objetivo == 'frontal' && _camara == 'frontal') {
      _objetivoCumplido = true;
    } else if (objetivo == 'foto_tomada' && _pantalla == 'foto_tomada') {
      _objetivoCumplido = true;
    }
  }

  void _tocarEnSimulador(String accion) {
    if (accion == 'boton_voltear' && _pantalla == 'visor') {
      _voltearCamara();
      return;
    }
    if (accion == 'boton_captura' && _pantalla == 'visor') {
      _dispararFoto();
      return;
    }
  }

  Future<void> _voltearCamara() async {
    _voltearController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() {
      _camara = _camara == 'trasera' ? 'frontal' : 'trasera';
      if (_camara == 'frontal') {
        _contadorSelfie++;
      }
      _revisarObjetivo();
    });
  }

  Future<void> _dispararFoto() async {
    setState(() => _mostrandoFlash = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _mostrandoFlash = false);

    setState(() => _pantalla = 'foto_tomada');
    _guardarController.forward(from: 0);

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
        title: const Text('Tomarte una selfie',
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
      case 'sim_info':
      case 'sim_voltear':
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
              child: _pantalla == 'foto_tomada'
                  ? _buildFotoTomada()
                  : _buildVisorCompleto(resalta),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisorCompleto(String? resalta) {
    return Stack(
      children: [
        Positioned.fill(child: _buildContenidoVisor()),
        if (_mostrandoFlash)
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.85)),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.black.withOpacity(0.25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Icon(Icons.flash_off_rounded, color: Colors.white, size: 20),
                Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                Icon(Icons.settings_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 92,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chipModo('FOTO', activo: true),
              const SizedBox(width: 16),
              _chipModo('VIDEO', activo: false),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: Colors.black.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white54, width: 1.5),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFBFE3FF), Color(0xFFEAF6E9)],
                    ),
                  ),
                  child: const Center(
                      child: Text('🌸', style: TextStyle(fontSize: 20))),
                ),
                _botonCaptura(resalta == 'boton_captura'),
                _botonVoltear(resalta == 'boton_voltear'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContenidoVisor() {
    return AnimatedBuilder(
      animation: _voltearAnimation,
      builder: (_, __) {
        final giro = (_voltearAnimation.value * 3.14159);
        final escalaX = (giro < 1.57)
            ? (1 - _voltearAnimation.value * 2).abs()
            : (_voltearAnimation.value * 2 - 1).abs();

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(escalaX.clamp(0.05, 1.0), 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: _camara == 'trasera'
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFBFE3FF), Color(0xFFEAF6E9)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFE9D6), Color(0xFFFFD6E8)],
                    ),
            ),
            child: Center(
              child: _camara == 'trasera'
                  ? const Text('🌸', style: TextStyle(fontSize: 64))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_contadorSelfie.isEven ? '👵' : '👴',
                            style: const TextStyle(fontSize: 72)),
                        const SizedBox(height: 6),
                        const Text('¡Ese eres tú! 😊',
                            style: TextStyle(
                                color: Color(0xFF854F0B),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _chipModo(String texto, {required bool activo}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFFFB300) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(texto,
          style: TextStyle(
              color: activo ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: activo ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Widget _botonCaptura(bool resaltado) {
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        return Transform.scale(
          scale: resaltado ? _pulsoAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador('boton_captura'),
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                    color: resaltado
                        ? const Color(0xFF8B5CF6)
                        : Colors.white54,
                    width: 4),
                boxShadow: resaltado
                    ? [
                        BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.7),
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
    );
  }

  Widget _botonVoltear(bool resaltado) {
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        return Transform.scale(
          scale: resaltado ? _pulsoAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador('boton_voltear'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: resaltado
                    ? const Color(0xFF8B5CF6)
                    : Colors.white.withOpacity(0.2),
                border: resaltado
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
                boxShadow: resaltado
                    ? [
                        BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.7),
                            blurRadius: 16,
                            spreadRadius: 1)
                      ]
                    : null,
              ),
              child: const Icon(Icons.flip_camera_ios_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFotoTomada() {
    return AnimatedBuilder(
      animation: _guardarAnimation,
      builder: (_, __) {
        final escala = 1.0 - (_guardarAnimation.value * 0.55);
        final moverX = -_guardarAnimation.value * 70;
        final moverY = _guardarAnimation.value * 120;

        return Container(
          color: const Color(0xFF111122),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: const Color(0xFF059669),
                        size: 40 + _guardarAnimation.value * 8),
                    const SizedBox(height: 8),
                    const Text('¡Selfie guardada!',
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
                          colors: [Color(0xFFFFE9D6), Color(0xFFFFD6E8)],
                        ),
                      ),
                      child: Center(
                        child: Text(_contadorSelfie.isEven ? '👵' : '👴',
                            style: const TextStyle(fontSize: 54)),
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
              child: Text('🤳', style: TextStyle(fontSize: 60))),
        ),
        const SizedBox(height: 16),
        const Text('¡Ya sabes tomar selfies!',
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
    final esSimulador = (tipo == 'sim_voltear' || tipo == 'sim_disparar');

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