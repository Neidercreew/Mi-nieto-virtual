import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'cuando_algo_sale_mal';

class TutorialCuandoAlgoSaleMalScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialCuandoAlgoSaleMalScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialCuandoAlgoSaleMalScreen> createState() =>
      _TutorialCuandoAlgoSaleMalScreenState();
}

class _TutorialCuandoAlgoSaleMalScreenState
    extends State<TutorialCuandoAlgoSaleMalScreen>
    with TickerProviderStateMixin {
  int _pasoActual = 0;

  // ─────────────────────────────────────────────────────────
  // ESTADO DEL SIMULADOR
  // Problema 1 (reinicio): congelado -> apagando -> encendido -> normal
  // Problema 2 (internet): sin_internet -> con_internet
  // Problema 3 (sonido): silencio -> con_sonido
  // ─────────────────────────────────────────────────────────
  String _estadoSim = 'normal';

  // Cuanto lleva presionado el boton de encendido (0.0 a 1.0)
  double _tiempoPresionado = 0.0;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;

  late AnimationController _pulsoController;
  late Animation<double> _pulsoAnimation;

  // Controla el "mantener presionado" del boton de encendido
  late AnimationController _presionarController;

  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _pasos = [
    // ── INTRO ─────────────────────────────────────────────
    {
      'tipo': 'intro',
      'titulo': 'Cuando algo\nsale mal 🔧',
      'instruccion':
          'A veces el celular se traba, se queda sin internet o no suena.\n\nHoy vas a aprender a resolver estos 3 problemas TÚ MISMO, sin llamar a nadie.',
      'icono': Icons.build_rounded,
      'colorIcono': Color(0xFF6B4EFF),
    },
    {
      'tipo': 'analogia',
      'titulo': 'Son cosas\nnormales 👍',
      'instruccion':
          'Que el celular falle de vez en cuando es normal — le pasa a TODOS, hasta a los jóvenes.\n\nNo es que lo dañaste. Solo hay que saber qué hacer.',
      'icono': Icons.sentiment_satisfied_rounded,
      'colorIcono': Color(0xFF059669),
    },

    // ── PROBLEMA 1: CELULAR CONGELADO ─────────────────────
    {
      'tipo': 'problema',
      'titulo': 'PROBLEMA 1\nEl celular no responde 🥶',
      'instruccion':
          'A veces tocas la pantalla y NADA se mueve. El celular quedó "congelado".\n\nEsto pasa cuando trabajó mucho y se cansó. Se arregla fácil.',
      'icono': Icons.ac_unit_rounded,
      'colorIcono': Color(0xFF0EA5E9),
      'numero': 1,
    },
    {
      'tipo': 'sim_reinicio',
      'titulo': 'SOLUCIÓN\nMantén presionado ⏻',
      'instruccion':
          'Este celular está congelado. Para revivirlo:\n\nMANTÉN presionado el botón de encendido (el del lado) hasta que se apague. No lo sueltes.',
      'objetivo': 'normal_reiniciado',
      'ayuda': 'Mantén presionado el botón del lado ⏻',
    },
    {
      'tipo': 'accion_real',
      'titulo': 'En tu celular 📱',
      'instruccion':
          'Ubica el botón de encendido en el LADO de tu celular real.\n\nRecuerda: si algún día se congela, mantienes ese botón hasta que se apague, y lo vuelves a prender.',
      'icono': Icons.power_settings_new_rounded,
      'colorIcono': Color(0xFF0EA5E9),
    },

    // ── PROBLEMA 2: SIN INTERNET ──────────────────────────
    {
      'tipo': 'problema',
      'titulo': 'PROBLEMA 2\nNo tengo internet 📡',
      'instruccion':
          'A veces WhatsApp o el navegador no cargan.\n\nCasi siempre es por una de dos razones muy fáciles de revisar.',
      'icono': Icons.wifi_off_rounded,
      'colorIcono': Color(0xFFE53E3E),
      'numero': 2,
    },
    {
      'tipo': 'tip',
      'titulo': 'Las 2 causas\nmás comunes 🔍',
      'instruccion':
          '1️⃣ El WiFi se apagó sin querer\n\n2️⃣ El modo avión ✈️ se activó sin querer (recuerda que apaga todo el internet)\n\nVamos a revisar las dos.',
      'icono': Icons.search_rounded,
      'colorIcono': Color(0xFFE53E3E),
    },
    {
      'tipo': 'sim_internet',
      'titulo': 'SOLUCIÓN\nRevisa el panel de arriba',
      'instruccion':
          'Mira el panel. El modo avión ✈️ está encendido — por eso no hay internet.\n\nTócalo para APAGARLO y recuperar la conexión.',
      'objetivo': 'con_internet',
      'ayuda': 'Toca el avión ✈️ para apagarlo',
    },
    {
      'tipo': 'accion_real',
      'titulo': 'En tu celular 📱',
      'instruccion':
          'Si algún día no tienes internet:\n\n1. Desliza desde arriba\n2. Revisa que el WiFi esté encendido\n3. Revisa que el avión ✈️ esté APAGADO',
      'icono': Icons.wifi_rounded,
      'colorIcono': Color(0xFFE53E3E),
    },

    // ── PROBLEMA 3: NO SUENA ──────────────────────────────
    {
      'tipo': 'problema',
      'titulo': 'PROBLEMA 3\nMi celular no suena 🔇',
      'instruccion':
          'A veces no escuchas las llamadas ni los mensajes.\n\nY te preocupa perderte una llamada importante de la familia.',
      'icono': Icons.volume_off_rounded,
      'colorIcono': Color(0xFFFFB300),
      'numero': 3,
    },
    {
      'tipo': 'tip',
      'titulo': '¿Por qué\nno suena? 🤔',
      'instruccion':
          'Casi siempre es porque:\n\n🔇 El modo silencio se activó sin querer\n\n🔉 O el volumen está muy bajo\n\nAmbas se arreglan en segundos.',
      'icono': Icons.help_outline_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
    {
      'tipo': 'sim_sonido',
      'titulo': 'SOLUCIÓN\nApaga el silencio',
      'instruccion':
          'El modo silencio 🔇 está encendido — por eso no suena.\n\nTócalo en el panel para APAGARLO y que tu celular vuelva a sonar.',
      'objetivo': 'con_sonido',
      'ayuda': 'Toca el símbolo de silencio 🔇 para apagarlo',
    },
    {
      'tipo': 'accion_real',
      'titulo': 'En tu celular 📱',
      'instruccion':
          'Si tu celular no suena:\n\n1. Revisa que el modo silencio esté apagado\n2. Sube el volumen con el botón del lado\n\nAsí no te pierdes ninguna llamada.',
      'icono': Icons.volume_up_rounded,
      'colorIcono': Color(0xFFFFB300),
    },

    // ── REPASO ────────────────────────────────────────────
    {
      'tipo': 'repaso',
      'titulo': '📋 Repaso rápido',
      'instruccion':
          'Ya sabes resolver los 3 problemas más comunes:',
      'icono': Icons.checklist_rounded,
      'colorIcono': Color(0xFF6B4EFF),
    },

    // ── CELEBRACION ───────────────────────────────────────
    {
      'tipo': 'celebracion',
      'titulo': '¡Módulo 2\nCompletado! 🎓',
      'instruccion':
          'Terminaste "Cómo navegar" completo.\n\nAhora sabes usar tu celular Y resolver problemas tú mismo.\n\n¡Eres oficialmente independiente! 🌟',
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
    _pulsoAnimation = Tween<double>(begin: 1.0, end: 1.13).animate(
      CurvedAnimation(parent: _pulsoController, curve: Curves.easeInOut),
    );

    // Controlador del "mantener presionado" (2 segundos)
    _presionarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        setState(() {
          _tiempoPresionado = _presionarController.value;
          // Al mantener presionado el tiempo completo, se apaga
          if (_presionarController.isCompleted &&
              _estadoSim == 'congelado') {
            _estadoSim = 'apagando';
            _secuenciaReinicio();
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
    _presionarController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Anima la secuencia apagando -> encendido -> normal
  Future<void> _secuenciaReinicio() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _estadoSim = 'encendiendo');
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _estadoSim = 'normal_reiniciado';
      _revisarObjetivo();
    });
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;
    _tiempoPresionado = 0.0;
    _presionarController.reset();

    // Estado inicial del simulador segun el tipo de paso
    switch (paso['tipo']) {
      case 'sim_reinicio':
        _estadoSim = 'congelado';
        break;
      case 'sim_internet':
        _estadoSim = 'sin_internet';
        break;
      case 'sim_sonido':
        _estadoSim = 'silencio';
        break;
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo != null && _estadoSim == objetivo) {
      _objetivoCumplido = true;
    }
  }

  // Cuando empieza a presionar el boton de encendido
  void _empezarPresion() {
    if (_estadoSim == 'congelado') {
      _presionarController.forward();
    }
  }

  // Si suelta antes de tiempo, se reinicia el contador
  void _soltarPresion() {
    if (_estadoSim == 'congelado' && !_presionarController.isCompleted) {
      _presionarController.reset();
      setState(() {
        _tiempoPresionado = 0.0;
        _mensajeGuia = 'No lo sueltes — mantén presionado';
      });
    }
  }

  // Toques en el panel (internet / sonido)
  void _tocarPanel(String elemento) {
    setState(() {
      _mensajeGuia = null;
      if (elemento == 'avion' && _estadoSim == 'sin_internet') {
        _estadoSim = 'con_internet';
      } else if (elemento == 'silencio' && _estadoSim == 'silencio') {
        _estadoSim = 'con_sonido';
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
        title: const Text('Cuando algo sale mal',
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
      case 'sim_reinicio':
        return _buildSimReinicio();
      case 'sim_internet':
        return _buildSimPanel(modo: 'internet');
      case 'sim_sonido':
        return _buildSimPanel(modo: 'sonido');
      case 'repaso':
        return _buildRepaso();
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
  // SIMULADOR DEL REINICIO (mantener presionado)
  // ═════════════════════════════════════════════════════════
  Widget _buildSimReinicio() {
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
          child: const Text('📱 Celular de práctica',
              style: TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
        // El celular con boton lateral
        SizedBox(
          width: 200,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cuerpo
              Container(
                width: 150,
                height: 260,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Center(child: _pantallaReinicio()),
              ),
              // Boton de encendido lateral (mantener presionado)
              Positioned(
                right: 18,
                top: 80,
                child: GestureDetector(
                  onTapDown: (_) => _empezarPresion(),
                  onTapUp: (_) => _soltarPresion(),
                  onTapCancel: () => _soltarPresion(),
                  child: AnimatedBuilder(
                    animation: _pulsoAnimation,
                    builder: (_, __) {
                      final resaltar = _estadoSim == 'congelado';
                      return Transform.scale(
                        scale: resaltar ? _pulsoAnimation.value : 1.0,
                        child: Container(
                          width: 14,
                          height: 54,
                          decoration: BoxDecoration(
                            color: resaltar
                                ? const Color(0xFF6B4EFF)
                                : const Color(0xFF3A3A55),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: resaltar
                                ? [
                                    BoxShadow(
                                        color: const Color(0xFF6B4EFF)
                                            .withOpacity(0.7),
                                        blurRadius: 14,
                                        spreadRadius: 1)
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Etiqueta del boton
              if (_estadoSim == 'congelado')
                Positioned(
                  right: -2,
                  top: 140,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4EFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Mantén\naquí ⏻',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Barra de "manteniendo presionado"
        if (_estadoSim == 'congelado' && _tiempoPresionado > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _tiempoPresionado,
                    backgroundColor: const Color(0xFFDED8FF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6B4EFF)),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Sigue presionando...',
                    style: TextStyle(
                        color: Color(0xFF6B4EFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }

  // Lo que se ve en la pantalla del celular segun el estado
  Widget _pantallaReinicio() {
    switch (_estadoSim) {
      case 'congelado':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulsoAnimation,
              builder: (_, __) => Icon(Icons.ac_unit_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 40 * _pulsoAnimation.value),
            ),
            const SizedBox(height: 10),
            const Text('Congelado',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const Text('(no responde)',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        );
      case 'apagando':
        return const Text('Apagando...',
            style: TextStyle(color: Colors.white54, fontSize: 12));
      case 'encendiendo':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                  color: Colors.white54, strokeWidth: 3),
            ),
            SizedBox(height: 12),
            Text('Encendiendo...',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        );
      case 'normal_reiniciado':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF059669), size: 44),
            SizedBox(height: 10),
            Text('¡Funciona!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ],
        );
      default:
        return const Text('10:30',
            style: TextStyle(color: Colors.white, fontSize: 16));
    }
  }

  // ═════════════════════════════════════════════════════════
  // SIMULADOR DEL PANEL (internet / sonido)
  // ═════════════════════════════════════════════════════════
  Widget _buildSimPanel({required String modo}) {
    // Que elemento resaltar y su estado
    final esInternet = modo == 'internet';
    final resuelto = esInternet
        ? _estadoSim == 'con_internet'
        : _estadoSim == 'con_sonido';

    final iconos = [
      {
        'id': 'wifi',
        'icono': Icons.wifi_rounded,
        'label': 'WiFi',
        'activo': true,
      },
      {
        'id': 'datos',
        'icono': Icons.signal_cellular_alt_rounded,
        'label': 'Datos',
        'activo': true,
      },
      {
        'id': 'avion',
        'icono': Icons.airplanemode_active_rounded,
        'label': 'Avión',
        // en modo internet arranca encendido (el problema)
        'activo': esInternet && _estadoSim == 'sin_internet',
      },
      {
        'id': 'silencio',
        'icono': Icons.do_not_disturb_on_rounded,
        'label': 'Silencio',
        // en modo sonido arranca encendido (el problema)
        'activo': !esInternet && _estadoSim == 'silencio',
      },
    ];

    // cual es el elemento que hay que tocar
    final objetivo = esInternet ? 'avion' : 'silencio';

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
          child: const Text('📱 Panel de tu celular',
              style: TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
        Container(
          width: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(22),
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
              // Estado de internet/sonido arriba
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: resuelto
                      ? const Color(0xFF059669).withOpacity(0.2)
                      : const Color(0xFFE53E3E).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      resuelto
                          ? (esInternet
                              ? Icons.wifi_rounded
                              : Icons.volume_up_rounded)
                          : (esInternet
                              ? Icons.wifi_off_rounded
                              : Icons.volume_off_rounded),
                      color: resuelto
                          ? const Color(0xFF059669)
                          : const Color(0xFFE53E3E),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      resuelto
                          ? (esInternet
                              ? '¡Internet funciona!'
                              : '¡Ya suena!')
                          : (esInternet
                              ? 'Sin internet'
                              : 'Sin sonido'),
                      style: TextStyle(
                        color: resuelto
                            ? const Color(0xFF059669)
                            : const Color(0xFFE53E3E),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Grid de iconos
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: iconos.map((item) {
                  final esObjetivo = item['id'] == objetivo && !resuelto;
                  final activo = item['activo'] as bool;
                  return AnimatedBuilder(
                    animation: _pulsoAnimation,
                    builder: (_, __) {
                      return Transform.scale(
                        scale: esObjetivo ? _pulsoAnimation.value : 1.0,
                        child: GestureDetector(
                          onTap: () => _tocarPanel(item['id'] as String),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: activo
                                      ? (esObjetivo
                                          ? const Color(0xFFE53E3E)
                                          : const Color(0xFF6B4EFF))
                                      : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: esObjetivo
                                      ? Border.all(
                                          color: Colors.white, width: 2.5)
                                      : null,
                                  boxShadow: esObjetivo
                                      ? [
                                          BoxShadow(
                                              color: const Color(0xFFE53E3E)
                                                  .withOpacity(0.6),
                                              blurRadius: 14,
                                              spreadRadius: 1)
                                        ]
                                      : null,
                                ),
                                child: Icon(item['icono'] as IconData,
                                    color: Colors.white, size: 26),
                              ),
                              const SizedBox(height: 4),
                              Text(item['label'] as String,
                                  style: TextStyle(
                                      color: esObjetivo
                                          ? const Color(0xFFE53E3E)
                                          : Colors.white54,
                                      fontSize: 10,
                                      fontWeight: esObjetivo
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
            ],
          ),
        ),
      ],
    );
  }

  // Tarjetas de repaso final
  Widget _buildRepaso() {
    final items = [
      {
        'icono': Icons.ac_unit_rounded,
        'problema': 'Se congela',
        'solucion': 'Mantén el botón de encendido',
        'color': const Color(0xFF0EA5E9),
      },
      {
        'icono': Icons.wifi_off_rounded,
        'problema': 'Sin internet',
        'solucion': 'Revisa WiFi y modo avión',
        'color': const Color(0xFFE53E3E),
      },
      {
        'icono': Icons.volume_off_rounded,
        'problema': 'No suena',
        'solucion': 'Apaga silencio y sube volumen',
        'color': const Color(0xFFFFB300),
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.15)),
                  child: Icon(item['icono'] as IconData,
                      color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['problema'] as String,
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(item['solucion'] as String,
                          style: const TextStyle(
                              color: Color(0xFF555577), fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_rounded,
                    color: color.withOpacity(0.5), size: 20),
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
          child: const Center(
              child: Text('🎓', style: TextStyle(fontSize: 64))),
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
        const Text('¡Ya resuelves problemas tú mismo! 🌟',
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
    final esSimulador = tipo.startsWith('sim_');

    String texto;
    Color color;

    if (esUltimo) {
      texto = '¡Completé el módulo! 🎓';
      color = const Color(0xFF059669);
    } else if (esSimulador && !_objetivoCumplido) {
      texto = paso['ayuda'] as String? ?? 'Practica en el celular';
      color = const Color(0xFFBBBBCC);
    } else if (esSimulador) {
      texto = '¡Lo lograste! Siguiente →';
      color = const Color(0xFF059669);
    } else if (tipo == 'accion_real') {
      texto = 'Entendido, siguiente →';
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