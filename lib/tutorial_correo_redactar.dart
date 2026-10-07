import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_correo.dart';

const String _leccionId = 'correo_redactar';

class TutorialCorreoRedactarScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialCorreoRedactarScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialCorreoRedactarScreen> createState() =>
      _TutorialCorreoRedactarScreenState();
}

class _TutorialCorreoRedactarScreenState
    extends State<TutorialCorreoRedactarScreen> {
  int _pasoActual = 0;

  // pantalla: bandeja | redactar
  String _pantalla = 'bandeja';
  // campo activo: ninguno | para | asunto | cuerpo
  String _campo = 'ninguno';
  String _paraEscrito = '';
  bool _paraOk = false;
  String _asunto = '';
  final List<String> _partes = [];
  bool _adjuntoOk = false;
  bool _hojaAdjuntar = false;
  bool _enviado = false;
  bool _mostrarCheck = false;
  String? _aviso;
  Timer? _timer;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const String _destino = 'lucia.nieta@correo.com';
  static const String _asuntoBueno = 'Receta del ajiaco';
  static const List<List<String>> _etapas = [
    ['Hola Lucía,', 'Querida nieta,', 'Buenos días,'],
    ['Te mando la receta que me pediste.', 'Aquí va la receta.', 'Mira lo que encontré.'],
    ['Con cariño, tu abue 💕', 'Un abrazo.', 'Besos.'],
  ];

  static const List<CoCorreo> _correos = [
    CoCorreo(
      clave: 'lucia',
      remitente: 'Lucía (nieta)',
      inicial: 'L',
      color: MnvColores.verde,
      asunto: '¿Me mandas la receta? 🍲',
      extracto: 'Abue, ¿me mandas la receta del ajiaco por correo?',
      fecha: '11:40 a. m.',
    ),
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
  ];

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Escribir un correo nuevo ✉️',
      'instruccion':
          'Lucía te pidió la receta del ajiaco por correo.\n\nHoy escribes uno desde cero: a quién (Para), de qué (Asunto), el mensaje y una foto de la receta.',
      'icono': Icons.edit_rounded,
      'colorIcono': MnvColores.azul,
    },
    {
      'tipo': 'sim',
      'titulo': 'Toca "Redactar" ✏️',
      'instruccion':
          'Para escribir un correo nuevo, abajo a la derecha hay un botón con un lápiz que dice Redactar.\n\nTócalo.',
      'objetivo': 'redactar',
      'ayuda': 'Toca el botón Redactar',
    },
    {
      'tipo': 'sim',
      'titulo': '¿Para quién? 👤',
      'instruccion':
          'Ya estás en "Para". No tienes que saberte la dirección: escribe "luc" y el celular te la sugiere.\n\nToca la sugerencia de Lucía.',
      'objetivo': 'para_ok',
      'ayuda': 'Escribe l, u, c y toca la sugerencia',
    },
    {
      'tipo': 'sim',
      'titulo': 'El asunto 📝',
      'instruccion':
          'El asunto es el título: le dice a Lucía de qué se trata antes de abrirlo.\n\nToca "Asunto" y elige "Receta del ajiaco".',
      'objetivo': 'asunto_ok',
      'ayuda': 'Toca Asunto y elige la frase',
    },
    {
      'tipo': 'sim',
      'titulo': 'El mensaje 💌',
      'instruccion':
          'Toca el espacio blanco grande y arma el mensaje con las frases: un saludo, lo que le mandas y una despedida.',
      'objetivo': 'cuerpo_ok',
      'ayuda': 'Toca el espacio blanco y elige 3 frases',
    },
    {
      'tipo': 'sim',
      'titulo': 'Adjunta la receta 📎',
      'instruccion':
          'Le tomaste foto a la receta del cuaderno. Toca el clip de arriba y elige "Receta_ajiaco".',
      'objetivo': 'adjunto_ok',
      'ayuda': 'Toca el clip y elige la receta',
    },
    {
      'tipo': 'sim',
      'titulo': '¡Envíalo! ➤',
      'instruccion':
          'Revisa que todo esté bien y toca el avioncito de arriba a la derecha.',
      'objetivo': 'enviado',
      'ayuda': 'Toca el avioncito de arriba',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Revisa el "Para"',
      'instruccion':
          'Una sola letra mal en la dirección y el correo le llega a otra persona o no le llega a nadie.\n\nPor eso es mejor elegir la sugerencia que escribir la dirección completa.',
      'icono': Icons.fact_check_rounded,
      'colorIcono': MnvColores.amarillo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Escríbele un correo a alguien de tu familia con asunto, un mensaje corto y una foto adjunta.\n\nPídele que te confirme que le llegó.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': MnvColores.azul,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Escribes correos completos! 🏆',
      'instruccion':
          'Para, asunto, mensaje, adjunto y enviar: hiciste un correo de principio a fin.\n\nLucía va a hacer el ajiaco gracias a ti. 🍲👏',
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
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _timer?.cancel();
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    _pantalla = _pasoActual >= 2 && _pasoActual <= 6 ? 'redactar' : 'bandeja';
    _campo = 'ninguno';
    _paraEscrito = '';
    _hojaAdjuntar = false;
    _enviado = false;
    _mostrarCheck = false;
    _aviso = null;

    // Lo que quedo hecho en los pasos anteriores
    _paraOk = _pasoActual >= 3;
    _asunto = _pasoActual >= 4 ? _asuntoBueno : '';
    _partes.clear();
    if (_pasoActual >= 5) {
      _partes.addAll([_etapas[0][0], _etapas[1][0], _etapas[2][0]]);
    }
    _adjuntoOk = _pasoActual >= 6;

    if (_pasoActual == 2) _campo = 'para';
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'redactar':
        cumple = _pantalla == 'redactar';
        break;
      case 'para_ok':
        cumple = _paraOk;
        break;
      case 'asunto_ok':
        cumple = _asunto == _asuntoBueno;
        break;
      case 'cuerpo_ok':
        cumple = _partes.length == 3;
        break;
      case 'adjunto_ok':
        cumple = _adjuntoOk;
        break;
      case 'enviado':
        cumple = _enviado;
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
        case 'redactar':
          if (_pasoActual == 1) {
            _pantalla = 'redactar';
            _campo = 'para';
          }
          break;
        case 'abrir':
          _mensajeGuia = _pasoActual == 1
              ? 'No hay que abrir este. Toca el botón Redactar de abajo'
              : 'Sigue la instrucción de la cajita morada';
          break;

        case 'campo':
          _tocarCampo(valor);
          break;

        case 'letra':
          if (_campo == 'para' && !_paraOk) {
            if (_paraEscrito.length < 10) _paraEscrito += valor;
            if (!'lucia'.startsWith(_paraEscrito)) {
              _mensajeGuia = 'Esa letra no va. Toca ⌫ para borrarla';
            }
          } else {
            _mensajeGuia = 'Usa las frases de arriba del teclado, es más fácil';
          }
          break;
        case 'borrar':
          if (_campo == 'para' && _paraEscrito.isNotEmpty) {
            _paraEscrito =
                _paraEscrito.substring(0, _paraEscrito.length - 1);
          } else if (_campo == 'cuerpo' && _partes.isNotEmpty) {
            _partes.removeLast();
          } else if (_campo == 'asunto') {
            _asunto = '';
          }
          break;
        case 'elegir_contacto':
          _paraOk = true;
          _paraEscrito = '';
          _campo = 'ninguno';
          break;

        case 'sugerencia':
          if (_campo == 'asunto') {
            if (valor == _asuntoBueno) {
              _asunto = valor;
              _campo = 'ninguno';
            } else {
              _mensajeGuia = 'Para que Lucía sepa de qué es, elige "Receta del ajiaco"';
            }
          } else if (_campo == 'cuerpo') {
            if (_partes.length < 3) _partes.add(valor);
            if (_partes.length == 3) _campo = 'ninguno';
          }
          break;

        case 'clip':
          if (_pasoActual < 5) {
            _mensajeGuia = 'El adjunto va después. Sigue la cajita morada';
          } else if (!_adjuntoOk) {
            _hojaAdjuntar = true;
            _campo = 'ninguno';
          }
          break;
        case 'archivo':
          if (valor == 'receta') {
            _adjuntoOk = true;
            _hojaAdjuntar = false;
          } else {
            _mensajeGuia = 'Ese no es. Busca "Receta_ajiaco" con la olla 🍲';
          }
          break;
        case 'cerrar_hoja':
          _hojaAdjuntar = false;
          break;

        case 'enviar':
          _intentarEnviar();
          break;
        case 'atras':
          _mensajeGuia = 'Si sales se guarda como borrador. Sigamos aquí';
          break;
      }

      _revisarObjetivo();
    });
  }

  void _tocarCampo(String campo) {
    if (_pasoActual == 2 && campo != 'para') {
      _mensajeGuia = 'Primero el "Para": escribe luc';
      return;
    }
    if (_pasoActual == 3 && campo != 'asunto') {
      _mensajeGuia = 'Ahora toca el renglón que dice Asunto';
      return;
    }
    if (_pasoActual == 4 && campo != 'cuerpo') {
      _mensajeGuia = 'Toca el espacio blanco grande de abajo';
      return;
    }
    if (_pasoActual >= 5) {
      _mensajeGuia = 'Eso ya está listo. Sigue la cajita morada';
      return;
    }
    _campo = campo;
  }

  void _intentarEnviar() {
    if (_pasoActual < 6) {
      _mensajeGuia = 'Todavía falta. Sigue los pasos de la cajita morada';
      return;
    }
    if (_enviado) return;
    _enviado = true;
    _mostrarCheck = true;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      setState(() {
        _mostrarCheck = false;
        _pantalla = 'bandeja';
        _aviso = 'Enviado a Lucía';
      });
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
    _timer?.cancel();
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
      tituloLeccion: 'Escribir un correo',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '✉️',
      textoTrofeo: '¡Escribes correos completos!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    if (_pantalla == 'bandeja') return 'CORREO · RECIBIDOS';
    if (_hojaAdjuntar) return 'NUEVO CORREO · ADJUNTAR';
    switch (_campo) {
      case 'para':
        return 'NUEVO CORREO · PARA';
      case 'asunto':
        return 'NUEVO CORREO · ASUNTO';
      case 'cuerpo':
        return 'NUEVO CORREO · MENSAJE';
      default:
        return 'NUEVO CORREO';
    }
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: _pantalla == 'redactar' ? _buildRedactar() : _buildBandeja(),
      encima: [
        if (_hojaAdjuntar) _buildHojaAdjuntar(),
        if (_mostrarCheck) const MnvCheckConfirmacion(texto: 'Enviado'),
        if (_aviso != null && _pantalla == 'bandeja')
          CoAvisoAbajo(texto: _aviso!),
      ],
    );
  }

  Widget _buildBandeja() {
    return Container(
      color: CoColores.fondo,
      child: Stack(
        children: [
          Column(
            children: [
              CoBarraBusqueda(
                onTap: () => setState(() =>
                    _mensajeGuia = 'Hoy no buscamos. Sigue la cajita morada'),
                onMenu: () => setState(() =>
                    _mensajeGuia = 'Hoy no usamos el menú'),
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
                    noLeido: c.clave == 'lucia' && !_enviado,
                    onTap: () => _tocarEnSimulador('abrir'),
                    onEstrella: () => _tocarEnSimulador('abrir'),
                  )),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 14,
            child: CoBotonRedactar(
              resaltado: _pasoActual == 1,
              onTap: () => _tocarEnSimulador('redactar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedactar() {
    final etapa = _partes.length;
    List<String> sugerencias = const [];
    String? resaltada;
    if (_campo == 'asunto') {
      sugerencias = const [_asuntoBueno, 'Hola', 'Fotos'];
      resaltada = _asuntoBueno;
    } else if (_campo == 'cuerpo' && etapa < _etapas.length) {
      sugerencias = _etapas[etapa];
      resaltada = sugerencias.first;
    }
    final letraEsperada = _campo == 'para' &&
            !_paraOk &&
            _paraEscrito.length < 3 &&
            'luc'.startsWith(_paraEscrito)
        ? 'luc'[_paraEscrito.length]
        : null;
    final mostrarSugerenciaPara = _campo == 'para' &&
        !_paraOk &&
        _paraEscrito.isNotEmpty &&
        'lucia'.startsWith(_paraEscrito);
    final cuerpo = _partes.join('\n\n');

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Column(
            children: [
              CoBarraSuperior(
                titulo: 'Redactar',
                onAtras: () => _tocarEnSimulador('atras'),
                acciones: [
                  CoIconoAccion(
                    icono: Icons.attach_file_rounded,
                    resaltado: _pasoActual == 5 && !_adjuntoOk,
                    onTap: () => _tocarEnSimulador('clip'),
                  ),
                  CoIconoAccion(
                    icono: Icons.send_rounded,
                    color: CoColores.acento,
                    resaltado: _pasoActual == 6 && !_enviado,
                    onTap: () => _tocarEnSimulador('enviar'),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              CoCampo(
                etiqueta: 'Para',
                valor: _paraEscrito,
                activo: _campo == 'para',
                resaltado: _pasoActual == 2 && _campo != 'para',
                onTap: () => _tocarEnSimulador('campo', valor: 'para'),
                extra: _paraOk ? _chipDestino() : null,
              ),
              CoCampo(
                etiqueta: 'Asunto',
                valor: _asunto,
                activo: _campo == 'asunto',
                resaltado: _pasoActual == 3 && _campo != 'asunto' && _asunto.isEmpty,
                onTap: () => _tocarEnSimulador('campo', valor: 'asunto'),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _tocarEnSimulador('campo', valor: 'cuerpo'),
                  child: MnvResalte(
                    activo: _pasoActual == 4 && _campo != 'cuerpo' && _partes.isEmpty,
                    radio: 8,
                    escala: 1.0,
                    child: Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                cuerpo.isEmpty ? 'Redacta un correo' : cuerpo,
                                style: TextStyle(
                                    color: cuerpo.isEmpty
                                        ? const Color(0xFFBBB6D8)
                                        : MnvColores.texto,
                                    fontSize: 13,
                                    height: 1.4)),
                            if (_adjuntoOk) ...[
                              const SizedBox(height: 10),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.6, end: 1),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.elasticOut,
                                builder: (_, t, hijo) =>
                                    Transform.scale(scale: t, child: hijo),
                                child: CoAdjunto(
                                  nombre: 'Receta_ajiaco.jpg',
                                  tamano: 'Foto · 1,1 MB',
                                  icono: Icons.image_rounded,
                                  color: MnvColores.verde,
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_campo != 'ninguno')
                MnvTecladoLetras(
                  onLetra: (l) => _tocarEnSimulador('letra', valor: l),
                  onBorrar: () => _tocarEnSimulador('borrar'),
                  letraEsperada: letraEsperada,
                  resaltarBorrar: _campo == 'para' &&
                      !'lucia'.startsWith(_paraEscrito),
                  sugerencias: sugerencias,
                  sugerenciaResaltada: resaltada,
                  onSugerencia: (s) =>
                      _tocarEnSimulador('sugerencia', valor: s),
                ),
            ],
          ),
          if (mostrarSugerenciaPara)
            Positioned(
              top: 46 + 42,
              left: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => _tocarEnSimulador('elegir_contacto'),
                child: MnvResalte(
                  activo: true,
                  radio: 12,
                  escala: 1.03,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Row(
                      children: [
                        MnvAvatar(texto: 'L', color: MnvColores.verde, tam: 32),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Lucía (nieta)',
                                  style: TextStyle(
                                      color: MnvColores.texto,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              Text(_destino,
                                  style: TextStyle(
                                      color: MnvColores.suave2,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chipDestino() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.7, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        builder: (_, t, hijo) => Transform.scale(scale: t, child: hijo),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: CoColores.barra,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MnvAvatar(texto: 'L', color: MnvColores.verde, tam: 18),
              SizedBox(width: 5),
              Text('Lucía (nieta)',
                  style: TextStyle(color: MnvColores.texto, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // Hoja para escoger el archivo a adjuntar
  Widget _buildHojaAdjuntar() {
    final archivos = [
      ['receta', 'Receta_ajiaco.jpg', '🍲', 'Foto · 1,1 MB'],
      ['jardin', 'Foto_jardin.jpg', '🌻', 'Foto · 2,3 MB'],
      ['factura', 'Factura_agua.pdf', '📄', 'PDF · 180 KB'],
    ];
    return Positioned.fill(
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _tocarEnSimulador('cerrar_hoja'),
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            builder: (_, t, hijo) =>
                Transform.translate(offset: Offset(0, 220 * t), child: hijo),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Adjuntar archivo',
                      style: TextStyle(
                          color: MnvColores.texto,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...archivos.map((a) {
                    final esReceta = a[0] == 'receta';
                    return GestureDetector(
                      onTap: () => _tocarEnSimulador('archivo', valor: a[0]),
                      child: MnvResalte(
                        activo: esReceta,
                        radio: 12,
                        escala: 1.03,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CoColores.fondo,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                    child: Text(a[2],
                                        style: const TextStyle(fontSize: 22))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a[1],
                                        style: const TextStyle(
                                            color: MnvColores.texto,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold)),
                                    Text(a[3],
                                        style: const TextStyle(
                                            color: MnvColores.suave2,
                                            fontSize: 10.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
