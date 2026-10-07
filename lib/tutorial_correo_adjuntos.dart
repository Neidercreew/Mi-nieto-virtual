import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_correo.dart';

const String _leccionId = 'correo_adjuntos';

class TutorialCorreoAdjuntosScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialCorreoAdjuntosScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialCorreoAdjuntosScreen> createState() =>
      _TutorialCorreoAdjuntosScreenState();
}

class _TutorialCorreoAdjuntosScreenState
    extends State<TutorialCorreoAdjuntosScreen> {
  int _pasoActual = 0;

  // pantalla: bandeja | correo_lab | visor | correo_falso
  String _pantalla = 'bandeja';
  bool _leidoLab = false;
  bool _zoom = false;
  bool _descargado = false;
  bool _mostrarDireccion = false;
  bool _dialogoSpam = false;
  bool _reportado = false;
  String? _aviso;
  Timer? _timerAviso;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const List<CoCorreo> _correos = [
    CoCorreo(
      clave: 'falso',
      remitente: 'Banco Andino',
      inicial: 'B',
      color: MnvColores.morado,
      asunto: '⚠️ URGENTE: Su cuenta será suspendida hoy',
      extracto: 'Actualice sus datos en las próximas 2 horas',
      fecha: '9:47 a. m.',
      adjunto: true,
    ),
    CoCorreo(
      clave: 'lab',
      remitente: 'Laboratorio Vida',
      inicial: 'V',
      color: MnvColores.verde,
      asunto: 'Resultados de sus exámenes',
      extracto: 'Adjuntamos los resultados de su examen de sangre',
      fecha: '9:10 a. m.',
      adjunto: true,
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
      'titulo': 'Archivos adjuntos 📎',
      'instruccion':
          'Un adjunto es como un papel que viene metido dentro del sobre: resultados de exámenes, facturas, certificados.\n\nHoy aprendes a abrirlos, leerlos bien y a no caer con adjuntos falsos.',
      'icono': Icons.attach_file_rounded,
      'colorIcono': MnvColores.azul,
    },
    {
      'tipo': 'sim',
      'titulo': 'El clip delata el adjunto 📎',
      'instruccion':
          'Los correos que traen un papel adentro tienen un clip pequeñito a la derecha.\n\nAbre el del Laboratorio Vida: te llegaron los resultados.',
      'objetivo': 'abrir_lab',
      'ayuda': 'Toca el correo del Laboratorio Vida',
    },
    {
      'tipo': 'sim',
      'titulo': 'Abre el archivo 📄',
      'instruccion':
          'Debajo del mensaje hay una tarjetita con el archivo. Los que terminan en PDF son documentos para leer.\n\nTócala.',
      'objetivo': 'adjunto_abierto',
      'ayuda': 'Toca la tarjeta del archivo PDF',
    },
    {
      'tipo': 'sim',
      'titulo': '¿Letra muy chiquita? 🔎',
      'instruccion':
          'Toca DOS veces seguidas sobre la hoja, rápido, como tocando una puerta: "toc-toc".\n\nLa hoja se agranda para leer mejor.',
      'objetivo': 'zoom',
      'ayuda': 'Toca dos veces seguidas sobre la hoja',
    },
    {
      'tipo': 'sim',
      'titulo': 'Guárdalo en tu celular ⬇️',
      'instruccion':
          'Para tenerlo aunque no haya internet, o para mostrarlo en la cita, toca la flecha hacia abajo de arriba a la derecha.',
      'objetivo': 'descargado',
      'ayuda': 'Toca la flecha de descargar',
    },
    {
      'tipo': 'sim',
      'titulo': '¿Es de verdad el banco? 🕵️',
      'instruccion':
          'Te llegó este correo "del banco" que te APURA y trae un archivo.\n\nNo abras el archivo. Toca el NOMBRE de quien lo manda para ver su dirección completa.',
      'objetivo': 'remitente_revisado',
      'ayuda': 'Toca el nombre "Banco Andino"',
    },
    {
      'tipo': 'sim',
      'titulo': 'Repórtalo como spam 🚫',
      'instruccion':
          'La dirección es rara: no es del banco. Es un engaño.\n\nToca "Reportar spam" y confirma. Se va a la carpeta de basura y te protege la próxima vez.',
      'objetivo': 'reportado',
      'ayuda': 'Toca Reportar spam y confirma',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Señales de un correo falso',
      'instruccion':
          'Dirección rara después del @ · te apura o te asusta · pide claves o datos · trae archivos .zip o .exe.\n\nTu banco NUNCA te pide la clave por correo. Si dudas, llama al banco al número de tu tarjeta.',
      'icono': Icons.gpp_maybe_rounded,
      'colorIcono': MnvColores.rojo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Busca en tu correo uno que tenga clip (una factura, por ejemplo). Ábrelo, agranda con doble toque y descárgalo.\n\nSi ves uno sospechoso, revisa la dirección del remitente.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': MnvColores.azul,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Adjuntos sin miedo! 🏆',
      'instruccion':
          'Abres documentos, los agrandas, los guardas y reconoces un correo falso por su dirección.\n\nEso es cuidarte de verdad. 👏',
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

    _leidoLab = _pasoActual >= 2;
    _zoom = _pasoActual >= 4;
    _descargado = false;
    _mostrarDireccion = _pasoActual >= 6;
    _dialogoSpam = false;
    _reportado = false;
    _aviso = null;

    switch (_pasoActual) {
      case 2:
        _pantalla = 'correo_lab';
        break;
      case 3:
      case 4:
        _pantalla = 'visor';
        break;
      case 5:
      case 6:
        _pantalla = 'correo_falso';
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
      case 'abrir_lab':
        cumple = _pantalla == 'correo_lab';
        break;
      case 'adjunto_abierto':
        cumple = _pantalla == 'visor';
        break;
      case 'zoom':
        cumple = _zoom;
        break;
      case 'descargado':
        cumple = _descargado;
        break;
      case 'remitente_revisado':
        cumple = _mostrarDireccion;
        break;
      case 'reportado':
        cumple = _reportado;
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
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'abrir':
          if (valor == 'lab') {
            _leidoLab = true;
            _pantalla = 'correo_lab';
          } else if (valor == 'falso') {
            _mensajeGuia = _pasoActual == 1
                ? 'Ese lo revisamos al final con cuidado. Abre el del Laboratorio'
                : 'Sigue la instrucción de la cajita morada';
          } else {
            _mensajeGuia = 'Busca el del Laboratorio Vida, el que tiene clip';
          }
          break;

        case 'adjunto_pdf':
          _pantalla = 'visor';
          break;
        case 'parte':
          if (valor == 'remitente' && _pantalla == 'correo_falso') {
            _mostrarDireccion = true;
          } else if (_pantalla == 'correo_lab' && _pasoActual == 2) {
            _mensajeGuia = 'El archivo está más abajo, en la tarjetita con PDF';
          }
          break;

        case 'doble_toque':
          if (_pasoActual >= 3) _zoom = !_zoom;
          break;
        case 'un_toque':
          if (_pasoActual == 3 && !_zoom) {
            _mensajeGuia = 'Casi: son DOS toques seguidos y rápidos, toc-toc';
          }
          break;
        case 'descargar':
          if (_pasoActual < 4) {
            _mensajeGuia = 'Primero agranda la hoja con doble toque';
          } else {
            _descargado = true;
            _mostrarAviso('Guardado en Descargas');
          }
          break;
        case 'atras_visor':
          _pantalla = 'correo_lab';
          break;
        case 'atras':
          _pantalla = 'bandeja';
          break;

        case 'adjunto_zip':
          _mensajeGuia = '¡No lo abras! Un .zip de alguien sospechoso puede dañar tu celular';
          break;
        case 'spam':
          if (_pasoActual < 6) {
            _mensajeGuia = 'Buen instinto. Primero revisa quién lo manda: toca "Banco Andino"';
          } else if (!_reportado) {
            _dialogoSpam = true;
          }
          break;
        case 'cancelar_spam':
          _dialogoSpam = false;
          break;
        case 'confirmar_spam':
          _dialogoSpam = false;
          _reportado = true;
          _mostrarAviso('Movido a Spam. Ya no te molesta');
          break;

        case 'responder':
          _mensajeGuia = _pantalla == 'correo_falso'
              ? '¡Nunca le respondas a un correo sospechoso!'
              : 'Responder lo practicamos en otra lección';
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
      tituloLeccion: 'Archivos adjuntos',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '📎',
      textoTrofeo: '¡Adjuntos sin miedo!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    switch (_pantalla) {
      case 'correo_lab':
        return 'CORREO DEL LABORATORIO';
      case 'visor':
        return 'DOCUMENTO PDF';
      case 'correo_falso':
        return 'CORREO SOSPECHOSO';
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
        if (_dialogoSpam)
          MnvDialogoSim(
            titulo: '¿Reportar como spam?',
            mensaje:
                'El correo se mueve a la carpeta Spam y el remitente queda marcado como peligroso.',
            textoConfirmar: 'Reportar',
            onCancelar: () => _tocarEnSimulador('cancelar_spam'),
            onConfirmar: () => _tocarEnSimulador('confirmar_spam'),
          ),
        if (_aviso != null) CoAvisoAbajo(texto: _aviso!),
      ],
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'correo_lab':
        return _buildCorreoLab();
      case 'visor':
        return _buildVisor();
      case 'correo_falso':
        return _buildCorreoFalso();
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
            onTap: () => setState(() =>
                _mensajeGuia = 'Hoy no buscamos: abre el correo del Laboratorio'),
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
                noLeido: c.clave == 'falso' ||
                    (c.clave == 'lab' && !_leidoLab),
                resaltada: c.clave == 'lab' && _pasoActual == 1,
                onTap: () => _tocarEnSimulador('abrir', valor: c.clave),
                onEstrella: () => setState(() =>
                    _mensajeGuia = 'Las estrellas las vimos en la lección anterior'),
              )),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCorreoLab() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          CoBarraSuperior(onAtras: () => _tocarEnSimulador('atras')),
          Expanded(
            child: CoVistaCorreo(
              asunto: 'Resultados de sus exámenes',
              remitente: 'Laboratorio Vida',
              direccion: 'resultados@laboratoriovida.co',
              inicial: 'V',
              color: MnvColores.verde,
              fecha: '9:10 a. m.',
              cuerpo:
                  'Buenos días.\n\nAdjuntamos los resultados de su examen de sangre del 2 de octubre. Puede mostrarlos en su próxima cita médica.\n\nLaboratorio Vida',
              onToque: (p) => _tocarEnSimulador('parte', valor: p),
              adjuntos: [
                CoAdjunto(
                  nombre: 'Resultados_examenes.pdf',
                  tamano: 'PDF · 245 KB',
                  resaltado: _pasoActual == 2,
                  onTap: () => _tocarEnSimulador('adjunto_pdf'),
                ),
              ],
              pie: CoBotonesResponder(
                  onToque: (_) => _tocarEnSimulador('responder')),
            ),
          ),
        ],
      ),
    );
  }

  // Visor de PDF: la hoja se agranda con doble toque
  Widget _buildVisor() {
    final filas = [
      ['Glucosa', '95 mg/dL', 'Normal'],
      ['Colesterol total', '182 mg/dL', 'Normal'],
      ['Triglicéridos', '140 mg/dL', 'Normal'],
      ['Hemoglobina', '13.8 g/dL', 'Normal'],
    ];
    return Container(
      color: const Color(0xFF3C3C4A),
      child: Column(
        children: [
          Container(
            height: 46,
            color: const Color(0xFF2B2B38),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                  onPressed: () => _tocarEnSimulador('atras_visor'),
                ),
                const Expanded(
                  child: Text('Resultados_examenes.pdf',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 12.5)),
                ),
                GestureDetector(
                  onTap: () => _tocarEnSimulador('descargar'),
                  child: MnvResalte(
                    activo: _pasoActual == 4 && !_descargado,
                    radio: 18,
                    escala: 1.2,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                          _descargado
                              ? Icons.download_done_rounded
                              : Icons.download_rounded,
                          color: _descargado
                              ? const Color(0xFF86EFAC)
                              : Colors.white,
                          size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onDoubleTap: () => _tocarEnSimulador('doble_toque'),
              onTap: () => _tocarEnSimulador('un_toque'),
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 12),
                child: ClipRect(
                  child: AnimatedScale(
                    scale: _zoom ? 1.0 : 0.62,
                    alignment: Alignment.topCenter,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    child: MnvResalte(
                      activo: _pasoActual == 3 && !_zoom,
                      radio: 4,
                      escala: 1.02,
                      child: Container(
                        width: 250,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.biotech_rounded,
                                    color: MnvColores.verde, size: 18),
                                SizedBox(width: 4),
                                Flexible(child: Text('LABORATORIO VIDA',
                                    style: TextStyle(
                                        color: MnvColores.verde,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text('Resultados de examen de sangre',
                                style: TextStyle(
                                    color: MnvColores.texto,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            const Text('Fecha: 2 de octubre de 2026',
                                style: TextStyle(
                                    color: MnvColores.suave, fontSize: 10)),
                            const Divider(height: 14),
                            ...filas.map((f) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Text(f[0],
                                            style: const TextStyle(
                                                color: MnvColores.texto,
                                                fontSize: 10.5)),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Text(f[1],
                                            style: const TextStyle(
                                                color: MnvColores.texto,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Text('✓ ${f[2]}',
                                          style: const TextStyle(
                                              color: MnvColores.verde,
                                              fontSize: 10)),
                                    ],
                                  ),
                                )),
                            const Divider(height: 14),
                            const Text(
                                'Lleve este documento a su cita con el médico tratante.',
                                style: TextStyle(
                                    color: MnvColores.suave, fontSize: 9.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
                _zoom ? '🔍 Agrandado. Toca dos veces para volver' : 'Página 1 de 1',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildCorreoFalso() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          CoBarraSuperior(onAtras: () => setState(() => _mensajeGuia =
              'Quédate aquí: vamos a revisar este correo')),
          Expanded(
            child: CoVistaCorreo(
              asunto: '⚠️ URGENTE: Su cuenta será suspendida hoy',
              remitente: 'Banco Andino',
              direccion: 'seguridad@bancoandino-alertas.xyz',
              inicial: 'B',
              color: MnvColores.morado,
              fecha: '9:47 a. m.',
              mostrarDireccion: _mostrarDireccion,
              resaltar: _pasoActual == 5 && !_mostrarDireccion
                  ? const {'remitente'}
                  : const {},
              cuerpo:
                  'Estimado cliente:\n\nDetectamos actividad sospechosa. Si no actualiza sus datos en las próximas 2 HORAS su cuenta será BLOQUEADA.\n\nDescargue el formulario adjunto y escriba su clave.',
              onToque: (p) => _tocarEnSimulador('parte', valor: p),
              adjuntos: [
                CoAdjunto(
                  nombre: 'Formulario_urgente.zip',
                  tamano: 'ZIP · 1,2 MB',
                  icono: Icons.folder_rounded,
                  color: MnvColores.amarillo,
                  onTap: () => _tocarEnSimulador('adjunto_zip'),
                ),
                if (_mostrarDireccion) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MnvColores.rojoSuave,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MnvColores.rojo),
                    ),
                    child: const Text(
                        '🚩 Después del @ dice "bancoandino-alertas.xyz". El banco de verdad no escribe desde ahí. Es un engaño.',
                        style: TextStyle(
                            color: MnvColores.texto,
                            fontSize: 11.5,
                            height: 1.35)),
                  ),
                ],
              ],
              pie: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _tocarEnSimulador('spam'),
                        child: MnvResalte(
                          activo: _pasoActual == 6 && !_reportado,
                          radio: 22,
                          escala: 1.05,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: _reportado
                                  ? MnvColores.verdeSuave
                                  : MnvColores.rojoSuave,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: _reportado
                                      ? MnvColores.verde
                                      : MnvColores.rojo),
                            ),
                            child: Center(
                              child: Text(
                                  _reportado
                                      ? '✓ Reportado'
                                      : '⚠️ Reportar spam',
                                  style: TextStyle(
                                      color: _reportado
                                          ? MnvColores.verde
                                          : MnvColores.rojo,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _tocarEnSimulador('responder'),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFC4C7C5)),
                          ),
                          child: const Center(
                            child: Text('Responder',
                                style: TextStyle(
                                    color: MnvColores.texto,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
