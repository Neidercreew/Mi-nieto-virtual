import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_correo.dart';

const String _leccionId = 'correo_bandeja';

class TutorialCorreoBandejaScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialCorreoBandejaScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialCorreoBandejaScreen> createState() =>
      _TutorialCorreoBandejaScreenState();
}

class _TutorialCorreoBandejaScreenState
    extends State<TutorialCorreoBandejaScreen> {
  int _pasoActual = 0;

  // pantalla: inicio | bandeja | correo
  String _pantalla = 'inicio';
  String _abierto = 'clinica';
  bool _leidoClinica = false;
  bool _estrellaClinica = false;
  bool _buscando = false;
  String _busqueda = '';
  final Set<String> _partesVistas = {};
  String? _ultimaParte;
  bool _volvio = false;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const List<CoCorreo> _correos = [
    CoCorreo(
      clave: 'clinica',
      remitente: 'Clínica Los Andes',
      inicial: 'C',
      color: MnvColores.azul,
      asunto: 'Confirmación de su cita médica',
      extracto: 'Le recordamos su cita de medicina general...',
      fecha: '8:15 a. m.',
    ),
    CoCorreo(
      clave: 'banco',
      remitente: 'Banco Andino',
      inicial: 'B',
      color: MnvColores.morado,
      asunto: 'Su extracto de septiembre',
      extracto: 'Ya está disponible su extracto mensual',
      fecha: '7:02 a. m.',
    ),
    CoCorreo(
      clave: 'agua',
      remitente: 'Aguas de la Ciudad',
      inicial: 'A',
      color: Color(0xFF0284C7),
      asunto: 'Factura de acueducto - octubre',
      extracto: 'Su factura por \$48.300 vence el 15 de octubre',
      fecha: '5 oct',
      adjunto: true,
    ),
    CoCorreo(
      clave: 'ofertas',
      remitente: 'Tienda Mundo Ofertas',
      inicial: 'T',
      color: Color(0xFFF97316),
      asunto: '¡50% en todo! Solo hoy 🔥',
      extracto: 'No te lo puedes perder, compra ya',
      fecha: '5 oct',
    ),
    CoCorreo(
      clave: 'luz',
      remitente: 'Energía Clara',
      inicial: 'E',
      color: MnvColores.amarillo,
      asunto: 'Factura de energía - octubre',
      extracto: 'Valor a pagar: \$92.100',
      fecha: '3 oct',
      adjunto: true,
    ),
    CoCorreo(
      clave: 'lucia',
      remitente: 'Lucía (nieta)',
      inicial: 'L',
      color: MnvColores.verde,
      asunto: 'Fotos del cumpleaños 🎂',
      extracto: 'Abue, te mando las fotos que tomamos',
      fecha: '2 oct',
    ),
  ];

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Tu correo electrónico 📧',
      'instruccion':
          'El correo es como el buzón de la casa, pero en el celular.\n\nAhí llegan las cosas formales: citas médicas, facturas, extractos del banco. Hoy aprendes a encontrarlas y leerlas.',
      'icono': Icons.mail_rounded,
      'colorIcono': MnvColores.azul,
    },
    {
      'tipo': 'sim',
      'titulo': 'Abre el Correo 📲',
      'instruccion':
          'En la pantalla de inicio busca el cuadro rojo con un sobre que dice Correo. (En muchos celulares se llama Gmail).',
      'objetivo': 'abrir_app',
      'ayuda': 'Toca el cuadro rojo del sobre',
    },
    {
      'tipo': 'sim_info',
      'titulo': 'La bandeja de entrada 📥',
      'instruccion':
          'Cada fila es un correo. Arriba dice QUIÉN lo manda, abajo DE QUÉ se trata (el asunto).\n\nLos que están en negrita oscura son los que todavía NO has leído.',
    },
    {
      'tipo': 'sim',
      'titulo': 'Abre el de la clínica 🏥',
      'instruccion':
          'El correo de la Clínica Los Andes está en negrita: no lo has leído.\n\nTócalo para abrirlo.',
      'objetivo': 'abrir_clinica',
      'ayuda': 'Toca el correo de la Clínica Los Andes',
    },
    {
      'tipo': 'sim',
      'titulo': 'Las partes de un correo 🔍',
      'instruccion':
          'Todo correo tiene tres datos importantes.\n\nToca QUIÉN lo manda, DE QUÉ se trata (el título grande) y CUÁNDO llegó (la hora).',
      'objetivo': 'partes_3',
      'ayuda': 'Toca remitente, asunto y hora',
    },
    {
      'tipo': 'sim',
      'titulo': 'Vuelve a la bandeja ⬅️',
      'instruccion':
          'Toca la flecha de arriba a la izquierda.\n\nFíjate: el correo de la clínica ya NO está en negrita, porque lo leíste.',
      'objetivo': 'volver',
      'ayuda': 'Toca la flecha ← de arriba',
    },
    {
      'tipo': 'sim',
      'titulo': 'Márcalo con estrella ⭐',
      'instruccion':
          'La cita es importante. Toca la estrellita de la derecha del correo de la clínica.\n\nAsí lo encuentras rápido después en "Destacados".',
      'objetivo': 'estrella',
      'ayuda': 'Toca la estrella del correo de la clínica',
    },
    {
      'tipo': 'sim',
      'titulo': 'Busca tus facturas 🔎',
      'instruccion':
          'Cuando tienes muchos correos, la barra de arriba los busca por ti.\n\nTócala y elige la palabra "factura".',
      'objetivo': 'busqueda',
      'ayuda': 'Toca "Buscar en el correo" y elige factura',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 ¿Correo o WhatsApp?',
      'instruccion':
          'WhatsApp es para hablar con la familia. El correo es para lo formal: bancos, EPS, trabajo, trámites.\n\nTu dirección de correo se ve así: nombre@correo.com. Apúntala en tu libreta.',
      'icono': Icons.alternate_email_rounded,
      'colorIcono': MnvColores.amarillo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Abre tu correo (Gmail). Busca un correo en negrita y léelo.\n\nLuego usa la barra de arriba para buscar la palabra "factura".',
      'icono': Icons.smartphone_rounded,
      'colorIcono': MnvColores.azul,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Ya manejas tu correo! 🏆',
      'instruccion':
          'Abres el correo, distingues los no leídos, sabes quién, qué y cuándo, marcas los importantes y buscas.\n\nEl buzón ya no te asusta. 👏',
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
    _confetti.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    _abierto = 'clinica';
    _buscando = false;
    _busqueda = '';
    _partesVistas.clear();
    _ultimaParte = null;
    _volvio = false;
    _leidoClinica = _pasoActual >= 4;
    _estrellaClinica = _pasoActual >= 7;

    switch (_pasoActual) {
      case 1:
        _pantalla = 'inicio';
        break;
      case 4:
      case 5:
        _pantalla = 'correo';
        break;
      case 2:
      case 3:
      case 6:
      case 7:
        _pantalla = 'bandeja';
        break;
      default:
        _pantalla = 'inicio';
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'abrir_app':
        cumple = _pantalla == 'bandeja';
        break;
      case 'abrir_clinica':
        cumple = _pantalla == 'correo' && _abierto == 'clinica';
        break;
      case 'partes_3':
        cumple = _partesVistas.length == 3;
        break;
      case 'volver':
        cumple = _volvio && _pantalla == 'bandeja';
        break;
      case 'estrella':
        cumple = _estrellaClinica;
        break;
      case 'busqueda':
        cumple = _busqueda == 'factura';
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // ─────────────────────────────────────────────
  // CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────
  void _tocarEnSimulador(String accion, {String valor = ''}) {
    final esInfo = _pasos[_pasoActual]['tipo'] == 'sim_info';
    setState(() {
      _mensajeGuia = null;
      if (esInfo) {
        _mensajeGuia = 'Aquí solo mira. Toca "Entendido" abajo para seguir';
        return;
      }

      switch (accion) {
        case 'app':
          if (valor == 'correo') {
            _pantalla = 'bandeja';
          } else {
            _mensajeGuia = 'Esa es otra app. Busca el cuadro rojo del sobre';
          }
          break;

        case 'abrir':
          if (_pasoActual == 3) {
            if (valor == 'clinica') {
              _abierto = 'clinica';
              _leidoClinica = true;
              _pantalla = 'correo';
            } else if (valor == 'ofertas') {
              _mensajeGuia = 'Ese es publicidad. Busca el de la Clínica Los Andes';
            } else {
              _mensajeGuia = 'Ese no. Busca el de la Clínica Los Andes, en negrita';
            }
          } else if (_pasoActual == 6) {
            _mensajeGuia = 'No hay que abrirlo: toca solo la estrellita de la derecha';
          } else if (_pasoActual == 7 && !_buscando) {
            _mensajeGuia = 'Primero toca la barra de arriba que dice "Buscar en el correo"';
          } else {
            _abierto = valor;
            _pantalla = 'correo';
          }
          break;

        case 'estrella':
          if (valor == 'clinica') {
            _estrellaClinica = !_estrellaClinica;
          } else {
            _mensajeGuia = _pasoActual == 6
                ? 'Esa es de otro correo. Busca la estrella de la clínica'
                : 'Las estrellas marcan correos importantes';
          }
          break;

        case 'parte':
          if (_pasoActual == 4 && valor != 'cuerpo') {
            _partesVistas.add(valor);
            _ultimaParte = valor;
          } else if (_pasoActual == 4) {
            _mensajeGuia = 'Ese es el mensaje. Toca quién lo manda, el asunto y la hora';
          }
          break;

        case 'atras':
          if (_pasoActual == 4) {
            _mensajeGuia = 'Antes de volver, toca las tres partes del correo';
          } else {
            _pantalla = 'bandeja';
            _volvio = true;
          }
          break;

        case 'barra':
          if (_pasoActual == 7) {
            _buscando = true;
          } else {
            _mensajeGuia = 'Buscar lo practicamos al final';
          }
          break;
        case 'sugerencia':
          _busqueda = valor;
          if (valor != 'factura') {
            _mensajeGuia = 'Así también busca. Para seguir, elige "factura"';
          }
          break;
        case 'letra':
          _mensajeGuia = 'Puedes escribir, pero es más fácil tocar la palabra de arriba';
          break;
        case 'cerrar_busqueda':
          _buscando = false;
          _busqueda = '';
          break;

        case 'menu':
          _mensajeGuia = 'El menú lo usamos en otra lección';
          break;
        case 'redactar':
          _mensajeGuia = 'Escribir correos tiene su propia lección';
          break;
      }

      _revisarObjetivo();
    });
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
      tituloLeccion: 'Conociendo tu correo',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '📧',
      textoTrofeo: '¡El buzón ya no te asusta!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    switch (_pantalla) {
      case 'bandeja':
        return _buscando ? 'CORREO · BUSCANDO' : 'CORREO · RECIBIDOS';
      case 'correo':
        return 'CORREO ABIERTO';
      default:
        return 'PANTALLA DE INICIO';
    }
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: _buildPantalla(),
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'bandeja':
        return _buildBandeja();
      case 'correo':
        return _buildCorreo();
      default:
        return MnvPantallaInicio(
          apps: MnvPantallaInicio.appsBase,
          resaltada: _pasoActual == 1 ? 'correo' : null,
          onApp: (clave) => _tocarEnSimulador('app', valor: clave),
        );
    }
  }

  Widget _buildBandeja() {
    final filtrados = _busqueda.isEmpty
        ? _correos
        : _correos
            .where((c) =>
                c.asunto.toLowerCase().contains(_busqueda) ||
                c.remitente.toLowerCase().contains(_busqueda))
            .toList();
    final infoFila = _pasoActual == 2;

    return Container(
      color: CoColores.fondo,
      child: Stack(
        children: [
          Column(
            children: [
              CoBarraBusqueda(
                texto: _busqueda,
                activa: _buscando,
                resaltada: _pasoActual == 7 && !_buscando,
                onTap: () => _tocarEnSimulador('barra'),
                onMenu: () => _tocarEnSimulador('menu'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
                child: Row(
                  children: [
                    Text(
                        _busqueda.isEmpty
                            ? 'Recibidos'
                            : '${filtrados.length} resultados para "$_busqueda"',
                        style: const TextStyle(
                            color: MnvColores.suave2,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (_buscando)
                      GestureDetector(
                        onTap: () => _tocarEnSimulador('cerrar_busqueda'),
                        child: const Text('Cerrar',
                            style: TextStyle(
                                color: CoColores.acento,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: filtrados.map((c) {
                    final esClinica = c.clave == 'clinica';
                    return CoFilaCorreo(
                      correo: c,
                      noLeido: esClinica
                          ? !_leidoClinica
                          : c.clave == 'ofertas',
                      destacado: esClinica && _estrellaClinica,
                      resaltada: (esClinica &&
                              (_pasoActual == 3 || infoFila)) ||
                          (_busqueda == 'factura' && c.adjunto),
                      resaltarEstrella: esClinica &&
                          _pasoActual == 6 &&
                          !_estrellaClinica,
                      onTap: () => _tocarEnSimulador('abrir', valor: c.clave),
                      onEstrella: () =>
                          _tocarEnSimulador('estrella', valor: c.clave),
                    );
                  }).toList(),
                ),
              ),
              if (_buscando)
                MnvTecladoLetras(
                  onLetra: (_) => _tocarEnSimulador('letra'),
                  onBorrar: () => _tocarEnSimulador('cerrar_busqueda'),
                  sugerencias: const ['factura', 'clínica', 'banco'],
                  sugerenciaResaltada:
                      _busqueda != 'factura' ? 'factura' : null,
                  onSugerencia: (s) =>
                      _tocarEnSimulador('sugerencia', valor: s),
                ),
            ],
          ),
          if (!_buscando)
            Positioned(
              right: 12,
              bottom: 14,
              child: CoBotonRedactar(
                  onTap: () => _tocarEnSimulador('redactar')),
            ),
        ],
      ),
    );
  }

  Widget _buildCorreo() {
    final c = _correos.firstWhere((x) => x.clave == _abierto,
        orElse: () => _correos.first);
    final esClinica = c.clave == 'clinica';
    final resaltar = <String>{};
    if (_pasoActual == 4) {
      for (final p in ['remitente', 'asunto', 'fecha']) {
        if (!_partesVistas.contains(p)) resaltar.add(p);
      }
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          CoBarraSuperior(
            onAtras: () => _tocarEnSimulador('atras'),
            resaltarAtras: _pasoActual == 5,
            acciones: const [
              Icon(Icons.archive_outlined, color: MnvColores.suave, size: 20),
              SizedBox(width: 16),
              Icon(Icons.delete_outline_rounded,
                  color: MnvColores.suave, size: 20),
              SizedBox(width: 16),
              Icon(Icons.more_vert_rounded, color: MnvColores.suave, size: 20),
              SizedBox(width: 8),
            ],
          ),
          Expanded(
            child: CoVistaCorreo(
              asunto: c.asunto,
              remitente: c.remitente,
              direccion: esClinica ? 'citas@clinicalosandes.co' : 'avisos@correo.co',
              inicial: c.inicial,
              color: c.color,
              fecha: c.fecha,
              destacado: esClinica && _estrellaClinica,
              cuerpo: esClinica
                  ? 'Buenos días.\n\nLe recordamos su cita de medicina general:\n\n📅 Jueves 8 de octubre\n🕤 9:30 a. m.\n👨‍⚕️ Dr. Ramírez, consultorio 204\n\nPor favor llegue 15 minutos antes con su documento.\n\nClínica Los Andes'
                  : '${c.extracto}.\n\nEste es un correo de práctica.',
              resaltar: resaltar,
              onToque: (parte) => _tocarEnSimulador('parte', valor: parte),
              pie: _pasoActual == 4 && _ultimaParte != null
                  ? _buildExplicacionParte()
                  : CoBotonesResponder(
                      onToque: (_) => setState(() => _mensajeGuia =
                          'Responder lo practicamos en otra lección'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplicacionParte() {
    String titulo;
    String texto;
    switch (_ultimaParte) {
      case 'remitente':
        titulo = '👤 Remitente: QUIÉN lo manda';
        texto = 'Aquí ves si es de alguien en quien confías.';
        break;
      case 'asunto':
        titulo = '📝 Asunto: DE QUÉ se trata';
        texto = 'Es como el título de la carta. Te dice si es urgente o no.';
        break;
      default:
        titulo = '🕒 Fecha: CUÁNDO llegó';
        texto = 'Si dice solo la hora, llegó hoy.';
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey(_ultimaParte),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (_, t, hijo) => Opacity(opacity: t, child: hijo),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: MnvColores.amarilloSuave,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MnvColores.amarillo, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(titulo,
                      style: const TextStyle(
                          color: MnvColores.texto,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold)),
                ),
                Text('${_partesVistas.length} de 3',
                    style: const TextStyle(
                        color: MnvColores.cafe,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 3),
            Text(texto,
                style: const TextStyle(
                    color: MnvColores.suave, fontSize: 11.5, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
