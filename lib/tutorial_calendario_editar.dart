import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_calendario.dart';

const String _leccionId = 'calendario_editar';

class TutorialCalendarioEditarScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialCalendarioEditarScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialCalendarioEditarScreen> createState() =>
      _TutorialCalendarioEditarScreenState();
}

class _TutorialCalendarioEditarScreenState
    extends State<TutorialCalendarioEditarScreen> {
  int _pasoActual = 0;

  // pantalla: mes | detalle_cita | formulario | detalle_reunion
  String _pantalla = 'mes';
  int? _diaSeleccionado;
  int _diaCita = 8;
  int _hora = 9;
  int _minuto = 30;
  bool _pm = false;
  bool _selectorFecha = false;
  bool _selectorHora = false;
  bool _horaConfirmada = false;
  bool _guardado = false;
  bool _dialogoBorrar = false;
  bool _reunionBorrada = false;
  bool _mostrarCheck = false;
  String? _aviso;
  Timer? _timer;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const int _anio = 2026;

  static const CaEvento _cumple = CaEvento('cumple', 10, 10, '🎂',
      'Cumpleaños de María', 'Todo el día', MnvColores.morado2);
  static const CaEvento _reunion = CaEvento('reunion', 10, 11, '👥',
      'Reunión de la junta', '4:00 p. m.', MnvColores.azul);

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Cambiar o cancelar ✏️',
      'instruccion':
          'La clínica te avisó: tu cita pasó del jueves 8 al VIERNES 9 a las 2:00 de la TARDE.\n\nY la reunión de la junta del domingo se canceló. Vamos a arreglar el calendario.',
      'icono': Icons.event_note_rounded,
      'colorIcono': CaColores.acento,
    },
    {
      'tipo': 'sim',
      'titulo': 'Abre la cita 🩺',
      'instruccion': 'Toca el jueves 8 y luego la cita médica de abajo.',
      'objetivo': 'abrir',
      'ayuda': 'Toca el 8 y luego la cita',
    },
    {
      'tipo': 'sim',
      'titulo': 'Toca el lápiz ✏️',
      'instruccion': 'Para cambiarla, toca el lápiz de arriba.',
      'objetivo': 'editar',
      'ayuda': 'Toca el lápiz',
    },
    {
      'tipo': 'sim',
      'titulo': 'Cambia el día 📅',
      'instruccion': 'Toca la fecha y elige el viernes 9.',
      'objetivo': 'fecha',
      'ayuda': 'Toca la fecha y elige el 9',
    },
    {
      'tipo': 'sim',
      'titulo': 'Cambia la hora 🕑',
      'instruccion':
          'Toca la hora y ponla en 2:00. Ojo: es de la TARDE, así que elige "p. m.".\n\na. m. es por la mañana, p. m. es después del mediodía.',
      'objetivo': 'hora',
      'ayuda': 'Pon 2:00 p. m. y toca Listo',
    },
    {
      'tipo': 'sim',
      'titulo': 'Guarda 💾',
      'instruccion':
          'Toca "Guardar". Mira cómo el puntico se pasa del jueves al viernes.',
      'objetivo': 'guardado',
      'ayuda': 'Toca Guardar',
    },
    {
      'tipo': 'sim',
      'titulo': 'Cancela la reunión 🗑️',
      'instruccion':
          'Toca el domingo 11, abre "Reunión de la junta" y toca el basurero. Confirma con "Eliminar".\n\nCuidado: el cumpleaños de María NO se borra.',
      'objetivo': 'eliminado',
      'ayuda': 'Domingo 11 → reunión → basurero',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 ¿Borraste algo por error?',
      'instruccion':
          'Casi siempre, al borrar sale abajo un mensajito con "Deshacer" por unos segundos.\n\nTócalo rápido y todo vuelve como estaba.',
      'icono': Icons.undo_rounded,
      'colorIcono': MnvColores.amarillo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Abre un evento de tu calendario, cámbiale la hora y guárdalo.\n\nSi tienes uno viejo que ya no sirve, bórralo.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': CaColores.acento,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Tu agenda al día! 🏆',
      'instruccion':
          'Cambias fecha y hora (sabes la diferencia entre a. m. y p. m.), guardas y cancelas lo que ya no va.\n\nEres el dueño de tu tiempo. ⏰👏',
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

    _diaSeleccionado = null;
    _selectorFecha = false;
    _selectorHora = false;
    _dialogoBorrar = false;
    _reunionBorrada = false;
    _mostrarCheck = false;
    _aviso = null;

    // Lo que ya quedo hecho en los pasos anteriores
    _diaCita = _pasoActual >= 4 ? 9 : 8;
    final horaLista = _pasoActual >= 5;
    _hora = horaLista ? 2 : 9;
    _minuto = horaLista ? 0 : 30;
    _pm = horaLista;
    _horaConfirmada = horaLista;
    _guardado = _pasoActual >= 6;

    switch (_pasoActual) {
      case 2:
        _pantalla = 'detalle_cita';
        break;
      case 3:
      case 4:
      case 5:
        _pantalla = 'formulario';
        break;
      default:
        _pantalla = 'mes';
    }
  }

  bool get _horaCorrecta => _hora == 2 && _minuto == 0 && _pm;

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'abrir':
        cumple = _pantalla == 'detalle_cita';
        break;
      case 'editar':
        cumple = _pantalla == 'formulario';
        break;
      case 'fecha':
        cumple = _diaCita == 9 && !_selectorFecha;
        break;
      case 'hora':
        cumple = _horaConfirmada && _horaCorrecta;
        break;
      case 'guardado':
        cumple = _guardado;
        break;
      case 'eliminado':
        cumple = _reunionBorrada;
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
            _mensajeGuia = 'La cita está el jueves 8';
          } else if (_pasoActual == 6 && dia != 11) {
            _mensajeGuia = 'La reunión está el domingo 11';
          }
          break;
        case 'evento':
          _abrirEvento(valor);
          break;

        case 'detalle_editar':
          if (_pantalla == 'detalle_cita' && _pasoActual == 2) {
            _pantalla = 'formulario';
          } else if (_pantalla == 'detalle_reunion') {
            _mensajeGuia = 'No hay que editarla: se canceló. Toca el basurero';
          } else {
            _mensajeGuia = 'Sigue la instrucción de la cajita morada';
          }
          break;
        case 'detalle_borrar':
          if (_pantalla == 'detalle_reunion') {
            _dialogoBorrar = true;
          } else {
            _mensajeGuia = '¡No la borres! La cita no se canceló, solo cambió';
          }
          break;
        case 'detalle_atras':
          _pantalla = 'mes';
          break;
        case 'cancelar_borrar':
          _dialogoBorrar = false;
          break;
        case 'confirmar_borrar':
          _dialogoBorrar = false;
          _reunionBorrada = true;
          _pantalla = 'mes';
          _diaSeleccionado = null;
          _aviso = 'Evento eliminado';
          _timer?.cancel();
          _timer = Timer(const Duration(milliseconds: 3000), () {
            if (mounted) setState(() => _aviso = null);
          });
          break;
        case 'deshacer':
          _mensajeGuia = 'Así se recupera. Pero esta reunión sí se canceló de verdad 😉';
          break;

        case 'fecha':
          if (_pasoActual == 3) {
            _selectorFecha = true;
          } else {
            _mensajeGuia = _pasoActual < 3
                ? 'Sigue la cajita morada'
                : 'La fecha ya quedó en el viernes 9';
          }
          break;
        case 'elegir_dia':
          _diaCita = dia;
          _selectorFecha = false;
          if (dia != 9) {
            _mensajeGuia = 'Ese es el $dia (${caNombreDia(_anio, 10, dia)}). La cita pasó al viernes 9';
          }
          break;
        case 'cerrar_fecha':
          _selectorFecha = false;
          break;

        case 'hora':
          if (_pasoActual == 4) {
            _selectorHora = true;
            _horaConfirmada = false;
          } else {
            _mensajeGuia = _pasoActual < 4
                ? 'Primero la fecha'
                : 'La hora ya quedó en 2:00 p. m.';
          }
          break;
        case 'hora_mas':
          _hora = _hora == 12 ? 1 : _hora + 1;
          break;
        case 'hora_menos':
          _hora = _hora == 1 ? 12 : _hora - 1;
          break;
        case 'min_mas':
          _minuto = (_minuto + 15) % 60;
          break;
        case 'min_menos':
          _minuto = (_minuto + 45) % 60;
          break;
        case 'ampm':
          _pm = !_pm;
          break;
        case 'listo':
          _selectorHora = false;
          _horaConfirmada = true;
          if (!_horaCorrecta) {
            _mensajeGuia = _hora == 2 && _minuto == 0 && !_pm
                ? 'Quedó 2:00 a. m., ¡de madrugada! Toca la hora y elige p. m.'
                : 'Quedó ${caHoraTexto(_hora, _minuto, _pm)}. Debe ser 2:00 p. m.';
          }
          break;

        case 'guardar':
          if (_pasoActual < 5) {
            _mensajeGuia = 'Todavía falta. Sigue la cajita morada';
          } else if (!_guardado) {
            _guardado = true;
            _mostrarCheck = true;
            _timer?.cancel();
            _timer = Timer(const Duration(milliseconds: 1200), () {
              if (!mounted) return;
              setState(() {
                _mostrarCheck = false;
                _pantalla = 'mes';
                _diaSeleccionado = 9;
              });
            });
          }
          break;
        case 'cerrar':
          _mensajeGuia = 'Si cierras sin guardar no se cambia nada. Sigamos';
          break;
      }

      _revisarObjetivo();
    });
  }

  void _abrirEvento(String clave) {
    if (clave == 'cita') {
      if (_pasoActual == 1) {
        _pantalla = 'detalle_cita';
      } else {
        _mensajeGuia = _pasoActual == 6
            ? 'Esa es tu cita. Busca la reunión del domingo 11'
            : 'Sigue la cajita morada';
      }
    } else if (clave == 'reunion') {
      if (_pasoActual == 6) {
        _pantalla = 'detalle_reunion';
      } else {
        _mensajeGuia = 'La reunión la cancelamos al final';
      }
    } else {
      _mensajeGuia = '¡El cumpleaños de María no se toca! 🎂';
    }
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
      tituloLeccion: 'Cambiar o cancelar una cita',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '⏰',
      textoTrofeo: '¡Tu agenda al día!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    switch (_pantalla) {
      case 'detalle_cita':
        return 'CALENDARIO · TU CITA';
      case 'detalle_reunion':
        return 'CALENDARIO · REUNIÓN';
      case 'formulario':
        if (_selectorFecha) return 'EDITAR CITA · DÍA';
        if (_selectorHora) return 'EDITAR CITA · HORA';
        return 'EDITAR CITA';
      default:
        return 'CALENDARIO · OCTUBRE';
    }
  }

  Widget _buildSimulador() {
    final resaltarHora = <String>{};
    if (_selectorHora) {
      if (_hora != 2) resaltarHora.add(_hora > 2 && _hora < 12 ? 'hora_menos' : 'hora_mas');
      if (_hora == 2 && _minuto != 0) {
        resaltarHora.add(_minuto <= 30 ? 'min_menos' : 'min_mas');
      }
      if (_hora == 2 && _minuto == 0 && !_pm) resaltarHora.add('ampm');
      if (_horaCorrecta) resaltarHora.add('listo');
    }

    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: _buildPantalla(),
      encima: [
        if (_selectorFecha)
          CaSelectorFecha(
            anio: _anio,
            mes: 10,
            seleccionado: _diaCita,
            resaltado: 9,
            onDia: (d) => _tocarEnSimulador('elegir_dia', dia: d),
            onCerrar: () => _tocarEnSimulador('cerrar_fecha'),
          ),
        if (_selectorHora)
          CaSelectorHora(
            hora: _hora,
            minuto: _minuto,
            pm: _pm,
            resaltar: resaltarHora,
            onAccion: (a) => _tocarEnSimulador(a),
          ),
        if (_dialogoBorrar)
          MnvDialogoSim(
            titulo: '¿Eliminar este evento?',
            mensaje: 'Se borra "Reunión de la junta" del domingo 11.',
            textoConfirmar: 'Eliminar',
            onCancelar: () => _tocarEnSimulador('cancelar_borrar'),
            onConfirmar: () => _tocarEnSimulador('confirmar_borrar'),
          ),
        if (_mostrarCheck) const MnvCheckConfirmacion(texto: 'Guardado'),
        if (_aviso != null) _buildAvisoDeshacer(),
      ],
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'detalle_cita':
        return CaDetalleEvento(
          emoji: '🩺',
          titulo: 'Cita médica',
          fecha: '${caNombreDia(_anio, 10, _diaCita)}, $_diaCita de octubre',
          hora: caHoraTexto(_hora, _minuto, _pm),
          color: CaColores.acento,
          avisos: const ['1 día antes', '1 hora antes'],
          resaltar: _pasoActual == 2 ? const {'editar'} : const {},
          onToque: (t) => _tocarEnSimulador('detalle_$t'),
        );
      case 'detalle_reunion':
        return CaDetalleEvento(
          emoji: '👥',
          titulo: 'Reunión de la junta',
          fecha: 'domingo, 11 de octubre',
          hora: '4:00 p. m. – 6:00 p. m.',
          color: MnvColores.azul,
          resaltar: const {'borrar'},
          onToque: (t) => _tocarEnSimulador('detalle_$t'),
        );
      case 'formulario':
        return _buildFormulario();
      default:
        return _buildMes();
    }
  }

  Widget _buildMes() {
    final cita = CaEvento('cita', 10, _diaCita, '🩺', 'Cita médica',
        caHoraTexto(_hora, _minuto, _pm), CaColores.acento);
    final eventos = <CaEvento>[
      cita,
      _cumple,
      if (!_reunionBorrada) _reunion,
    ];
    final puntos = <int, Color>{for (final e in eventos) e.dia: e.color};
    final delDia = eventos.where((e) => e.dia == _diaSeleccionado).toList();

    Set<int> resaltados = {};
    if (_pasoActual == 1 && _diaSeleccionado != 8) resaltados = {8};
    if (_pasoActual == 6 && _diaSeleccionado != 11 && !_reunionBorrada) {
      resaltados = {11};
    }

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
            resaltados: resaltados,
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
              child: _diaSeleccionado == null
                  ? Center(
                      child: Text(
                          _reunionBorrada
                              ? 'El domingo 11 quedó libre ✨'
                              : 'Toca un día para ver qué tienes',
                          style: const TextStyle(
                              color: MnvColores.suave2, fontSize: 11.5)),
                    )
                  : delDia.isEmpty
                      ? const Center(
                          child: Text('Día libre',
                              style: TextStyle(
                                  color: MnvColores.suave, fontSize: 12)),
                        )
                      : ListView(
                          padding: EdgeInsets.zero,
                          children: delDia
                              .map((e) => CaFilaEvento(
                                    evento: e,
                                    subtitulo: e.clave == 'cita' && _guardado
                                        ? '${e.hora} · ¡cambiada!'
                                        : null,
                                    resaltada: (e.clave == 'cita' &&
                                            _pasoActual == 1) ||
                                        (e.clave == 'reunion' &&
                                            _pasoActual == 6),
                                    onTap: () => _tocarEnSimulador('evento',
                                        valor: e.clave),
                                  ))
                              .toList(),
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
            resaltarGuardar: _pasoActual == 5 && !_guardado,
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
          CaFilaFormulario(
            icono: Icons.event_rounded,
            texto: caFechaCorta(_anio, 10, _diaCita),
            resaltada: _pasoActual == 3 && _diaCita != 9 && !_selectorFecha,
            onTap: () => _tocarEnSimulador('fecha'),
          ),
          CaFilaFormulario(
            icono: Icons.schedule_rounded,
            texto: caHoraTexto(_hora, _minuto, _pm),
            resaltada:
                _pasoActual == 4 && !_selectorHora && !_horaCorrecta,
            onTap: () => _tocarEnSimulador('hora'),
          ),
          const CaFilaFormulario(
            icono: Icons.notifications_none_rounded,
            texto: '1 día antes · 1 hora antes',
            colorTexto: MnvColores.suave,
            onTap: _nada,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // Mensajito de "Evento eliminado" con Deshacer
  Widget _buildAvisoDeshacer() {
    return Positioned(
      left: 10,
      right: 10,
      bottom: 12,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 30, end: 0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (_, y, hijo) =>
            Transform.translate(offset: Offset(0, y), child: hijo),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B3C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(_aviso ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ),
              GestureDetector(
                onTap: () => _tocarEnSimulador('deshacer'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text('Deshacer',
                      style: TextStyle(
                          color: Color(0xFFFCD34D),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _nada() {}
}
