import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'telefono_hacer_llamada';

class TutorialHacerLlamadaScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialHacerLlamadaScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialHacerLlamadaScreen> createState() =>
      _TutorialHacerLlamadaScreenState();
}

class _TutorialHacerLlamadaScreenState
    extends State<TutorialHacerLlamadaScreen> with TickerProviderStateMixin {
  int _pasoActual = 0;

  // ─────────────────────────────────────────────────────────
  // ESTADO DEL SIMULADOR
  // pantalla: 'inicio' | 'teclado' | 'llamando'
  // ─────────────────────────────────────────────────────────
  String _pantalla = 'inicio';
  String _numeroMarcado = '';
  int _segundosLlamada = 0;
  Timer? _timerLlamada;

  // El numero objetivo que deben marcar en la practica
  final String _numeroObjetivo = '3005551234';

  bool _objetivoCumplido = false;
  String? _mensajeGuia;

  late AnimationController _pulsoController;
  late Animation<double> _pulsoAnimation;

  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Hacer una\nllamada 📞',
      'instruccion':
          'Hoy vas a aprender a llamar por teléfono con tu celular.\n\nPracticaremos aquí primero, en un teléfono de mentiras. ¡Sin miedo!',
      'icono': Icons.phone_rounded,
      'colorIcono': Color(0xFF059669),
    },
    {
      'tipo': 'analogia',
      'titulo': '¿Cómo funciona? ☎️',
      'instruccion':
          'Es como el teléfono de casa de toda la vida.\n\nLa diferencia: los números están en la pantalla, y los tocas con el dedo en vez de apretar teclas.',
      'icono': Icons.dialpad_rounded,
      'colorIcono': Color(0xFF059669),
    },
    {
      'tipo': 'sim_abrir',
      'titulo': 'PRÁCTICA 1\nAbre el Teléfono 📞',
      'instruccion':
          'Este es un celular de práctica.\n\nBusca el ícono verde del teléfono y tócalo.',
      'objetivo': 'teclado',
      'resalta': 'icono_telefono',
      'ayuda': 'Toca el ícono verde del teléfono 📞',
    },
    {
      'tipo': 'sim_info',
      'titulo': 'Este es el teclado 🔢',
      'instruccion':
          'Aquí están los números para marcar.\n\nSon grandes para que los veas bien. Cada uno tiene sus letras, como los teléfonos de antes.',
      'objetivo': null,
      'resalta': 'teclado',
    },
    {
      'tipo': 'sim_marcar', 
      'titulo': 'PRÁCTICA 2\nMarca este número 📱',
      'instruccion':
          'Marca: 300 555 1234\n\nSi te equivocas, usa borrar ⌫',
      'objetivo': 'numero_completo',
      'resalta': 'teclado',
      'ayuda': 'Marca 300 555 1234 con el teclado',
    },
    {
      'tipo': 'sim_info_borrar',
      'titulo': 'El botón de borrar ⌫',
      'instruccion':
          '¿Ves el botón de borrar ⌫ al lado del número?\n\nSi marcas mal, tócalo y borra el último número. Puedes corregir todas las veces que quieras. ¡Equivocarse está bien!',
      'objetivo': null,
      'resalta': 'boton_borrar',
    },
    {
      'tipo': 'sim_llamar',
      'titulo': 'PRÁCTICA 3\n¡Haz la llamada! 📞',
      'instruccion':
          'El número ya está listo.\n\nToca el botón VERDE grande para llamar.',
      'objetivo': 'llamando',
      'resalta': 'boton_llamar',
      'ayuda': 'Toca el botón verde de llamar 📞',
    },
    {
      'tipo': 'sim_info_llamando',
      'titulo': 'Estás llamando ☎️',
      'instruccion':
          'La llamada está en curso. Del otro lado suena el teléfono.\n\nCuando la persona contesta, hablan. El reloj muestra cuánto llevas hablando.',
      'objetivo': null,
      'resalta': null,
    },
    {
      'tipo': 'sim_colgar',
      'titulo': 'PRÁCTICA 4\nCuelga la llamada 🔴',
      'instruccion':
          'Cuando terminas de hablar, tocas el botón ROJO para colgar.\n\nEse botón rojo SIEMPRE es para terminar la llamada. Tócalo.',
      'objetivo': 'colgado',
      'resalta': 'boton_colgar',
      'ayuda': 'Toca el botón rojo para colgar 🔴',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Un consejo',
      'instruccion':
          'Antes de llamar, revisa que el número esté bien.\n\nY recuerda: el botón VERDE llama, el botón ROJO cuelga. Siempre es así en cualquier teléfono.',
      'icono': Icons.lightbulb_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Abre el teléfono en tu celular real y marca un número que conozcas.\n\nPuedes llamar a alguien de confianza para saludar. ¡Tú puedes!',
      'icono': Icons.smartphone_rounded,
      'colorIcono': Color(0xFF059669),
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste! 🏆',
      'instruccion':
          'Ya sabes hacer llamadas con tu celular.\n\n¡Ahora puedes comunicarte con quien quieras! 📞',
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
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _pulsoAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulsoController, curve: Curves.easeInOut),
    );

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    _prepararPaso();
  }

  @override
  void dispose() {
    _timerLlamada?.cancel();
    _pulsoController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    switch (paso['tipo']) {
      case 'sim_abrir':
        _pantalla = 'inicio';
        _numeroMarcado = '';
        break;
      case 'sim_info':
        _pantalla = 'teclado';
        _numeroMarcado = '';
        break;
      case 'sim_marcar':
        _pantalla = 'teclado';
        _numeroMarcado = '';
        break;
      case 'sim_info_borrar':
        _pantalla = 'teclado';
        // dejamos un numero parcial para que vean el boton borrar
        if (_numeroMarcado.isEmpty) _numeroMarcado = _numeroObjetivo;
        break;
      case 'sim_llamar':
        _pantalla = 'teclado';
        _numeroMarcado = _numeroObjetivo;
        break;
      case 'sim_info_llamando':
        _pantalla = 'llamando';
        _numeroMarcado = _numeroObjetivo;
        break;
      case 'sim_colgar':
        _pantalla = 'llamando';
        _numeroMarcado = _numeroObjetivo;
        _iniciarCronometroLlamada();
        break;
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'teclado':
        cumple = _pantalla == 'teclado';
        break;
      case 'numero_completo':
        cumple = _numeroMarcado == _numeroObjetivo;
        break;
      case 'llamando':
        cumple = _pantalla == 'llamando';
        break;
      case 'colgado':
        cumple = _pantalla == 'teclado' && _colgo;
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  bool _colgo = false;

  void _iniciarCronometroLlamada() {
    _timerLlamada?.cancel();
    _segundosLlamada = 0;
    _timerLlamada = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _segundosLlamada++);
    });
  }

  String _tiempoLlamada() {
    final m = (_segundosLlamada ~/ 60).toString().padLeft(2, '0');
    final s = (_segundosLlamada % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Formatea el numero: 300 555 1234
  String _numeroFormateado(String n) {
    if (n.isEmpty) return '';
    if (n.length <= 3) return n;
    if (n.length <= 6) return '${n.substring(0, 3)} ${n.substring(3)}';
    return '${n.substring(0, 3)} ${n.substring(3, 6)} ${n.substring(6)}';
  }

  // ─────────────────────────────────────────────────────────
  // EL CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────────────────
  void _tocarEnSimulador(String accion, {String? tecla}) {
    setState(() {
      _mensajeGuia = null;

      // Abrir la app
      if (accion == 'icono_telefono' && _pantalla == 'inicio') {
        _pantalla = 'teclado';
        _revisarObjetivo();
        return;
      }

      // Marcar un numero (solo en pasos donde deben marcar)
      if (accion == 'tecla' && _pantalla == 'teclado' && tecla != null) {
        // Solo permitimos marcar si estamos en un paso de marcado o libre
        final tipo = _pasos[_pasoActual]['tipo'];
        if (tipo == 'sim_marcar' || tipo == 'sim_info') {
          if (_numeroMarcado.length < 10) {
            _numeroMarcado += tecla;
          }
        }
        _revisarObjetivo();
        return;
      }

      // Borrar ultimo digito
      if (accion == 'boton_borrar' && _pantalla == 'teclado') {
        if (_numeroMarcado.isNotEmpty) {
          _numeroMarcado =
              _numeroMarcado.substring(0, _numeroMarcado.length - 1);
        }
        _revisarObjetivo();
        return;
      }

      // Llamar
      if (accion == 'boton_llamar' && _pantalla == 'teclado') {
        if (_numeroMarcado.isNotEmpty) {
          _pantalla = 'llamando';
          _iniciarCronometroLlamada();
        } else {
          _mensajeGuia = 'Primero marca un número';
        }
        _revisarObjetivo();
        return;
      }

      // Colgar
      if (accion == 'boton_colgar' && _pantalla == 'llamando') {
        _timerLlamada?.cancel();
        _pantalla = 'teclado';
        _colgo = true;
        _revisarObjetivo();
        return;
      }
    });
  }

  Future<void> _avanzar() async {
    if (!_objetivoCumplido) return;

    _timerLlamada?.cancel();

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
      _colgo = false;
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
        title: const Text('Hacer una llamada',
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

    if (tipo.startsWith('sim_')) {
      return SingleChildScrollView(
        child: _buildSimulador(paso['resalta'] as String?),
      );
    }else if (tipo == 'celebracion') {
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
  // EL SIMULADOR DE TELEFONO
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
          child: const Text('📱 Teléfono de práctica — toca sin miedo',
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
              height: 460,
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
      case 'teclado':
        return _buildTeclado(resalta);
      case 'llamando':
        return _buildLlamando(resalta);
      default:
        return const SizedBox();
    }
  }

  Widget _buildInicio(String? resalta) {
    final esResaltado = resalta == 'icono_telefono';
    return Container(
      color: const Color(0xFF111122),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulsoAnimation,
          builder: (_, __) {
            return Transform.scale(
              scale: esResaltado ? _pulsoAnimation.value : 1.0,
              child: GestureDetector(
                onTap: () => _tocarEnSimulador('icono_telefono'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF059669),
                        border: esResaltado
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: esResaltado
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF059669)
                                        .withOpacity(0.7),
                                    blurRadius: 18,
                                    spreadRadius: 2)
                              ]
                            : null,
                      ),
                      child: const Icon(Icons.phone_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 8),
                    const Text('Teléfono',
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

  // La pantalla del teclado de marcado
  Widget _buildTeclado(String? resalta) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          // Zona donde aparece el numero marcado
          Container(
            height: 56,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _numeroMarcado.isEmpty
                      ? 'Marca un número'
                      : _numeroFormateado(_numeroMarcado),
                  style: TextStyle(
                    color: _numeroMarcado.isEmpty
                        ? Colors.white38
                        : Colors.white,
                    fontSize: _numeroMarcado.isEmpty ? 15 : 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                if (_numeroMarcado.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  _buildBotonBorrar(resalta == 'boton_borrar'),
                ],
              ],
            ),
          ),
          // El teclado numerico
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: resalta == 'teclado'
                    ? Border.all(color: const Color(0xFFFFB300), width: 2)
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _filaTeclas(['1', '2', '3'], ['', 'ABC', 'DEF']),
                  _filaTeclas(['4', '5', '6'], ['GHI', 'JKL', 'MNO']),
                  _filaTeclas(['7', '8', '9'], ['PQRS', 'TUV', 'WXYZ']),
                  _filaTeclas(['*', '0', '#'], ['', '+', '']),
                  const SizedBox(height: 6),
                  // Boton de llamar
                  _buildBotonLlamar(resalta == 'boton_llamar'),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaTeclas(List<String> numeros, List<String> letras) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) {
          return _tecla(numeros[i], letras[i]);
        }),
      ),
    );
  }

  Widget _tecla(String numero, String letras) {
    return GestureDetector(
      onTap: () => _tocarEnSimulador('tecla', tecla: numero),
      child: Container(
        width: 46,
        height: 46,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(numero,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500)),
            if (letras.isNotEmpty)
              Text(letras,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 8,
                      letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonBorrar(bool resaltado) {
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        return Transform.scale(
          scale: resaltado ? _pulsoAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador('boton_borrar'),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: resaltado
                    ? const Color(0xFFFFB300).withOpacity(0.3)
                    : Colors.transparent,
                border: resaltado
                    ? Border.all(color: const Color(0xFFFFB300), width: 2)
                    : null,
              ),
              child: Icon(Icons.backspace_rounded,
                  color: resaltado ? const Color(0xFFFFB300) : Colors.white54,
                  size: 22),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBotonLlamar(bool resaltado) {
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        return Transform.scale(
          scale: resaltado ? _pulsoAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador('boton_llamar'),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669),
                border: resaltado
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: resaltado
                    ? [
                        BoxShadow(
                            color: const Color(0xFF059669).withOpacity(0.7),
                            blurRadius: 18,
                            spreadRadius: 2)
                      ]
                    : [
                        BoxShadow(
                            color: const Color(0xFF059669).withOpacity(0.4),
                            blurRadius: 10)
                      ],
              ),
              child: const Icon(Icons.phone_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }

  // La pantalla de llamada en curso
  Widget _buildLlamando(String? resalta) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B3D2E), Color(0xFF059669)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: const Center(
                child: Text('👤', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 16),
          Text(
            _numeroFormateado(_numeroMarcado),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _segundosLlamada == 0 ? 'Llamando...' : _tiempoLlamada(),
            style: TextStyle(
                color: Colors.white.withOpacity(0.85), fontSize: 15),
          ),
          const Spacer(),
          // Boton de colgar
          _buildBotonColgar(resalta == 'boton_colgar'),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBotonColgar(bool resaltado) {
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        return Transform.scale(
          scale: resaltado ? _pulsoAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador('boton_colgar'),
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE53E3E),
                border: resaltado
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: resaltado
                    ? [
                        BoxShadow(
                            color: const Color(0xFFE53E3E).withOpacity(0.8),
                            blurRadius: 20,
                            spreadRadius: 3)
                      ]
                    : [
                        BoxShadow(
                            color: const Color(0xFFE53E3E).withOpacity(0.5),
                            blurRadius: 12)
                      ],
              ),
              child: const Icon(Icons.call_end_rounded,
                  color: Colors.white, size: 32),
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
          child: const Center(
              child: Text('📞', style: TextStyle(fontSize: 60))),
        ),
        const SizedBox(height: 16),
        const Text('¡Ya sabes hacer llamadas!',
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
    final esSimulador = tipo.startsWith('sim_') &&
        tipo != 'sim_info' &&
        tipo != 'sim_info_borrar' &&
        tipo != 'sim_info_llamando';

    String texto;
    Color color;

    if (esUltimo) {
      texto = '¡Terminé! 🎉';
      color = const Color(0xFF059669);
    } else if (esSimulador && !_objetivoCumplido) {
      texto = paso['ayuda'] as String? ?? 'Practica en el teléfono de arriba';
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