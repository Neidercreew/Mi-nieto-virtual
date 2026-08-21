import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'cambiando_apps';

class TutorialCambiandoAppsScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialCambiandoAppsScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialCambiandoAppsScreen> createState() =>
      _TutorialCambiandoAppsScreenState();
}

class _TutorialCambiandoAppsScreenState
    extends State<TutorialCambiandoAppsScreen>
    with TickerProviderStateMixin {
  int _pasoActual = 0;

  // Estado del celular simulado
  String _pantalla = 'inicio';
  final List<String> _appsAbiertas = [];
  bool _objetivoCumplido = false;
  String? _mensajeGuia;

  late AnimationController _pulsoController;
  late Animation<double> _pulsoAnimation;
  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Dos apps al mismo\ntiempo 🔄',
      'instruccion':
          'Ya sabes abrir una app y salir de ella.\n\nHoy vas a aprender algo nuevo: tener DOS apps abiertas y saltar entre ellas sin perder nada.',
      'icono': Icons.swap_horiz_rounded,
      'colorIcono': Color(0xFF6B4EFF),
    },
    {
      'tipo': 'analogia',
      'titulo': '¿Cómo funciona? 📖',
      'instruccion':
          'Es como dejar un libro abierto boca abajo mientras contestas el teléfono.\n\nCuando vuelves al libro, sigues en la misma página. No perdiste nada.',
      'icono': Icons.menu_book_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'analogia',
      'titulo': '¿Te ha pasado? 🤔',
      'instruccion':
          'Muchas personas salen de una app y luego no saben cómo volver a lo que estaban haciendo.\n\nHoy eso se acaba. Vas a practicar aquí mismo, sin salir de esta app.',
      'icono': Icons.help_outline_rounded,
      'colorIcono': Color(0xFF0EA5E9),
    },
    {
      'tipo': 'simulador',
      'titulo': 'PRÁCTICA 1\nAbre Ajustes ⚙️',
      'instruccion':
          'Este es un celular de práctica. Es de mentiras, así que puedes tocar sin miedo.\n\nToca el ícono de Ajustes ⚙️',
      'objetivo': 'ajustes',
      'resalta': 'icono_ajustes',
      'ayuda': 'Toca el engranaje ⚙️ de la pantalla',
    },
    {
      'tipo': 'simulador',
      'titulo': 'PRÁCTICA 2\nToca el botón ▢',
      'instruccion':
          '¿Recuerdas el botón cuadrado ▢ de la barra de abajo?\n\nHoy lo vas a usar de verdad. Tócalo SIN salir de Ajustes.',
      'objetivo': 'recientes',
      'resalta': 'boton_recientes',
      'ayuda': 'Toca el cuadrado ▢ en la barra de abajo',
    },
    {
      'tipo': 'simulador_info',
      'titulo': '¡Mira esto! 👀',
      'instruccion':
          'Estas tarjetas son tus apps VIVAS.\n\nAjustes no se cerró — sigue ahí, esperándote, en la misma página donde lo dejaste.',
      'objetivo': null,
      'resalta': null,
    },
    {
      'tipo': 'simulador',
      'titulo': 'PRÁCTICA 3\nVuelve a Ajustes',
      'instruccion':
          'Toca la tarjeta de Ajustes para volver.\n\nVas a ver que regresas exactamente donde estabas.',
      'objetivo': 'ajustes',
      'resalta': 'tarjeta_ajustes',
      'ayuda': 'Toca la tarjeta de Ajustes ⚙️',
    },
    {
      'tipo': 'simulador_info',
      'titulo': '¡No perdiste nada! ✅',
      'instruccion':
          'Volviste justo donde estabas.\n\nEsto es cambiar entre apps: saltas y regresas, sin perder nada.',
      'objetivo': null,
      'resalta': null,
    },
    {
      'tipo': 'simulador',
      'titulo': 'PRÁCTICA 4\nAhora abre la Cámara 📷',
      'instruccion':
          'Sal a la pantalla principal con el botón inicio ⬤\n\nLuego toca la Cámara 📷',
      'objetivo': 'camara',
      'resalta': 'boton_inicio',
      'ayuda': 'Primero toca el círculo ⬤, después la Cámara 📷',
    },
    {
      'tipo': 'simulador',
      'titulo': 'PRÁCTICA 5\nSalta de vuelta a Ajustes',
      'instruccion':
          'Ahora tienes DOS apps abiertas.\n\nToca el botón ▢ y luego la tarjeta de Ajustes para saltar allá.',
      'objetivo': 'ajustes',
      'resalta': 'boton_recientes',
      'ayuda': 'Toca ▢ y después la tarjeta de Ajustes',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Muy importante',
      'instruccion':
          'Dejar apps abiertas NO daña tu celular.\n\nNO gasta más batería.\n\nNO tienes que cerrarlas.\n\nEl celular se organiza solito. Tú solo salta entre ellas tranquilo.',
      'icono': Icons.favorite_rounded,
      'colorIcono': Color(0xFF059669),
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Ya sabes exactamente qué va a pasar.\n\nAbre dos apps en tu celular real y salta entre ellas con el botón ▢\n\nCuando quieras, vuelve aquí.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': Color(0xFF6B4EFF),
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Eres un experto! 🏆',
      'instruccion':
          'Ya sabes tener varias apps abiertas y saltar entre ellas.\n\nAbrir ✅  Saltar ✅  Volver ✅\n\n¡Sin perder nada nunca más!',
      'icono': Icons.emoji_events_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial;

    _pulsoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulsoAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulsoController, curve: Curves.easeInOut),
    );

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    _prepararPaso();
  }

  @override
  void dispose() {
    _pulsoController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Prepara el simulador segun el paso actual
  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    switch (_pasoActual) {
      case 3:
        _pantalla = 'inicio';
        _appsAbiertas.clear();
        break;
      case 4:
        _pantalla = 'ajustes';
        if (!_appsAbiertas.contains('ajustes')) _appsAbiertas.add('ajustes');
        break;
      case 5:
      case 6:
        _pantalla = 'recientes';
        if (!_appsAbiertas.contains('ajustes')) _appsAbiertas.add('ajustes');
        break;
      case 7:
      case 8:
        _pantalla = 'ajustes';
        if (!_appsAbiertas.contains('ajustes')) _appsAbiertas.add('ajustes');
        break;
      case 9:
        _pantalla = 'camara';
        if (!_appsAbiertas.contains('ajustes')) _appsAbiertas.add('ajustes');
        if (!_appsAbiertas.contains('camara')) _appsAbiertas.add('camara');
        break;
    }
  }

  // El cerebro del simulador: que pasa cuando tocan algo
  void _tocarEnSimulador(String accion) {
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'icono_ajustes':
          if (_pantalla == 'inicio') {
            _pantalla = 'ajustes';
            if (!_appsAbiertas.contains('ajustes')) {
              _appsAbiertas.add('ajustes');
            }
          }
          break;
        case 'icono_camara':
          if (_pantalla == 'inicio') {
            _pantalla = 'camara';
            if (!_appsAbiertas.contains('camara')) {
              _appsAbiertas.add('camara');
            }
          }
          break;
        case 'boton_inicio':
          _pantalla = 'inicio';
          break;
        case 'boton_recientes':
          if (_appsAbiertas.isEmpty) {
            _mensajeGuia = 'Primero abre una app';
          } else {
            _pantalla = 'recientes';
          }
          break;
        case 'boton_atras':
          _pantalla = 'inicio';
          break;
        case 'tarjeta_ajustes':
          _pantalla = 'ajustes';
          break;
        case 'tarjeta_camara':
          _pantalla = 'camara';
          break;
      }

      // Revisa si cumplio el objetivo del paso
      final objetivo = _pasos[_pasoActual]['objetivo'];
      if (objetivo != null && _pantalla == objetivo) {
        _objetivoCumplido = true;
      }
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
        title: const Text('Cambiando entre apps',
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
              Color(0xFF0EA5E9),
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
      case 'simulador':
      case 'simulador_info':
        return _buildSimulador(paso['resalta'] as String?);
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

  // EL SIMULADOR
  Widget _buildSimulador(String? resalta) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('📱 Celular de práctica — toca sin miedo',
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('10:30',
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                      Row(children: [
                        Icon(Icons.wifi_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Icon(Icons.battery_full_rounded,
                            color: Colors.white, size: 12),
                      ]),
                    ],
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: _buildPantallaSimulada(resalta),
                ),
                _buildBarraNavegacion(resalta),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPantallaSimulada(String? resalta) {
    switch (_pantalla) {
      case 'inicio':
        return _buildPantallaInicio(resalta);
      case 'ajustes':
        return _buildAppAbierta(
            'Ajustes', Icons.settings_rounded, const Color(0xFF6B4EFF));
      case 'camara':
        return _buildAppAbierta(
            'Cámara', Icons.camera_alt_rounded, const Color(0xFF8B5CF6));
      case 'recientes':
        return _buildPantallaRecientes(resalta);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPantallaInicio(String? resalta) {
    final apps = [
      {
        'id': 'icono_ajustes',
        'nombre': 'Ajustes',
        'icono': Icons.settings_rounded,
        'color': const Color(0xFF6B4EFF),
      },
      {
        'id': 'icono_camara',
        'nombre': 'Cámara',
        'icono': Icons.camera_alt_rounded,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: apps.map((app) {
            final esResaltado = resalta == app['id'];
            return AnimatedBuilder(
              animation: _pulsoAnimation,
              builder: (_, __) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Transform.scale(
                    scale: esResaltado ? _pulsoAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: () => _tocarEnSimulador(app['id'] as String),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: app['color'] as Color,
                              border: esResaltado
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: esResaltado
                                  ? [
                                      BoxShadow(
                                          color: (app['color'] as Color)
                                              .withOpacity(0.7),
                                          blurRadius: 16,
                                          spreadRadius: 2),
                                    ]
                                  : null,
                            ),
                            child: Icon(app['icono'] as IconData,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 6),
                          Text(app['nombre'] as String,
                              style: TextStyle(
                                  color: esResaltado
                                      ? Colors.white
                                      : Colors.white60,
                                  fontSize: 11,
                                  fontWeight: esResaltado
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppAbierta(String nombre, IconData icono, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icono, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Text(nombre,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('App abierta ✓',
                style: TextStyle(color: color, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildPantallaRecientes(String? resalta) {
    final info = {
      'ajustes': {
        'nombre': 'Ajustes',
        'icono': Icons.settings_rounded,
        'color': const Color(0xFF6B4EFF),
        'tarjeta': 'tarjeta_ajustes',
      },
      'camara': {
        'nombre': 'Cámara',
        'icono': Icons.camera_alt_rounded,
        'color': const Color(0xFF8B5CF6),
        'tarjeta': 'tarjeta_camara',
      },
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text('Apps abiertas',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _appsAbiertas.map((appId) {
                final app = info[appId]!;
                final esResaltado = resalta == app['tarjeta'];
                return AnimatedBuilder(
                  animation: _pulsoAnimation,
                  builder: (_, __) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Transform.scale(
                        scale: esResaltado ? _pulsoAnimation.value : 1.0,
                        child: GestureDetector(
                          onTap: () =>
                              _tocarEnSimulador(app['tarjeta'] as String),
                          child: Container(
                            width: 84,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D44),
                              borderRadius: BorderRadius.circular(12),
                              border: esResaltado
                                  ? Border.all(
                                      color: app['color'] as Color, width: 3)
                                  : Border.all(
                                      color: Colors.white24, width: 1),
                              boxShadow: esResaltado
                                  ? [
                                      BoxShadow(
                                          color: (app['color'] as Color)
                                              .withOpacity(0.6),
                                          blurRadius: 14),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: app['color'] as Color,
                                  ),
                                  child: Icon(app['icono'] as IconData,
                                      color: Colors.white, size: 19),
                                ),
                                const SizedBox(height: 6),
                                Text(app['nombre'] as String,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                const Text('sigue viva',
                                    style: TextStyle(
                                        color: Color(0xFF059669),
                                        fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraNavegacion(String? resalta) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _botonNav('boton_atras', Icons.arrow_back_rounded, resalta),
          _botonNavCirculo('boton_inicio', resalta),
          _botonNav('boton_recientes', Icons.crop_square_rounded, resalta),
        ],
      ),
    );
  }

  Widget _botonNav(String id, IconData icono, String? resalta) {
    final esResaltado = resalta == id;
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        return Transform.scale(
          scale: esResaltado ? _pulsoAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador(id),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    esResaltado ? const Color(0xFF6B4EFF) : Colors.transparent,
                boxShadow: esResaltado
                    ? [
                        BoxShadow(
                            color: const Color(0xFF6B4EFF).withOpacity(0.6),
                            blurRadius: 14)
                      ]
                    : null,
              ),
              child: Icon(icono,
                  color: esResaltado ? Colors.white : Colors.white54, size: 22),
            ),
          ),
        );
      },
    );
  }

  Widget _botonNavCirculo(String id, String? resalta) {
    final esResaltado = resalta == id;
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        return Transform.scale(
          scale: esResaltado ? _pulsoAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador(id),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    esResaltado ? const Color(0xFF6B4EFF) : Colors.transparent,
                border: Border.all(
                    color: esResaltado ? Colors.white : Colors.white54,
                    width: 2),
                boxShadow: esResaltado
                    ? [
                        BoxShadow(
                            color: const Color(0xFF6B4EFF).withOpacity(0.6),
                            blurRadius: 14)
                      ]
                    : null,
              ),
            ),
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
          child:
              const Center(child: Text('🏆', style: TextStyle(fontSize: 64))),
        ),
        const SizedBox(height: 16),
        const Text('¡Saltas entre apps como un experto!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF854F0B),
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBoton(Map<String, dynamic> paso) {
    final tipo = paso['tipo'] as String;
    final esUltimo = _pasoActual == _pasos.length - 1;

    String texto;
    Color color;

    if (esUltimo) {
      texto = '¡Terminé! 🎉';
      color = const Color(0xFF059669);
    } else if (!_objetivoCumplido) {
      texto = paso['ayuda'] as String? ?? 'Practica en el celular de arriba';
      color = const Color(0xFFBBBBCC);
    } else if (tipo == 'simulador') {
      texto = '¡Lo lograste! Siguiente →';
      color = const Color(0xFF059669);
    } else if (tipo == 'accion_real') {
      texto = 'Ya practiqué, siguiente →';
      color = const Color(0xFF6B4EFF);
    } else {
      texto = 'Entendido, siguiente →';
      color = const Color(0xFF6B4EFF);
    }

    return GestureDetector(
      onTap: _objetivoCumplido ? _avanzar : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _objetivoCumplido
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