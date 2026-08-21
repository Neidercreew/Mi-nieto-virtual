import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'camara_galeria';

class TutorialGaleriaScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialGaleriaScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialGaleriaScreen> createState() => _TutorialGaleriaScreenState();
}

// Cada foto/video de la galeria de practica
class _Media {
  final String emoji;
  final List<Color> fondo;
  final bool esVideo;
  const _Media(this.emoji, this.fondo, {this.esVideo = false});
}

class _TutorialGaleriaScreenState extends State<TutorialGaleriaScreen>
    with TickerProviderStateMixin {
  int _pasoActual = 0;

  // ─────────────────────────────────────────────────────────
  // ESTADO DEL SIMULADOR
  // inicio  -> pantalla con icono galeria
  // grilla  -> las fotos en cuadritos
  // grande  -> una foto abierta en grande (con desliz)
  // ─────────────────────────────────────────────────────────
  String _pantalla = 'inicio';
  int _fotoAbierta = 0;      // cual foto se ve en grande
  bool _reproduciendo = false;
  bool _yaDeslizo = false;   // para el objetivo de "desliza"

  bool _objetivoCumplido = false;
  String? _mensajeGuia;

  late final PageController _pageController;

  late AnimationController _pulsoController;
  late Animation<double> _pulsoAnimation;

  late AnimationController _abrirController;
  late Animation<double> _abrirAnimation;

  // Perrito del video en reproduccion
  late AnimationController _perritoController;
  late Animation<double> _perritoAnimation;

  late ConfettiController _confettiController;

  // Las 3 piezas de la galeria de practica
  final List<_Media> _medios = const [
    _Media('🌸', [Color(0xFFBFE3FF), Color(0xFFEAF6E9)]),
    _Media('👵', [Color(0xFFFFE9D6), Color(0xFFFFD6E8)]),
    _Media('🐕', [Color(0xFFBFE3FF), Color(0xFFD6F5D6)], esVideo: true),
  ];

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Ver tus fotos\ny videos 🖼️',
      'instruccion':
          'Ya tomaste fotos, selfies y videos.\n\n¿Dónde quedaron guardados? Hoy vas a aprender a encontrarlos y verlos.',
      'icono': Icons.photo_library_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'analogia',
      'titulo': '¿Qué es la\ngalería? 📚',
      'instruccion':
          'La galería es como un álbum de fotos, pero dentro de tu celular.\n\nTODO lo que capturas con la cámara se guarda ahí solito.',
      'icono': Icons.collections_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'sim_abrir',
      'titulo': 'PRÁCTICA 1\nAbre la galería 🖼️',
      'instruccion':
          'Este es un celular de práctica.\n\nBusca el ícono de la galería (parece una fotico) y tócalo.',
      'objetivo': 'grilla',
      'resalta': 'icono_galeria',
      'ayuda': 'Toca el ícono de la galería 🖼️',
    },
    {
      'tipo': 'sim_info',
      'titulo': '¡Ahí están! 🎉',
      'instruccion':
          'Cada cuadrito es una foto o un video que tomaste.\n\n¿Ves la flor, tu selfie, y el video del perrito? El video tiene un ▶️.',
      'objetivo': null,
      'resalta': null,
    },
    {
      'tipo': 'sim_abrir_foto',
      'titulo': 'PRÁCTICA 2\nAbre una foto 👆',
      'instruccion':
          'Toca la foto de la flor 🌸 para verla en grande.',
      'objetivo': 'grande',
      'resalta': 'foto_0',
      'ayuda': 'Toca la foto de la flor 🌸',
    },
    {
      'tipo': 'sim_deslizar',
      'titulo': 'PRÁCTICA 3\nDesliza para ver más 👉',
      'instruccion':
          'Desliza con el dedo hacia la IZQUIERDA para pasar a la siguiente foto.\n\n¡Es el mismo movimiento que ya conoces!',
      'objetivo': 'deslizo',
      'resalta': null,
      'ayuda': 'Desliza la foto hacia la izquierda 👈',
    },
    {
      'tipo': 'sim_info',
      'titulo': 'Así de fácil 👏',
      'instruccion':
          'Puedes ver todas tus fotos, una por una, deslizando.\n\nHacia la izquierda para avanzar, hacia la derecha para volver.',
      'objetivo': null,
      'resalta': null,
    },
    {
      'tipo': 'sim_video',
      'titulo': 'PRÁCTICA 4\nReproduce el video ▶️',
      'instruccion':
          'Desliza hasta el video del perrito 🐕 (tiene un ▶️).\n\nToca el botón de play para verlo moverse.',
      'objetivo': 'reproducido',
      'resalta': 'boton_play',
      'ayuda': 'Desliza hasta el perrito y toca ▶️',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Para volver',
      'instruccion':
          'Cuando quieras volver a ver todas las fotos juntas, toca el botón de ATRÁS ⬅️ de tu celular.\n\nSiempre puedes volver sin perder nada.',
      'icono': Icons.arrow_back_rounded,
      'colorIcono': Color(0xFF0EA5E9),
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Abre la galería en tu celular real.\n\nMira las fotos que has tomado, toca una para verla grande, y desliza para ver las demás.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste! 🏆',
      'instruccion':
          'Ya sabes encontrar y ver tus fotos y videos.\n\n¡Todos tus recuerdos están a un toque de distancia! 🖼️',
      'icono': Icons.emoji_events_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial.clamp(0, _pasos.length - 1);
    _pageController = PageController();

    _pulsoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulsoAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulsoController, curve: Curves.easeInOut),
    );

    _abrirController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _abrirAnimation = CurvedAnimation(
      parent: _abrirController,
      curve: Curves.easeOut,
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
    _pageController.dispose();
    _pulsoController.dispose();
    _abrirController.dispose();
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
      case 'sim_abrir':
        _pantalla = 'inicio';
        break;
      case 'sim_info':
        // paso 3 (ahi estan) muestra grilla; paso 6 muestra grande
        if (_pasoActual == 3) {
          _pantalla = 'grilla';
        } else {
          _pantalla = 'grande';
        }
        break;
      case 'sim_abrir_foto':
        _pantalla = 'grilla';
        break;
      case 'sim_deslizar':
        _pantalla = 'grande';
        _fotoAbierta = 0;
        _yaDeslizo = false;
        // reposiciona el PageView al inicio
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
        break;
      case 'sim_video':
        _pantalla = 'grande';
        _fotoAbierta = 2; // el video
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(2);
          }
        });
        break;
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'grilla':
        cumple = _pantalla == 'grilla';
        break;
      case 'grande':
        cumple = _pantalla == 'grande';
        break;
      case 'deslizo':
        cumple = _yaDeslizo;
        break;
      case 'reproducido':
        cumple = _reproduciendo;
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // ─────────────────────────────────────────────────────────
  // EL CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────────────────
  void _tocarEnSimulador(String accion) {
    setState(() {
      _mensajeGuia = null;

      if (accion == 'icono_galeria' && _pantalla == 'inicio') {
        _pantalla = 'grilla';
      } else if (accion.startsWith('foto_') && _pantalla == 'grilla') {
        final idx = int.parse(accion.split('_')[1]);
        _fotoAbierta = idx;
        _pantalla = 'grande';
        _abrirController.forward(from: 0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(idx);
          }
        });
      } else if (accion == 'boton_play' &&
          _pantalla == 'grande' &&
          _medios[_fotoAbierta].esVideo) {
        _reproduciendo = true;
        _perritoController.repeat(reverse: true);
      }

      _revisarObjetivo();
    });
  }

  // Cuando el adulto desliza en el PageView
  void _alDeslizar(int nuevaPagina) {
    setState(() {
      _fotoAbierta = nuevaPagina;
      _reproduciendo = false;
      _perritoController.stop();
      if (nuevaPagina != 0) _yaDeslizo = true;
      _revisarObjetivo();
    });
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
        title: const Text('Ver tus fotos y videos',
            style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 17,
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

    if (tipo.startsWith('sim_')) {
      return _buildSimulador(paso['resalta'] as String?);
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
  // EL SIMULADOR DE GALERIA
  // ═════════════════════════════════════════════════════════
  Widget _buildSimulador(String? resalta) {
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
          child: const Text('📱 Galería de práctica — toca sin miedo',
              style: TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
        Container(
          width: 250,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 330,
              child: _buildPantallaSim(resalta),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPantallaSim(String? resalta) {
    switch (_pantalla) {
      case 'inicio':
        return _buildInicio(resalta);
      case 'grilla':
        return _buildGrilla(resalta);
      case 'grande':
        return _buildFotoGrande(resalta);
      default:
        return const SizedBox();
    }
  }

  // Pantalla con el icono de la galeria
  Widget _buildInicio(String? resalta) {
    final esResaltado = resalta == 'icono_galeria';
    return Container(
      color: const Color(0xFF111122),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulsoAnimation,
          builder: (_, __) {
            return Transform.scale(
              scale: esResaltado ? _pulsoAnimation.value : 1.0,
              child: GestureDetector(
                onTap: () => _tocarEnSimulador('icono_galeria'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB300), Color(0xFFE53E3E)],
                        ),
                        border: esResaltado
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: esResaltado
                            ? [
                                BoxShadow(
                                    color: const Color(0xFFFFB300)
                                        .withOpacity(0.7),
                                    blurRadius: 18,
                                    spreadRadius: 2)
                              ]
                            : null,
                      ),
                      child: const Icon(Icons.photo_library_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 8),
                    const Text('Galería',
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

  // La cuadricula de fotos
  Widget _buildGrilla(String? resalta) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            width: double.infinity,
            color: const Color(0xFFF1F3F4),
            child: const Center(
              child: Text('Galería',
                  style: TextStyle(
                      color: Color(0xFF202124),
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          // La cuadricula
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _medios.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, i) {
                  final esResaltado = resalta == 'foto_$i';
                  final media = _medios[i];
                  return AnimatedBuilder(
                    animation: _pulsoAnimation,
                    builder: (_, __) {
                      return Transform.scale(
                        scale: esResaltado ? _pulsoAnimation.value : 1.0,
                        child: GestureDetector(
                          onTap: () => _tocarEnSimulador('foto_$i'),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: media.fondo,
                              ),
                              border: esResaltado
                                  ? Border.all(
                                      color: const Color(0xFF8B5CF6),
                                      width: 3)
                                  : Border.all(
                                      color: const Color(0xFFDADCE0)),
                              boxShadow: esResaltado
                                  ? [
                                      BoxShadow(
                                          color: const Color(0xFF8B5CF6)
                                              .withOpacity(0.5),
                                          blurRadius: 12)
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                Center(
                                    child: Text(media.emoji,
                                        style:
                                            const TextStyle(fontSize: 40))),
                                // Marca de video
                                if (media.esVideo)
                                  Center(
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withOpacity(0.4),
                                      ),
                                      child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 20),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Una foto abierta en grande, con desliz entre fotos
  Widget _buildFotoGrande(String? resalta) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // PageView para deslizar entre fotos
          PageView.builder(
            controller: _pageController,
            itemCount: _medios.length,
            onPageChanged: _alDeslizar,
            itemBuilder: (context, i) {
              final media = _medios[i];
              final estaReproduciendo = _reproduciendo && i == _fotoAbierta;
              return _buildVistaMedia(media, estaReproduciendo,
                  resalta == 'boton_play' && i == _fotoAbierta);
            },
          ),

          // Indicador de cual foto es (puntos abajo)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_medios.length, (i) {
                final activo = i == _fotoAbierta;
                return Container(
                  width: activo ? 10 : 7,
                  height: activo ? 10 : 7,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activo ? Colors.white : Colors.white38,
                  ),
                );
              }),
            ),
          ),

          // Pista de "desliza" (mano animada) en el paso de deslizar
          if (_pasos[_pasoActual]['tipo'] == 'sim_deslizar' && !_yaDeslizo)
            Positioned(
              bottom: 40,
              right: 20,
              child: AnimatedBuilder(
                animation: _pulsoAnimation,
                builder: (_, __) {
                  return Transform.translate(
                    offset: Offset(-(_pulsoAnimation.value - 1) * 60, 0),
                    child: const Text('👈', style: TextStyle(fontSize: 32)),
                  );
                },
              ),
            ),

          // Contador arriba
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_fotoAbierta + 1} de ${_medios.length}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // La vista de una foto o video en grande
  Widget _buildVistaMedia(_Media media, bool reproduciendo, bool resaltarPlay) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: media.fondo,
        ),
      ),
      child: Stack(
        children: [
          // Contenido
          Center(
            child: media.esVideo && reproduciendo
                ? AnimatedBuilder(
                    animation: _perritoAnimation,
                    builder: (_, __) {
                      return Transform.translate(
                        offset: Offset(0, _perritoAnimation.value * 40),
                        child: Transform.rotate(
                          angle: _perritoAnimation.value,
                          child: Text(media.emoji,
                              style: const TextStyle(fontSize: 90)),
                        ),
                      );
                    },
                  )
                : Text(media.emoji, style: const TextStyle(fontSize: 90)),
          ),

          // Boton de play para el video (si no se esta reproduciendo)
          if (media.esVideo && !reproduciendo)
            Center(
              child: AnimatedBuilder(
                animation: _pulsoAnimation,
                builder: (_, __) {
                  return Transform.scale(
                    scale: resaltarPlay ? _pulsoAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: () => _tocarEnSimulador('boton_play'),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9),
                          boxShadow: resaltarPlay
                              ? [
                                  BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 20,
                                      spreadRadius: 3)
                                ]
                              : null,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Color(0xFF1A1A2E), size: 38),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Etiqueta "video" arriba
          if (media.esVideo)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    reproduciendo ? '▶️ Reproduciendo' : '🎥 Video',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
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
              child: Text('🖼️', style: TextStyle(fontSize: 60))),
        ),
        const SizedBox(height: 16),
        const Text('¡Ya encuentras tus recuerdos!',
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
      texto = paso['ayuda'] as String? ?? 'Practica en la galería de arriba';
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