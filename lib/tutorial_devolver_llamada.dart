import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'devolver_llamada';

class TutorialDevolverLlamadaScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialDevolverLlamadaScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialDevolverLlamadaScreen> createState() =>
      _TutorialDevolverLlamadaScreenState();
}

class _TutorialDevolverLlamadaScreenState
    extends State<TutorialDevolverLlamadaScreen> with TickerProviderStateMixin {
  // Paleta oficial
  static const Color _morado = Color(0xFF6B4EFF);
  static const Color _verde = Color(0xFF059669);
  static const Color _amarillo = Color(0xFFFFB300);
  static const Color _azul = Color(0xFF0EA5E9);
  static const Color _rojo = Color(0xFFE53E3E);
  static const Color _fondo = Color(0xFFF0EEFF);
  static const Color _texto = Color(0xFF1A1A2E);
  static const Color _suave = Color(0xFF555577);

  int _pasoActual = 0;

  // pantalla: timbrando | perdida | inicio | recientes | contactos | ficha | llamando
  String _pantalla = 'inicio';
  // pestana activa del telefono: recientes | contactos | teclado | (vacio)
  String _tab = '';

  List<Map<String, String>> _llamadas = [];
  int? _filaSeleccionada;
  bool _mariaDevuelta = false;
  bool _animarCambio = false;
  bool _colgo = false;
  bool _panelInfo = false;
  int _badge = 0;

  String _llamadaCon = '';
  String _llamadaDesde = '';
  int _segundos = 0;
  Timer? _timerLlamada;
  Timer? _timerEscena;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;

  late AnimationController _pulso;
  late Animation<double> _pulsoAnim;
  late AnimationController _anillos;
  late AnimationController _onda;
  late ConfettiController _confetti;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': '¿Te llamaron y no\nalcanzaste? 📲',
      'instruccion':
          'No perdiste nada. Tu celular anota quién te llamó, aunque no contestes.\n\nHoy aprendes a ver esa lista y a devolver la llamada sin marcar ningún número.',
      'icono': Icons.phone_missed_rounded,
      'colorIcono': Color(0xFFE53E3E),
    },
    {
      'tipo': 'escena',
      'titulo': 'Mira lo que pasa 👀',
      'instruccion':
          'María te está llamando ahora mismo.\n\nNo toques nada. Solo observa qué hace el celular cuando no alcanzas a contestar.',
      'mapa': null,
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 1\nBusca la señal 🔴',
      'instruccion':
          '¿Ves el globito rojo con el 1 sobre el teléfono? Significa "tienes 1 llamada sin ver".\n\nAbre el teléfono y toca la pestaña Recientes.',
      'objetivo': 'recientes',
      'mapa': 'recientes',
      'ayuda': 'Abre el Teléfono y toca Recientes',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 2\nLee la lista 📋',
      'instruccion':
          'Esta lista son tus llamadas. Mira los símbolos:\n↙ verde: te llamaron y contestaste\n↗ azul: tú llamaste\n🔴 rojo: no alcanzaste\n\nToca la llamada ROJA de María.',
      'objetivo': 'seleccionada',
      'mapa': 'recientes',
      'ayuda': 'Toca la llamada roja de María',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 3\nDevuélvele la llamada 📞',
      'instruccion':
          'Se abrió un botón verde debajo del nombre de María.\n\nTócalo. No tienes que marcar ni un solo número: el celular ya sabe cuál es.',
      'objetivo': 'llamando',
      'mapa': 'recientes',
      'ayuda': 'Toca el botón verde de llamar',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 4\nTermina la llamada 🔴',
      'instruccion':
          'Ya hablaste con María y se despidieron.\n\nToca el botón ROJO para colgar. El botón rojo siempre termina la llamada, en cualquier teléfono.',
      'objetivo': 'colgado',
      'mapa': null,
      'ayuda': 'Toca el botón rojo para colgar',
    },
    {
      'tipo': 'sim_info',
      'titulo': 'Mira la lista ahora 🔄',
      'instruccion':
          'La llamada de María cambió sola: ya no está roja, ahora es azul ↗.\n\nEso significa "tú la llamaste". La lista se actualiza sin que hagas nada.',
      'mapa': 'recientes',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 5\nEl otro camino 👥',
      'instruccion':
          'Hay dos caminos para llamar a María: desde Recientes, o desde Contactos.\n\nToca la pestaña Contactos, abre a María y llámala con el botón verde.',
      'objetivo': 'llamando_ficha',
      'mapa': 'contactos',
      'ayuda': 'Ve a Contactos, abre a María y llámala',
    },
    {
      'tipo': 'sim_info',
      'titulo': 'El número desconocido ❓',
      'instruccion':
          'Mira la segunda llamada: es un número que no tienes guardado.\n\nSi fuera alguien conocido, con el botón ⓘ de la derecha puedes guardarlo en tus contactos. Tócalo para ver.',
      'mapa': 'recientes',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Mucho ojo',
      'instruccion':
          'No devuelvas llamadas a números raros, muy largos o de otros países.\n\nSi no reconoces el número y no dejaron mensaje, déjalo así. Nadie importante se enoja por eso.',
      'icono': Icons.shield_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Abre el teléfono y entra a Recientes.\n\nSolo míralas: ¿quién te llamó?, ¿cuáles contestaste? No llames a nadie todavía.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': Color(0xFF059669),
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste! 🏆',
      'instruccion':
          'Ya sabes ver quién te llamó y devolver la llamada.\n\nNunca más te vas a quedar con la duda. 👏',
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
    _onda = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);

    _confetti = ConfettiController(duration: const Duration(seconds: 5));

    _prepararPaso();
  }

  @override
  void dispose() {
    _timerLlamada?.cancel();
    _timerEscena?.cancel();
    _pulso.dispose();
    _anillos.dispose();
    _onda.dispose();
    _confetti.dispose();
    super.dispose();
  }

  // Historial base: siempre el mismo, para que el paso se pueda repetir
  List<Map<String, String>> _historialBase() {
    return [
      {
        'nombre': 'María',
        'numero': '3005551235',
        'tipo': 'perdida',
        'hora': 'Hace 5 minutos'
      },
      {
        'nombre': '',
        'numero': '3184447766',
        'tipo': 'entrante',
        'hora': 'Ayer, 3:20 p. m.'
      },
      {
        'nombre': 'Ana vecina',
        'numero': '3012223344',
        'tipo': 'saliente',
        'hora': 'Ayer, 10:05 a. m.'
      },
    ];
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;
    _timerLlamada?.cancel();
    _timerEscena?.cancel();

    _llamadas = _historialBase();
    _filaSeleccionada = null;
    _panelInfo = false;
    _colgo = false;
    _animarCambio = false;
    _segundos = 0;
    _llamadaCon = '';
    _llamadaDesde = '';
    _mariaDevuelta = false;
    _badge = 0;
    _tab = '';

    switch (_pasoActual) {
      case 1:
        _pantalla = 'timbrando';
        // La escena corre sola: timbra y despues queda como perdida
        _timerEscena = Timer(const Duration(milliseconds: 3200), () {
          if (!mounted) return;
          setState(() {
            _pantalla = 'perdida';
            _badge = 1;
          });
        });
        break;
      case 2:
        _pantalla = 'inicio';
        _badge = 1;
        break;
      case 3:
        _pantalla = 'recientes';
        _tab = 'recientes';
        break;
      case 4:
        _pantalla = 'recientes';
        _tab = 'recientes';
        _filaSeleccionada = 0;
        break;
      case 5:
        _pantalla = 'llamando';
        _llamadaCon = 'María';
        _llamadaDesde = 'recientes';
        _iniciarCronometro();
        break;
      case 6:
        _pantalla = 'recientes';
        _tab = 'recientes';
        _colgo = true;
        _mariaDevuelta = true;
        _animarCambio = true; // dispara la animacion rojo a azul
        break;
      case 7:
        _pantalla = 'contactos';
        _tab = 'contactos';
        _mariaDevuelta = true;
        break;
      case 8:
        _pantalla = 'recientes';
        _tab = 'recientes';
        _mariaDevuelta = true;
        break;
      default:
        _pantalla = 'inicio';
    }

    if (_mariaDevuelta) _llamadas[0]['tipo'] = 'saliente';
  }

  void _iniciarCronometro() {
    _timerLlamada?.cancel();
    _segundos = 0;
    _timerLlamada = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _segundos++);
    });
  }

  String _tiempo() {
    final m = (_segundos ~/ 60).toString().padLeft(2, '0');
    final s = (_segundos % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _numeroFormateado(String n) {
    if (n.length <= 3) return n;
    if (n.length <= 6) return '${n.substring(0, 3)} ${n.substring(3)}';
    return '${n.substring(0, 3)} ${n.substring(3, 6)} ${n.substring(6)}';
  }

  String _tituloFila(Map<String, String> l) =>
      l['nombre']!.isEmpty ? _numeroFormateado(l['numero']!) : l['nombre']!;

  // Nombre de la pantalla para la barra de ubicacion
  String _ubicacion() {
    switch (_pantalla) {
      case 'timbrando':
        return 'LLAMADA ENTRANTE';
      case 'perdida':
        return 'LLAMADA PERDIDA';
      case 'inicio':
        return 'PANTALLA DE INICIO';
      case 'recientes':
        return 'RECIENTES';
      case 'contactos':
        return 'CONTACTOS';
      case 'ficha':
        return 'FICHA DE MARÍA';
      case 'llamando':
        return 'EN LLAMADA';
      default:
        return '';
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'recientes':
        cumple = _pantalla == 'recientes';
        break;
      case 'seleccionada':
        cumple = _filaSeleccionada == 0;
        break;
      case 'llamando':
        cumple = _pantalla == 'llamando' && _llamadaCon == 'María';
        break;
      case 'colgado':
        cumple = _colgo;
        break;
      case 'llamando_ficha':
        cumple = _pantalla == 'llamando' && _llamadaDesde == 'ficha';
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // ─────────────────────────────────────────────
  // CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────
  void _tocarEnSimulador(String accion, {String? valor}) {
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'icono_telefono':
          if (_pantalla == 'inicio' || _pantalla == 'perdida') {
            _pantalla = 'recientes';
            _tab = 'recientes';
            _badge = 0;
          }
          break;

        case 'tab_recientes':
          _pantalla = 'recientes';
          _tab = 'recientes';
          _badge = 0;
          break;

        case 'tab_contactos':
          _pantalla = 'contactos';
          _tab = 'contactos';
          break;

        case 'tab_teclado':
          _mensajeGuia = 'El teclado ya lo aprendiste. Aquí no hace falta';
          break;

        case 'fila':
          final i = int.tryParse(valor ?? '');
          if (i == null) break;
          _filaSeleccionada = (_filaSeleccionada == i) ? null : i;
          _panelInfo = false;
          break;

        case 'llamar_fila':
          final i = int.tryParse(valor ?? '');
          if (i == null) break;
          _llamadaCon = _tituloFila(_llamadas[i]);
          _llamadaDesde = 'recientes';
          _pantalla = 'llamando';
          _iniciarCronometro();
          break;

        case 'info_fila':
          _panelInfo = !_panelInfo;
          break;

        case 'cerrar_panel':
          _panelInfo = false;
          break;

        case 'abrir_ficha':
          _pantalla = 'ficha';
          break;

        case 'volver_contactos':
          _pantalla = 'contactos';
          _tab = 'contactos';
          break;

        case 'llamar_ficha':
          _llamadaCon = 'María';
          _llamadaDesde = 'ficha';
          _pantalla = 'llamando';
          _iniciarCronometro();
          break;

        case 'colgar':
          _timerLlamada?.cancel();
          _colgo = true;
          if (_llamadaDesde == 'ficha') {
            _pantalla = 'ficha';
          } else {
            _pantalla = 'recientes';
            _tab = 'recientes';
          }
          break;

        case 'mensaje_ficha':
          _mensajeGuia = 'Los mensajes los vemos en la próxima lección';
          break;
      }

      _revisarObjetivo();
    });
  }

  Future<void> _avanzar() async {
    if (!_objetivoCumplido) return;
    _timerLlamada?.cancel();
    _timerEscena?.cancel();

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
    // ─────────────────────────────────────────────
  // PANTALLA DE LA LECCION
  // ─────────────────────────────────────────────
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
        title: const Text('Devolver una llamada',
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
    final mapa = paso['mapa'] as String?;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _morado, borderRadius: BorderRadius.circular(16)),
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
          // Mini mapa: en que pestana debe estar
          if (mapa != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Debes estar en:',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 8),
                  _miniMapa(mapa, Colors.white),
                  const SizedBox(width: 8),
                  Text(mapa.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Tres puntos: recientes, contactos, teclado
  Widget _miniMapa(String activo, Color color) {
    const orden = ['recientes', 'contactos', 'teclado'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: orden.map((t) {
        final es = t == activo;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: es ? 16 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: es ? color : color.withOpacity(0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }).toList(),
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
    if (tipo == 'sim' || tipo == 'sim_info' || tipo == 'escena') {
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
  // SIMULADOR
  // ═════════════════════════════════════════════
  Widget _buildSimulador() {
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
                    child: Stack(
                      children: [
                        AnimatedSwitcher(
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
                        if (_panelInfo) _buildPanelInfo(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Barra que siempre dice donde esta parado el usuario
  Widget _buildBarraUbicacion() {
    return TweenAnimationBuilder<double>(
      key: ValueKey('ubi_$_pantalla'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, t, __) {
        // Arranca en ambar y vuelve al morado: el cambio se nota
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
                child: Text(
                  'Estás en: ${_ubicacion()}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4),
                ),
              ),
              if (_tab.isNotEmpty) _miniMapa(_tab, Colors.white),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPantallaSim() {
    switch (_pantalla) {
      case 'timbrando':
        return _buildTimbrando();
      case 'perdida':
        return _buildPerdida();
      case 'inicio':
        return _buildInicio();
      case 'recientes':
        return _buildRecientes();
      case 'contactos':
        return _buildContactos();
      case 'ficha':
        return _buildFicha();
      case 'llamando':
        return _buildLlamando();
      default:
        return const SizedBox();
    }
  }

  // Escena: el telefono timbrando con anillos que se expanden
  Widget _buildTimbrando() {
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
          const SizedBox(height: 34),
          const Text('Llamada entrante',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 22),
          SizedBox(
            height: 150,
            child: AnimatedBuilder(
              animation: _anillos,
              builder: (_, __) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int i = 0; i < 3; i++)
                      _anillo((_anillos.value + i / 3) % 1.0),
                    Transform.rotate(
                      angle: math.sin(_anillos.value * math.pi * 8) * 0.06,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.22),
                          border:
                              Border.all(color: Colors.white54, width: 2),
                        ),
                        child: const Center(
                          child: Text('M',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          const Text('María',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('300 555 1235',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 26),
            child: Text('Está timbrando... solo observa',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12)),
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
  }

  Widget _anillo(double t) {
    return Opacity(
      opacity: (1 - t).clamp(0.0, 1.0) * 0.5,
      child: Container(
        width: 86 + (t * 70),
        height: 86 + (t * 70),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  // Resultado de la escena: llamada perdida
  Widget _buildPerdida() {
    return Container(
      color: const Color(0xFF2A1114),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, t, hijo) => Transform.scale(scale: t, child: hijo),
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _rojo.withOpacity(0.2),
                border: Border.all(color: _rojo, width: 3),
              ),
              child: const Icon(Icons.phone_missed_rounded,
                  color: _rojo, size: 44),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Llamada perdida',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('María · hace 5 minutos',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 26),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 26),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Tranquilo: el celular guardó quién te llamó. Ahora vas a aprender a devolverle la llamada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // Escritorio con el globito rojo
  Widget _buildInicio() {
    final resaltado = _pasoActual == 2;
    return Container(
      color: const Color(0xFF111122),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulsoAnim,
          builder: (_, __) => Transform.scale(
            scale: resaltado ? _pulsoAnim.value : 1.0,
            child: GestureDetector(
              onTap: () => _tocarEnSimulador('icono_telefono'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _verde,
                          border: resaltado
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: resaltado
                              ? [
                                  BoxShadow(
                                      color: _verde.withOpacity(0.7),
                                      blurRadius: 18,
                                      spreadRadius: 2)
                                ]
                              : null,
                        ),
                        child: const Icon(Icons.phone_rounded,
                            color: Colors.white, size: 36),
                      ),
                      if (_badge > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 650),
                            curve: Curves.elasticOut,
                            builder: (_, t, hijo) =>
                                Transform.scale(scale: t, child: hijo),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _rojo,
                                border: Border.all(
                                    color: const Color(0xFF111122), width: 2),
                              ),
                              child: Center(
                                child: Text('$_badge',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Teléfono',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
    // Lista de llamadas recientes
  Widget _buildRecientes() {
    return Container(
      color: const Color(0xFFF7F6FF),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            color: Colors.white,
            child: Row(
              children: [
                const Expanded(
                  child: Text('Recientes',
                      style: TextStyle(
                          color: _texto,
                          fontSize: 19,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          _buildLeyenda(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _llamadas.length,
              itemBuilder: (_, i) => _filaLlamada(i),
            ),
          ),
          _buildPestanas(),
        ],
      ),
    );
  }

  // Explica que significa cada simbolo
  Widget _buildLeyenda() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDED8FF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _itemLeyenda(Icons.call_received_rounded, _verde, 'Contestada'),
          _itemLeyenda(Icons.call_made_rounded, _azul, 'Tú llamaste'),
          _itemLeyenda(Icons.call_missed_rounded, _rojo, 'Perdida'),
        ],
      ),
    );
  }

  Widget _itemLeyenda(IconData icono, Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: color),
        const SizedBox(width: 4),
        Text(texto,
            style: const TextStyle(
                color: _suave, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _filaLlamada(int i) {
    final l = _llamadas[i];
    final esMaria = i == 0;
    final seleccionada = _filaSeleccionada == i;
    final resaltada = (_pasoActual == 3 && esMaria) ||
        (_pasoActual == 8 && i == 1 && !_panelInfo);

    // En el paso 6 la fila de Maria cambia de rojo a azul a la vista
    final animando = _animarCambio && esMaria && _pasoActual == 6;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animando ? 0 : 1, end: 1),
      duration: Duration(milliseconds: animando ? 1200 : 1),
      curve: Curves.easeInOut,
      builder: (_, t, __) {
        final color = animando
            ? Color.lerp(_rojo, _azul, t)!
            : _colorTipo(l['tipo']!);
        final icono = animando
            ? (t < 0.5 ? Icons.call_missed_rounded : Icons.call_made_rounded)
            : _iconoTipo(l['tipo']!);

        return AnimatedBuilder(
          animation: _pulsoAnim,
          builder: (_, __) => Transform.scale(
            scale: resaltada ? _pulsoAnim.value.clamp(1.0, 1.04) : 1.0,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: resaltada ? _amarillo : const Color(0xFFEDEAFF),
                    width: resaltada ? 2 : 1),
                boxShadow: resaltada
                    ? [BoxShadow(color: _amarillo.withOpacity(0.35), blurRadius: 12)]
                    : null,
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _tocarEnSimulador('fila', valor: '$i'),
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withOpacity(0.12)),
                            child: Icon(icono, size: 19, color: color),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_tituloFila(l),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: animando || l['tipo'] == 'perdida'
                                            ? color
                                            : _texto,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                Text(l['hora']!,
                                    style: const TextStyle(
                                        color: _suave, fontSize: 11)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _tocarEnSimulador('info_fila'),
                            child: AnimatedBuilder(
                              animation: _pulsoAnim,
                              builder: (_, __) => Transform.scale(
                                scale: (_pasoActual == 8 && i == 1)
                                    ? _pulsoAnim.value
                                    : 1.0,
                                child: Icon(Icons.info_outline_rounded,
                                    size: 20,
                                    color: (_pasoActual == 8 && i == 1)
                                        ? _amarillo
                                        : const Color(0xFFBBB6D8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Al tocar la fila se abre el boton de llamar
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 260),
                    crossFadeState: seleccionada
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: AnimatedBuilder(
                        animation: _pulsoAnim,
                        builder: (_, __) => Transform.scale(
                          scale: _pasoActual == 4 ? _pulsoAnim.value : 1.0,
                          child: GestureDetector(
                            onTap: () =>
                                _tocarEnSimulador('llamar_fila', valor: '$i'),
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: _verde,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: _verde.withOpacity(0.4),
                                      blurRadius: 10)
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.phone_rounded,
                                      color: Colors.white, size: 19),
                                  SizedBox(width: 8),
                                  Text('Llamar',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'perdida':
        return _rojo;
      case 'saliente':
        return _azul;
      default:
        return _verde;
    }
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'perdida':
        return Icons.call_missed_rounded;
      case 'saliente':
        return Icons.call_made_rounded;
      default:
        return Icons.call_received_rounded;
    }
  }

  // Panel del boton de informacion
  Widget _buildPanelInfo() {
    return GestureDetector(
      onTap: () => _tocarEnSimulador('cerrar_panel'),
      child: Container(
        color: Colors.black45,
        alignment: Alignment.bottomCenter,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 60, end: 0),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          builder: (_, y, hijo) =>
              Transform.translate(offset: Offset(0, y), child: hijo),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDED8FF),
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 14),
                const Text('318 444 7766',
                    style: TextStyle(
                        color: _texto,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                _opcionPanel(Icons.person_add_alt_1_rounded,
                    'Guardar en contactos', _morado),
                const SizedBox(height: 8),
                _opcionPanel(Icons.block_rounded, 'Bloquear número', _rojo),
                const SizedBox(height: 12),
                const Text('Toca fuera para cerrar',
                    style: TextStyle(color: _suave, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _opcionPanel(IconData icono, String texto, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 10),
          Text(texto,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Pestaña de contactos
  Widget _buildContactos() {
    final resaltada = _pasoActual == 7;
    return Container(
      color: const Color(0xFFF7F6FF),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            color: Colors.white,
            width: double.infinity,
            child: const Text('Contactos',
                style: TextStyle(
                    color: _texto,
                    fontSize: 19,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _pulsoAnim,
            builder: (_, __) => Transform.scale(
              scale: resaltada ? _pulsoAnim.value.clamp(1.0, 1.04) : 1.0,
              child: GestureDetector(
                onTap: () => _tocarEnSimulador('abrir_ficha'),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: resaltada ? _amarillo : const Color(0xFFEDEAFF),
                        width: resaltada ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _morado.withOpacity(0.12)),
                        child: const Center(
                          child: Text('M',
                              style: TextStyle(
                                  color: _morado,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('María',
                            style: TextStyle(
                                color: _texto,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFFBBB6D8), size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          _buildPestanas(),
        ],
      ),
    );
  }

  // Ficha de Maria
  Widget _buildFicha() {
    final resaltado = _pasoActual == 7;
    return Container(
      color: const Color(0xFFF7F6FF),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            color: Colors.white,
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _tocarEnSimulador('volver_contactos'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left_rounded, color: _morado, size: 22),
                  Text('Contactos',
                      style: TextStyle(color: _morado, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _morado.withOpacity(0.12),
              border: Border.all(color: _morado.withOpacity(0.35), width: 3),
            ),
            child: const Center(
              child: Text('M',
                  style: TextStyle(
                      color: _morado,
                      fontSize: 36,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('María',
              style: TextStyle(
                  color: _texto, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('300 555 1235',
              style: TextStyle(color: _suave, fontSize: 15)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulsoAnim,
                builder: (_, __) => Transform.scale(
                  scale: resaltado ? _pulsoAnim.value : 1.0,
                  child: _accionFicha(Icons.phone_rounded, 'Llamar', _verde,
                      'llamar_ficha'),
                ),
              ),
              const SizedBox(width: 26),
              _accionFicha(
                  Icons.message_rounded, 'Mensaje', _azul, 'mensaje_ficha'),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _accionFicha(
      IconData icono, String texto, Color color, String accion) {
    return GestureDetector(
      onTap: () => _tocarEnSimulador(accion),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.35), blurRadius: 10)
              ],
            ),
            child: Icon(icono, color: Colors.white, size: 25),
          ),
          const SizedBox(height: 6),
          Text(texto,
              style: const TextStyle(
                  color: _suave, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Llamada en curso, con barras de sonido animadas
  Widget _buildLlamando() {
    final resaltado = _pasoActual == 5;
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
          const SizedBox(height: 30),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
            child: Center(
              child: Text(
                _llamadaCon.isEmpty ? '?' : _llamadaCon[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(_llamadaCon,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(_segundos == 0 ? 'Llamando...' : _tiempo(),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85), fontSize: 15)),
          const SizedBox(height: 22),
          // Barras de sonido mientras hablan
          AnimatedBuilder(
            animation: _onda,
            builder: (_, __) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(5, (i) {
                  final fase = (_onda.value + i * 0.18) % 1.0;
                  final alto = 10 + math.sin(fase * math.pi) * 26;
                  return Container(
                    width: 6,
                    height: _segundos == 0 ? 10 : alto,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              );
            },
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulsoAnim,
            builder: (_, __) => Transform.scale(
              scale: resaltado ? _pulsoAnim.value : 1.0,
              child: GestureDetector(
                onTap: () => _tocarEnSimulador('colgar'),
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _rojo,
                    border: resaltado
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                          color: _rojo.withOpacity(resaltado ? 0.8 : 0.5),
                          blurRadius: resaltado ? 20 : 12,
                          spreadRadius: resaltado ? 3 : 0)
                    ],
                  ),
                  child: const Icon(Icons.call_end_rounded,
                      color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // Barra inferior de pestañas
  Widget _buildPestanas() {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: Color(0xFF13131F),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          _pestana(Icons.access_time_rounded, 'Recientes', 'recientes',
              'tab_recientes'),
          _pestana(Icons.person_rounded, 'Contactos', 'contactos',
              'tab_contactos'),
          _pestana(Icons.dialpad_rounded, 'Teclado', 'teclado', 'tab_teclado'),
        ],
      ),
    );
  }

  Widget _pestana(IconData icono, String texto, String clave, String accion) {
    final activa = _tab == clave;
    final resaltada = (_pasoActual == 2 && clave == 'recientes') ||
        (_pasoActual == 7 && clave == 'contactos' && _pantalla != 'ficha');
    return Expanded(
      child: AnimatedBuilder(
        animation: _pulsoAnim,
        builder: (_, __) => Transform.scale(
          scale: resaltada ? _pulsoAnim.value : 1.0,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador(accion),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: resaltada
                          ? _amarillo.withOpacity(0.25)
                          : Colors.transparent,
                      border: resaltada
                          ? Border.all(color: _amarillo, width: 2)
                          : null,
                    ),
                    child: Icon(icono,
                        size: 22,
                        color: activa
                            ? _morado
                            : (resaltada ? _amarillo : Colors.white54)),
                  ),
                  const SizedBox(height: 2),
                  Text(texto,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              activa ? FontWeight.bold : FontWeight.normal,
                          color: activa ? _morado : Colors.white54)),
                ],
              ),
            ),
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
          child: const Center(
              child: Text('📲', style: TextStyle(fontSize: 60))),
        ),
        const SizedBox(height: 16),
        const Text('¡Ya nadie se te pierde!',
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