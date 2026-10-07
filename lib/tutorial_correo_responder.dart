import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_correo.dart';

const String _leccionId = 'correo_responder';

class TutorialCorreoResponderScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialCorreoResponderScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialCorreoResponderScreen> createState() =>
      _TutorialCorreoResponderScreenState();
}

class _TutorialCorreoResponderScreenState
    extends State<TutorialCorreoResponderScreen> {
  int _pasoActual = 0;

  // pantalla: bandeja | correo | redactar | enviados
  String _pantalla = 'bandeja';
  bool _leido = false;
  bool _tecladoAbierto = false;
  final List<String> _partes = [];
  bool _enviado = false;
  bool _menuAbierto = false;
  String? _aviso;
  Timer? _timerAviso;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const String _asunto = 'Por favor confirme su cita';
  static const List<List<String>> _etapas = [
    ['Buenos días,', 'Hola,', 'Señores:'],
    ['Confirmo mi cita del jueves.', 'Necesito cambiar la cita.', 'No podré asistir.'],
    ['Muchas gracias.', 'Quedo atento.', 'Saludos.'],
  ];

  static const List<CoCorreo> _correos = [
    CoCorreo(
      clave: 'clinica',
      remitente: 'Clínica Los Andes',
      inicial: 'C',
      color: MnvColores.azul,
      asunto: _asunto,
      extracto: 'Responda este correo para confirmar su asistencia',
      fecha: '10:05 a. m.',
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
      'titulo': 'Responder un correo ↩️',
      'instruccion':
          'La Clínica Los Andes te pide que confirmes tu cita respondiendo el correo.\n\nHoy aprendes a responder con buena forma: saludo, mensaje y despedida.',
      'icono': Icons.reply_rounded,
      'colorIcono': MnvColores.azul,
    },
    {
      'tipo': 'sim',
      'titulo': 'Abre el correo de la clínica 🏥',
      'instruccion': 'Está arriba, en negrita. Tócalo para leerlo.',
      'objetivo': 'abrir',
      'ayuda': 'Toca el correo de la Clínica Los Andes',
    },
    {
      'tipo': 'sim',
      'titulo': 'Toca "Responder" ↩️',
      'instruccion':
          'Abajo hay dos botones. RESPONDER le contesta a quien te escribió. REENVIAR se lo manda a otra persona.\n\nToca Responder.',
      'objetivo': 'responder',
      'ayuda': 'Toca el botón Responder',
    },
    {
      'tipo': 'sim_info',
      'titulo': 'Ya viene casi todo listo ✅',
      'instruccion':
          'Mira: en "Para" ya está la dirección de la clínica, y el asunto empieza con "Re:", que quiere decir "respuesta".\n\nNo tienes que escribirlos.',
    },
    {
      'tipo': 'sim',
      'titulo': 'Escribe tu respuesta ✍️',
      'instruccion':
          'Toca el espacio blanco grande y arma tu correo con las frases del teclado, en orden:\n\nprimero el SALUDO, luego el MENSAJE y al final la DESPEDIDA.',
      'objetivo': 'cuerpo',
      'ayuda': 'Toca el espacio blanco y elige 3 frases',
    },
    {
      'tipo': 'sim',
      'titulo': 'Envíalo ➤',
      'instruccion':
          'En el correo, el botón de enviar es un avioncito ARRIBA a la derecha (no abajo como en WhatsApp).\n\nTócalo.',
      'objetivo': 'enviado',
      'ayuda': 'Toca el avioncito de arriba a la derecha',
    },
    {
      'tipo': 'sim',
      'titulo': '¿Sí se fue? Revisa Enviados 📤',
      'instruccion':
          'Todo lo que mandas queda guardado en "Enviados".\n\nToca las tres rayitas ☰ de la barra de arriba y elige Enviados.',
      'objetivo': 'ver_enviados',
      'ayuda': 'Toca ☰ y luego Enviados',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Un correo con buena forma',
      'instruccion':
          'Saludo ("Buenos días,") · mensaje corto y claro · despedida ("Muchas gracias.") y tu nombre.\n\nCon entidades usa "usted". Con la familia puedes ser como en WhatsApp.',
      'icono': Icons.format_align_left_rounded,
      'colorIcono': MnvColores.amarillo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Respóndele un correo a alguien de confianza (o a ti mismo) con saludo, mensaje y despedida.\n\nDespués búscalo en "Enviados".',
      'icono': Icons.smartphone_rounded,
      'colorIcono': MnvColores.azul,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Ya respondes correos! 🏆',
      'instruccion':
          'Abres, respondes, escribes con buena forma, envías y compruebas en Enviados.\n\nYa puedes hacer trámites por correo. 👏',
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
    _timerAviso?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _timerAviso?.cancel();
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    _leido = _pasoActual >= 2;
    _tecladoAbierto = false;
    _partes.clear();
    _enviado = _pasoActual >= 6;
    _menuAbierto = false;
    _aviso = null;

    switch (_pasoActual) {
      case 2:
        _pantalla = 'correo';
        break;
      case 3:
      case 4:
        _pantalla = 'redactar';
        break;
      case 5:
        _pantalla = 'redactar';
        _partes.addAll(
            ['Buenos días,', 'Confirmo mi cita del jueves.', 'Muchas gracias.']);
        break;
      default:
        _pantalla = 'bandeja';
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'abrir':
        cumple = _pantalla == 'correo';
        break;
      case 'responder':
        cumple = _pantalla == 'redactar';
        break;
      case 'cuerpo':
        cumple = _partes.length == 3;
        break;
      case 'enviado':
        cumple = _enviado;
        break;
      case 'ver_enviados':
        cumple = _pantalla == 'enviados';
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  void _mostrarAviso(String texto) {
    _aviso = texto;
    _timerAviso?.cancel();
    _timerAviso = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _aviso = null);
    });
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
        case 'abrir':
          if (valor == 'clinica' && _pasoActual == 1) {
            _leido = true;
            _pantalla = 'correo';
          } else if (_pasoActual == 1) {
            _mensajeGuia = 'Ese no. Busca el de la Clínica Los Andes';
          } else {
            _mensajeGuia = 'Sigue la instrucción de la cajita morada';
          }
          break;

        case 'responder':
          if (_pasoActual == 2) _pantalla = 'redactar';
          break;
        case 'reenviar':
          _mensajeGuia = 'Reenviar es mandárselo a OTRA persona. Toca Responder';
          break;

        case 'cuerpo':
          if (_pasoActual == 4) _tecladoAbierto = true;
          break;
        case 'sugerencia':
          if (_partes.length < 3) _partes.add(valor);
          if (_partes.length == 3) _tecladoAbierto = false;
          break;
        case 'borrar':
          if (_partes.isNotEmpty && _pasoActual == 4) _partes.removeLast();
          break;
        case 'letra':
          _mensajeGuia = 'Puedes escribir, pero hoy usamos las frases de arriba';
          break;

        case 'enviar':
          if (_pasoActual == 4) {
            _mensajeGuia = _partes.length == 3
                ? '¡Quedó lindo! Toca el botón verde de abajo para seguir'
                : 'Primero escribe el saludo, el mensaje y la despedida';
          } else if (_pasoActual == 5) {
            _enviado = true;
            _pantalla = 'bandeja';
            _mostrarAviso('Enviado');
          }
          break;
        case 'adjuntar':
          _mensajeGuia = 'Hoy no hace falta adjuntar nada';
          break;
        case 'atras':
          if (_pantalla == 'redactar') {
            _mensajeGuia = 'Si sales ahora se guarda como borrador. Sigamos aquí';
          } else if (_pantalla == 'correo') {
            _pantalla = 'bandeja';
          } else if (_pantalla == 'enviados') {
            _pantalla = 'bandeja';
          }
          break;

        case 'menu':
          if (_pasoActual == 6) {
            _menuAbierto = true;
          } else {
            _mensajeGuia = 'El menú lo usamos al final de la lección';
          }
          break;
        case 'cerrar_menu':
          _menuAbierto = false;
          break;
        case 'opcion_menu':
          _menuAbierto = false;
          if (valor == 'enviados') {
            _pantalla = 'enviados';
          } else if (valor == 'recibidos') {
            _pantalla = 'bandeja';
          } else {
            _mensajeGuia = 'Esa carpeta no. Busca "Enviados"';
            _menuAbierto = true;
          }
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
    _timerAviso?.cancel();
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
      tituloLeccion: 'Responder un correo',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '↩️',
      textoTrofeo: '¡Ya respondes correos!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    if (_menuAbierto) return 'CORREO · MENÚ';
    switch (_pantalla) {
      case 'correo':
        return 'CORREO DE LA CLÍNICA';
      case 'redactar':
        return 'RESPONDER CORREO';
      case 'enviados':
        return 'CORREO · ENVIADOS';
      default:
        return 'CORREO · RECIBIDOS';
    }
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: _buildPantalla(),
      encima: [
        if (_menuAbierto)
          CoMenuLateral(
            activa: _pantalla == 'enviados' ? 'enviados' : 'recibidos',
            resaltada: _pasoActual == 6 ? 'enviados' : null,
            onOpcion: (o) => _tocarEnSimulador('opcion_menu', valor: o),
            onCerrar: () => _tocarEnSimulador('cerrar_menu'),
          ),
        if (_aviso != null) CoAvisoAbajo(texto: _aviso!),
      ],
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'correo':
        return _buildCorreo();
      case 'redactar':
        return _buildRedactar();
      case 'enviados':
        return _buildEnviados();
      default:
        return _buildBandeja();
    }
  }

  Widget _buildBandeja() {
    return Container(
      color: CoColores.fondo,
      child: Column(
        children: [
          CoBarraBusqueda(
            resaltarMenu: _pasoActual == 6 && !_menuAbierto,
            onTap: () => setState(() =>
                _mensajeGuia = 'Hoy no buscamos. Sigue la cajita morada'),
            onMenu: () => _tocarEnSimulador('menu'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 2, 14, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Recibidos',
                  style: TextStyle(
                      color: MnvColores.suave2,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          ..._correos.map((c) => CoFilaCorreo(
                correo: c,
                noLeido: c.clave == 'clinica' && !_leido,
                resaltada: c.clave == 'clinica' && _pasoActual == 1,
                onTap: () => _tocarEnSimulador('abrir', valor: c.clave),
                onEstrella: () => setState(() =>
                    _mensajeGuia = 'Las estrellas ya las conoces. Sigamos'),
              )),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCorreo() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          CoBarraSuperior(onAtras: () => _tocarEnSimulador('atras')),
          Expanded(
            child: CoVistaCorreo(
              asunto: _asunto,
              remitente: 'Clínica Los Andes',
              direccion: 'citas@clinicalosandes.co',
              inicial: 'C',
              color: MnvColores.azul,
              fecha: '10:05 a. m.',
              cuerpo:
                  'Buenos días.\n\nTiene una cita de medicina general el jueves 8 de octubre a las 9:30 a. m. con el Dr. Ramírez.\n\nPor favor responda este correo para confirmar su asistencia.\n\nClínica Los Andes',
              onToque: (_) {},
              pie: CoBotonesResponder(
                resaltarResponder: _pasoActual == 2,
                onToque: (b) => _tocarEnSimulador(b),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedactar() {
    final infoCampos = _pasoActual == 3;
    final cuerpo = _partes.join('\n\n');
    final etapa = _partes.length;
    final sugerencias =
        etapa < _etapas.length ? _etapas[etapa] : const <String>[];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          CoBarraSuperior(
            titulo: 'Responder',
            onAtras: () => _tocarEnSimulador('atras'),
            acciones: [
              CoIconoAccion(
                  icono: Icons.attach_file_rounded,
                  onTap: () => _tocarEnSimulador('adjuntar')),
              CoIconoAccion(
                icono: Icons.send_rounded,
                color: CoColores.acento,
                resaltado: _pasoActual == 5,
                onTap: () => _tocarEnSimulador('enviar'),
              ),
              const SizedBox(width: 4),
            ],
          ),
          CoCampo(
            etiqueta: 'De',
            valor: 'tu.nombre@correo.com',
            onTap: () {},
          ),
          CoCampo(
            etiqueta: 'Para',
            valor: '',
            resaltado: infoCampos,
            onTap: () => setState(() =>
                _mensajeGuia = 'La dirección ya está puesta. No hay que tocarla'),
            extra: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CoColores.barra,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MnvAvatar(texto: 'C', color: MnvColores.azul, tam: 18),
                    SizedBox(width: 5),
                    Text('citas@clinicalosandes.co',
                        style: TextStyle(
                            color: MnvColores.texto, fontSize: 11.5)),
                  ],
                ),
              ),
            ),
          ),
          CoCampo(
            etiqueta: 'Asunto',
            valor: 'Re: $_asunto',
            resaltado: infoCampos,
            onTap: () => setState(() =>
                _mensajeGuia = 'El asunto ya está puesto con "Re:"'),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _tocarEnSimulador('cuerpo'),
              child: MnvResalte(
                activo: _pasoActual == 4 && !_tecladoAbierto && _partes.isEmpty,
                radio: 8,
                escala: 1.0,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: SingleChildScrollView(
                    child: Text(
                        cuerpo.isEmpty ? 'Redacta un correo' : cuerpo,
                        style: TextStyle(
                            color: cuerpo.isEmpty
                                ? const Color(0xFFBBB6D8)
                                : MnvColores.texto,
                            fontSize: 13,
                            height: 1.4)),
                  ),
                ),
              ),
            ),
          ),
          if (_tecladoAbierto)
            MnvTecladoLetras(
              onLetra: (_) => _tocarEnSimulador('letra'),
              onBorrar: () => _tocarEnSimulador('borrar'),
              sugerencias: sugerencias,
              sugerenciaResaltada:
                  sugerencias.isNotEmpty ? sugerencias.first : null,
              onSugerencia: (s) => _tocarEnSimulador('sugerencia', valor: s),
            ),
        ],
      ),
    );
  }

  Widget _buildEnviados() {
    return Container(
      color: CoColores.fondo,
      child: Column(
        children: [
          CoBarraBusqueda(
            onTap: () {},
            onMenu: () => _tocarEnSimulador('menu'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 2, 14, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Enviados',
                  style: TextStyle(
                      color: MnvColores.suave2,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            builder: (_, t, hijo) => Container(
              color: Color.lerp(MnvColores.verdeSuave, CoColores.fondo, t),
              child: hijo,
            ),
            child: CoFilaCorreo(
              correo: const CoCorreo(
                clave: 'mio',
                remitente: 'Para: Clínica Los Andes',
                inicial: 'Tú',
                color: MnvColores.morado,
                asunto: 'Re: $_asunto',
                extracto: 'Buenos días, Confirmo mi cita del jueves...',
                fecha: '10:12 a. m.',
              ),
              onTap: () {},
              onEstrella: () {},
            ),
          ),
          CoFilaCorreo(
            correo: const CoCorreo(
              clave: 'viejo',
              remitente: 'Para: Lucía (nieta)',
              inicial: 'Tú',
              color: MnvColores.morado,
              asunto: 'Re: Fotos del cumpleaños 🎂',
              extracto: '¡Qué lindas! Gracias, mi amor',
              fecha: '2 oct',
            ),
            onTap: () {},
            onEstrella: () {},
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MnvColores.verdeSuave,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: MnvColores.verde, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Ahí está tu respuesta. Sí le llegó a la clínica.',
                        style: TextStyle(
                            color: MnvColores.texto, fontSize: 11.5)),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
