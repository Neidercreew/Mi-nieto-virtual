import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_whatsapp.dart';

const String _leccionId = 'whatsapp_responder';

class TutorialWhatsappResponderScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialWhatsappResponderScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialWhatsappResponderScreen> createState() =>
      _TutorialWhatsappResponderScreenState();
}

// Un mensaje dentro del chat simulado
class _Mensaje {
  final String texto;
  final bool mia;
  final String hora;
  String? estado;
  final String? citado;
  _Mensaje(this.texto, this.mia, this.hora, {this.estado, this.citado});
}

class _TutorialWhatsappResponderScreenState
    extends State<TutorialWhatsappResponderScreen> {
  int _pasoActual = 0;

  // pantalla: chats | chat
  String _pantalla = 'chats';
  // teclado: ninguno | letras | emojis
  String _teclado = 'ninguno';
  String _texto = '';
  String? _citando;
  String _subtitulo = 'en línea';
  double _arrastre = 0;
  bool _leidoCarlos = false;
  bool _respuestaLlego = false;
  bool _citadaEnviada = false;
  final List<_Mensaje> _mensajes = [];
  final List<Timer> _timers = [];

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const String _miRespuesta = 'Hola, claro que sí ❤️';
  static const String _preguntaPostre = '¿Llevas el postre? 🍰';

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Responder un\nmensaje ✍️',
      'instruccion':
          'Carlos, tu hijo, te preguntó si vas a almorzar el domingo.\n\nHoy le vas a contestar: escribir, usar las palabras que te sugiere el teclado, poner un emoji y enviar.',
      'icono': Icons.edit_note_rounded,
      'colorIcono': MnvColores.verde,
    },
    {
      'tipo': 'sim',
      'titulo': 'Abre el chat de Carlos 💬',
      'instruccion':
          'Tiene un circulito verde: te escribió y no lo has leído.\n\nToca su chat.',
      'objetivo': 'abrir_carlos',
      'ayuda': 'Toca el chat de Carlos',
    },
    {
      'tipo': 'sim',
      'titulo': 'Toca la cajita para escribir ⌨️',
      'instruccion':
          'Abajo hay una cajita blanca que dice "Mensaje".\n\nTócala y verás que sube el teclado.',
      'objetivo': 'teclado_abierto',
      'ayuda': 'Toca la cajita que dice "Mensaje"',
    },
    {
      'tipo': 'sim',
      'titulo': 'Escribe "hola" 🔤',
      'instruccion':
          'La letra que sigue se pinta de amarillo. Tócala sin afán.\n\nSi te equivocas, la tecla ⌫ borra la última letra.',
      'objetivo': 'texto_hola',
      'ayuda': 'Escribe h, o, l, a',
    },
    {
      'tipo': 'sim',
      'titulo': 'El teclado te ayuda 💡',
      'instruccion':
          'Encima de las letras salen frases listas. Así no tienes que escribir todo.\n\nToca "claro que sí".',
      'objetivo': 'sugerencia_usada',
      'ayuda': 'Toca la frase "claro que sí"',
    },
    {
      'tipo': 'sim',
      'titulo': 'Ponle cariño ❤️',
      'instruccion':
          'La carita del lado izquierdo de la cajita abre los emojis: dibujitos que dicen lo que sientes.\n\nTócala y elige el corazón.',
      'objetivo': 'emoji_agregado',
      'ayuda': 'Toca la carita y luego un emoji',
    },
    {
      'tipo': 'sim',
      'titulo': '¡Envía! ➤',
      'instruccion':
          'Cuando hay algo escrito, el micrófono se vuelve una flechita verde.\n\nTócala y mira cómo cambian los chulitos hasta que Carlos lo lea y responda.',
      'objetivo': 'respuesta_recibida',
      'ayuda': 'Toca la flecha verde y espera la respuesta',
    },
    {
      'tipo': 'sim',
      'titulo': 'Responde a una pregunta 👉',
      'instruccion':
          'Carlos preguntó por el postre. Pon el dedo sobre ESE mensaje y arrástralo hacia la derecha: así sabe a qué le contestas.\n\nLuego toca la frase y envía.',
      'objetivo': 'respuesta_citada',
      'ayuda': 'Arrastra el mensaje del postre a la derecha',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 ¿Te equivocaste?',
      'instruccion':
          'Antes de enviar: borra con ⌫.\n\nSi ya lo enviaste: deja el dedo quieto sobre el mensaje, toca el basurero y elige "Eliminar para todos". Hazlo pronto, porque eso solo se puede durante un rato.',
      'icono': Icons.backspace_rounded,
      'colorIcono': MnvColores.amarillo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Contéstale a alguien de tu familia un mensaje que tengas pendiente.\n\nUsa las frases que te sugiere el teclado y ponle un emoji.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': MnvColores.verde,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Ya respondes como un experto! 🏆',
      'instruccion':
          'Escribes, usas sugerencias, pones emojis, envías y respondes a una pregunta exacta.\n\nTu familia va a estar feliz de leerte. 👏',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial.clamp(0, _pasos.length - 1);
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    _prepararPaso();
  }

  @override
  void dispose() {
    _cancelarTimers();
    _confetti.dispose();
    super.dispose();
  }

  void _cancelarTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _programar(int ms, VoidCallback accion) {
    _timers.add(Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      setState(() {
        accion();
        _revisarObjetivo();
      });
    }));
  }

  // Mensajes que ya existian antes de la leccion
  List<_Mensaje> _mensajesBase() => [
        _Mensaje('Hola, ¿cómo estás?', false, '6:10 p. m.'),
        _Mensaje('Bien mijo, todo tranquilo', true, '6:12 p. m.',
            estado: 'leido'),
        _Mensaje('¿Vienes a almorzar el domingo? 🍲', false, '10:02'),
      ];

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _cancelarTimers();
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    _pantalla = 'chat';
    _teclado = 'ninguno';
    _texto = '';
    _citando = null;
    _subtitulo = 'en línea';
    _arrastre = 0;
    _leidoCarlos = true;
    _respuestaLlego = false;
    _citadaEnviada = false;
    _mensajes
      ..clear()
      ..addAll(_mensajesBase());

    switch (_pasoActual) {
      case 1:
        _pantalla = 'chats';
        _leidoCarlos = false;
        break;
      case 2:
        break;
      case 3:
        _teclado = 'letras';
        break;
      case 4:
        _teclado = 'letras';
        _texto = 'hola';
        break;
      case 5:
        _teclado = 'letras';
        _texto = 'Hola, claro que sí';
        break;
      case 6:
        _teclado = 'letras';
        _texto = _miRespuesta;
        break;
      case 7:
        _agregarConversacionEnviada();
        break;
      default:
        _pantalla = 'chats';
        _leidoCarlos = false;
    }
  }

  // Estado del chat despues de enviar la respuesta y recibir la de Carlos
  void _agregarConversacionEnviada() {
    _mensajes.add(_Mensaje(_miRespuesta, true, '10:05', estado: 'leido'));
    _mensajes.add(_Mensaje('¡Qué bien! 🎉 Te recojo a las 12', false, '10:06'));
    _mensajes.add(_Mensaje(_preguntaPostre, false, '10:06'));
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'abrir_carlos':
        cumple = _pantalla == 'chat';
        break;
      case 'teclado_abierto':
        cumple = _teclado == 'letras';
        break;
      case 'texto_hola':
        cumple = _texto.toLowerCase() == 'hola';
        break;
      case 'sugerencia_usada':
        cumple = _texto == 'Hola, claro que sí';
        break;
      case 'emoji_agregado':
        cumple = _texto.length > 'Hola, claro que sí'.length;
        break;
      case 'respuesta_recibida':
        cumple = _respuestaLlego;
        break;
      case 'respuesta_citada':
        cumple = _citadaEnviada;
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // ─────────────────────────────────────────────
  // CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────
  void _tocarEnSimulador(String accion, {String valor = ''}) {
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'chat_carlos':
          _leidoCarlos = true;
          _pantalla = 'chat';
          break;
        case 'chat_otro':
          _mensajeGuia = 'Ese no. Busca el chat de Carlos, el del circulito';
          break;
        case 'atras':
          if (_pasoActual == 1) {
            _pantalla = 'chats';
          } else {
            _mensajeGuia = 'Quédate en el chat de Carlos para responderle';
          }
          break;

        case 'caja':
          if (_teclado == 'ninguno') _teclado = 'letras';
          break;

        case 'letra':
          _escribirLetra(valor);
          break;
        case 'borrar':
          if (_texto.isNotEmpty) {
            _texto = _texto.substring(0, _texto.length - 1);
          }
          break;

        case 'sugerencia':
          _usarSugerencia(valor);
          break;

        case 'emoji_boton':
          if (_pasoActual < 5) {
            _mensajeGuia = 'Los emojis van en un momentico. Sigue la cajita morada';
          } else {
            _teclado = _teclado == 'emojis' ? 'letras' : 'emojis';
          }
          break;
        case 'emoji':
          if (_pasoActual == 5 && _texto == 'Hola, claro que sí') {
            _texto = '$_texto $valor';
          } else {
            _mensajeGuia = 'Ya tiene su emoji. Sigue la cajita morada';
          }
          break;
        case 'volver_teclado':
          _teclado = 'letras';
          break;

        case 'clip':
          _mensajeGuia = 'El clip es para mandar fotos. Eso lo vemos más adelante';
          break;
        case 'microfono':
          _mensajeGuia = _teclado == 'ninguno'
              ? 'Ese botón es para audios. Primero toca la cajita "Mensaje"'
              : 'Primero escribe algo y el micrófono se vuelve flecha';
          break;

        case 'enviar':
          _enviar();
          break;

        case 'tocar_postre':
          _mensajeGuia = 'No es tocar: deja el dedo y arrástralo hacia la derecha →';
          break;
        case 'tocar_burbuja':
          if (_pasoActual == 7) {
            _mensajeGuia = 'Ese no. Arrastra el mensaje que pregunta por el postre';
          }
          break;
      }

      _revisarObjetivo();
    });
  }

  void _escribirLetra(String letra) {
    if (_pasoActual != 3) {
      _mensajeGuia = _pasoActual == 7
          ? 'Usa la frase de arriba del teclado, es más fácil'
          : 'Ya está escrito. Sigue la cajita morada';
      return;
    }
    if (_texto.length >= 12) return;
    _texto += letra;
    if (!'hola'.startsWith(_texto.toLowerCase())) {
      _mensajeGuia = 'Esa letra no va. Toca ⌫ para borrarla, tranquilo';
    }
  }

  void _usarSugerencia(String s) {
    if (_pasoActual == 4) {
      if (s == 'claro que sí') {
        _texto = 'Hola, claro que sí';
      } else {
        _mensajeGuia = 'Hoy sí vas a ir 😉 Toca "claro que sí"';
      }
    } else if (_pasoActual == 7 && _citando != null) {
      _texto = s;
    }
  }

  void _enviar() {
    if (_texto.isEmpty) return;
    if (_pasoActual == 6) {
      final msg = _Mensaje(_texto, true, '10:05', estado: 'reloj');
      _mensajes.add(msg);
      _texto = '';
      _teclado = 'ninguno';
      _programar(600, () => msg.estado = 'enviado');
      _programar(1400, () => msg.estado = 'entregado');
      _programar(2400, () => msg.estado = 'leido');
      _programar(3000, () => _subtitulo = 'escribiendo...');
      _programar(4400, () {
        _subtitulo = 'en línea';
        _mensajes.add(
            _Mensaje('¡Qué bien! 🎉 Te recojo a las 12', false, '10:06'));
      });
      _programar(5400, () {
        _mensajes.add(_Mensaje(_preguntaPostre, false, '10:06'));
        _respuestaLlego = true;
      });
    } else if (_pasoActual == 7 && _citando != null) {
      final msg =
          _Mensaje(_texto, true, '10:07', estado: 'enviado', citado: _citando);
      _mensajes.add(msg);
      _texto = '';
      _citando = null;
      _teclado = 'ninguno';
      _citadaEnviada = true;
      _programar(900, () => msg.estado = 'leido');
    } else {
      _mensajeGuia = 'Sigue primero la instrucción de la cajita morada';
    }
  }

  // Arrastre horizontal sobre el mensaje del postre
  void _arrastrarPostre(double dx) {
    if (_pasoActual != 7 || _citando != null || _citadaEnviada) return;
    setState(() => _arrastre = (_arrastre + dx).clamp(0.0, 70.0));
  }

  void _soltarPostre() {
    if (_pasoActual != 7 || _citando != null || _citadaEnviada) return;
    setState(() {
      if (_arrastre > 45) {
        _citando = _preguntaPostre;
        _teclado = 'letras';
        _mensajeGuia = null;
      } else {
        _mensajeGuia = 'Casi. Arrástralo un poquito más a la derecha';
      }
      _arrastre = 0;
    });
  }

  Future<void> _avanzar() async {
    if (!_objetivoCumplido) return;
    _cancelarTimers();
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
      tituloLeccion: 'Responder un mensaje',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '✍️',
      textoTrofeo: '¡Ya respondes mensajes!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    if (_pantalla == 'chats') return 'WHATSAPP · CHATS';
    if (_teclado == 'emojis') return 'CHAT CON CARLOS · EMOJIS';
    if (_teclado == 'letras') return 'CHAT CON CARLOS · ESCRIBIENDO';
    return 'CHAT CON CARLOS';
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: _pantalla == 'chats' ? _buildChats() : _buildChat(),
    );
  }

  Widget _buildChats() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const WaCabeceraLista(),
          WaFilaChat(
            nombre: 'Carlos (hijo)',
            inicial: 'C',
            color: MnvColores.azul,
            ultimo: '¿Vienes a almorzar el domingo? 🍲',
            hora: '10:02',
            noLeidos: _leidoCarlos ? 0 : 1,
            resaltada: _pasoActual == 1,
            onTap: () => _tocarEnSimulador('chat_carlos'),
          ),
          WaFilaChat(
            nombre: 'Lucía (nieta)',
            inicial: 'L',
            color: MnvColores.morado,
            ultimo: 'Te mando un abrazo grande 🤗',
            hora: '9:30',
            onTap: () => _tocarEnSimulador('chat_otro'),
          ),
          WaFilaChat(
            nombre: 'María',
            inicial: 'M',
            color: MnvColores.verde,
            ultimo: '¿A qué hora te queda bien?',
            hora: '8:11',
            estadoMio: 'leido',
            onTap: () => _tocarEnSimulador('chat_otro'),
          ),
          WaFilaChat(
            nombre: 'Familia 💛',
            inicial: 'F',
            color: MnvColores.amarillo,
            ultimo: 'Tía Rosa: Feliz día a todos 🌸',
            hora: 'Ayer',
            onTap: () => _tocarEnSimulador('chat_otro'),
          ),
          const Spacer(),
          WaPestanas(
            activa: 'chats',
            onPestana: (_) => _tocarEnSimulador('chat_otro'),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    final hayTexto = _texto.isNotEmpty;
    final resaltaEnviar = (_pasoActual == 6 && hayTexto) ||
        (_pasoActual == 7 && _citando != null && hayTexto);
    final letraEsperada = _pasoActual == 3 &&
            _texto.length < 4 &&
            'hola'.startsWith(_texto.toLowerCase())
        ? 'hola'[_texto.length]
        : null;
    final textoMalo =
        _pasoActual == 3 && !'hola'.startsWith(_texto.toLowerCase());

    List<String> sugerencias = const [];
    String? sugResaltada;
    if (_pasoActual == 4) {
      sugerencias = const ['claro que sí', 'no puedo', '¿a qué hora?'];
      sugResaltada = _texto == 'hola' ? 'claro que sí' : null;
    } else if (_pasoActual == 7 && _citando != null) {
      sugerencias = const ['Sí, yo lo llevo 🍰', 'Lleva tú', 'No alcanzo'];
      sugResaltada = _texto.isEmpty ? 'Sí, yo lo llevo 🍰' : null;
    }

    return Container(
      color: WaColores.fondoChat,
      child: Column(
        children: [
          WaCabeceraChat(
            nombre: 'Carlos (hijo)',
            inicial: 'C',
            color: MnvColores.azul,
            subtitulo: _subtitulo,
            onAtras: () => _tocarEnSimulador('atras'),
          ),
          Expanded(
            child: ListView(
              reverse: true,
              padding: const EdgeInsets.only(bottom: 4),
              children: _burbujas().reversed.toList(),
            ),
          ),
          if (_citando != null) _buildCitando(),
          WaCajaEscribir(
            texto: _texto,
            enfocada: _teclado != 'ninguno',
            resaltarCaja: _pasoActual == 2 && _teclado == 'ninguno',
            resaltarEmoji: _pasoActual == 5 && _teclado != 'emojis',
            onCaja: () => _tocarEnSimulador('caja'),
            onEmoji: () => _tocarEnSimulador('emoji_boton'),
            onClip: () => _tocarEnSimulador('clip'),
            botonDerecho: hayTexto
                ? WaBotonRedondo(
                    icono: Icons.send_rounded,
                    resaltado: resaltaEnviar,
                    onTap: () => _tocarEnSimulador('enviar'),
                  )
                : WaBotonRedondo(
                    icono: Icons.mic_rounded,
                    onTap: () => _tocarEnSimulador('microfono'),
                  ),
          ),
          AnimatedSlide(
            offset: _teclado == 'ninguno' ? const Offset(0, 1) : Offset.zero,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            child: _teclado == 'emojis'
                ? WaPanelEmojis(
                    resaltado: _pasoActual == 5 &&
                            _texto == 'Hola, claro que sí'
                        ? '❤️'
                        : null,
                    onEmoji: (e) => _tocarEnSimulador('emoji', valor: e),
                    onTeclado: () => _tocarEnSimulador('volver_teclado'),
                  )
                : _teclado == 'letras'
                    ? MnvTecladoLetras(
                        onLetra: (l) => _tocarEnSimulador('letra', valor: l),
                        onBorrar: () => _tocarEnSimulador('borrar'),
                        letraEsperada: letraEsperada,
                        resaltarBorrar: textoMalo,
                        sugerencias: sugerencias,
                        sugerenciaResaltada: sugResaltada,
                        onSugerencia: (s) =>
                            _tocarEnSimulador('sugerencia', valor: s),
                      )
                    : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  List<Widget> _burbujas() {
    final lista = <Widget>[
      const WaSeparadorFecha(texto: 'AYER'),
    ];
    for (int i = 0; i < _mensajes.length; i++) {
      final m = _mensajes[i];
      if (i == 2) lista.add(const WaSeparadorFecha(texto: 'HOY'));
      final esPostre = !m.mia && m.texto == _preguntaPostre;
      final burbuja = WaBurbuja(
        texto: m.texto,
        mia: m.mia,
        hora: m.hora,
        estado: m.estado,
        citado: m.citado,
        resaltada: esPostre &&
            _pasoActual == 7 &&
            _citando == null &&
            !_citadaEnviada,
        onTap: () =>
            _tocarEnSimulador(esPostre ? 'tocar_postre' : 'tocar_burbuja'),
      );
      if (esPostre) {
        lista.add(GestureDetector(
          onHorizontalDragUpdate: (d) => _arrastrarPostre(d.delta.dx),
          onHorizontalDragEnd: (_) => _soltarPostre(),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (_arrastre > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Opacity(
                    opacity: (_arrastre / 45).clamp(0.0, 1.0),
                    child: const Icon(Icons.reply_rounded,
                        color: WaColores.verde, size: 22),
                  ),
                ),
              Transform.translate(
                offset: Offset(_arrastre, 0),
                child: burbuja,
              ),
            ],
          ),
        ));
      } else {
        lista.add(burbuja);
      }
    }
    return lista;
  }

  // Franja que muestra a que mensaje se esta respondiendo
  Widget _buildCitando() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 30,
              decoration: BoxDecoration(
                  color: WaColores.verde,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          const Icon(Icons.reply_rounded, size: 16, color: WaColores.verde),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Respondiendo a Carlos',
                    style: TextStyle(
                        color: WaColores.verde,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold)),
                Text(_citando ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: MnvColores.suave, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
