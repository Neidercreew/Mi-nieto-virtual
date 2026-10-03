import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'contestar_llamada';

class TutorialContestarLlamadaScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialContestarLlamadaScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialContestarLlamadaScreen> createState() =>
      _TutorialContestarLlamadaScreenState();
}

class _TutorialContestarLlamadaScreenState
    extends State<TutorialContestarLlamadaScreen> with TickerProviderStateMixin {
  static const Color _morado = Color(0xFF6B4EFF);
  static const Color _verde = Color(0xFF059669);
  static const Color _amarillo = Color(0xFFFFB300);
  static const Color _rojo = Color(0xFFE53E3E);
  static const Color _fondo = Color(0xFFF0EEFF);
  static const Color _texto = Color(0xFF1A1A2E);

  int _pasoActual = 0;

  // pantalla: reposo | entrante | en_llamada | pantalla_negra | bloqueado
  //           | fotos | desconocido | silenciar | rechazada
  String _pantalla = 'reposo';
  String _llamadaCon = 'María';

  bool _altavoz = false;
  bool _colgo = false;
  bool _rechazo = false;
  bool _volvio = false;          // alejó el celular de la oreja
  bool _desdeBanner = false;     // contestó desde la barrita
  bool _desdeBloqueado = false;
  double _arrastre = 0;
  int _volumen = 3;              // 3 = alto, 0 = silencio
  int _segundos = 0;
  Timer? _timer;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;

  late AnimationController _pulso;
  late Animation<double> _pulsoAnim;
  late AnimationController _anillos;
  late AnimationController _flecha;
  late ConfettiController _confetti;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Cuando te\nllaman 📞',
      'instruccion':
          'Una llamada no siempre se ve igual en la pantalla. Depende de qué estaba haciendo tu celular cuando sonó.\n\nHoy vas a reconocer todas las formas y a saber qué hacer en cada una.',
      'icono': Icons.ring_volume_rounded,
      'colorIcono': Color(0xFF059669),
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 1\nContesta 🟢',
      'instruccion':
          'El celular estaba despierto, así que salen dos botones grandes.\n\nEl VERDE contesta, el ROJO rechaza. Toca el verde.',
      'objetivo': 'contestado',
      'ayuda': 'Toca el botón verde para contestar',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 2\n¿Se apagó? 🌑',
      'instruccion':
          'Te acercaste el celular a la oreja y la pantalla se puso NEGRA.\n\nNo se dañó ni colgaste: se apaga sola para que no la toques con el cachete. Aleja el celular y mira qué pasa.',
      'objetivo': 'volvio',
      'ayuda': 'Toca "Alejar de la oreja" para que vuelva',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 3\n¿No oyes bien? 🔊',
      'instruccion':
          'Toca ALTAVOZ y la voz sale más fuerte, sin pegarte el celular a la oreja.\n\nAsí también puedes dejarlo en la mesa mientras hablas.',
      'objetivo': 'altavoz',
      'ayuda': 'Toca el botón de Altavoz',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 4\nCuelga 🔴',
      'instruccion':
          'Ya se despidieron.\n\nToca el botón ROJO. Ese botón siempre termina la llamada, en cualquier celular.',
      'objetivo': 'colgado',
      'ayuda': 'Toca el botón rojo para colgar',
    },
    {
      'tipo': 'sim_info',
      'titulo': 'Ahora lo difícil 🔒',
      'instruccion':
          'El celular está bloqueado y suena. Mira bien: NO hay botones redondos.\n\nHay una flecha. Aquí es donde se queda mucha gente sin poder contestar.',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 5\nDesliza hacia arriba ⬆️',
      'instruccion':
          'Pon el dedo sobre el botón verde y, SIN SOLTARLO, empújalo hacia arriba.\n\nNo es tocar: es empujar. Despacio, no hay afán.',
      'objetivo': 'contestado_bloqueado',
      'ayuda': 'Arrastra el botón verde hacia arriba, sin soltarlo',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 6\nLlaman mientras usas el celular 📷',
      'instruccion':
          'Estabas viendo tus fotos y entró una llamada.\n\nAquí no aparece la pantalla grande: sale una barrita arriba con dos botones pequeños. Toca "Contestar" en esa barrita.',
      'objetivo': 'contestado_banner',
      'ayuda': 'Toca Contestar en la barrita de arriba',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 7\nRechaza sin pena 🔴',
      'instruccion':
          'Te llama un número que no conoces. No tienes ninguna obligación de contestar.\n\nToca el botón ROJO para rechazar.',
      'objetivo': 'rechazado',
      'ayuda': 'Toca el botón rojo para rechazar',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 8\nEstá sonando en misa 🤫',
      'instruccion':
          'Suena en un lugar donde da pena. Mira el costado del celular: ahí están los botones de volumen.\n\nToca el de ABAJO hasta que quede en silencio. Ojo: no le estás colgando, solo dejas de hacer ruido.',
      'objetivo': 'silenciado',
      'ayuda': 'Toca el botón de volumen del lado hasta silenciar',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Si se cae la llamada',
      'instruccion':
          'A veces la llamada se corta sola por la señal. No es culpa tuya ni dañaste nada.\n\nEntras a Recientes y la devuelves, como ya aprendiste.',
      'icono': Icons.signal_cellular_alt_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora de verdad 📱',
      'instruccion':
          'Pídele a alguien de confianza que te llame.\n\nPractica con el celular despierto y también bloqueado. Esa segunda es la que cuesta.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': Color(0xFF059669),
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste! 🏆',
      'instruccion':
          'Reconoces la llamada en cualquier pantalla, contestas bloqueado, pones altavoz, rechazas y silencias.\n\nYa nadie te agarra desprevenido. 👏',
      'icono': Icons.emoji_events_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial.clamp(0, _pasos.length - 1);

    _pulso = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..repeat(reverse: true);
    _pulsoAnim = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _pulso, curve: Curves.easeInOut));

    _anillos = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
    _flecha = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();

    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    _prepararPaso();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulso.dispose();
    _anillos.dispose();
    _flecha.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;
    _timer?.cancel();

    _altavoz = false;
    _colgo = false;
    _rechazo = false;
    _volvio = false;
    _desdeBanner = false;
    _desdeBloqueado = false;
    _arrastre = 0;
    _volumen = 3;
    _segundos = 0;
    _llamadaCon = 'María';

    switch (_pasoActual) {
      case 1:
        _pantalla = 'entrante';
        break;
      case 2:
        _pantalla = 'pantalla_negra';
        _segundos = 12;
        _iniciarCronometro();
        break;
      case 3:
        _pantalla = 'en_llamada';
        _segundos = 18;
        _iniciarCronometro();
        break;
      case 4:
        _pantalla = 'en_llamada';
        _altavoz = true;
        _segundos = 46;
        _iniciarCronometro();
        break;
      case 5:
      case 6:
        _pantalla = 'bloqueado';
        break;
      case 7:
        _pantalla = 'fotos';
        break;
      case 8:
        _pantalla = 'desconocido';
        _llamadaCon = '318 444 7766';
        break;
      case 9:
        _pantalla = 'silenciar';
        break;
      default:
        _pantalla = 'reposo';
    }
  }

  void _iniciarCronometro() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _segundos++);
    });
  }

  String _tiempo() {
    final m = (_segundos ~/ 60).toString().padLeft(2, '0');
    final s = (_segundos % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _ubicacion() {
    switch (_pantalla) {
      case 'reposo':
        return 'PANTALLA DE INICIO';
      case 'entrante':
        return 'LLAMADA ENTRANTE';
      case 'en_llamada':
        return 'EN LLAMADA';
      case 'pantalla_negra':
        return 'EN LLAMADA (PANTALLA APAGADA)';
      case 'bloqueado':
        return 'CELULAR BLOQUEADO';
      case 'fotos':
        return 'TUS FOTOS';
      case 'desconocido':
        return 'NÚMERO DESCONOCIDO';
      case 'silenciar':
        return 'SONANDO EN PÚBLICO';
      case 'rechazada':
        return 'LLAMADA RECHAZADA';
      default:
        return '';
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'contestado':
        cumple = _pantalla == 'en_llamada';
        break;
      case 'volvio':
        cumple = _volvio;
        break;
      case 'altavoz':
        cumple = _altavoz;
        break;
      case 'colgado':
        cumple = _colgo;
        break;
      case 'contestado_bloqueado':
        cumple = _pantalla == 'en_llamada' && _desdeBloqueado;
        break;
      case 'contestado_banner':
        cumple = _pantalla == 'en_llamada' && _desdeBanner;
        break;
      case 'rechazado':
        cumple = _rechazo;
        break;
      case 'silenciado':
        cumple = _volumen == 0;
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // ─────────────────────────────────────────────
  // CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────
  void _tocarEnSimulador(String accion) {
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'contestar':
          _pantalla = 'en_llamada';
          _iniciarCronometro();
          break;

        case 'contestar_banner':
          _desdeBanner = true;
          _pantalla = 'en_llamada';
          _iniciarCronometro();
          break;

        case 'rechazar':
        case 'rechazar_banner':
          _timer?.cancel();
          _rechazo = true;
          _pantalla = 'rechazada';
          break;

        case 'alejar':
          _volvio = true;
          _pantalla = 'en_llamada';
          break;

        case 'altavoz':
          _altavoz = !_altavoz;
          break;

        case 'silenciar_micro':
          _mensajeGuia = 'Eso apaga tu micrófono: la otra persona no te oye';
          break;

        case 'colgar':
          _timer?.cancel();
          _colgo = true;
          _pantalla = 'reposo';
          break;

        case 'tocar_bloqueado':
          _mensajeGuia = 'Aquí no sirve tocar: mantén el dedo y desliza arriba';
          break;

        case 'bajar_volumen':
          if (_volumen > 0) _volumen--;
          break;

        case 'subir_volumen':
          if (_volumen < 3) _volumen++;
          break;
      }

      _revisarObjetivo();
    });
  }

  void _arrastrar(double dy) {
    setState(() => _arrastre = (_arrastre - dy / 150).clamp(0.0, 1.0));
  }

  void _soltarArrastre() {
    if (_arrastre > 0.6) {
      setState(() {
        _arrastre = 1;
        _desdeBloqueado = true;
        _pantalla = 'en_llamada';
        _iniciarCronometro();
        _revisarObjetivo();
      });
    } else {
      setState(() {
        _arrastre = 0;
        _mensajeGuia = 'Casi. Empuja un poco más arriba antes de soltar';
      });
    }
  }

  Future<void> _avanzar() async {
    if (!_objetivoCumplido) return;
    _timer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    final esUltimo = _pasoActual == _pasos.length - 1;

    if (userId != null) {
      await ApiService.guardarPaso(userId, _leccionId, _pasoActual + 1,
          completada: esUltimo);
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

    if (_pasos[_pasoActual]['tipo'] == 'celebracion') _confetti.play();
  }
    @override
  Widget build(BuildContext context) {
    final paso = _pasos[_pasoActual];

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _morado),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Contestar una llamada',
            style: TextStyle(
                color: _texto, fontSize: 18, fontWeight: FontWeight.w700)),
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
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            gravity: 0.1,
            colors: const [_morado, _amarillo, _verde, Color(0xFF8B5CF6)],
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
                  color: _morado, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (_pasoActual + 1) / _pasos.length),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor: const Color(0xFFDED8FF),
                valueColor: const AlwaysStoppedAnimation<Color>(_morado),
                minHeight: 8,
              ),
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
      decoration:
          BoxDecoration(color: _morado, borderRadius: BorderRadius.circular(16)),
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
        color: _amarillo.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amarillo, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_rounded, color: _amarillo, size: 18),
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
    if (tipo == 'sim' || tipo == 'sim_info') {
      return SingleChildScrollView(child: _buildSimulador());
    } else if (tipo == 'celebracion') {
      return _buildTrofeo();
    }
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

  // ═════════════════════════════════════════════
  // SIMULADOR (con botones laterales en el chasis)
  // ═════════════════════════════════════════════
  Widget _buildSimulador() {
    final resaltaVolumen = _pasoActual == 9;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: _verde.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20)),
          child: const Text('📱 Teléfono de práctica — toca sin miedo',
              style: TextStyle(
                  color: _verde, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          width: 292,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Cuerpo del celular
              Container(
                width: 270,
                decoration: BoxDecoration(
                  color: _texto,
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
                    height: 520,
                    child: Column(
                      children: [
                        _buildBarraUbicacion(),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (hijo, anim) => FadeTransition(
                              opacity: anim,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.97, end: 1.0)
                                    .animate(anim),
                                child: hijo,
                              ),
                            ),
                            child: Container(
                                key: ValueKey(_pantalla),
                                child: _buildPantallaSim()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Botones fisicos del costado
              Positioned(
                right: 4,
                top: 120,
                child: Column(
                  children: [
                    _botonChasis(
                        '＋', 'subir_volumen', false, 'Subir volumen'),
                    const SizedBox(height: 8),
                    _botonChasis(
                        '－', 'bajar_volumen', resaltaVolumen, 'Bajar volumen'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Un boton dibujado en el borde del celular
  Widget _botonChasis(
      String simbolo, String accion, bool resaltado, String etiqueta) {
    return AnimatedBuilder(
      animation: _pulsoAnim,
      builder: (_, __) => Transform.scale(
        scale: resaltado ? _pulsoAnim.value.clamp(1.0, 1.08) : 1.0,
        child: GestureDetector(
          onTap: () => _tocarEnSimulador(accion),
          child: Tooltip(
            message: etiqueta,
            child: Container(
              width: 18,
              height: 44,
              decoration: BoxDecoration(
                color: resaltado ? _amarillo : const Color(0xFF3A3A55),
                borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(6), left: Radius.circular(3)),
                boxShadow: resaltado
                    ? [BoxShadow(color: _amarillo.withOpacity(0.6), blurRadius: 12)]
                    : null,
              ),
              child: Center(
                child: Text(simbolo,
                    style: TextStyle(
                        color: resaltado ? _texto : Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarraUbicacion() {
    return TweenAnimationBuilder<double>(
      key: ValueKey('ubi_$_pantalla'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, t, __) {
        final color = Color.lerp(_amarillo, _morado, t)!;
        return Container(
          width: double.infinity,
          color: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.place_rounded,
                  size: 15, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Estás en: ${_ubicacion()}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPantallaSim() {
    switch (_pantalla) {
      case 'entrante':
        return _buildEntrante(conocido: true, enPublico: false);
      case 'silenciar':
        return _buildEntrante(conocido: true, enPublico: true);
      case 'desconocido':
        return _buildEntrante(conocido: false, enPublico: false);
      case 'en_llamada':
        return _buildEnLlamada();
      case 'pantalla_negra':
        return _buildPantallaNegra();
      case 'bloqueado':
        return _buildBloqueado();
      case 'fotos':
        return _buildFotos();
      case 'rechazada':
        return _buildFinal(
            Icons.phone_disabled_rounded, _rojo, 'Llamada rechazada',
            'No pasó nada malo. Estás en tu derecho');
      default:
        return _buildFinal(Icons.check_circle_rounded, _verde,
            'Llamada terminada', 'Tu celular vuelve a quedar tranquilo');
    }
  }

  Widget _buildFinal(
      IconData icono, Color color, String titulo, String sub) {
    return Container(
      color: const Color(0xFF111122),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: color, size: 54),
              const SizedBox(height: 14),
              Text(titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // Llamada entrante. enPublico muestra el indicador de volumen
  Widget _buildEntrante({required bool conocido, required bool enPublico}) {
    final resaltaVerde = _pasoActual == 1;
    final resaltaRojo = _pasoActual == 8;
    final silencio = _volumen == 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: conocido
              ? const [Color(0xFF0B3D2E), Color(0xFF059669)]
              : const [Color(0xFF2C2C3E), Color(0xFF4A4A63)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          if (enPublico) _buildIndicadorVolumen(silencio),
          const SizedBox(height: 6),
          Text(silencio && enPublico ? 'En silencio' : 'Llamada entrante',
              style: TextStyle(
                  color: silencio && enPublico ? _amarillo : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SizedBox(
            height: 118,
            child: AnimatedBuilder(
              animation: _anillos,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  if (!silencio)
                    for (int i = 0; i < 3; i++)
                      _anillo((_anillos.value + i / 3) % 1.0),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.22),
                      border: Border.all(color: Colors.white54, width: 2),
                    ),
                    child: Center(
                      child: conocido
                          ? const Text('M',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold))
                          : const Icon(Icons.person_off_rounded,
                              color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(conocido ? 'María' : '318 444 7766',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(conocido ? 'Tu contacto' : 'No está en tus contactos',
              style: TextStyle(
                  color: conocido ? Colors.white70 : _amarillo, fontSize: 12)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _botonLlamada(Icons.call_end_rounded, _rojo, 'rechazar',
                    'Rechazar', resaltaRojo),
                _botonLlamada(Icons.phone_rounded, _verde, 'contestar',
                    'Contestar', resaltaVerde),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Barritas de volumen que bajan al tocar el boton del costado
  Widget _buildIndicadorVolumen(bool silencio) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(silencio ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              size: 16, color: silencio ? _amarillo : Colors.white),
          const SizedBox(width: 8),
          for (int i = 0; i < 3; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 16,
              height: 8,
              decoration: BoxDecoration(
                color: i < _volumen ? Colors.white : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _anillo(double t) {
    return Opacity(
      opacity: (1 - t).clamp(0.0, 1.0) * 0.5,
      child: Container(
        width: 72 + (t * 56),
        height: 72 + (t * 56),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _botonLlamada(IconData icono, Color color, String accion,
      String etiqueta, bool resaltado) {
    return AnimatedBuilder(
      animation: _pulsoAnim,
      builder: (_, __) => Transform.scale(
        scale: resaltado ? _pulsoAnim.value : 1.0,
        child: GestureDetector(
          onTap: () => _tocarEnSimulador(accion),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: resaltado
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(resaltado ? 0.8 : 0.45),
                        blurRadius: resaltado ? 20 : 12,
                        spreadRadius: resaltado ? 3 : 0)
                  ],
                ),
                child: Icon(icono, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 5),
              Text(etiqueta,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
    // La pantalla se apaga sola al acercarla a la oreja
  Widget _buildPantallaNegra() {
    final resaltado = _pasoActual == 2;
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            builder: (_, t, __) => Opacity(
              opacity: 0.25 + (t * 0.15),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hearing_rounded, color: Colors.white, size: 40),
                  SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 34),
                    child: Text(
                      'La pantalla se apagó sola porque la tienes pegada a la oreja.\n\nLa llamada sigue, tranquilo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulsoAnim,
            builder: (_, __) => Transform.scale(
              scale: resaltado ? _pulsoAnim.value : 1.0,
              child: GestureDetector(
                onTap: () => _tocarEnSimulador('alejar'),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 26),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: resaltado ? _amarillo : Colors.white24,
                        width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe_down_alt_rounded,
                          color: resaltado ? _amarillo : Colors.white70,
                          size: 20),
                      const SizedBox(width: 8),
                      Text('Alejar de la oreja',
                          style: TextStyle(
                              color: resaltado ? _amarillo : Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
  }

  // Celular bloqueado: hay que deslizar
  Widget _buildBloqueado() {
    final resaltado = _pasoActual == 6;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14142B), Color(0xFF2B2B52)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded,
                  size: 13, color: Colors.white.withOpacity(0.6)),
              const SizedBox(width: 5),
              Text('Bloqueado',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: AnimatedBuilder(
              animation: _anillos,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  for (int i = 0; i < 2; i++)
                    Opacity(
                      opacity: (1 - ((_anillos.value + i / 2) % 1.0))
                              .clamp(0.0, 1.0) *
                          0.35,
                      child: Container(
                        width: 66 + (((_anillos.value + i / 2) % 1.0) * 40),
                        height: 66 + (((_anillos.value + i / 2) % 1.0) * 40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                      border: Border.all(color: Colors.white38, width: 2),
                    ),
                    child: const Center(
                      child: Text('M',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('María',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const Text('te está llamando',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
          const Spacer(),
          // Carril de arrastre
          SizedBox(
            height: 170,
            width: 110,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: 74,
                  child: AnimatedBuilder(
                    animation: _flecha,
                    builder: (_, __) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final fase = (_flecha.value + i * 0.25) % 1.0;
                        return Opacity(
                          opacity: (1 - fase) * (resaltado ? 0.9 : 0.3),
                          child: Transform.translate(
                            offset: Offset(0, -fase * 10),
                            child: Icon(Icons.keyboard_arrow_up_rounded,
                                color: resaltado ? _amarillo : Colors.white,
                                size: 24),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8 + (_arrastre * 108),
                  child: GestureDetector(
                    onVerticalDragUpdate: (d) => _arrastrar(d.delta.dy),
                    onVerticalDragEnd: (_) => _soltarArrastre(),
                    onTap: () => _tocarEnSimulador('tocar_bloqueado'),
                    child: AnimatedBuilder(
                      animation: _pulsoAnim,
                      builder: (_, __) => Transform.scale(
                        scale: (resaltado && _arrastre == 0)
                            ? _pulsoAnim.value
                            : 1.0,
                        child: Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(
                                _verde, Colors.white, _arrastre * 0.25),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5), width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: _verde
                                      .withOpacity(0.5 + _arrastre * 0.4),
                                  blurRadius: 18 + (_arrastre * 14),
                                  spreadRadius: _arrastre * 4)
                            ],
                          ),
                          child: const Icon(Icons.phone_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(
              _arrastre > 0.6
                  ? '¡Suelta ahora!'
                  : 'Desliza hacia arriba para contestar',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _arrastre > 0.6 ? _amarillo : Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Estaba viendo fotos y entra la llamada como barrita arriba
  Widget _buildFotos() {
    final resaltado = _pasoActual == 7;
    return Container(
      color: const Color(0xFFF7F6FF),
      child: Column(
        children: [
          // La barrita de llamada entra desde arriba
          TweenAnimationBuilder<double>(
            tween: Tween(begin: -70, end: 0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (_, y, hijo) =>
                Transform.translate(offset: Offset(0, y), child: hijo),
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: resaltado ? _amarillo : const Color(0xFFDED8FF),
                    width: resaltado ? 2 : 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _verde.withOpacity(0.15)),
                    child: const Icon(Icons.phone_rounded,
                        color: _verde, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('María',
                            style: TextStyle(
                                color: _texto,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        Text('Llamando...',
                            style: TextStyle(
                                color: Color(0xFF777799), fontSize: 10)),
                      ],
                    ),
                  ),
                  _miniBoton(Icons.call_end_rounded, _rojo, 'rechazar_banner',
                      false),
                  const SizedBox(width: 6),
                  _miniBoton(Icons.phone_rounded, _verde, 'contestar_banner',
                      resaltado),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text('Tus fotos',
                    style: TextStyle(
                        color: _texto,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Rejilla de fotos de mentiras
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(9, (i) {
                const emojis = ['🌻', '👵', '🏞️', '🐕', '🎂', '👨‍👩‍👧', '🌅', '🍲', '⛪'];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEAFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(emojis[i],
                        style: const TextStyle(fontSize: 22)),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBoton(
      IconData icono, Color color, String accion, bool resaltado) {
    return AnimatedBuilder(
      animation: _pulsoAnim,
      builder: (_, __) => Transform.scale(
        scale: resaltado ? _pulsoAnim.value : 1.0,
        child: GestureDetector(
          onTap: () => _tocarEnSimulador(accion),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border:
                  resaltado ? Border.all(color: _amarillo, width: 2) : null,
              boxShadow: resaltado
                  ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 12)]
                  : null,
            ),
            child: Icon(icono, color: Colors.white, size: 17),
          ),
        ),
      ),
    );
  }

  // Llamada en curso
  Widget _buildEnLlamada() {
    final resaltaAltavoz = _pasoActual == 3;
    final resaltaColgar = _pasoActual == 4;
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
          const SizedBox(height: 22),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
            child: Center(
              child: Text(_llamadaCon[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          Text(_llamadaCon,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(_tiempo(),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85), fontSize: 14)),
          const SizedBox(height: 10),
          AnimatedOpacity(
            opacity: _altavoz ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _amarillo.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _amarillo, width: 1.5),
              ),
              child: const Text('🔊 Altavoz encendido: se oye más fuerte',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _botonEnLlamada(Icons.volume_up_rounded, 'Altavoz', _altavoz,
                  'altavoz', resaltaAltavoz),
              const SizedBox(width: 24),
              _botonEnLlamada(Icons.mic_off_rounded, 'Silenciar', false,
                  'silenciar_micro', false),
            ],
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulsoAnim,
            builder: (_, __) => Transform.scale(
              scale: resaltaColgar ? _pulsoAnim.value : 1.0,
              child: GestureDetector(
                onTap: () => _tocarEnSimulador('colgar'),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _rojo,
                    border: resaltaColgar
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                          color: _rojo.withOpacity(resaltaColgar ? 0.8 : 0.5),
                          blurRadius: resaltaColgar ? 20 : 12,
                          spreadRadius: resaltaColgar ? 3 : 0)
                    ],
                  ),
                  child: const Icon(Icons.call_end_rounded,
                      color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _botonEnLlamada(IconData icono, String etiqueta, bool activo,
      String accion, bool resaltado) {
    return AnimatedBuilder(
      animation: _pulsoAnim,
      builder: (_, __) => Transform.scale(
        scale: resaltado ? _pulsoAnim.value : 1.0,
        child: GestureDetector(
          onTap: () => _tocarEnSimulador(accion),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activo ? _amarillo : Colors.white.withOpacity(0.18),
                  border: resaltado
                      ? Border.all(color: _amarillo, width: 2.5)
                      : Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: activo
                      ? [
                          BoxShadow(
                              color: _amarillo.withOpacity(0.6),
                              blurRadius: 16)
                        ]
                      : null,
                ),
                child:
                    Icon(icono, color: activo ? _texto : Colors.white, size: 24),
              ),
              const SizedBox(height: 5),
              Text(etiqueta,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
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
                  color: _amarillo.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 4)
            ],
          ),
          child:
              const Center(child: Text('📞', style: TextStyle(fontSize: 60))),
        ),
        const SizedBox(height: 16),
        const Text('¡Ya sabes contestar!',
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
    final esPractica = tipo == 'sim';

    String texto;
    Color color;

    if (esUltimo) {
      texto = '¡Terminé! 🎉';
      color = _verde;
    } else if (esPractica && !_objetivoCumplido) {
      texto = paso['ayuda'] as String? ?? 'Practica en el teléfono de arriba';
      color = const Color(0xFFBBBBCC);
    } else if (esPractica) {
      texto = '¡Lo lograste! Siguiente →';
      color = _verde;
    } else if (tipo == 'accion_real') {
      texto = 'Ya practiqué, siguiente →';
      color = _morado;
    } else {
      texto = 'Entendido, siguiente →';
      color = _morado;
    }

    final habilitado = !esPractica || _objetivoCumplido;

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