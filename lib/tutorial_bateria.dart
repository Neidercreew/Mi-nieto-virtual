import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'bateria_y_cuidado';

class TutorialBateriaScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialBateriaScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialBateriaScreen> createState() => _TutorialBateriaScreenState();
}

class _TutorialBateriaScreenState extends State<TutorialBateriaScreen>
    with TickerProviderStateMixin {
  int _pasoActual = 0;
  bool _mostrarFelicitacion = false;

  late AnimationController _cargaController;
  late Animation<double> _cargaAnimation;

  late AnimationController _pulsoController;
  late Animation<double> _pulsoAnimation;

  late AnimationController _flechaController;
  late Animation<double> _flechaAnimation;

  late AnimationController _electricidadController;
  late Animation<double> _electricidadAnimation;

  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Batería y\ncuidado 🔋',
      'instruccion': 'La batería es el corazón de tu celular.\n\nHoy aprenderás a cuidarla para que dure mucho más tiempo.',
      'icono': Icons.battery_full_rounded,
      'colorIcono': const Color(0xFF059669),
    },
    {
      'tipo': 'analogia',
      'titulo': '¿Qué es la\nbatería? 🔋',
      'instruccion': 'La batería es como el tanque de gasolina de un carro.\n\nCuando está llena el celular funciona. Cuando se vacía, se apaga.',
      'icono': Icons.battery_full_rounded,
      'colorIcono': const Color(0xFF059669),
    },
    {
      'tipo': 'muestra_bateria_flecha',
      'titulo': 'Aquí ves cuánta\nbatería tienes 👆',
      'instruccion': 'En la esquina ARRIBA a la DERECHA de tu pantalla siempre verás el símbolo de batería.\n\nFíjate en la flecha que señala dónde está.',
      'icono': Icons.battery_full_rounded,
      'colorIcono': const Color(0xFF059669),
      'nivel': 0.75,
    },
    {
      'tipo': 'niveles_bateria',
      'titulo': '¿Qué significan\nlos colores? 🎨',
      'instruccion': 'El color de la batería te dice qué tan urgente es cargarla.\n\nCuando está roja y pulsando — ¡carga YA!',
      'icono': Icons.battery_alert_rounded,
      'colorIcono': const Color(0xFFE53E3E),
    },
    {
      'tipo': 'analogia',
      'titulo': '¿Cuándo cargar\ntu celular? ⚡',
      'instruccion': 'No esperes a que se apague solo.\n\nEs como llenar el tanque del carro — mejor antes de que se vacíe completamente.',
      'icono': Icons.electric_bolt_rounded,
      'colorIcono': const Color(0xFFFFB300),
    },
    {
      'tipo': 'muestra_carga_animada',
      'titulo': 'Así se carga\ntu celular ⚡',
      'instruccion': 'El cable va en el hueco de ABAJO de tu celular.\n\nObserva cómo la electricidad viaja por el cable hasta llenar la batería.',
      'icono': Icons.cable_rounded,
      'colorIcono': const Color(0xFFFFB300),
    },
    {
      'tipo': 'accion',
      'titulo': 'PRÁCTICA\nConecta tu cargador',
      'instruccion': 'Busca tu cable cargador.\n\nConéctalo en el hueco de abajo de tu celular y en el enchufe de la pared.',
      'icono': Icons.cable_rounded,
      'colorIcono': const Color(0xFFFFB300),
      'confirmacion': '✅ Ya conecté el cargador',
    },
    {
      'tipo': 'verificacion_carga',
      'titulo': '¿Ves el rayo\nde carga? ⚡',
      'instruccion': 'Cuando el cargador está bien conectado verás un pequeño rayo ⚡ junto a la batería.\n\n¡Eso significa que está cargando!',
      'icono': Icons.check_circle_rounded,
      'colorIcono': const Color(0xFF059669),
      'nivel': 0.45,
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Mitos y verdades\nde la batería',
      'instruccion': '❌ "Debo cargar hasta 100% siempre"\n✅ Puedes desconectar entre 80-90%\n\n❌ "Debo agotar la batería primero"\n✅ Puedes cargar cuando quieras\n\n❌ "Cargar de noche la daña"\n✅ Los celulares modernos se protegen solos',
      'icono': Icons.lightbulb_rounded,
      'colorIcono': const Color(0xFFFFB300),
    },
    {
      'tipo': 'que_gasta',
      'titulo': '¿Qué gasta más\nla batería? 😮',
      'instruccion': 'Estas cosas consumen (gastan) la batería más rápido.\n\nEvítalas cuando tengas poca batería.',
      'icono': Icons.battery_alert_rounded,
      'colorIcono': const Color(0xFFE53E3E),
    },
    {
      'tipo': 'muestra_panel_ahorro',
      'titulo': 'El modo ahorro\nte protege 🛡️',
      'instruccion': 'El modo ahorro reduce automáticamente lo que gasta tu celular.\n\nBusca este símbolo en el panel de arriba 👇',
      'icono': Icons.battery_saver_rounded,
      'colorIcono': const Color(0xFF059669),
    },
    {
      'tipo': 'accion',
      'titulo': 'PRÁCTICA\nActiva el modo ahorro',
      'instruccion': 'Desliza desde ARRIBA hacia ABAJO.\n\nBusca el símbolo de batería con corazón 🔋 o la palabra "Ahorro".\n\nTócalo para activarlo.',
      'icono': Icons.battery_saver_rounded,
      'colorIcono': const Color(0xFF059669),
      'confirmacion': '✅ Ya lo encontré y activé',
    },
    {
      'tipo': 'cuidado_fisico',
      'titulo': '🛡️ Cuida tu\ncelular siempre',
      'instruccion': 'Tu celular es una herramienta valiosa (valuable tool).\n\nSigue estos consejos para que dure muchos años.',
      'icono': Icons.shield_rounded,
      'colorIcono': const Color(0xFF6B4EFF),
    },
    {
      'tipo': 'celebracion_modulo',
      'titulo': '¡Módulo 1\nCompletado! 🎓',
      'instruccion': 'Has terminado "Conociendo tu celular".\n\nBotones ✅  Pantalla ✅  Navegación ✅\nConfiguraciones ✅  Batería ✅\n\n¡Felicidades, has terminado el primer modulo, que gran avance!!',
      'icono': Icons.emoji_events_rounded,
      'colorIcono': const Color(0xFFFFB300),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial;

    _cargaController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _cargaAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cargaController, curve: Curves.easeInOut),
    );

    _pulsoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _pulsoAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulsoController, curve: Curves.easeInOut),
    );

    _flechaController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _flechaAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _flechaController, curve: Curves.easeInOut),
    );

    _electricidadController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _electricidadAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _electricidadController, curve: Curves.linear),
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 6));
  }

  @override
  void dispose() {
    _cargaController.dispose();
    _pulsoController.dispose();
    _flechaController.dispose();
    _electricidadController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _verificarConfetti() {
    final tipo = _pasos[_pasoActual]['tipo'];
    if (tipo == 'celebracion_modulo') {
      _confettiController.play();
    }
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

    _verificarConfetti();
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
        title: const Text('Batería y cuidado',
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
            colors: const [
              Color(0xFF6B4EFF), Color(0xFFFFB300),
              Color(0xFF059669), Color(0xFF0EA5E9),
              Color(0xFFE53E3E),
            ],
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
    final icono = paso['icono'] as IconData;
    final color = paso['colorIcono'] as Color;

    switch (tipo) {
      case 'muestra_bateria_flecha':
        return _buildMuestraBateriaConFlecha(paso['nivel'] as double);
      case 'niveles_bateria':
        return _buildNivelesBateria();
      case 'muestra_carga_animada':
        return _buildCargaAnimada();
      case 'verificacion_carga':
        return _buildVerificacionCarga(paso['nivel'] as double);
      case 'que_gasta':
        return _buildQueGasta();
      case 'muestra_panel_ahorro':
        return _buildPanelAhorro();
      case 'cuidado_fisico':
        return _buildCuidadoFisico();
      case 'celebracion_modulo':
        return _buildCelebracionModulo();
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

  Widget _buildMuestraBateriaConFlecha(double nivel) {
    return AnimatedBuilder(
      animation: _flechaAnimation,
      builder: (_, __) {
        return Container(
          width: 270, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('10:30', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Row(children: [
                const Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF059669), width: 2),
                    boxShadow: [BoxShadow(color: const Color(0xFF059669).withOpacity(0.5), blurRadius: 8)],
                  ),
                  child: Row(children: [
                    _buildIconoBateria(nivel),
                    const SizedBox(width: 4),
                    Text('${(nivel * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Transform.translate(
                offset: Offset(0, -_flechaAnimation.value),
                child: Column(children: [
                  const Icon(Icons.arrow_upward_rounded, color: Color(0xFF059669), size: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(8)),
                    child: const Text('¡Aquí está!',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, height: 90,
              decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Pantalla de tu celular',
                  style: TextStyle(color: Colors.white38, fontSize: 12))),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildIconoBateria(double nivel) {
    Color colorBateria;
    if (nivel > 0.5) colorBateria = const Color(0xFF059669);
    else if (nivel > 0.2) colorBateria = const Color(0xFFFFB300);
    else colorBateria = const Color(0xFFE53E3E);

    return SizedBox(width: 28, height: 14, child: Stack(children: [
      Container(width: 24, height: 14,
          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.5), borderRadius: BorderRadius.circular(3))),
      Positioned(right: 0, top: 4, child: Container(width: 3, height: 6, color: Colors.white)),
      Positioned(left: 2, top: 2, child: Container(
        width: (20 * nivel).clamp(0.0, 20.0), height: 10,
        decoration: BoxDecoration(color: colorBateria, borderRadius: BorderRadius.circular(1.5)),
      )),
    ]));
  }

  Widget _buildNivelesBateria() {
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        final niveles = [
          {'nivel': 0.85, 'label': 'Llena (80–100%)', 'desc': 'Bien, no necesitas cargar', 'color': const Color(0xFF059669), 'pulsa': false},
          {'nivel': 0.45, 'label': 'Media (20–80%)', 'desc': 'Puedes seguir usando tranquilo', 'color': const Color(0xFFFFB300), 'pulsa': false},
          {'nivel': 0.08, 'label': 'Baja (menos 20%)', 'desc': '¡Carga pronto!', 'color': const Color(0xFFE53E3E), 'pulsa': true},
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: niveles.map((n) {
            final color = n['color'] as Color;
            final pulsa = n['pulsa'] as bool;
            return Transform.scale(
              scale: pulsa ? _pulsoAnimation.value : 1.0,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(pulsa ? 0.9 : 0.4), width: pulsa ? 2.5 : 2),
                  boxShadow: pulsa ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)] : null,
                ),
                child: Row(children: [
                  _buildIconoBateriaGrande(n['nivel'] as double, color),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n['label'] as String,
                        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(n['desc'] as String,
                        style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
                  ])),
                  if (pulsa) Icon(Icons.warning_rounded, color: color, size: 22),
                ]),
              ),
            );
          }).toList()),
        );
      },
    );
  }

  Widget _buildIconoBateriaGrande(double nivel, Color color) {
    return SizedBox(width: 44, height: 22, child: Stack(children: [
      Container(width: 38, height: 22,
          decoration: BoxDecoration(border: Border.all(color: color, width: 2), borderRadius: BorderRadius.circular(5))),
      Positioned(right: 0, top: 6, child: Container(width: 5, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
      Positioned(left: 3, top: 3, child: Container(
        width: (32 * nivel).clamp(0.0, 32.0), height: 16,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      )),
    ]));
  }

  Widget _buildCargaAnimada() {
    return AnimatedBuilder(
      animation: _electricidadAnimation,
      builder: (_, __) {
        final progreso = _electricidadAnimation.value;
        final nivelBateria = 0.3 + (progreso * 0.5);
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 150, height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.2 + progreso * 0.4),
                blurRadius: 20 + progreso * 15, spreadRadius: progreso * 6,
              )],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 55, height: 95, child: Stack(alignment: Alignment.center, children: [
                Container(width: 48, height: 88,
                    decoration: BoxDecoration(border: Border.all(color: Colors.white38, width: 2), borderRadius: BorderRadius.circular(8))),
                Positioned(top: 0, child: Container(width: 18, height: 5,
                    decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2)))),
                Positioned(bottom: 3, child: Container(
                  width: 40, height: (80 * nivelBateria).clamp(4.0, 80.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669), borderRadius: BorderRadius.circular(5),
                    boxShadow: [BoxShadow(color: const Color(0xFF059669).withOpacity(0.6), blurRadius: 8)],
                  ),
                )),
                const Icon(Icons.electric_bolt_rounded, color: Colors.white, size: 26),
              ])),
              const SizedBox(height: 10),
              Text('${(nivelBateria * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
          SizedBox(width: 60, height: 50, child: Stack(alignment: Alignment.center, children: [
            Container(width: 5, height: 50, color: const Color(0xFF333355)),
            ...List.generate(3, (i) {
              final offset = (progreso + i / 3) % 1.0;
              return Positioned(
                bottom: offset * 50,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFB300).withOpacity(1.0 - offset),
                    boxShadow: [BoxShadow(color: const Color(0xFFFFB300).withOpacity(0.8), blurRadius: 6)],
                  ),
                ),
              );
            }),
          ])),
          Container(
            width: 50, height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF444466), borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white24),
            ),
            child: const Center(child: Text('USB-C', style: TextStyle(color: Colors.white54, fontSize: 8))),
          ),
        ]);
      },
    );
  }

  Widget _buildVerificacionCarga(double nivel) {
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        return Container(
          width: 270, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('10:30', style: TextStyle(color: Colors.white, fontSize: 14)),
              Row(children: [
                const Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Row(children: [
                  _buildIconoBateria(nivel),
                  const SizedBox(width: 2),
                  Transform.scale(
                    scale: _pulsoAnimation.value,
                    child: const Icon(Icons.electric_bolt_rounded, color: Color(0xFFFFB300), size: 16),
                  ),
                ]),
              ]),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFB300), borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('¡Este rayo = cargando!',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, height: 80,
              decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Pantalla de tu celular',
                  style: TextStyle(color: Colors.white38, fontSize: 12))),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildQueGasta() {
    final items = [
      {'icono': Icons.brightness_high_rounded, 'label': 'Brillo muy alto', 'color': const Color(0xFFFFB300)},
      {'icono': Icons.location_on_rounded, 'label': 'GPS encendido', 'color': const Color(0xFF0EA5E9)},
      {'icono': Icons.wifi_rounded, 'label': 'WiFi y datos siempre activos', 'color': const Color(0xFF8B5CF6)},
      {'icono': Icons.notifications_active_rounded, 'label': 'Muchas notificaciones', 'color': const Color(0xFFE53E3E)},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: items.map((item) {
        final color = item['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
              child: Icon(item['icono'] as IconData, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(item['label'] as String,
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600))),
            Icon(Icons.battery_alert_rounded, color: color.withOpacity(0.6), size: 18),
          ]),
        );
      }).toList()),
    );
  }

  Widget _buildPanelAhorro() {
    final iconos = [
      {'icono': Icons.wifi_rounded, 'label': 'WiFi'},
      {'icono': Icons.signal_cellular_alt_rounded, 'label': 'Datos'},
      {'icono': Icons.bluetooth_rounded, 'label': 'Bluetooth'},
      {'icono': Icons.battery_saver_rounded, 'label': 'Ahorro'},
      {'icono': Icons.flashlight_on_rounded, 'label': 'Linterna'},
      {'icono': Icons.do_not_disturb_on_rounded, 'label': 'Silencio'},
    ];
    return AnimatedBuilder(
      animation: _flechaAnimation,
      builder: (_, __) {
        return Container(
          width: 270, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
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
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: iconos.map((item) {
              final esAhorro = item['label'] == 'Ahorro';
              return Column(mainAxisSize: MainAxisSize.min, children: [
                if (esAhorro)
                  Transform.translate(
                    offset: Offset(0, -_flechaAnimation.value),
                    child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF059669), size: 18),
                  )
                else
                  const SizedBox(height: 18),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    color: esAhorro ? const Color(0xFF059669) : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: esAhorro ? Border.all(color: Colors.white, width: 2) : null,
                    boxShadow: esAhorro ? [const BoxShadow(color: Color(0xFF059669), blurRadius: 14)] : null,
                  ),
                  child: Icon(item['icono'] as IconData, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 4),
                Text(item['label'] as String, style: TextStyle(
                  color: esAhorro ? const Color(0xFF059669) : Colors.white54,
                  fontSize: 10, fontWeight: esAhorro ? FontWeight.bold : FontWeight.normal,
                )),
              ]);
            }).toList()),
          ]),
        );
      },
    );
  }

  Widget _buildCuidadoFisico() {
    final consejos = [
      {'icono': Icons.wb_sunny_rounded, 'label': 'No lo dejes al sol', 'color': const Color(0xFFFFB300)},
      {'icono': Icons.water_drop_rounded, 'label': 'Aléjalo del agua', 'color': const Color(0xFF0EA5E9)},
      {'icono': Icons.phone_android_rounded, 'label': 'Usa funda protectora', 'color': const Color(0xFF8B5CF6)},
      {'icono': Icons.cable_rounded, 'label': 'Usa el cargador original', 'color': const Color(0xFF059669)},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: consejos.map((c) {
        final color = c['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
              child: Icon(c['icono'] as IconData, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(c['label'] as String,
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600))),
            Icon(Icons.check_circle_rounded, color: color.withOpacity(0.6), size: 18),
          ]),
        );
      }).toList()),
    );
  }

  Widget _buildCelebracionModulo() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 140, height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [Color(0xFFFFF3CD), Color(0xFFFAEEDA)]),
          border: Border.all(color: const Color(0xFFEF9F27), width: 4),
          boxShadow: [BoxShadow(color: const Color(0xFFFFB300).withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
        ),
        child: const Center(child: Text('🎓', style: TextStyle(fontSize: 72))),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6B4EFF), Color(0xFF3700B3)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: const Color(0xFF6B4EFF).withOpacity(0.4), blurRadius: 15)],
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Módulo 1 completado',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
      ),
      const SizedBox(height: 12),
      const Text('¡Ya eres experto básico! 🌟',
          style: TextStyle(color: Color(0xFF854F0B), fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildBoton(Map<String, dynamic> paso) {
    final tipo = paso['tipo'] as String;
    final esUltimo = _pasoActual == _pasos.length - 1;
    String texto;
    Color color;
    if (esUltimo) {
      texto = '¡Completé el módulo! 🎓';
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
        child: Center(child: Text(texto,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
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