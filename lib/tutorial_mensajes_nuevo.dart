import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_mensajes.dart';

const String _leccionId = 'mensajes_nuevo';

class TutorialMensajesNuevoScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialMensajesNuevoScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialMensajesNuevoScreen> createState() =>
      _TutorialMensajesNuevoScreenState();
}

// Un SMS enviado y su estado (Enviando, Enviado, Entregado)
class _Sms {
  final String texto;
  final String hora;
  String estado;
  _Sms(this.texto, this.hora, this.estado);
}

class _TutorialMensajesNuevoScreenState
    extends State<TutorialMensajesNuevoScreen> {
  int _pasoActual = 0;

  // pantalla: lista | nuevo | conversacion
  String _pantalla = 'lista';
  String _busqueda = '';
  bool _tecladoAbierto = false;
  final List<String> _palabras = [];
  final List<_Sms> _enviados = [];
  bool _sinInternet = false;
  final List<Timer> _timers = [];

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  // Frase que se arma con el texto predictivo, palabra por palabra
  static const List<String> _frase = [
    'Hola', 'María,', 'llego', 'en', '10', 'minutos'
  ];
  static const List<List<String>> _opciones = [
    ['Buenos', 'Hola', 'Qué'],
    ['amiga', 'María,', 'cómo'],
    ['voy', 'llego', 'estoy'],
    ['a', 'en', 'tarde'],
    ['5', '10', 'un'],
    ['ratico', 'minutos', 'horas'],
  ];

  static const List<List<String>> _contactos = [
    ['Carlos (hijo)', 'C'],
    ['Lucía (nieta)', 'L'],
    ['Manuel (vecino)', 'M'],
    ['María', 'M'],
    ['Marta (hermana)', 'M'],
    ['Pedro (tienda)', 'P'],
  ];

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Un mensaje nuevo 🆕',
      'instruccion':
          'Ya sabes responder. Hoy empiezas una conversación desde cero: le vas a avisar a María que llegas en 10 minutos.\n\nY vas a ver que el mensaje de texto sale aunque no tengas internet.',
      'icono': Icons.add_comment_rounded,
      'colorIcono': MnvColores.morado,
    },
    {
      'tipo': 'sim',
      'titulo': 'Toca "Iniciar chat" 💬',
      'instruccion':
          'En la app de Mensajes, abajo a la derecha, está el botón morado "Iniciar chat".\n\nTócalo.',
      'objetivo': 'nuevo',
      'ayuda': 'Toca el botón Iniciar chat',
    },
    {
      'tipo': 'sim',
      'titulo': '¿A quién le escribes? 👤',
      'instruccion':
          'No hace falta buscar en toda la lista: escribe "ma" y quedan solo los que empiezan así.\n\nLuego toca a María.',
      'objetivo': 'destinatario',
      'ayuda': 'Escribe m, a y toca a María',
    },
    {
      'tipo': 'sim',
      'titulo': 'El teclado adivina 🔮',
      'instruccion':
          'Encima de las letras salen 3 palabras. El teclado adivina la que sigue.\n\nToca la palabra resaltada, una por una, hasta armar: "Hola María, llego en 10 minutos".',
      'objetivo': 'mensaje_listo',
      'ayuda': 'Toca las palabras resaltadas en orden',
    },
    {
      'tipo': 'sim',
      'titulo': 'Envíalo ➤',
      'instruccion':
          'Toca la flecha morada. En los mensajes de texto no hay chulitos: abajo dice "Enviado" y luego "Entregado".',
      'objetivo': 'enviado',
      'ayuda': 'Toca la flecha morada y espera',
    },
    {
      'tipo': 'sim',
      'titulo': '¿Y sin internet? 📶',
      'instruccion':
          'Se fue el internet (arriba lo dice). Ya llegaste: toca "Ya llegué 👋" y envíalo.\n\nVerás que igual sale, porque el mensaje de texto usa la señal del celular, no internet.',
      'objetivo': 'sin_internet',
      'ayuda': 'Toca "Ya llegué 👋" y luego enviar',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 ¿Mensaje de texto o WhatsApp?',
      'instruccion':
          'Mensaje de texto: sale sin internet, solo con señal. Puede costar según tu plan. Solo letras.\n\nWhatsApp: necesita internet o wifi. Manda audios, fotos y videos.',
      'icono': Icons.compare_arrows_rounded,
      'colorIcono': MnvColores.amarillo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Abre Mensajes, toca "Iniciar chat", busca a alguien escribiendo las primeras letras y mándale un saludo usando las palabras que adivina el teclado.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': MnvColores.morado,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Ya escribes a quien quieras! 🏆',
      'instruccion':
          'Empiezas conversaciones, encuentras contactos rápido, usas el texto que adivina el teclado y sabes que el SMS no necesita internet.\n\n¡Muy bien! 👏',
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

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _cancelarTimers();
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    _busqueda = '';
    _tecladoAbierto = false;
    _palabras.clear();
    _enviados.clear();
    _sinInternet = false;

    switch (_pasoActual) {
      case 1:
        _pantalla = 'lista';
        break;
      case 2:
        _pantalla = 'nuevo';
        _tecladoAbierto = true;
        break;
      case 3:
        _pantalla = 'conversacion';
        _tecladoAbierto = true;
        break;
      case 4:
        _pantalla = 'conversacion';
        _tecladoAbierto = true;
        _palabras.addAll(_frase);
        break;
      case 5:
        _pantalla = 'conversacion';
        _sinInternet = true;
        _tecladoAbierto = true;
        _enviados.add(_Sms(_frase.join(' '), '4:02 p. m.', 'Entregado'));
        break;
      default:
        _pantalla = 'lista';
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'nuevo':
        cumple = _pantalla == 'nuevo';
        break;
      case 'destinatario':
        cumple = _pantalla == 'conversacion';
        break;
      case 'mensaje_listo':
        cumple = _palabras.length == _frase.length;
        break;
      case 'enviado':
        cumple = _enviados.isNotEmpty && _enviados.first.estado == 'Entregado';
        break;
      case 'sin_internet':
        cumple = _enviados.length == 2 && _enviados.last.estado == 'Entregado';
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
        case 'iniciar_chat':
          if (_pasoActual == 1) {
            _pantalla = 'nuevo';
            _tecladoAbierto = true;
          }
          break;
        case 'abrir_lista':
          _mensajeGuia = _pasoActual == 1
              ? 'Hoy empezamos uno nuevo. Toca "Iniciar chat"'
              : 'Sigue la instrucción de la cajita morada';
          break;

        case 'letra':
          if (_pantalla == 'nuevo') {
            if (_busqueda.length < 8) _busqueda += valor;
            if (!'ma'.startsWith(_busqueda) && !_busqueda.startsWith('ma')) {
              _mensajeGuia = 'Esa letra no va. Toca ⌫ para borrarla';
            }
          } else {
            _mensajeGuia = 'Es más fácil tocar la palabra resaltada de arriba';
          }
          break;
        case 'borrar':
          if (_pantalla == 'nuevo' && _busqueda.isNotEmpty) {
            _busqueda = _busqueda.substring(0, _busqueda.length - 1);
          } else if (_pantalla == 'conversacion' &&
              _palabras.isNotEmpty &&
              _pasoActual == 3) {
            _palabras.removeLast();
          }
          break;
        case 'contacto':
          if (valor == 'María') {
            _pantalla = 'conversacion';
            _tecladoAbierto = true;
          } else {
            _mensajeGuia = 'Ese es $valor. Busca a María';
          }
          break;

        case 'palabra':
          _elegirPalabra(valor);
          break;
        case 'rapida':
          if (_pasoActual == 5) {
            _palabras
              ..clear()
              ..add(valor);
          }
          break;

        case 'caja':
          _tecladoAbierto = true;
          break;
        case 'enviar':
          _enviar();
          break;
        case 'atras':
          _mensajeGuia = 'Quédate aquí para terminar el mensaje';
          break;
      }

      _revisarObjetivo();
    });
  }

  void _elegirPalabra(String palabra) {
    if (_pasoActual != 3) return;
    final i = _palabras.length;
    if (i >= _frase.length) return;
    if (palabra == _frase[i]) {
      _palabras.add(palabra);
    } else {
      _mensajeGuia = 'Esa no. La palabra que sigue está resaltada en amarillo';
    }
  }

  void _enviar() {
    if (_palabras.isEmpty) return;
    if (_pasoActual == 3) {
      _mensajeGuia = _palabras.length == _frase.length
          ? '¡Quedó! Toca el botón verde de abajo para seguir'
          : 'Termina primero la frase';
      return;
    }
    if (_pasoActual != 4 && _pasoActual != 5) return;
    final sms = _Sms(_palabras.join(' '), '4:0${_pasoActual == 4 ? 2 : 9} p. m.',
        'Enviando...');
    _enviados.add(sms);
    _palabras.clear();
    _tecladoAbierto = false;
    _programar(900, () => sms.estado = 'Enviado');
    _programar(2000, () => sms.estado = 'Entregado');
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
      tituloLeccion: 'Mensaje nuevo',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '🆕',
      textoTrofeo: '¡Ya escribes a quien quieras!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    switch (_pantalla) {
      case 'nuevo':
        return 'MENSAJES · NUEVA CONVERSACIÓN';
      case 'conversacion':
        return 'MENSAJES · CON MARÍA';
      default:
        return 'MENSAJES · CONVERSACIONES';
    }
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: Column(
        children: [
          _barraEstado(),
          Expanded(child: _buildPantalla()),
        ],
      ),
    );
  }

  // Barrita de arriba con la senal y el internet
  Widget _barraEstado() {
    return Container(
      height: 20,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Text('4:01',
              style: TextStyle(
                  color: MnvColores.texto,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          if (_sinInternet)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: MnvColores.rojoSuave,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Sin internet',
                  style: TextStyle(
                      color: MnvColores.rojo,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          Icon(_sinInternet ? Icons.wifi_off_rounded : Icons.wifi_rounded,
              size: 13,
              color: _sinInternet ? MnvColores.rojo : MnvColores.texto),
          const SizedBox(width: 4),
          const Icon(Icons.signal_cellular_alt_rounded,
              size: 13, color: MnvColores.texto),
          const SizedBox(width: 4),
          const Icon(Icons.battery_full_rounded,
              size: 13, color: MnvColores.texto),
        ],
      ),
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'nuevo':
        return _buildNuevo();
      case 'conversacion':
        return _buildConversacion();
      default:
        return _buildLista();
    }
  }

  Widget _buildLista() {
    return Container(
      color: MsColores.fondo,
      child: Stack(
        children: [
          Column(
            children: [
              MsCabeceraLista(
                onBuscar: () => _tocarEnSimulador('abrir_lista'),
                onBorrar: () {},
                onCancelarSeleccion: () {},
              ),
              MsFilaConversacion(
                nombre: 'Carlos (hijo)',
                inicial: 'C',
                color: MnvColores.azul,
                ultimo: 'Te llamo más tarde',
                hora: '1:20 p. m.',
                onTap: () => _tocarEnSimulador('abrir_lista'),
              ),
              MsFilaConversacion(
                nombre: 'MiEPS',
                inicial: 'M',
                color: const Color(0xFF0F766E),
                ultimo: 'Tu código es 731506. No lo compartas...',
                hora: '9:12 a. m.',
                onTap: () => _tocarEnSimulador('abrir_lista'),
              ),
              MsFilaConversacion(
                nombre: 'Operador Móvil',
                inicial: 'O',
                color: MnvColores.suave2,
                ultimo: 'Tu recarga de \$10.000 fue exitosa',
                hora: 'Ayer',
                onTap: () => _tocarEnSimulador('abrir_lista'),
              ),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 14,
            child: MsBotonIniciarChat(
              resaltado: _pasoActual == 1,
              onTap: () => _tocarEnSimulador('iniciar_chat'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNuevo() {
    final filtrados = _busqueda.isEmpty
        ? _contactos
        : _contactos
            .where((c) => c[0].toLowerCase().startsWith(_busqueda))
            .toList();
    final esperada = _busqueda.length < 2 && 'ma'.startsWith(_busqueda)
        ? 'ma'[_busqueda.length]
        : null;
    final malo = !'ma'.startsWith(_busqueda) && !_busqueda.startsWith('ma');

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          MsCabeceraConversacion(
            nombre: 'Nueva conversación',
            inicial: '+',
            color: MsColores.acento,
            onAtras: () => _tocarEnSimulador('atras'),
          ),
          Container(
            height: 40,
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: MnvColores.lila,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MsColores.acento, width: 1.5),
            ),
            child: Row(
              children: [
                const Text('Para: ',
                    style: TextStyle(color: MnvColores.suave, fontSize: 13)),
                Flexible(child: Text(_busqueda,
                    style: const TextStyle(
                        color: MnvColores.texto,
                        fontSize: 13,
                        fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Container(width: 2, height: 16, color: MsColores.acento),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: filtrados.map((c) {
                final esMaria = c[0] == 'María';
                return GestureDetector(
                  onTap: () => _tocarEnSimulador('contacto', valor: c[0]),
                  child: MnvResalte(
                    activo: esMaria && _busqueda == 'ma',
                    radio: 10,
                    escala: 1.03,
                    child: Container(
                      height: 46,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          MnvAvatar(
                              texto: c[1],
                              color: esMaria ? MnvColores.verde : MsColores.acento,
                              tam: 32),
                          const SizedBox(width: 10),
                          Flexible(child: Text(c[0],
                              style: const TextStyle(
                                  color: MnvColores.texto,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_tecladoAbierto)
            MnvTecladoLetras(
              onLetra: (l) => _tocarEnSimulador('letra', valor: l),
              onBorrar: () => _tocarEnSimulador('borrar'),
              letraEsperada: esperada,
              resaltarBorrar: malo,
            ),
        ],
      ),
    );
  }

  Widget _buildConversacion() {
    final texto = _palabras.join(' ');
    final i = _palabras.length;
    List<String> sugerencias = const [];
    String? resaltada;
    if (_pasoActual == 3 && i < _opciones.length) {
      sugerencias = _opciones[i];
      resaltada = _frase[i];
    } else if (_pasoActual == 5 && _enviados.length == 1) {
      sugerencias = const ['Ya llegué 👋', 'Voy tarde', 'Ok'];
      resaltada = _palabras.isEmpty ? 'Ya llegué 👋' : null;
    }

    return Container(
      color: MsColores.fondo,
      child: Column(
        children: [
          MsCabeceraConversacion(
            nombre: 'María',
            inicial: 'M',
            color: MnvColores.verde,
            subtitulo: '300 555 1234',
            onAtras: () => _tocarEnSimulador('atras'),
            acciones: const [
              Icon(Icons.call_outlined, color: MnvColores.texto, size: 20),
              SizedBox(width: 10),
            ],
          ),
          Expanded(
            child: _enviados.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                          'Nueva conversación con María\nMensaje de texto (SMS)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: MnvColores.suave2.withValues(alpha: 0.9),
                              fontSize: 11.5,
                              height: 1.4)),
                    ),
                  )
                : ListView(
                    reverse: true,
                    padding: const EdgeInsets.only(bottom: 6),
                    children: _enviados.reversed
                        .map((s) => MsBurbuja(
                              texto: s.texto,
                              mia: true,
                              hora: s.hora,
                              estado: s.estado,
                            ))
                        .toList(),
                  ),
          ),
          if (_sinInternet && _enviados.length == 2 &&
              _enviados.last.estado == 'Entregado')
            Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MnvColores.verdeSuave,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                  '📶 Sin internet, pero con señal: el mensaje de texto llegó igual.',
                  style: TextStyle(color: MnvColores.texto, fontSize: 11)),
            ),
          MsCajaEscribir(
            texto: texto,
            enfocada: _tecladoAbierto,
            resaltarEnviar: (_pasoActual == 4 && _enviados.isEmpty) ||
                (_pasoActual == 5 && _palabras.isNotEmpty),
            onCaja: () => _tocarEnSimulador('caja'),
            onEnviar: () => _tocarEnSimulador('enviar'),
          ),
          if (_tecladoAbierto)
            MnvTecladoLetras(
              onLetra: (l) => _tocarEnSimulador('letra', valor: l),
              onBorrar: () => _tocarEnSimulador('borrar'),
              sugerencias: sugerencias,
              sugerenciaResaltada: resaltada,
              onSugerencia: (s) => _tocarEnSimulador(
                  _pasoActual == 5 ? 'rapida' : 'palabra',
                  valor: s),
            ),
        ],
      ),
    );
  }
}
