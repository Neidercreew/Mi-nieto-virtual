import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'reconociendo_iconos';

class TutorialReconociendoIconosScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialReconociendoIconosScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialReconociendoIconosScreen> createState() =>
      _TutorialReconociendoIconosScreenState();
}

class _TutorialReconociendoIconosScreenState
    extends State<TutorialReconociendoIconosScreen>
    with TickerProviderStateMixin {
  int _pasoActual = 0;
  bool _mostrarFelicitacion = false;

  String? _iconoSeleccionado;
  bool? _respuestaCorrecta;

  late AnimationController _flechaController;
  late Animation<double> _flechaAnimation;

  late ConfettiController _confettiController;

  final Map<String, Map<String, dynamic>> _iconosInfo = {
    'Teléfono': {'icono': Icons.call_rounded, 'color': const Color(0xFF059669)},
    'Mensajes': {'icono': Icons.chat_bubble_rounded, 'color': const Color(0xFF0EA5E9)},
    'Cámara': {'icono': Icons.camera_alt_rounded, 'color': const Color(0xFF8B5CF6)},
    'Internet': {'icono': Icons.language_rounded, 'color': const Color(0xFFFFB300)},
    'Ajustes': {'icono': Icons.settings_rounded, 'color': const Color(0xFF6B4EFF)},
    'WhatsApp': {'icono': Icons.chat_rounded, 'color': const Color(0xFF25D366)},
  };

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Reconociendo tus\naplicaciones 📱',
      'instruccion': 'Hoy vas a aprender a reconocer qué hace cada ícono de tu celular.\n\n¡Así nunca te sentirás perdido!.\n\nSolo aprenderemos a identificarlos — más adelante aprenderás a usarlos uno por uno.',
      'icono': Icons.apps_rounded,
      'colorIcono': const Color(0xFF6B4EFF),
    },
    {
      'tipo': 'analogia',
      'titulo': '¿Qué es un\nícono? 🏪',
      'instruccion': 'Los íconos son como los letreros de las tiendas en un centro comercial.\n\nCada dibujo te dice qué encontrarás adentro, sin necesidad de leer.',
      'icono': Icons.storefront_rounded,
      'colorIcono': const Color(0xFF8B5CF6),
    },
    {
      'tipo': 'muestra_iconos',
      'titulo': 'Para comunicarte 💬',
      'instruccion': 'Estos dos íconos son para hablar con tus seres queridos.',
      'iconos': ['Teléfono', 'Mensajes'],
      'descripciones': [
        'El teléfono verde es para hacer LLAMADAS',
        'La burbuja es para enviar MENSAJES de texto',
      ],
    },
    {
      'tipo': 'muestra_iconos',
      'titulo': 'Para hacer cosas 📷',
      'instruccion': 'Estos íconos te ayudan a tomar fotos y buscar información.',
      'iconos': ['Cámara', 'Internet'],
      'descripciones': [
        'La cámara es para tomar FOTOS',
        'El globo es para buscar cosas en INTERNET',
      ],
    },
    {
      'tipo': 'muestra_iconos',
      'titulo': 'Dos más importantes ⚙️',
      'instruccion': 'El engranaje ya lo conoces. WhatsApp lo verás mucho — es para mensajes con fotos y video.',
      'iconos': ['Ajustes', 'WhatsApp'],
      'descripciones': [
        '¿Recuerdas este? Es para AJUSTES de tu celular',
        'El verde con teléfono blanco es WHATSAPP',
      ],
    },
    {
      'tipo': 'quiz',
      'titulo': 'PRÁCTICA 1\n¿Cuál es el Teléfono? 🎯',
      'instruccion': 'Toca el ícono correcto entre los que ves abajo.',
      'respuestaCorrecta': 'Teléfono',
      'opciones': ['Teléfono', 'Cámara', 'Internet'],
    },
    {
      'tipo': 'quiz',
      'titulo': 'PRÁCTICA 2\n¿Cuál es la Cámara? 🎯',
      'instruccion': 'Toca el ícono correcto entre los que ves abajo.',
      'respuestaCorrecta': 'Cámara',
      'opciones': ['Mensajes', 'Cámara', 'Ajustes'],
    },
    {
      'tipo': 'quiz',
      'titulo': 'PRÁCTICA 3\n¿Cuál es Mensajes? 🎯',
      'instruccion': 'Toca el ícono correcto entre los que ves abajo.',
      'respuestaCorrecta': 'Mensajes',
      'opciones': ['WhatsApp', 'Internet', 'Mensajes'],
    },
    {
      'tipo': 'quiz',
      'titulo': 'PRÁCTICA 4\n¿Cuál es Internet? 🎯',
      'instruccion': 'Toca el ícono correcto entre los que ves abajo.',
      'respuestaCorrecta': 'Internet',
      'opciones': ['Teléfono', 'Internet', 'WhatsApp'],
    },
    {
      'tipo': 'accion',
      'titulo': 'PRÁCTICA FINAL\nBúscalos en tu celular',
      'instruccion': 'Ve a la pantalla principal de tu celular.\n\nBusca el ícono del Teléfono y el de la Cámara.\n\nFíjate bien en sus colores y formas.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': const Color(0xFF6B4EFF),
      'confirmacion': '✅ Ya los encontré',
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste! 🏆',
      'instruccion': 'Ya reconoces los íconos más importantes de tu celular.\n\nTeléfono ✅  Mensajes ✅  Cámara ✅\nInternet ✅  Ajustes ✅  WhatsApp ✅',
      'icono': Icons.emoji_events_rounded,
      'colorIcono': const Color(0xFFFFB300),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial;

    _flechaController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _flechaAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _flechaController, curve: Curves.easeInOut),
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 6));
  }

  @override
  void dispose() {
    _flechaController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _seleccionarOpcion(String opcion, String correcta) {
    final acerto = opcion == correcta;
    setState(() {
      _iconoSeleccionado = opcion;
      _respuestaCorrecta = acerto;
    });
    // si fallo, se reinicia despues de un momento para que intente otra vez
    if (!acerto) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _iconoSeleccionado = null;
          _respuestaCorrecta = null;
        });
      });
    }
  }

  Future<void> _avanzar() async {
    if (_mostrarFelicitacion) return;

    final tipoActual = _pasos[_pasoActual]['tipo'];
    if (tipoActual == 'quiz' && _respuestaCorrecta == null) return;

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

    setState(() {
      _iconoSeleccionado = null;
      _respuestaCorrecta = null;
    });

    if (tipoActual == 'accion') {
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF6B4EFF)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Reconociendo íconos',
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

    switch (tipo) {
      case 'muestra_iconos':
        return _buildMuestraIconos(
          List<String>.from(paso['iconos']),
          List<String>.from(paso['descripciones']),
        );
      case 'quiz':
        return _buildQuiz(paso);
      case 'celebracion':
        return _buildTrofeo();
      default:
        final icono = paso['icono'] as IconData;
        final color = paso['colorIcono'] as Color;
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

  Widget _buildMuestraIconos(List<String> nombres, List<String> descripciones) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: nombres.map((nombre) {
              final info = _iconosInfo[nombre]!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: info['color'] as Color,
                      boxShadow: [BoxShadow(color: (info['color'] as Color).withOpacity(0.5), blurRadius: 12)],
                    ),
                    child: Icon(info['icono'] as IconData, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        ...descripciones.map((desc) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.arrow_right_rounded, color: Color(0xFF6B4EFF), size: 20),
              Expanded(child: Text(desc, style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 13))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildQuiz(Map<String, dynamic> paso) {
    final opciones = List<String>.from(paso['opciones']);
    final correcta = paso['respuestaCorrecta'] as String;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 270,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: opciones.map((opcion) {
              final info = _iconosInfo[opcion]!;
              final esSeleccionado = _iconoSeleccionado == opcion;
              final esLaCorrecta = opcion == correcta;

              Color colorBorde = Colors.transparent;
              if (_respuestaCorrecta != null) {
                if (esLaCorrecta) {
                  colorBorde = const Color(0xFF059669);
                } else if (esSeleccionado) {
                  colorBorde = const Color(0xFFE53E3E);
                }
              }

              return GestureDetector(
                onTap: () => _seleccionarOpcion(opcion, correcta),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: info['color'] as Color,
                    border: Border.all(color: colorBorde, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: (info['color'] as Color).withOpacity(0.5),
                        blurRadius: esSeleccionado ? 20 : 12,
                        spreadRadius: esSeleccionado ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Icon(info['icono'] as IconData, color: Colors.white, size: 34),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        if (_respuestaCorrecta != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _respuestaCorrecta!
                  ? const Color(0xFF059669).withOpacity(0.1)
                  : const Color(0xFFE53E3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _respuestaCorrecta! ? const Color(0xFF059669) : const Color(0xFFE53E3E),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _respuestaCorrecta! ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: _respuestaCorrecta! ? const Color(0xFF059669) : const Color(0xFFE53E3E),
                ),
                const SizedBox(width: 8),
                Text(
                  _respuestaCorrecta! ? '¡Correcto! 🎉' : 'No es ese, ¡pero ya viste cuál es! 👍',
                  style: TextStyle(
                    color: _respuestaCorrecta! ? const Color(0xFF059669) : const Color(0xFFE53E3E),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTrofeo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 140, height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFAEEDA),
            border: Border.all(color: const Color(0xFFEF9F27), width: 3),
          ),
          child: const Center(child: Text('🏆', style: TextStyle(fontSize: 70))),
        ),
        const SizedBox(height: 16),
        const Text('¡Eres un experto reconociendo apps!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF854F0B), fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBoton(Map<String, dynamic> paso) {
    final tipo = paso['tipo'] as String;
    final esUltimo = _pasoActual == _pasos.length - 1;
    final esQuizSinResponder = tipo == 'quiz' && _respuestaCorrecta != true;

    String texto;
    Color color;

    if (esUltimo) {
      texto = '¡Terminé! 🎉';
      color = const Color(0xFF059669);
    } else if (tipo == 'quiz') {
      final puedeAvanzar = _respuestaCorrecta == true;
      texto = puedeAvanzar ? 'Siguiente →' : 'Elige el ícono correcto';
      color = puedeAvanzar ? const Color(0xFF6B4EFF) : const Color(0xFFBBBBCC);
    } else if (tipo == 'accion') {
      texto = paso['confirmacion'] ?? '✅ Lo hice';
      color = const Color(0xFF059669);
    } else {
      texto = 'Entendido, siguiente →';
      color = const Color(0xFF6B4EFF);
    }

    return GestureDetector(
      onTap: esQuizSinResponder ? null : _avanzar,
      child: Container(
        width: double.infinity, height: 60,
        decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(16),
          boxShadow: esQuizSinResponder ? null : [
            BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5)),
          ],
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