import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'camara_borrar';

class TutorialBorrarFotosScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialBorrarFotosScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialBorrarFotosScreen> createState() =>
      _TutorialBorrarFotosScreenState();
}

class _TutorialBorrarFotosScreenState extends State<TutorialBorrarFotosScreen>
    with TickerProviderStateMixin {
  int _pasoActual = 0;

  // ─────────────────────────────────────────────────────────
  // ESTADO DEL SIMULADOR
  // pantalla: 'foto_fav' | 'foto_borrar' | 'papelera'
  // ─────────────────────────────────────────────────────────
  String _pantalla = 'foto_fav';
  bool _esFavorita = false;
  bool _mostrandoConfirmacion = false;
  bool _fotoEnPapelera = false;
  bool _fotoRecuperada = false;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;

  late AnimationController _pulsoController;
  late Animation<double> _pulsoAnimation;

  // "Pop" de la estrella al marcar favorita
  late AnimationController _estrellaController;
  late Animation<double> _estrellaAnimation;

  // Confirmacion que sube desde abajo
  late AnimationController _confirmController;
  late Animation<double> _confirmAnimation;

  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Organizar y\nborrar 🗑️',
      'instruccion':
          'Ya sabes ver tus fotos.\n\nHoy vas a aprender a guardar las que amas y a borrar las que no sirven — ¡sin miedo!',
      'icono': Icons.auto_awesome_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },

    // ── FAVORITAS ─────────────────────────────────────────
    {
      'tipo': 'analogia',
      'titulo': 'Tus fotos\nfavoritas ⭐',
      'instruccion':
          'A veces tienes una foto que amas y quieres encontrarla fácil.\n\nMarcarla como FAVORITA es como ponerla en un marco especial.',
      'icono': Icons.star_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
    {
      'tipo': 'sim_favorita',
      'titulo': 'PRÁCTICA 1\nMarca tu favorita ⭐',
      'instruccion':
          'Esta es una foto que te encanta.\n\nToca la estrella ⭐ para marcarla como favorita.',
      'objetivo': 'favorita',
      'resalta': 'boton_estrella',
      'ayuda': 'Toca la estrella ⭐',
    },
    {
      'tipo': 'sim_info',
      'titulo': '¡Guardada! ⭐',
      'instruccion':
          'La estrella se puso dorada.\n\nAhora esta foto está en tus FAVORITAS, y la vas a encontrar fácil y rápido cuando la busques.',
      'objetivo': null,
      'resalta': null,
    },

    // ── BORRAR ────────────────────────────────────────────
    {
      'tipo': 'analogia',
      'titulo': 'Borrar sin\nmiedo 🗑️',
      'instruccion':
          'A veces tomas una foto movida o repetida que no sirve.\n\nBorrarla es como botar un papel a la basura... pero esta basura se puede recuperar por un tiempo.',
      'icono': Icons.delete_outline_rounded,
      'colorIcono': Color(0xFFE53E3E),
    },
    {
      'tipo': 'sim_borrar',
      'titulo': 'PRÁCTICA 2\nBorra esta foto 🗑️',
      'instruccion':
          'Esta foto salió movida, no sirve.\n\nToca el bote de basura 🗑️ para borrarla.',
      'objetivo': 'confirmando',
      'resalta': 'boton_papelera',
      'ayuda': 'Toca el bote de basura 🗑️',
    },
    {
      'tipo': 'sim_confirmar',
      'titulo': 'Siempre pregunta ✋',
      'instruccion':
          'Fíjate: antes de borrar, tu celular SIEMPRE te pregunta si estás seguro.\n\nAsí nunca borras algo por accidente. Toca "Sí, borrar".',
      'objetivo': 'borrado',
      'resalta': 'boton_confirmar',
      'ayuda': 'Toca "Sí, borrar" para confirmar',
    },
    {
      'tipo': 'sim_info',
      'titulo': 'No se perdió 😌',
      'instruccion':
          'La foto NO desapareció para siempre.\n\nSe fue a la PAPELERA, donde queda guardada por un tiempo por si te arrepientes.',
      'objetivo': null,
      'resalta': null,
    },

    // ── PAPELERA ──────────────────────────────────────────
    {
      'tipo': 'sim_papelera',
      'titulo': 'PRÁCTICA 3\nAbre la Papelera 🗑️',
      'instruccion':
          'Vamos a ver la papelera.\n\nToca el botón de la Papelera para ver lo que borraste.',
      'objetivo': 'en_papelera',
      'resalta': 'boton_ver_papelera',
      'ayuda': 'Toca el botón de la Papelera 🗑️',
    },
    {
      'tipo': 'sim_recuperar',
      'titulo': 'PRÁCTICA 4\nRecupera la foto ↩️',
      'instruccion':
          '¡Ahí está la foto que borraste!\n\nSi te arrepentiste, toca RECUPERAR y vuelve a tu galería.',
      'objetivo': 'recuperada',
      'resalta': 'boton_recuperar',
      'ayuda': 'Toca el botón RECUPERAR ↩️',
    },
    {
      'tipo': 'sim_info',
      'titulo': '¡De vuelta! 🎉',
      'instruccion':
          'La foto volvió a tu galería, sana y salva.\n\n¿Ves? Borrar NUNCA es para siempre de inmediato. Siempre tienes una segunda oportunidad.',
      'objetivo': null,
      'resalta': null,
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Importante',
      'instruccion':
          'La papelera se vacía SOLA después de un tiempo (normalmente 30 días).\n\nAsí que si borraste algo importante por error, recupéralo pronto, no lo dejes pasar mucho.',
      'icono': Icons.schedule_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'En tu galería real:\n\n⭐ Marca como favorita una foto que ames\n\n🗑️ Borra una que no sirva (sin miedo, recuerda la papelera)',
      'icono': Icons.smartphone_rounded,
      'colorIcono': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Módulo Cámara\nCompletado! 🎓',
      'instruccion':
          'Terminaste todo el módulo de la cámara.\n\nTomar fotos ✅  Selfies ✅  Videos ✅\nVer la galería ✅  Organizar y borrar ✅\n\n¡Eres todo un experto con tu cámara! 📸',
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

    _estrellaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _estrellaAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
        parent: _estrellaController, curve: Curves.easeInOut));

    _confirmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _confirmAnimation = CurvedAnimation(
      parent: _confirmController,
      curve: Curves.easeOut,
    );

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 6));

    _prepararPaso();
  }

  @override
  void dispose() {
    _pulsoController.dispose();
    _estrellaController.dispose();
    _confirmController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;
    _mostrandoConfirmacion = false;

    switch (paso['tipo']) {
      case 'sim_favorita':
        _pantalla = 'foto_fav';
        _esFavorita = false;
        break;
      case 'sim_info':
        // varios pasos de info segun donde estemos
        if (_pasoActual == 3) {
          _pantalla = 'foto_fav';
          _esFavorita = true;
        } else if (_pasoActual == 8) {
          _pantalla = 'foto_borrar';
        } else if (_pasoActual == 11) {
          _pantalla = 'papelera';
          _fotoRecuperada = true;
        }
        break;
      case 'sim_borrar':
        _pantalla = 'foto_borrar';
        _mostrandoConfirmacion = false;
        break;
      case 'sim_confirmar':
        _pantalla = 'foto_borrar';
        _mostrandoConfirmacion = true;
        _confirmController.forward(from: 0);
        break;
      case 'sim_papelera':
        _pantalla = 'foto_borrar';
        _fotoEnPapelera = true;
        break;
      case 'sim_recuperar':
        _pantalla = 'papelera';
        _fotoEnPapelera = true;
        _fotoRecuperada = false;
        break;
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'favorita':
        cumple = _esFavorita;
        break;
      case 'confirmando':
        cumple = _mostrandoConfirmacion;
        break;
      case 'borrado':
        cumple = _fotoEnPapelera;
        break;
      case 'en_papelera':
        cumple = _pantalla == 'papelera';
        break;
      case 'recuperada':
        cumple = _fotoRecuperada;
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

      switch (accion) {
        case 'boton_estrella':
          if (!_esFavorita) {
            _esFavorita = true;
            _estrellaController.forward(from: 0);
          }
          break;

        case 'boton_papelera':
          if (!_mostrandoConfirmacion) {
            _mostrandoConfirmacion = true;
            _confirmController.forward(from: 0);
          }
          break;

        case 'boton_cancelar':
          _mostrandoConfirmacion = false;
          break;

        case 'boton_confirmar':
          _mostrandoConfirmacion = false;
          _fotoEnPapelera = true;
          break;

        case 'boton_ver_papelera':
          _pantalla = 'papelera';
          break;

        case 'boton_recuperar':
          _fotoRecuperada = true;
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
        title: const Text('Organizar y borrar',
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
              Color(0xFF8B5CF6),
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
  // EL SIMULADOR
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
              child: _pantalla == 'papelera'
                  ? _buildPapelera(resalta)
                  : _buildFotoConAcciones(resalta),
            ),
          ),
        ),
      ],
    );
  }

  // Una foto abierta con barra de acciones (favorita, papelera)
  Widget _buildFotoConAcciones(String? resalta) {
    // Cual foto mostrar segun el contexto
    final esFotoFav = _pantalla == 'foto_fav';
    final emoji = esFotoFav ? '🌷' : '📷';
    final fondo = esFotoFav
        ? const [Color(0xFFFFE9D6), Color(0xFFFFD6E8)]
        : const [Color(0xFF888888), Color(0xFFAAAAAA)];

    return Stack(
      children: [
        // La foto
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: fondo,
              ),
            ),
            child: Center(
              child: esFotoFav
                  ? Text(emoji, style: const TextStyle(fontSize: 90))
                  : Transform.rotate(
                      angle: 0.1,
                      child: Opacity(
                        opacity: 0.7,
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 80)),
                      ),
                    ),
            ),
          ),
        ),

        // Etiqueta "movida" si es la foto a borrar
        if (!esFotoFav)
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Foto movida 😖',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ),

        // Si esta en papelera ya, tapa con mensaje
        if (_fotoEnPapelera && _pantalla == 'foto_borrar')
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delete_rounded,
                        color: Colors.white54, size: 40),
                    const SizedBox(height: 8),
                    const Text('Movida a la papelera',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 16),
                    // Boton para ver la papelera
                    AnimatedBuilder(
                      animation: _pulsoAnimation,
                      builder: (_, __) {
                        final resaltar = resalta == 'boton_ver_papelera';
                        return Transform.scale(
                          scale: resaltar ? _pulsoAnimation.value : 1.0,
                          child: GestureDetector(
                            onTap: () =>
                                _tocarEnSimulador('boton_ver_papelera'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B4EFF),
                                borderRadius: BorderRadius.circular(20),
                                border: resaltar
                                    ? Border.all(
                                        color: Colors.white, width: 2)
                                    : null,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text('Ver Papelera',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Barra de acciones abajo (estrella + papelera)
        if (!(_fotoEnPapelera && _pantalla == 'foto_borrar'))
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: Colors.black.withOpacity(0.35),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Estrella favorita
                  _accionEstrella(resalta == 'boton_estrella'),
                  // Compartir (decorativo)
                  const Icon(Icons.share_rounded,
                      color: Colors.white54, size: 26),
                  // Papelera
                  _accionPapelera(resalta == 'boton_papelera'),
                ],
              ),
            ),
          ),

        // Dialogo de confirmacion
        if (_mostrandoConfirmacion) _buildConfirmacion(resalta),
      ],
    );
  }

  Widget _accionEstrella(bool resaltado) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulsoAnimation, _estrellaAnimation]),
      builder: (_, __) {
        final escala = _esFavorita
            ? _estrellaAnimation.value
            : (resaltado ? _pulsoAnimation.value : 1.0);
        return Transform.scale(
          scale: escala,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador('boton_estrella'),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: resaltado && !_esFavorita
                    ? const Color(0xFFFFB300).withOpacity(0.3)
                    : Colors.transparent,
                border: resaltado && !_esFavorita
                    ? Border.all(color: const Color(0xFFFFB300), width: 2)
                    : null,
              ),
              child: Icon(
                _esFavorita ? Icons.star_rounded : Icons.star_border_rounded,
                color: _esFavorita
                    ? const Color(0xFFFFB300)
                    : Colors.white,
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _accionPapelera(bool resaltado) {
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) {
        return Transform.scale(
          scale: resaltado ? _pulsoAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _tocarEnSimulador('boton_papelera'),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: resaltado
                    ? const Color(0xFFE53E3E).withOpacity(0.3)
                    : Colors.transparent,
                border: resaltado
                    ? Border.all(color: const Color(0xFFE53E3E), width: 2)
                    : null,
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: resaltado ? const Color(0xFFE53E3E) : Colors.white,
                  size: 30),
            ),
          ),
        );
      },
    );
  }

  // Dialogo "¿Seguro?" que sube desde abajo
  Widget _buildConfirmacion(String? resalta) {
    return AnimatedBuilder(
      animation: _confirmAnimation,
      builder: (_, __) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, (1 - _confirmAnimation.value) * 200),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.help_outline_rounded,
                      color: Color(0xFFE53E3E), size: 32),
                  const SizedBox(height: 8),
                  const Text('¿Borrar esta foto?',
                      style: TextStyle(
                          color: Color(0xFF202124),
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Podrás recuperarla de la papelera',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFF5F6368), fontSize: 11)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Cancelar
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _tocarEnSimulador('boton_cancelar'),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('Cancelar',
                                  style: TextStyle(
                                      color: Color(0xFF5F6368),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Confirmar
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _pulsoAnimation,
                          builder: (_, __) {
                            final resaltar = resalta == 'boton_confirmar';
                            return Transform.scale(
                              scale: resaltar ? _pulsoAnimation.value : 1.0,
                              child: GestureDetector(
                                onTap: () =>
                                    _tocarEnSimulador('boton_confirmar'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53E3E),
                                    borderRadius: BorderRadius.circular(12),
                                    border: resaltar
                                        ? Border.all(
                                            color: const Color(0xFFFFB300),
                                            width: 2)
                                        : null,
                                  ),
                                  child: const Center(
                                    child: Text('Sí, borrar',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // La pantalla de la papelera
  Widget _buildPapelera(String? resalta) {
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded,
                      color: Color(0xFF5F6368), size: 16),
                  SizedBox(width: 6),
                  Text('Papelera',
                      style: TextStyle(
                          color: Color(0xFF202124),
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Expanded(
            child: _fotoRecuperada
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Color(0xFF059669), size: 44),
                        SizedBox(height: 10),
                        Text('¡Foto recuperada!',
                            style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Volvió a tu galería',
                            style: TextStyle(
                                color: Color(0xFF5F6368), fontSize: 11)),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Se borrará sola en 30 días',
                              style: TextStyle(
                                  color: Color(0xFF9AA0A6), fontSize: 10)),
                        ),
                        const SizedBox(height: 10),
                        // La foto borrada
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFFDADCE0)),
                          ),
                          child: Row(
                            children: [
                              // Miniatura
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF888888),
                                      Color(0xFFAAAAAA)
                                    ],
                                  ),
                                ),
                                child: const Center(
                                    child: Text('📷',
                                        style: TextStyle(fontSize: 24))),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Foto movida',
                                        style: TextStyle(
                                            color: Color(0xFF202124),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    Text('Borrada hoy',
                                        style: TextStyle(
                                            color: Color(0xFF5F6368),
                                            fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Boton recuperar
                        AnimatedBuilder(
                          animation: _pulsoAnimation,
                          builder: (_, __) {
                            final resaltar = resalta == 'boton_recuperar';
                            return Transform.scale(
                              scale: resaltar ? _pulsoAnimation.value : 1.0,
                              child: GestureDetector(
                                onTap: () =>
                                    _tocarEnSimulador('boton_recuperar'),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(14),
                                    border: resaltar
                                        ? Border.all(
                                            color: const Color(0xFFFFB300),
                                            width: 2)
                                        : null,
                                    boxShadow: resaltar
                                        ? [
                                            BoxShadow(
                                                color: const Color(0xFF059669)
                                                    .withOpacity(0.5),
                                                blurRadius: 14)
                                          ]
                                        : null,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.restore_rounded,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text('Recuperar',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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
              child: Text('🎓', style: TextStyle(fontSize: 60))),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6B4EFF), Color(0xFF3700B3)]),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Módulo Cámara completado',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text('¡Dominas la cámara de tu celular! 📸',
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
    final esSimulador = tipo.startsWith('sim_') && tipo != 'sim_info';

    String texto;
    Color color;

    if (esUltimo) {
      texto = '¡Completé el módulo! 🎓';
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