import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_calendario.dart';

const String _leccionId = 'calendario_recordatorios';

class TutorialCalendarioRecordatoriosScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialCalendarioRecordatoriosScreen(
      {super.key, this.pasoInicial = 0});

  @override
  State<TutorialCalendarioRecordatoriosScreen> createState() =>
      _TutorialCalendarioRecordatoriosScreenState();
}

class _TutorialCalendarioRecordatoriosScreenState
    extends State<TutorialCalendarioRecordatoriosScreen> {
  int _pasoActual = 0;

  // pantalla: mes | detalle | formulario | inicio | pastilla
  String _pantalla = 'mes';
  int? _diaSeleccionado;
  final List<String> _avisos = [];
  bool _hojaAvisos = false;
  bool _guardadoAvisos = false;
  bool _abrioDesdeAviso = false;
  String _repite = 'No se repite';
  bool _hojaRepite = false;
  bool _guardadaPastilla = false;
  bool _mostrarCheck = false;
  Timer? _timer;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const int _anio = 2026;
  static const String _diaAntes = '1 día antes';
  static const String _horaAntes = '1 hora antes';
  static const List<String> _opcionesAviso = [
    '10 minutos antes', _horaAntes, _diaAntes
  ];
  static const List<String> _opcionesRepite = [
    'No se repite', 'Todos los días', 'Cada semana', 'Cada mes'
  ];

  static const CaEvento _cita = CaEvento('cita', 10, 8, '🩺', 'Cita médica',
      '9:30 a. m.', CaColores.acento);
  static const CaEvento _cumple = CaEvento('cumple', 10, 10, '🎂',
      'Cumpleaños de María', 'Todo el día', MnvColores.morado2);

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Que el celular te avise 🔔',
      'instruccion':
          'Anotar la cita está bien, pero lo mejor es que el celular te AVISE antes.\n\nHoy le pones avisos a tu cita del jueves y anotas la pastilla de la presión para todos los días.',
      'icono': Icons.notifications_active_rounded,
      'colorIcono': CaColores.acento,
    },
    {
      'tipo': 'sim',
      'titulo': 'Abre tu cita 🩺',
      'instruccion':
          'Toca el jueves 8 y, abajo, toca la cita médica para abrirla.',
      'objetivo': 'abrir_cita',
      'ayuda': 'Toca el 8 y luego la cita de abajo',
    },
    {
      'tipo': 'sim',
      'titulo': 'Toca el lápiz ✏️',
      'instruccion':
          'Dice "Sin avisos". Para cambiar algo de una cita, arriba está el lápiz de editar.\n\nTócalo.',
      'objetivo': 'editar',
      'ayuda': 'Toca el lápiz de arriba',
    },
    {
      'tipo': 'sim',
      'titulo': 'Pon dos avisos ⏰',
      'instruccion':
          'Toca "Añadir aviso" y elige "1 día antes". Repite y elige "1 hora antes".\n\nAsí te acuerdas el día anterior y también justo antes de salir.',
      'objetivo': 'dos_avisos',
      'ayuda': 'Añade "1 día antes" y "1 hora antes"',
    },
    {
      'tipo': 'sim',
      'titulo': 'Guarda los cambios 💾',
      'instruccion': 'Toca "Guardar" arriba a la derecha.',
      'objetivo': 'guardado',
      'ayuda': 'Toca Guardar',
    },
    {
      'tipo': 'sim',
      'titulo': '¡Llegó el aviso! 🔔',
      'instruccion':
          'Es miércoles. El celular sonó y bajó una notificación: tu cita es mañana.\n\nTócala para ver los detalles.',
      'objetivo': 'notif',
      'ayuda': 'Toca la notificación de arriba',
    },
    {
      'tipo': 'sim',
      'titulo': 'La pastilla de todos los días 💊',
      'instruccion':
          'Ya está anotada "Pastilla de la presión" a las 8:00 a. m. Falta decirle que se repita.\n\nToca "No se repite", elige "Todos los días" y guarda.',
      'objetivo': 'repite_diario',
      'ayuda': 'Elige "Todos los días" y toca Guardar',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Que sí suene',
      'instruccion':
          'Si el celular está en silencio, el aviso sale en la pantalla pero no suena.\n\nPara cosas importantes, como medicinas, revisa que el volumen esté arriba.',
      'icono': Icons.volume_up_rounded,
      'colorIcono': MnvColores.amarillo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Abre una cita que tengas anotada y ponle un aviso "1 día antes".\n\nSi tomas alguna medicina, anótala para que se repita todos los días.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': CaColores.acento,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡El celular te cuida! 🏆',
      'instruccion':
          'Pones avisos, abres la cita desde la notificación y programas recordatorios diarios.\n\nYa no se te pasa ni una cita ni una pastilla. 💊👏',
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
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _timer?.cancel();
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    _diaSeleccionado = null;
    _hojaAvisos = false;
    _hojaRepite = false;
    _abrioDesdeAviso = false;
    _repite = 'No se repite';
    _guardadaPastilla = false;
    _mostrarCheck = false;

    // Lo que ya quedo hecho en los pasos anteriores
    _avisos.clear();
    if (_pasoActual >= 4) _avisos.addAll([_diaAntes, _horaAntes]);
    _guardadoAvisos = _pasoActual >= 5;

    switch (_pasoActual) {
      case 2:
        _pantalla = 'detalle';
        break;
      case 3:
      case 4:
        _pantalla = 'formulario';
        break;
      case 5:
        _pantalla = 'inicio';
        break;
      case 6:
        _pantalla = 'pastilla';
        break;
      default:
        _pantalla = 'mes';
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'abrir_cita':
        cumple = _pantalla == 'detalle';
        break;
      case 'editar':
        cumple = _pantalla == 'formulario';
        break;
      case 'dos_avisos':
        cumple = _avisos.contains(_diaAntes) && _avisos.contains(_horaAntes);
        break;
      case 'guardado':
        cumple = _guardadoAvisos;
        break;
      case 'notif':
        cumple = _abrioDesdeAviso;
        break;
      case 'repite_diario':
        cumple = _guardadaPastilla && _repite == 'Todos los días';
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // ─────────────────────────────────────────────
  // CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────
  void _tocarEnSimulador(String accion, {String valor = '', int dia = 0}) {
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'dia':
          _diaSeleccionado = dia;
          if (_pasoActual == 1 && dia != 8) {
            _mensajeGuia = 'Tu cita está el jueves 8';
          }
          break;
        case 'evento':
          if (valor == 'cita' && _pasoActual == 1) {
            _pantalla = 'detalle';
          } else if (valor == 'cita') {
            _mensajeGuia = 'Ahí está tu cita';
          } else {
            _mensajeGuia = 'Ese es el cumpleaños. Busca la cita médica';
          }
          break;

        case 'detalle_editar':
          if (_pasoActual == 2) {
            _pantalla = 'formulario';
          } else {
            _mensajeGuia = 'Sigue la instrucción de la cajita morada';
          }
          break;
        case 'detalle_borrar':
          _mensajeGuia = '¡No la borres! Solo queremos ponerle avisos';
          break;
        case 'detalle_atras':
          _mensajeGuia = 'Quédate aquí, vamos bien';
          break;

        case 'anadir_aviso':
          if (_pasoActual == 3) {
            _hojaAvisos = true;
          } else {
            _mensajeGuia = 'Los avisos ya están puestos';
          }
          break;
        case 'opcion_aviso':
          _hojaAvisos = false;
          if (!_avisos.contains(valor)) _avisos.add(valor);
          if (valor == '10 minutos antes') {
            _mensajeGuia = '10 minutos es muy poco para alistarse. Mejor 1 día y 1 hora antes';
          }
          break;
        case 'quitar_aviso':
          _avisos.remove(valor);
          break;
        case 'cerrar_hoja':
          _hojaAvisos = false;
          _hojaRepite = false;
          break;

        case 'guardar':
          if (_pantalla == 'pastilla') {
            _guardarPastilla();
          } else if (_pasoActual == 4) {
            _guardadoAvisos = true;
            _mostrarCheck = true;
            _volverDespues('detalle');
          } else if (_pasoActual == 3) {
            _mensajeGuia = _avisos.length >= 2
                ? '¡Listos los avisos! Toca el botón verde de abajo para seguir'
                : 'Primero añade los dos avisos';
          }
          break;
        case 'cerrar':
          _mensajeGuia = 'Si cierras sin guardar se pierde. Sigamos';
          break;

        case 'notificacion':
          _pantalla = 'detalle';
          _abrioDesdeAviso = true;
          break;
        case 'app':
          _mensajeGuia = 'Toca la notificación de arriba, es más rápido';
          break;

        case 'repite':
          _hojaRepite = true;
          break;
        case 'opcion_repite':
          _repite = valor;
          _hojaRepite = false;
          if (valor != 'Todos los días') {
            _mensajeGuia = 'La pastilla es diaria: elige "Todos los días"';
          }
          break;
      }

      _revisarObjetivo();
    });
  }

  void _guardarPastilla() {
    if (_repite != 'Todos los días') {
      _mensajeGuia = 'Antes de guardar, toca "No se repite" y elige "Todos los días"';
      return;
    }
    _guardadaPastilla = true;
    _mostrarCheck = true;
    _volverDespues('mes');
  }

  void _volverDespues(String pantalla) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _mostrarCheck = false;
        _pantalla = pantalla;
      });
    });
  }

  Future<void> _avanzar() async {
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
      tituloLeccion: 'Que el celular te avise',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '🔔',
      textoTrofeo: '¡El celular te cuida!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    switch (_pantalla) {
      case 'detalle':
        return 'CALENDARIO · TU CITA';
      case 'formulario':
        return _hojaAvisos ? 'EDITAR CITA · AVISOS' : 'EDITAR CITA';
      case 'inicio':
        return 'PANTALLA DE INICIO · MIÉRCOLES';
      case 'pastilla':
        return _hojaRepite ? 'NUEVO EVENTO · REPETIR' : 'NUEVO EVENTO';
      default:
        return 'CALENDARIO · OCTUBRE';
    }
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: _buildPantalla(),
      encima: [
        if (_pantalla == 'inicio')
          MnvNotificacion(
            icono: Icons.calendar_month_rounded,
            color: MnvColores.azul,
            app: 'Calendario',
            titulo: '🩺 Cita médica',
            texto: 'Mañana jueves 8, 9:30 a. m.',
            resaltada: true,
            onTap: () => _tocarEnSimulador('notificacion'),
          ),
        if (_hojaAvisos)
          CaHojaOpciones(
            titulo: 'Avisarme',
            opciones: _opcionesAviso,
            resaltada: !_avisos.contains(_diaAntes) ? _diaAntes : _horaAntes,
            onOpcion: (o) => _tocarEnSimulador('opcion_aviso', valor: o),
            onCerrar: () => _tocarEnSimulador('cerrar_hoja'),
          ),
        if (_hojaRepite)
          CaHojaOpciones(
            titulo: 'Repetir',
            opciones: _opcionesRepite,
            resaltada: 'Todos los días',
            onOpcion: (o) => _tocarEnSimulador('opcion_repite', valor: o),
            onCerrar: () => _tocarEnSimulador('cerrar_hoja'),
          ),
        if (_mostrarCheck) const MnvCheckConfirmacion(texto: 'Guardado'),
      ],
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'detalle':
        return CaDetalleEvento(
          emoji: '🩺',
          titulo: 'Cita médica',
          fecha: 'jueves, 8 de octubre',
          hora: '9:30 a. m. – 10:00 a. m.',
          color: CaColores.acento,
          avisos: _guardadoAvisos ? _avisos : const [],
          resaltar: _pasoActual == 2 ? const {'editar'} : const {},
          onToque: (t) => _tocarEnSimulador('detalle_$t'),
        );
      case 'formulario':
        return _buildFormulario();
      case 'inicio':
        return MnvPantallaInicio(
          apps: MnvPantallaInicio.appsBase,
          resaltada: null,
          hora: '9:30',
          fecha: 'miércoles, 7 de octubre',
          onApp: (_) => _tocarEnSimulador('app'),
        );
      case 'pastilla':
        return _buildPastilla();
      default:
        return _buildMes();
    }
  }

  Widget _buildMes() {
    final puntos = <int, Color>{
      8: CaColores.acento,
      10: MnvColores.morado2,
    };
    if (_guardadaPastilla) {
      for (int d = 6; d <= 31; d++) {
        puntos.putIfAbsent(d, () => MnvColores.verde);
      }
    }
    final delDia = <CaEvento>[
      if (_diaSeleccionado == 8) _cita,
      if (_diaSeleccionado == 10) _cumple,
    ];
    final pastilla = CaEvento('pastilla', 10, _diaSeleccionado ?? 6, '💊',
        'Pastilla de la presión', '8:00 a. m. · todos los días',
        MnvColores.verde);

    return Container(
      color: CaColores.fondo,
      child: Column(
        children: [
          CaCabeceraMes(
            anio: _anio,
            mes: 10,
            onAnterior: () {},
            onSiguiente: () {},
          ),
          CaMes(
            anio: _anio,
            mes: 10,
            hoy: 6,
            seleccionado: _diaSeleccionado,
            puntos: puntos,
            resaltados: _pasoActual == 1 && _diaSeleccionado != 8 ? {8} : {},
            onDia: (d) => _tocarEnSimulador('dia', dia: d),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F6FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              padding: const EdgeInsets.only(top: 8),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (_guardadaPastilla)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(14, 0, 14, 4),
                      child: Text('💊 La pastilla quedó TODOS los días',
                          style: TextStyle(
                              color: MnvColores.verde,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  if (_guardadaPastilla && _diaSeleccionado != null &&
                      _diaSeleccionado! >= 6)
                    CaFilaEvento(evento: pastilla, onTap: () {}),
                  ...delDia.map((e) => CaFilaEvento(
                        evento: e,
                        resaltada: e.clave == 'cita' && _pasoActual == 1,
                        onTap: () =>
                            _tocarEnSimulador('evento', valor: e.clave),
                      )),
                  if (_diaSeleccionado == null && !_guardadaPastilla)
                    const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(
                        child: Text('Toca un día para ver qué tienes',
                            style: TextStyle(
                                color: MnvColores.suave2, fontSize: 11.5)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CaBarraFormulario(
            resaltarGuardar: _pasoActual == 4,
            onCerrar: () => _tocarEnSimulador('cerrar'),
            onGuardar: () => _tocarEnSimulador('guardar'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(54, 4, 14, 12),
            child: Text('Cita médica',
                style: TextStyle(
                    color: MnvColores.texto,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 1, color: MnvColores.borde),
          const CaFilaFormulario(
              icono: Icons.event_rounded, texto: 'jue, 8 oct', onTap: _nada),
          const CaFilaFormulario(
              icono: Icons.schedule_rounded,
              texto: '9:30 a. m.',
              onTap: _nada),
          const Divider(height: 1, color: MnvColores.borde),
          ..._avisos.map((a) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (_, t, hijo) => Container(
                  color: Color.lerp(MnvColores.verdeSuave, Colors.white, t),
                  child: hijo,
                ),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined,
                          size: 20, color: CaColores.acento),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(a,
                            style: const TextStyle(
                                color: MnvColores.texto,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600)),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _tocarEnSimulador('quitar_aviso', valor: a),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: MnvColores.suave2),
                      ),
                    ],
                  ),
                ),
              )),
          CaFilaFormulario(
            icono: Icons.add_alert_outlined,
            texto: 'Añadir aviso',
            colorTexto: CaColores.acento,
            resaltada: _pasoActual == 3 && _avisos.length < 2 && !_hojaAvisos,
            onTap: () => _tocarEnSimulador('anadir_aviso'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPastilla() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CaBarraFormulario(
            resaltarGuardar: _repite == 'Todos los días' && !_guardadaPastilla,
            onCerrar: () => _tocarEnSimulador('cerrar'),
            onGuardar: () => _tocarEnSimulador('guardar'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(54, 4, 14, 12),
            child: Text('💊 Pastilla de la presión',
                style: TextStyle(
                    color: MnvColores.texto,
                    fontSize: 19,
                    fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 1, color: MnvColores.borde),
          const CaFilaFormulario(
              icono: Icons.event_rounded, texto: 'mar, 6 oct', onTap: _nada),
          const CaFilaFormulario(
              icono: Icons.schedule_rounded,
              texto: '8:00 a. m.',
              onTap: _nada),
          CaFilaFormulario(
            icono: Icons.repeat_rounded,
            texto: _repite,
            resaltada: _repite != 'Todos los días' && !_hojaRepite,
            onTap: () => _tocarEnSimulador('repite'),
          ),
          const CaFilaFormulario(
              icono: Icons.notifications_none_rounded,
              texto: 'Aviso: a la hora',
              colorTexto: MnvColores.suave,
              onTap: _nada),
          const Spacer(),
        ],
      ),
    );
  }

  static void _nada() {}
}
