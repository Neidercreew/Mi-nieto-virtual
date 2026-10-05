import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_calendario.dart';

const String _leccionId = 'calendario_crear_evento';

class TutorialCalendarioCrearEventoScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialCalendarioCrearEventoScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialCalendarioCrearEventoScreen> createState() =>
      _TutorialCalendarioCrearEventoScreenState();
}

class _TutorialCalendarioCrearEventoScreenState
    extends State<TutorialCalendarioCrearEventoScreen> {
  int _pasoActual = 0;

  // pantalla: mes | formulario
  String _pantalla = 'mes';
  String _titulo = '';
  bool _tecladoTitulo = false;
  int _dia = 6;
  bool _selectorFecha = false;
  int _hora = 10;
  int _minuto = 0;
  bool _pm = false;
  bool _selectorHora = false;
  bool _horaConfirmada = false;
  bool _guardado = false;
  bool _mostrarCheck = false;
  int? _diaSeleccionado;
  Timer? _timer;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const int _anio = 2026;
  static const String _tituloBueno = 'Cita médica';

  static const List<CaEvento> _otros = [
    CaEvento('cumple', 10, 10, '🎂', 'Cumpleaños de María', 'Todo el día',
        MnvColores.morado2),
    CaEvento('agua', 10, 15, '💧', 'Pagar factura del agua', '10:00 a. m.',
        MnvColores.azul),
  ];

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Agenda tu cita 🩺',
      'instruccion':
          'El jueves 8 tienes cita con el Dr. Ramírez a las 9:30 de la mañana.\n\nVas a anotarla en el calendario para que el celular se acuerde por ti.',
      'icono': Icons.medical_services_rounded,
      'colorIcono': CaColores.acento,
    },
    {
      'tipo': 'sim',
      'titulo': 'Toca el botón + ➕',
      'instruccion':
          'Abajo a la derecha hay un botón con un signo más. Es para anotar algo nuevo.\n\nTócalo.',
      'objetivo': 'nuevo',
      'ayuda': 'Toca el botón + de abajo',
    },
    {
      'tipo': 'sim',
      'titulo': 'Ponle nombre ✍️',
      'instruccion':
          'Arriba dice "Añade un título". El teclado ya te sugiere frases.\n\nToca "Cita médica".',
      'objetivo': 'titulo_ok',
      'ayuda': 'Toca la frase "Cita médica"',
    },
    {
      'tipo': 'sim',
      'titulo': 'Elige el día 📅',
      'instruccion':
          'El celular puso la fecha de hoy. Tócala para cambiarla y elige el jueves 8.',
      'objetivo': 'fecha_ok',
      'ayuda': 'Toca la fecha y elige el 8',
    },
    {
      'tipo': 'sim',
      'titulo': 'Elige la hora 🕤',
      'instruccion':
          'Toca la hora. Con las flechas sube o baja: deja 9 en la hora y 30 en los minutos, en "a. m." (mañana).\n\nTermina con "Listo".',
      'objetivo': 'hora_ok',
      'ayuda': 'Pon 9:30 a. m. y toca Listo',
    },
    {
      'tipo': 'sim',
      'titulo': '¡Guárdala! 💾',
      'instruccion':
          'Revisa que diga Cita médica, jueves 8 y 9:30 a. m.\n\nToca "Guardar" arriba a la derecha.',
      'objetivo': 'guardado',
      'ayuda': 'Toca Guardar',
    },
    {
      'tipo': 'sim',
      'titulo': 'Compruébalo 🔍',
      'instruccion':
          'Mira: el jueves 8 ya tiene un puntico.\n\nTócalo y verás tu cita abajo.',
      'objetivo': 'verificado',
      'ayuda': 'Toca el jueves 8',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Un buen título',
      'instruccion':
          'Escribe el título como te gustaría leerlo: "Cita médica – Dr. Ramírez, consultorio 204".\n\nAsí no tienes que buscar el papelito.',
      'icono': Icons.notes_rounded,
      'colorIcono': MnvColores.amarillo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Anota en tu calendario tu próxima cita o un cumpleaños de la familia: título, día y hora. Guárdalo y míralo en el mes.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': CaColores.acento,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Cita agendada! 🏆',
      'instruccion':
          'Creaste un evento con título, fecha y hora, lo guardaste y lo comprobaste.\n\nYa no se te pasa ninguna cita. 👏',
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

    _pantalla = _pasoActual >= 2 && _pasoActual <= 5 ? 'formulario' : 'mes';
    _tecladoTitulo = _pasoActual == 2;
    _selectorFecha = false;
    _selectorHora = false;
    _mostrarCheck = false;
    _diaSeleccionado = null;

    // Lo que ya quedo hecho en los pasos anteriores
    _titulo = _pasoActual >= 3 ? _tituloBueno : '';
    _dia = _pasoActual >= 4 ? 8 : 6;
    final horaLista = _pasoActual >= 5;
    _hora = horaLista ? 9 : 10;
    _minuto = horaLista ? 30 : 0;
    _pm = false;
    _horaConfirmada = horaLista;
    _guardado = _pasoActual >= 6;
  }

  bool get _horaCorrecta => _hora == 9 && _minuto == 30 && !_pm;

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'nuevo':
        cumple = _pantalla == 'formulario';
        break;
      case 'titulo_ok':
        cumple = _titulo == _tituloBueno;
        break;
      case 'fecha_ok':
        cumple = _dia == 8 && !_selectorFecha;
        break;
      case 'hora_ok':
        cumple = _horaConfirmada && _horaCorrecta;
        break;
      case 'guardado':
        cumple = _guardado;
        break;
      case 'verificado':
        cumple = _diaSeleccionado == 8;
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
        case 'mas':
          if (_pasoActual == 1) {
            _pantalla = 'formulario';
            _tecladoTitulo = true;
          } else {
            _mensajeGuia = 'Sigue la instrucción de la cajita morada';
          }
          break;
        case 'dia_mes':
          _diaSeleccionado = dia;
          if (_pasoActual == 1) {
            _mensajeGuia = 'Para anotar algo nuevo usa el botón + de abajo';
          } else if (_pasoActual == 6 && dia != 8) {
            _mensajeGuia = 'Ese es el $dia. Tu cita quedó el jueves 8';
          }
          break;

        case 'campo_titulo':
          if (_pasoActual == 2) _tecladoTitulo = true;
          break;
        case 'sugerencia':
          if (valor == _tituloBueno) {
            _titulo = valor;
            _tecladoTitulo = false;
          } else {
            _mensajeGuia = 'Para el médico, elige "Cita médica"';
          }
          break;
        case 'letra':
          _mensajeGuia = 'Más fácil: toca la frase de arriba del teclado';
          break;
        case 'borrar_titulo':
          if (_pasoActual == 2) _titulo = '';
          break;

        case 'fecha':
          if (_pasoActual == 3) {
            _selectorFecha = true;
          } else if (_pasoActual < 3) {
            _mensajeGuia = 'Primero el título';
          } else {
            _mensajeGuia = 'La fecha ya está lista';
          }
          break;
        case 'elegir_dia':
          _dia = dia;
          _selectorFecha = false;
          if (dia != 8) {
            _mensajeGuia = 'Ese es el $dia (${caNombreDia(_anio, 10, dia)}). La cita es el jueves 8: toca la fecha otra vez';
          }
          break;
        case 'cerrar_fecha':
          _selectorFecha = false;
          break;

        case 'hora':
          if (_pasoActual == 4) {
            _selectorHora = true;
            _horaConfirmada = false;
          } else if (_pasoActual < 4) {
            _mensajeGuia = 'La hora va después de la fecha';
          } else {
            _mensajeGuia = 'La hora ya está lista';
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
            _mensajeGuia = 'Quedó ${caHoraTexto(_hora, _minuto, _pm)}. La cita es 9:30 a. m.: toca la hora otra vez';
          }
          break;

        case 'guardar':
          _guardar();
          break;
        case 'cerrar':
          _mensajeGuia = 'Si cierras se pierde lo que anotaste. Sigamos';
          break;
        case 'evento':
          _mensajeGuia = 'Ahí está tu cita. ¡Muy bien!';
          break;
      }

      _revisarObjetivo();
    });
  }

  void _guardar() {
    if (_pasoActual < 5) {
      _mensajeGuia = 'Todavía falta. Sigue la cajita morada';
      return;
    }
    if (_guardado) return;
    _guardado = true;
    _mostrarCheck = true;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _mostrarCheck = false;
        _pantalla = 'mes';
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
      tituloLeccion: 'Agendar una cita',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '🩺',
      textoTrofeo: '¡Cita agendada!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    if (_pantalla == 'mes') return 'CALENDARIO · OCTUBRE';
    if (_selectorFecha) return 'NUEVO EVENTO · ELEGIR DÍA';
    if (_selectorHora) return 'NUEVO EVENTO · ELEGIR HORA';
    return 'NUEVO EVENTO';
  }

  Widget _buildSimulador() {
    final resaltarHora = <String>{};
    if (_selectorHora) {
      if (_hora != 9) resaltarHora.add(_hora > 9 ? 'hora_menos' : 'hora_mas');
      if (_hora == 9 && _minuto != 30) {
        resaltarHora.add(_minuto < 30 ? 'min_mas' : 'min_menos');
      }
      if (_hora == 9 && _minuto == 30 && _pm) resaltarHora.add('ampm');
      if (_horaCorrecta) resaltarHora.add('listo');
    }

    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: _pantalla == 'mes' ? _buildMes() : _buildFormulario(),
      encima: [
        if (_selectorFecha)
          CaSelectorFecha(
            anio: _anio,
            mes: 10,
            seleccionado: _dia,
            resaltado: 8,
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
        if (_mostrarCheck) const MnvCheckConfirmacion(texto: 'Guardado'),
      ],
    );
  }

  Widget _buildMes() {
    final puntos = <int, Color>{
      for (final e in _otros) e.dia: e.color,
      if (_guardado) 8: CaColores.acento,
    };
    final cita = CaEvento('cita', 10, 8, '🩺', _tituloBueno,
        caHoraTexto(9, 30, false), CaColores.acento);
    final delDia = <CaEvento>[
      if (_diaSeleccionado == 8 && _guardado) cita,
      ..._otros.where((e) => e.dia == _diaSeleccionado),
    ];

    return Container(
      color: CaColores.fondo,
      child: Stack(
        children: [
          Column(
            children: [
              CaCabeceraMes(
                anio: _anio,
                mes: 10,
                onAnterior: () => setState(() =>
                    _mensajeGuia = 'Hoy nos quedamos en octubre'),
                onSiguiente: () => setState(() =>
                    _mensajeGuia = 'Hoy nos quedamos en octubre'),
              ),
              CaMes(
                anio: _anio,
                mes: 10,
                hoy: 6,
                seleccionado: _diaSeleccionado,
                puntos: puntos,
                resaltados:
                    _pasoActual == 6 && _diaSeleccionado != 8 ? {8} : {},
                onDia: (d) => _tocarEnSimulador('dia_mes', dia: d),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F6FB),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  padding: const EdgeInsets.only(top: 8),
                  child: _diaSeleccionado == null
                      ? const Center(
                          child: Text('Toca un día para ver qué tienes',
                              style: TextStyle(
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
                                        resaltada: e.clave == 'cita',
                                        onTap: () =>
                                            _tocarEnSimulador('evento'),
                                      ))
                                  .toList(),
                            ),
                ),
              ),
            ],
          ),
          if (!_guardado)
            Positioned(
              right: 14,
              bottom: 14,
              child: CaBotonMas(
                resaltado: _pasoActual == 1,
                onTap: () => _tocarEnSimulador('mas'),
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
        children: [
          CaBarraFormulario(
            resaltarGuardar: _pasoActual == 5 && !_guardado,
            onCerrar: () => _tocarEnSimulador('cerrar'),
            onGuardar: () => _tocarEnSimulador('guardar'),
          ),
          GestureDetector(
            onTap: () => _tocarEnSimulador('campo_titulo'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(54, 4, 14, 12),
              child: Row(
                children: [
                  Flexible(
                    child: Text(_titulo.isEmpty ? 'Añade un título' : _titulo,
                        style: TextStyle(
                            color: _titulo.isEmpty
                                ? const Color(0xFFBBB6D8)
                                : MnvColores.texto,
                            fontSize: 20,
                            fontWeight: FontWeight.w600)),
                  ),
                  if (_tecladoTitulo)
                    Container(
                        width: 2,
                        height: 22,
                        margin: const EdgeInsets.only(left: 2),
                        color: CaColores.acento),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: MnvColores.borde),
          CaFilaFormulario(
            icono: Icons.event_rounded,
            texto: caFechaCorta(_anio, 10, _dia),
            resaltada: _pasoActual == 3 && _dia != 8 && !_selectorFecha,
            onTap: () => _tocarEnSimulador('fecha'),
          ),
          CaFilaFormulario(
            icono: Icons.schedule_rounded,
            texto: caHoraTexto(_hora, _minuto, _pm),
            resaltada:
                _pasoActual == 4 && !_selectorHora && !_horaConfirmada,
            onTap: () => _tocarEnSimulador('hora'),
          ),
          const CaFilaFormulario(
            icono: Icons.notifications_none_rounded,
            texto: 'Sin avisos',
            colorTexto: MnvColores.suave,
            onTap: _nada,
          ),
          const Spacer(),
          if (_tecladoTitulo)
            MnvTecladoLetras(
              onLetra: (_) => _tocarEnSimulador('letra'),
              onBorrar: () => _tocarEnSimulador('borrar_titulo'),
              sugerencias: const [_tituloBueno, 'Cumpleaños', 'Pagar recibo'],
              sugerenciaResaltada: _tituloBueno,
              onSugerencia: (s) => _tocarEnSimulador('sugerencia', valor: s),
            ),
        ],
      ),
    );
  }

  static void _nada() {}
}
