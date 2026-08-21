import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'buscar_descargar';

class TutorialBuscarDescargarScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialBuscarDescargarScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialBuscarDescargarScreen> createState() =>
      _TutorialBuscarDescargarScreenState();
}

class _TutorialBuscarDescargarScreenState
    extends State<TutorialBuscarDescargarScreen>
    with TickerProviderStateMixin {
  int _pasoActual = 0;

  // Estado del celular simulado
  String _pantalla = 'inicio';
  String _textoBuscado = '';
  double _progresoDescarga = 0.0;
  bool _objetivoCumplido = false;
  String? _mensajeGuia;

  late AnimationController _pulsoController;
  late Animation<double> _pulsoAnimation;
  late AnimationController _descargaController;
  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Consiguiendo apps\nnuevas 🔍',
      'instruccion':
          'Hasta ahora usaste las apps que ya venían en tu celular.\n\nHoy vas a aprender a conseguir apps NUEVAS por ti mismo.',
      'icono': Icons.download_rounded,
      'colorIcono': Color(0xFF6B4EFF),
    },
    {
      'tipo': 'analogia',
      'titulo': '¿Qué es la\nPlay Store? 🏪',
      'instruccion':
          'La Play Store es como un supermercado de aplicaciones.\n\nEntras, buscas lo que quieres, y te lo llevas.\n\nLa gran mayoría son COMPLETAMENTE GRATIS.',
      'icono': Icons.storefront_rounded,
      'colorIcono': Color(0xFF059669),
    },
    {
      'tipo': 'miedo',
      'titulo': 'Tranquilo, no te\nvan a cobrar 🛡️',
      'instruccion':
          'Muchas personas tienen miedo de la Play Store.\n\nPero escucha bien:\n\n✅ Si una app es gratis, dice "Instalar"\n✅ Si cuesta dinero, muestra el PRECIO antes\n✅ Nunca te cobran sin avisarte primero',
      'icono': Icons.verified_user_rounded,
      'colorIcono': Color(0xFF059669),
    },
    {
      'tipo': 'simulador',
      'titulo': 'PRÁCTICA 1\nAbre la Play Store ▶️',
      'instruccion':
          'Este es un celular de práctica. Todo es de mentiras — toca sin miedo.\n\nBusca el triángulo de colores ▶️ y tócalo.',
      'objetivo': 'tienda',
      'resalta': 'icono_tienda',
      'ayuda': 'Toca el triángulo de colores ▶️',
    },
    {
      'tipo': 'simulador',
      'titulo': 'PRÁCTICA 2\nToca la lupa 🔍',
      'instruccion':
          'Ya estás dentro de la tienda.\n\nPara buscar una app, toca la barra de búsqueda con la lupa 🔍 que está arriba.',
      'objetivo': 'busqueda',
      'resalta': 'barra_busqueda',
      'ayuda': 'Toca la barra de búsqueda de arriba 🔍',
    },
    {
      'tipo': 'simulador',
      'titulo': 'PRÁCTICA 3\nEscribe WhatsApp',
      'instruccion':
          'Apareció el teclado.\n\nToca las letras para escribir "WhatsApp".\n\nNo te preocupes por escribirlo perfecto — te ayudamos.',
      'objetivo': 'resultados',
      'resalta': 'teclado',
      'ayuda': 'Toca las letras del teclado para escribir',
    },
    {
      'tipo': 'simulador',
      'titulo': 'PRÁCTICA 4\nToca WhatsApp',
      'instruccion':
          'Aparecieron los resultados.\n\nToca la app de WhatsApp — es la primera de la lista.',
      'objetivo': 'ficha',
      'resalta': 'resultado_whatsapp',
      'ayuda': 'Toca la primera app de la lista',
    },
    {
      'tipo': 'simulador',
      'titulo': 'PRÁCTICA 5\nToca INSTALAR 📥',
      'instruccion':
          'Esta es la ficha de la app.\n\n¿Ves el botón VERDE que dice "Instalar"?\n\nVerde y sin precio = GRATIS. Tócalo.',
      'objetivo': 'instalada',
      'resalta': 'boton_instalar',
      'ayuda': 'Toca el botón verde que dice Instalar',
    },
    {
      'tipo': 'simulador_info',
      'titulo': '¡Instalada! ✅',
      'instruccion':
          'La app se descargó e instaló sola.\n\nNo tuviste que hacer nada más. Sin pagar, sin problemas.',
      'objetivo': null,
      'resalta': null,
    },
    {
      'tipo': 'simulador',
      'titulo': 'PRÁCTICA 6\nVuelve a la pantalla principal',
      'instruccion':
          'Toca el botón inicio ⬤ de abajo.\n\nMira lo que apareció en tu pantalla...',
      'objetivo': 'inicio_con_app',
      'resalta': 'boton_inicio',
      'ayuda': 'Toca el círculo ⬤ de la barra de abajo',
    },
    {
      'tipo': 'simulador_info',
      'titulo': '¡Ahí está! 🎉',
      'instruccion':
          'El ícono de WhatsApp ya está en tu pantalla principal.\n\nAhora puedes abrirlo cuando quieras, igual que cualquier otra app.',
      'objetivo': null,
      'resalta': null,
    },
    {
      'tipo': 'seguridad',
      'titulo': '🛡️ ¿Cómo saber si una\napp es confiable?',
      'instruccion': 'Antes de instalar, revisa estas 3 cosas:',
      'icono': Icons.shield_rounded,
      'colorIcono': Color(0xFF059669),
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Ya sabes exactamente qué va a pasar en cada paso.\n\nBusca la Play Store ▶️ en tu celular real e instala una app que quieras.\n\nCuando termines, vuelve aquí.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': Color(0xFF6B4EFF),
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Módulo 2\nCompletado! 🎓',
      'instruccion':
          'Terminaste "Cómo navegar".\n\nReconocer íconos ✅\nAbrir y cerrar apps ✅\nCambiar entre apps ✅\nInstalar apps nuevas ✅\n\n¡Ya eres independiente con tu celular!',
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
    _pulsoAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulsoController, curve: Curves.easeInOut),
    );

    _descargaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() {
        setState(() {
          _progresoDescarga = _descargaController.value;
          if (_descargaController.isCompleted && _pantalla == 'instalando') {
            _pantalla = 'instalada';
            _revisarObjetivo();
          }
        });
      });

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 6));

    _prepararPaso();
  }

  @override
  void dispose() {
    _pulsoController.dispose();
    _descargaController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    switch (_pasoActual) {
      case 3:
        _pantalla = 'inicio';
        _textoBuscado = '';
        break;
      case 4:
        _pantalla = 'tienda';
        break;
      case 5:
        _pantalla = 'busqueda';
        _textoBuscado = '';
        break;
      case 6:
        _pantalla = 'resultados';
        break;
      case 7:
        _pantalla = 'ficha';
        _progresoDescarga = 0.0;
        break;
      case 8:
        _pantalla = 'instalada';
        break;
      case 9:
        _pantalla = 'instalada';
        break;
      case 10:
        _pantalla = 'inicio_con_app';
        break;
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo != null && _pantalla == objetivo) {
      _objetivoCumplido = true;
    }
  }

  // El cerebro del simulador
  void _tocarEnSimulador(String accion) {
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'icono_tienda':
          if (_pantalla == 'inicio' || _pantalla == 'inicio_con_app') {
            _pantalla = 'tienda';
          }
          break;
        case 'barra_busqueda':
          if (_pantalla == 'tienda') {
            _pantalla = 'busqueda';
            _textoBuscado = '';
          }
          break;
        case 'tecla':
          if (_pantalla == 'busqueda') {
            const objetivo = 'WhatsApp';
            if (_textoBuscado.length < objetivo.length) {
              _textoBuscado = objetivo.substring(0, _textoBuscado.length + 1);
            }
            if (_textoBuscado == objetivo) {
              _pantalla = 'resultados';
            }
          }
          break;
        case 'resultado_whatsapp':
          if (_pantalla == 'resultados') {
            _pantalla = 'ficha';
          }
          break;
        case 'boton_instalar':
          if (_pantalla == 'ficha') {
            _pantalla = 'instalando';
            _progresoDescarga = 0.0;
            _descargaController.reset();
            _descargaController.forward();
          }
          break;
        case 'boton_inicio':
          if (_pantalla == 'instalada' || _pantalla == 'instalando') {
            _pantalla = 'inicio_con_app';
          } else if (_pantalla != 'inicio') {
            _pantalla = 'inicio_con_app';
          }
          break;
        case 'boton_atras':
          if (_pantalla == 'busqueda') {
            _pantalla = 'tienda';
          } else if (_pantalla == 'resultados') {
            _pantalla = 'busqueda';
          } else if (_pantalla == 'ficha') {
            _pantalla = 'resultados';
          }
          break;
      }

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
        title: const Text('Buscando y descargando apps',
            style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 16,
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
            numberOfParticles: 32,
            gravity: 0.1,
            colors: const [
              Color(0xFF6B4EFF),
              Color(0xFFFFB300),
              Color(0xFF059669),
              Color(0xFF0EA5E9),
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

    switch (tipo) {
      case 'simulador':
      case 'simulador_info':
        return _buildSimulador(paso['resalta'] as String?);
      case 'seguridad':
        return _buildTarjetasSeguridad();
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
                  height: 210,
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
        return _buildPantallaInicio(resalta, conWhatsApp: false);
      case 'inicio_con_app':
        return _buildPantallaInicio(resalta, conWhatsApp: true);
      case 'tienda':
        return _buildTienda(resalta);
      case 'busqueda':
        return _buildBusqueda(resalta);
      case 'resultados':
        return _buildResultados(resalta);
      case 'ficha':
        return _buildFicha(resalta);
      case 'instalando':
        return _buildInstalando();
      case 'instalada':
        return _buildInstalada();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPantallaInicio(String? resalta, {required bool conWhatsApp}) {
    final apps = <Map<String, dynamic>>[
      {
        'id': 'icono_tienda',
        'nombre': 'Play Store',
        'icono': Icons.play_arrow_rounded,
        'color': const Color(0xFF00C853),
      },
      {
        'id': 'icono_camara',
        'nombre': 'Cámara',
        'icono': Icons.camera_alt_rounded,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    if (conWhatsApp) {
      apps.add({
        'id': 'icono_whatsapp',
        'nombre': 'WhatsApp',
        'icono': Icons.chat_rounded,
        'color': const Color(0xFF25D366),
        'esNuevo': true,
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 12,
          children: apps.map((app) {
            final esResaltado = resalta == app['id'];
            final esNuevo = app['esNuevo'] == true;
            return AnimatedBuilder(
              animation: _pulsoAnimation,
              builder: (_, __) {
                return Transform.scale(
                  scale: (esResaltado || esNuevo) ? _pulsoAnimation.value : 1.0,
                  child: GestureDetector(
                    onTap: () => _tocarEnSimulador(app['id'] as String),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: app['color'] as Color,
                                border: (esResaltado || esNuevo)
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: (esResaltado || esNuevo)
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
                                  color: Colors.white, size: 26),
                            ),
                            if (esNuevo)
                              Positioned(
                                top: -4,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53E3E),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('NUEVA',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(app['nombre'] as String,
                            style: TextStyle(
                                color: (esResaltado || esNuevo)
                                    ? Colors.white
                                    : Colors.white60,
                                fontSize: 10,
                                fontWeight: (esResaltado || esNuevo)
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ],
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

  Widget _buildTienda(String? resalta) {
    final esResaltado = resalta == 'barra_busqueda';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulsoAnimation,
            builder: (_, __) {
              return Transform.scale(
                scale: esResaltado ? _pulsoAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: () => _tocarEnSimulador('barra_busqueda'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(24),
                      border: esResaltado
                          ? Border.all(
                              color: const Color(0xFF6B4EFF), width: 2.5)
                          : Border.all(color: Colors.transparent),
                      boxShadow: esResaltado
                          ? [
                              BoxShadow(
                                  color:
                                      const Color(0xFF6B4EFF).withOpacity(0.4),
                                  blurRadius: 12)
                            ]
                          : null,
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search_rounded,
                            color: Color(0xFF5F6368), size: 18),
                        SizedBox(width: 8),
                        Text('Buscar apps',
                            style: TextStyle(
                                color: Color(0xFF5F6368), fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Apps recomendadas',
                style: TextStyle(
                    color: Color(0xFF202124),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _appTiendaDecorativa(
                    Icons.music_note_rounded, const Color(0xFFE53E3E)),
                _appTiendaDecorativa(
                    Icons.map_rounded, const Color(0xFF0EA5E9)),
                _appTiendaDecorativa(
                    Icons.newspaper_rounded, const Color(0xFFFFB300)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appTiendaDecorativa(IconData icono, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDADCE0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildBusqueda(String? resalta) {
    final esResaltado = resalta == 'teclado';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: Color(0xFF5F6368), size: 16),
                const SizedBox(width: 6),
                Text(
                  _textoBuscado.isEmpty ? 'Escribe aquí...' : _textoBuscado,
                  style: TextStyle(
                    color: _textoBuscado.isEmpty
                        ? const Color(0xFF9AA0A6)
                        : const Color(0xFF202124),
                    fontSize: 13,
                    fontWeight: _textoBuscado.isEmpty
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                if (_textoBuscado.isNotEmpty)
                  AnimatedBuilder(
                    animation: _pulsoAnimation,
                    builder: (_, __) => Opacity(
                      opacity: _pulsoAnimation.value > 1.06 ? 1 : 0.2,
                      child: Container(
                          width: 1.5,
                          height: 14,
                          color: const Color(0xFF6B4EFF)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: _pulsoAnimation,
              builder: (_, __) {
                return Transform.scale(
                  scale:
                      esResaltado ? 1 + (_pulsoAnimation.value - 1) * 0.4 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAED),
                      borderRadius: BorderRadius.circular(10),
                      border: esResaltado
                          ? Border.all(
                              color: const Color(0xFF6B4EFF), width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _filaTeclado('QWERTYUIOP'),
                        const SizedBox(height: 4),
                        _filaTeclado('ASDFGHJKL'),
                        const SizedBox(height: 4),
                        _filaTeclado('ZXCVBNM'),
                      ],
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

  Widget _filaTeclado(String letras) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letras.split('').map((letra) {
        return GestureDetector(
          onTap: () => _tocarEnSimulador('tecla'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 18,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 1,
                    offset: const Offset(0, 1)),
              ],
            ),
            child: Center(
              child: Text(letra,
                  style: const TextStyle(
                      color: Color(0xFF202124),
                      fontSize: 9,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultados(String? resalta) {
    final esResaltado = resalta == 'resultado_whatsapp';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(Icons.search_rounded, color: Color(0xFF5F6368), size: 14),
                SizedBox(width: 6),
                Text('WhatsApp',
                    style: TextStyle(
                        color: Color(0xFF202124),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _pulsoAnimation,
            builder: (_, __) {
              return Transform.scale(
                scale: esResaltado ? _pulsoAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: () => _tocarEnSimulador('resultado_whatsapp'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: esResaltado
                          ? const Color(0xFF25D366).withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: esResaltado
                          ? Border.all(
                              color: const Color(0xFF25D366), width: 2.5)
                          : Border.all(color: const Color(0xFFDADCE0)),
                      boxShadow: esResaltado
                          ? [
                              BoxShadow(
                                  color:
                                      const Color(0xFF25D366).withOpacity(0.4),
                                  blurRadius: 12)
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.chat_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('WhatsApp',
                                  style: TextStyle(
                                      color: Color(0xFF202124),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              Row(
                                children: const [
                                  Text('4.5',
                                      style: TextStyle(
                                          color: Color(0xFF5F6368),
                                          fontSize: 9)),
                                  Icon(Icons.star_rounded,
                                      color: Color(0xFFFFB300), size: 10),
                                  SizedBox(width: 6),
                                  Text('Gratis',
                                      style: TextStyle(
                                          color: Color(0xFF059669),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          _resultadoDecorativo(),
          _resultadoDecorativo(),
        ],
      ),
    );
  }

  Widget _resultadoDecorativo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAED),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE8EAED),
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 4),
                Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(3))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFicha(String? resalta) {
    final esResaltado = resalta == 'boton_instalar';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.chat_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          const Text('WhatsApp',
              style: TextStyle(
                  color: Color(0xFF202124),
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _datoFicha('4.5★', 'Calificación'),
              Container(width: 1, height: 20, color: const Color(0xFFDADCE0)),
              _datoFicha('5 mil M+', 'Descargas'),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _pulsoAnimation,
            builder: (_, __) {
              return Transform.scale(
                scale: esResaltado ? _pulsoAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: () => _tocarEnSimulador('boton_instalar'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(20),
                      border: esResaltado
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: esResaltado
                          ? [
                              BoxShadow(
                                  color:
                                      const Color(0xFF059669).withOpacity(0.6),
                                  blurRadius: 16,
                                  spreadRadius: 1)
                            ]
                          : null,
                    ),
                    child: const Text('Instalar',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          const Text('Sin costo · No te cobrarán',
              style: TextStyle(color: Color(0xFF059669), fontSize: 9)),
        ],
      ),
    );
  }

  Widget _datoFicha(String valor, String etiqueta) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Text(valor,
              style: const TextStyle(
                  color: Color(0xFF202124),
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          Text(etiqueta,
              style: const TextStyle(color: Color(0xFF5F6368), fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildInstalando() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.chat_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 10),
          const Text('Descargando...',
              style: TextStyle(
                  color: Color(0xFF202124),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progresoDescarga,
                backgroundColor: const Color(0xFFE8EAED),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('${(_progresoDescarga * 100).toInt()}%',
              style: const TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Espera un momento...',
              style: TextStyle(color: Color(0xFF5F6368), fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildInstalada() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.chat_rounded,
                    color: Colors.white, size: 28),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('¡Instalada!',
              style: TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('No pagaste nada ✓',
                style: TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
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

  Widget _buildTarjetasSeguridad() {
    final items = [
      {
        'icono': Icons.star_rounded,
        'titulo': 'Mira las estrellas',
        'desc': 'De 4 estrellas para arriba es buena señal',
        'color': const Color(0xFFFFB300),
      },
      {
        'icono': Icons.download_rounded,
        'titulo': 'Mira las descargas',
        'desc': 'Millones de descargas = mucha gente confía',
        'color': const Color(0xFF0EA5E9),
      },
      {
        'icono': Icons.attach_money_rounded,
        'titulo': 'Mira el botón',
        'desc': 'Si dice "Instalar" en verde, es GRATIS',
        'color': const Color(0xFF059669),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final color = item['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.35), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: color.withOpacity(0.15)),
                  child: Icon(item['icono'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['titulo'] as String,
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(item['desc'] as String,
                          style: const TextStyle(
                              color: Color(0xFF555577), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
            gradient: const RadialGradient(
                colors: [Color(0xFFFFF3CD), Color(0xFFFAEEDA)]),
            border: Border.all(color: const Color(0xFFEF9F27), width: 4),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFFFB300).withOpacity(0.5),
                  blurRadius: 28,
                  spreadRadius: 5)
            ],
          ),
          child: const Center(child: Text('🎓', style: TextStyle(fontSize: 64))),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6B4EFF), Color(0xFF3700B3)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF6B4EFF).withOpacity(0.4),
                  blurRadius: 14)
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Módulo 2 completado',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text('¡Ya consigues apps por ti mismo! 🌟',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF854F0B),
                fontSize: 14,
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
      texto = '¡Completé el módulo! 🎓';
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