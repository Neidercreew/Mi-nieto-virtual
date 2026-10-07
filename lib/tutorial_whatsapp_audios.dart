import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_whatsapp.dart';

const String _leccionId = 'whatsapp_audios';

class TutorialWhatsappAudiosScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialWhatsappAudiosScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialWhatsappAudiosScreen> createState() =>
      _TutorialWhatsappAudiosScreenState();
}

class _TutorialWhatsappAudiosScreenState
    extends State<TutorialWhatsappAudiosScreen> {
  int _pasoActual = 0;

  // Audio de Lucia
  bool _reproduciendo = false;
  double _progresoAudio = 0;
  bool _audioEscuchado = false;

  // Grabacion propia
  bool _grabando = false;
  bool _conCandado = false;
  double _segundosGrabados = 0;
  Offset _desplazamiento = Offset.zero;
  bool _cancelado = false;
  int _audiosEnviados = 0;
  bool _enviadoConCandado = false;
  bool _mostrarBasurero = false;

  int _tick = 0;
  Timer? _reloj;
  Timer? _ocultarBasurero;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const double _duracionAudioLucia = 5;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Notas de voz 🎤',
      'instruccion':
          'Escribir cansa los dedos y la vista. Con un audio hablas y listo, como dejar un recado.\n\nHoy aprendes a escuchar audios y a mandar los tuyos.',
      'icono': Icons.mic_rounded,
      'colorIcono': MnvColores.verde,
    },
    {
      'tipo': 'sim',
      'titulo': 'Escucha el audio ▶️',
      'instruccion':
          'Lucía te mandó un audio. Toca el triángulo ▶ y espera a que la barrita llegue al final.',
      'objetivo': 'audio_escuchado',
      'ayuda': 'Toca ▶ y escucha hasta el final',
    },
    {
      'tipo': 'sim',
      'titulo': 'Mantén el micrófono 🎤',
      'instruccion':
          'Para grabar NO es tocar: deja el dedo QUIETO sobre el micrófono verde mientras hablas.\n\nCuenta hasta 3 y suelta: el audio se envía solo.',
      'objetivo': 'audio_enviado',
      'ayuda': 'Deja el dedo sobre el micrófono, cuenta 3 y suelta',
    },
    {
      'tipo': 'sim',
      'titulo': '¿Te equivocaste? Bórralo ⬅️',
      'instruccion':
          'Graba otra vez, pero ANTES de soltar arrastra el dedo hacia la izquierda.\n\nEl audio se va al basurero y nadie lo escucha.',
      'objetivo': 'audio_cancelado',
      'ayuda': 'Mantén el micrófono y arrastra a la izquierda',
    },
    {
      'tipo': 'sim',
      'titulo': 'Audio largo: el candado 🔒',
      'instruccion':
          'Si vas a hablar mucho, mantén el micrófono y arrastra el dedo hacia ARRIBA hasta el candado.\n\nYa puedes soltar: sigue grabando. Cuando termines toca la flecha para enviar.',
      'objetivo': 'audio_candado',
      'ayuda': 'Mantén, sube al candado y luego toca enviar',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Para que te oigan bien',
      'instruccion':
          'El micrófono está en la parte de abajo del celular: habla cerca, sin gritar.\n\nBusca un lugar sin ruido y, si el audio es para algo importante, escúchalo antes de que se vaya.',
      'icono': Icons.record_voice_over_rounded,
      'colorIcono': MnvColores.amarillo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Mándale a alguien de confianza un audio corto: "Hola, estoy practicando".\n\nPídele que te conteste con otro audio y escúchalo.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': MnvColores.verde,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Ya mandas audios! 🏆',
      'instruccion':
          'Escuchas, grabas, cancelas y usas el candado para hablar sin dedo.\n\nAhora tu familia va a oír tu voz más seguido. 👏',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial.clamp(0, _pasos.length - 1);
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    _prepararPaso();
    // Si se retoma justo en la celebracion, tambien hay confeti
    if (_pasos[_pasoActual]['tipo'] == 'celebracion') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confetti.play();
      });
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _ocultarBasurero?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _reloj?.cancel();
    _reloj = null;
    _ocultarBasurero?.cancel();
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    _reproduciendo = false;
    _grabando = false;
    _conCandado = false;
    _segundosGrabados = 0;
    _desplazamiento = Offset.zero;
    _cancelado = false;
    _enviadoConCandado = false;
    _mostrarBasurero = false;

    // Lo que ya paso en los pasos anteriores
    _audioEscuchado = _pasoActual >= 2;
    _progresoAudio = _audioEscuchado ? 1 : 0;
    _audiosEnviados = _pasoActual >= 3 ? 1 : 0;
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'audio_escuchado':
        cumple = _audioEscuchado;
        break;
      case 'audio_enviado':
        cumple = _audiosEnviados >= 1;
        break;
      case 'audio_cancelado':
        cumple = _cancelado;
        break;
      case 'audio_candado':
        cumple = _enviadoConCandado;
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // Reloj de 100 ms que mueve la reproduccion y la grabacion
  void _encenderReloj() {
    _reloj ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        _tick++;
        if (_reproduciendo) {
          _progresoAudio += 0.1 / _duracionAudioLucia;
          if (_progresoAudio >= 1) {
            _progresoAudio = 1;
            _reproduciendo = false;
            _audioEscuchado = true;
          }
        }
        if (_grabando) _segundosGrabados += 0.1;
        if (!_reproduciendo && !_grabando) {
          _reloj?.cancel();
          _reloj = null;
        }
        _revisarObjetivo();
      });
    });
  }

  // ─────────────────────────────────────────────
  // CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────
  void _tocarEnSimulador(String accion) {
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'play':
          if (_pasoActual != 1 && !_audioEscuchado) break;
          if (_reproduciendo) {
            _reproduciendo = false;
          } else {
            if (_progresoAudio >= 1) _progresoAudio = 0;
            _reproduciendo = true;
            _encenderReloj();
          }
          break;

        case 'tocar_micro':
          if (_pasoActual == 1) {
            _mensajeGuia = 'Primero escucha el audio de Lucía con ▶';
          } else if (_grabando) {
            break;
          } else {
            _mensajeGuia = 'No es tocar: deja el dedo quieto sobre el micrófono';
          }
          break;

        case 'enviar_candado':
          if (_grabando && _conCandado) {
            _terminarGrabacion(enviar: true);
            if (_pasoActual == 4) _enviadoConCandado = true;
          }
          break;
        case 'basurero_candado':
          if (_grabando && _conCandado) {
            _grabando = false;
            _conCandado = false;
            _mensajeGuia = 'Lo borraste. Vuelve a intentarlo y esta vez toca la flecha';
          }
          break;

        case 'otro':
          _mensajeGuia = 'Hoy practicamos con el micrófono y el audio';
          break;
      }

      _revisarObjetivo();
    });
  }

  void _empezarGrabacion() {
    if (_pasoActual == 1) {
      setState(() => _mensajeGuia = 'Primero escucha el audio de Lucía con ▶');
      return;
    }
    if (_pasoActual < 2 || _pasoActual > 4 || _grabando) return;
    setState(() {
      _mensajeGuia = null;
      _grabando = true;
      _conCandado = false;
      _segundosGrabados = 0;
      _desplazamiento = Offset.zero;
      _reproduciendo = false;
      _encenderReloj();
    });
  }

  void _moverDedo(Offset desdeInicio) {
    if (!_grabando || _conCandado) return;
    setState(() {
      _desplazamiento = Offset(desdeInicio.dx.clamp(-120.0, 0.0),
          desdeInicio.dy.clamp(-90.0, 0.0));

      // Arrastro a la izquierda: se cancela
      if (_desplazamiento.dx < -90) {
        _grabando = false;
        _desplazamiento = Offset.zero;
        _mostrarBasurero = true;
        if (_pasoActual == 3) {
          _cancelado = true;
        } else {
          _mensajeGuia = 'Lo cancelaste. Así se borra un audio';
        }
        _ocultarBasurero?.cancel();
        _ocultarBasurero = Timer(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _mostrarBasurero = false);
        });
      }

      // Subio hasta el candado: sigue grabando sin dedo
      if (_desplazamiento.dy < -70 && _grabando) {
        _conCandado = true;
        _desplazamiento = Offset.zero;
        if (_pasoActual != 4) {
          _mensajeGuia = 'Ese es el candado. Lo practicamos en el siguiente paso';
        }
      }
      _revisarObjetivo();
    });
  }

  void _soltarDedo() {
    if (!_grabando || _conCandado) return;
    setState(() {
      _desplazamiento = Offset.zero;
      if (_segundosGrabados < 2) {
        _grabando = false;
        _mensajeGuia = 'Muy cortito. Deja el dedo un poco más, cuenta hasta 3';
      } else {
        _terminarGrabacion(enviar: true);
        if (_pasoActual == 3) {
          _mensajeGuia = 'Se envió. Esta vez arrastra a la izquierda ANTES de soltar';
        } else if (_pasoActual == 4) {
          _mensajeGuia = 'Se envió. Esta vez sube al candado antes de soltar';
        }
      }
      _revisarObjetivo();
    });
  }

  void _terminarGrabacion({required bool enviar}) {
    _grabando = false;
    _conCandado = false;
    if (enviar) _audiosEnviados++;
  }

  // Evita que un doble toque en el boton salte un paso o cierre dos pantallas
  bool _avanzando = false;

  Future<void> _avanzar() async {
    if (_avanzando) return;
    _avanzando = true;
    try {
      await _avanzarPaso();
    } finally {
      // Si la leccion ya se cerro el boton queda bloqueado
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        _avanzando = false;
      }
    }
  }

  Future<void> _avanzarPaso() async {
    if (!_objetivoCumplido) return;
    _reloj?.cancel();
    _reloj = null;
    final esUltimo = _pasoActual == _pasos.length - 1;
    await mnvGuardarPaso(_leccionId, _pasoActual + 1, completada: esUltimo);

    if (esUltimo) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.pop(context);
      return;
    }
    if (!mounted) return;
    setState(() {
      _pasoActual++;
      _prepararPaso();
    });
    if (_pasos[_pasoActual]['tipo'] == 'celebracion') _confetti.play();
  }

  @override
  Widget build(BuildContext context) {
    return MnvLeccionLayout(
      tituloLeccion: 'Notas de voz',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '🎤',
      textoTrofeo: '¡Tu voz llega a tu familia!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    if (_grabando && _conCandado) return 'CHAT CON LUCÍA · GRABANDO 🔒';
    if (_grabando) return 'CHAT CON LUCÍA · GRABANDO';
    return 'CHAT CON LUCÍA';
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: 'chat',
      pantalla: _buildChat(),
      encima: [
        if (_mostrarBasurero) _buildBasurero(),
      ],
    );
  }

  Widget _buildChat() {
    final burbujas = <Widget>[
      const WaSeparadorFecha(texto: 'HOY'),
      const WaBurbuja(texto: 'Abue, escucha 👇', mia: false, hora: '11:20'),
      WaBurbuja(
        texto: '',
        mia: false,
        hora: '11:20',
        contenido: _audio(
          mia: false,
          progreso: _progresoAudio,
          duracion: '0:05',
          reproduciendo: _reproduciendo,
          resaltarPlay: _pasoActual == 1 && !_reproduciendo,
        ),
      ),
      const WaBurbuja(
          texto: 'Mándame un audio, quiero oír tu voz 🥰',
          mia: false,
          hora: '11:21'),
    ];
    for (int i = 0; i < _audiosEnviados; i++) {
      burbujas.add(WaBurbuja(
        texto: '',
        mia: true,
        hora: '11:2${4 + i}',
        estado: i == 0 ? 'leido' : 'entregado',
        contenido: _audio(
            mia: true,
            progreso: 0,
            duracion: '0:0${3 + (i % 5)}',
            reproduciendo: false,
            resaltarPlay: false),
      ));
    }

    return Container(
      color: WaColores.fondoChat,
      child: Column(
        children: [
          WaCabeceraChat(
            nombre: 'Lucía (nieta)',
            inicial: 'L',
            color: MnvColores.morado,
            subtitulo: _grabando ? 'grabando audio...' : 'en línea',
            onAtras: () => _tocarEnSimulador('otro'),
          ),
          Expanded(
            child: ListView(
              reverse: true,
              padding: const EdgeInsets.only(bottom: 4),
              children: burbujas.reversed.toList(),
            ),
          ),
          SizedBox(
            height: 120,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _grabando ? _barraGrabando() : _barraNormal(),
                ),
                if (_grabando && !_conCandado) _guiaCandado(),
                if (!_conCandado)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Transform.translate(
                      offset: _desplazamiento,
                      child: _botonMicrofono(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // Burbuja de audio: boton, ondas y duracion
  Widget _audio({
    required bool mia,
    required double progreso,
    required String duracion,
    required bool reproduciendo,
    required bool resaltarPlay,
  }) {
    const alturas = [6.0, 12.0, 18.0, 10.0, 16.0, 22.0, 14.0, 8.0, 18.0, 12.0,
      20.0, 10.0, 6.0, 14.0, 9.0, 16.0, 7.0];
    return SizedBox(
      width: 172,
      child: Row(
        children: [
          GestureDetector(
            onTap: mia ? null : () => _tocarEnSimulador('play'),
            child: MnvResalte(
              activo: resaltarPlay,
              circular: true,
              escala: 1.2,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mia
                      ? WaColores.verde.withValues(alpha: 0.15)
                      : MnvColores.lila,
                ),
                child: Icon(
                    reproduciendo
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: mia ? WaColores.verde : MnvColores.morado,
                    size: 24),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(alturas.length, (i) {
                      final pintada = (i + 1) / alturas.length <= progreso;
                      final h = reproduciendo
                          ? alturas[i] *
                              (0.6 +
                                  0.4 *
                                      math.sin(_tick * 0.7 + i).abs())
                          : alturas[i];
                      return Container(
                        width: 3,
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 1.2),
                        decoration: BoxDecoration(
                          color: pintada
                              ? (mia ? WaColores.verde : MnvColores.morado)
                              : MnvColores.suave2.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
                Text(duracion,
                    style: const TextStyle(
                        color: MnvColores.suave2, fontSize: 9.5)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.mic_rounded,
              size: 16, color: mia ? WaColores.verde : MnvColores.azul),
        ],
      ),
    );
  }

  // Caja normal con el microfono a la derecha
  Widget _barraNormal() {
    return Container(
      height: 54,
      padding: const EdgeInsets.fromLTRB(6, 5, 56, 6),
      color: WaColores.fondoChat,
      child: GestureDetector(
        onTap: () => setState(() => _mensajeGuia =
            'Hoy no escribimos: usamos el micrófono de la derecha'),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const Row(
            children: [
              Icon(Icons.emoji_emotions_outlined,
                  color: MnvColores.suave2, size: 20),
              SizedBox(width: 8),
              Text('Mensaje',
                  style: TextStyle(color: MnvColores.suave2, fontSize: 13)),
              Spacer(),
              Icon(Icons.attach_file_rounded,
                  color: MnvColores.suave2, size: 19),
            ],
          ),
        ),
      ),
    );
  }

  // Barra mientras graba: punto rojo, tiempo y "desliza para cancelar"
  Widget _barraGrabando() {
    final segundos = _segundosGrabados.floor();
    final tiempo = '0:${segundos.toString().padLeft(2, '0')}';
    final puntoVisible = (_tick ~/ 5).isEven;

    if (_conCandado) {
      return Container(
        height: 96,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedOpacity(
                  opacity: puntoVisible ? 1 : 0.2,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.circle, color: MnvColores.rojo, size: 12),
                ),
                const SizedBox(width: 8),
                Text(tiempo,
                    style: const TextStyle(
                        color: MnvColores.texto,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(child: _ondasVivas(MnvColores.rojo)),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _tocarEnSimulador('basurero_candado'),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.delete_outline_rounded,
                        color: MnvColores.suave, size: 26),
                  ),
                ),
                const Text('Ya puedes soltar el dedo',
                    style: TextStyle(color: MnvColores.suave2, fontSize: 11)),
                WaBotonRedondo(
                  icono: Icons.send_rounded,
                  resaltado: _pasoActual == 4,
                  onTap: () => _tocarEnSimulador('enviar_candado'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final cerca = _desplazamiento.dx < -45;
    return Container(
      height: 54,
      padding: const EdgeInsets.fromLTRB(12, 0, 66, 0),
      color: Colors.white,
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: puntoVisible ? 1 : 0.2,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.circle, color: MnvColores.rojo, size: 12),
          ),
          const SizedBox(width: 6),
          Text(tiempo,
              style: const TextStyle(
                  color: MnvColores.texto,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Icon(Icons.chevron_left_rounded,
              color: cerca ? MnvColores.rojo : MnvColores.suave2, size: 18),
          Text(cerca ? 'Suelta para borrar' : 'Desliza para cancelar',
              style: TextStyle(
                  color: cerca ? MnvColores.rojo : MnvColores.suave2,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _ondasVivas(Color color) {
    return SizedBox(
      height: 20,
      child: Row(
        children: List.generate(16, (i) {
          final h = 4 + 14 * math.sin(_tick * 0.8 + i * 0.9).abs();
          return Container(
            width: 3,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  // Candado encima del microfono que invita a subir
  Widget _guiaCandado() {
    final resaltar = _pasoActual == 4;
    final cerca = _desplazamiento.dy < -35;
    return Positioned(
      right: 10,
      bottom: 62,
      child: Container(
        width: 36,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: resaltar || cerca ? MnvColores.amarillo : MnvColores.borde,
              width: resaltar ? 2 : 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cerca ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 18,
                color: cerca ? MnvColores.amarillo : MnvColores.suave),
            const SizedBox(height: 4),
            Icon(Icons.keyboard_arrow_up_rounded,
                size: 18,
                color: resaltar ? MnvColores.amarillo : MnvColores.suave2),
          ],
        ),
      ),
    );
  }

  // Microfono que se mantiene presionado (pulsacion larga)
  Widget _botonMicrofono() {
    final resaltar = !_grabando && _pasoActual >= 2 && _pasoActual <= 4;
    return GestureDetector(
      onTap: () => _tocarEnSimulador('tocar_micro'),
      onLongPressStart: (_) => _empezarGrabacion(),
      onLongPressMoveUpdate: (d) => _moverDedo(d.offsetFromOrigin),
      onLongPressEnd: (_) => _soltarDedo(),
      child: MnvResalte(
        activo: resaltar,
        circular: true,
        escala: 1.15,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _grabando ? 62 : 44,
          height: _grabando ? 62 : 44,
          decoration: BoxDecoration(
            color: _grabando ? MnvColores.rojo : WaColores.verde,
            shape: BoxShape.circle,
            boxShadow: _grabando
                ? [
                    BoxShadow(
                        color: MnvColores.rojo.withValues(alpha: 0.45),
                        blurRadius: 18,
                        spreadRadius: 3)
                  ]
                : null,
          ),
          child: Icon(Icons.mic_rounded,
              color: Colors.white, size: _grabando ? 30 : 22),
        ),
      ),
    );
  }

  // Basurero que se traga el audio cancelado
  Widget _buildBasurero() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 70,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, t, hijo) => Transform.scale(scale: t, child: hijo),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: MnvColores.rojoSuave,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MnvColores.rojo, width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_rounded, color: MnvColores.rojo, size: 22),
                  SizedBox(width: 6),
                  Text('Audio borrado, nadie lo oyó',
                      style: TextStyle(
                          color: MnvColores.rojo,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
