import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_calendario.dart';

const String _leccionId = 'calendario_conociendo';

class TutorialCalendarioConociendoScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialCalendarioConociendoScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialCalendarioConociendoScreen> createState() =>
      _TutorialCalendarioConociendoScreenState();
}

class _TutorialCalendarioConociendoScreenState
    extends State<TutorialCalendarioConociendoScreen> {
  int _pasoActual = 0;

  // pantalla: inicio | calendario
  String _pantalla = 'inicio';
  // vista: mes | agenda
  String _vista = 'mes';
  int _mes = 10;
  int? _diaSeleccionado;
  bool _fueANoviembre = false;
  bool _volvioAOctubre = false;
  double _arrastre = 0;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const int _anio = 2026;
  static const int _hoy = 6;

  static const List<CaEvento> _eventos = [
    CaEvento('cumple', 10, 10, '🎂', 'Cumpleaños de María', 'Todo el día',
        MnvColores.morado2),
    CaEvento('agua', 10, 15, '💧', 'Pagar factura del agua', '10:00 a. m.',
        MnvColores.azul),
    CaEvento('bazar', 10, 24, '⛪', 'Bazar de la parroquia', '3:00 p. m.',
        MnvColores.verde),
    CaEvento('odonto', 11, 12, '🦷', 'Cita de odontología', '8:00 a. m.',
        MnvColores.rojo),
  ];

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'El calendario 📅',
      'instruccion':
          'Es como el almanaque de la cocina, pero en el celular. Y tiene una ventaja: te puede avisar.\n\nHoy aprendes a leerlo. En este celular de práctica hoy es martes 6 de octubre.',
      'icono': Icons.calendar_month_rounded,
      'colorIcono': CaColores.acento,
    },
    {
      'tipo': 'sim',
      'titulo': 'Abre el Calendario 📲',
      'instruccion':
          'En la pantalla de inicio busca el cuadro azul con un calendario y tócalo.',
      'objetivo': 'abrir',
      'ayuda': 'Toca el cuadro del Calendario',
    },
    {
      'tipo': 'sim',
      'titulo': '¿Qué día es hoy? ⭕',
      'instruccion':
          'El día de HOY siempre tiene un círculo de color lleno.\n\nBúscalo y tócalo.',
      'objetivo': 'hoy',
      'ayuda': 'Toca el día con el círculo lleno',
    },
    {
      'tipo': 'sim',
      'titulo': 'Las letras de arriba 🔤',
      'instruccion':
          'Arriba de cada columna está la inicial del día: L lunes, M martes, M miércoles, J jueves, V viernes, S sábado, D domingo.\n\nToca el JUEVES de esta semana.',
      'objetivo': 'jueves',
      'ayuda': 'Baja desde la J hasta la semana de hoy',
    },
    {
      'tipo': 'sim',
      'titulo': 'Los puntiquitos 🔵',
      'instruccion':
          'Un puntico debajo del número quiere decir que ese día tienes algo.\n\nToca el sábado de esta semana para ver qué hay.',
      'objetivo': 'evento',
      'ayuda': 'Toca el sábado 10',
    },
    {
      'tipo': 'sim',
      'titulo': 'Cambia de mes ➡️',
      'instruccion':
          'Toca la flecha › de arriba para ver noviembre (también puedes deslizar el mes con el dedo).\n\nLuego regresa a octubre con la flecha ‹.',
      'objetivo': 'mes_ida_vuelta',
      'ayuda': 'Ve a noviembre y vuelve a octubre',
    },
    {
      'tipo': 'sim',
      'titulo': 'La Agenda 📋',
      'instruccion':
          'Si te cuesta leer la cuadrícula, la vista "Agenda" te muestra tus cosas en una lista, en orden.\n\nToca "Agenda".',
      'objetivo': 'agenda',
      'ayuda': 'Toca la pestaña Agenda',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 ¿Y si no veo el día de hoy?',
      'instruccion':
          'Si te perdiste entre meses, busca el botón "Hoy" o el numerito del día arriba: te devuelve al día de hoy.\n\nCada celular lo pone en un lugar distinto, pero siempre está.',
      'icono': Icons.today_rounded,
      'colorIcono': MnvColores.amarillo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Abre el Calendario de tu celular. Encuentra el día de hoy, busca el próximo domingo y mira si tienes algo anotado.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': CaColores.acento,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Ya lees el calendario! 🏆',
      'instruccion':
          'Encuentras hoy, reconoces los días de la semana, ves qué tienes cada día, cambias de mes y usas la agenda.\n\nEl almanaque ya vive en tu bolsillo. 👏',
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
    _confetti.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    _pantalla = _pasoActual >= 2 ? 'calendario' : 'inicio';
    _vista = 'mes';
    _mes = 10;
    _diaSeleccionado = null;
    _fueANoviembre = false;
    _volvioAOctubre = false;
    _arrastre = 0;
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'abrir':
        cumple = _pantalla == 'calendario';
        break;
      case 'hoy':
        cumple = _diaSeleccionado == _hoy && _mes == 10;
        break;
      case 'jueves':
        cumple = _diaSeleccionado == 8 && _mes == 10;
        break;
      case 'evento':
        cumple = _diaSeleccionado == 10 && _mes == 10;
        break;
      case 'mes_ida_vuelta':
        cumple = _fueANoviembre && _volvioAOctubre && _mes == 10;
        break;
      case 'agenda':
        cumple = _vista == 'agenda';
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // ─────────────────────────────────────────────
  // CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────
  void _tocarEnSimulador(String accion, {int dia = 0, String valor = ''}) {
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'app':
          if (valor == 'calendario') {
            _pantalla = 'calendario';
          } else {
            _mensajeGuia = 'Esa es otra app. El Calendario es el cuadro azul';
          }
          break;

        case 'dia':
          _tocarDia(dia);
          break;

        case 'siguiente':
          if (_pasoActual < 5) {
            _mensajeGuia = 'Cambiar de mes lo hacemos en un momento';
          } else if (_mes == 10) {
            _mes = 11;
            _diaSeleccionado = null;
            _fueANoviembre = true;
          }
          break;
        case 'anterior':
          if (_mes == 11) {
            _mes = 10;
            _diaSeleccionado = null;
            if (_fueANoviembre) _volvioAOctubre = true;
          } else {
            _mensajeGuia = _pasoActual == 5
                ? 'Primero ve a noviembre con la flecha ›'
                : 'Quedémonos en octubre';
          }
          break;

        case 'vista':
          if (_pasoActual == 6 || valor == 'mes') {
            _vista = valor;
          } else {
            _mensajeGuia = 'La Agenda la vemos al final';
          }
          break;
        case 'evento':
          _mensajeGuia = 'Abrir y cambiar eventos lo practicas en otras lecciones';
          break;
      }

      _revisarObjetivo();
    });
  }

  void _tocarDia(int dia) {
    _diaSeleccionado = dia;
    final nombre = caNombreDia(_anio, _mes, dia);
    switch (_pasoActual) {
      case 2:
        if (dia != _hoy) {
          _mensajeGuia = 'Ese es el $dia. Hoy es el que tiene el círculo lleno';
        }
        break;
      case 3:
        if (dia != 8) {
          _mensajeGuia = 'Ese es el $dia, un $nombre. Busca la J y baja a la semana de hoy';
        }
        break;
      case 4:
        if (dia != 10) {
          final hayAlgo = _eventos.any((e) => e.mes == _mes && e.dia == dia);
          _mensajeGuia = hayAlgo
              ? 'Ese también tiene algo. Pero busca el sábado de esta semana'
              : 'Ese día no tiene puntico: está libre. Busca el sábado 10';
        }
        break;
    }
  }

  void _soltarMes() {
    if (_arrastre < -60) {
      _tocarEnSimulador('siguiente');
    } else if (_arrastre > 60) {
      _tocarEnSimulador('anterior');
    }
    setState(() => _arrastre = 0);
  }

  Future<void> _avanzar() async {
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
      tituloLeccion: 'Conociendo el calendario',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '📅',
      textoTrofeo: '¡El almanaque en tu bolsillo!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    if (_pantalla == 'inicio') return 'PANTALLA DE INICIO';
    if (_vista == 'agenda') return 'CALENDARIO · AGENDA';
    return 'CALENDARIO · ${caNombresMes[_mes - 1].toUpperCase()}';
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: '$_pantalla$_vista',
      pantalla: _pantalla == 'inicio'
          ? MnvPantallaInicio(
              apps: MnvPantallaInicio.appsBase,
              resaltada: _pasoActual == 1 ? 'calendario' : null,
              onApp: (c) => _tocarEnSimulador('app', valor: c),
            )
          : _buildCalendario(),
    );
  }

  Map<int, Color> _puntosDelMes() {
    final mapa = <int, Color>{};
    for (final e in _eventos) {
      if (e.mes == _mes) mapa[e.dia] = e.color;
    }
    return mapa;
  }

  Widget _buildCalendario() {
    return Container(
      color: CaColores.fondo,
      child: Column(
        children: [
          CaPestanasVista(
            activa: _vista,
            resaltada: _pasoActual == 6 ? 'agenda' : null,
            onCambio: (v) => _tocarEnSimulador('vista', valor: v),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _vista == 'agenda'
                  ? KeyedSubtree(
                      key: const ValueKey('agenda'), child: _buildAgenda())
                  : KeyedSubtree(
                      key: ValueKey('mes$_mes'), child: _buildVistaMes()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaMes() {
    Set<int> resaltados = {};
    if (_mes == 10) {
      if (_pasoActual == 2 && _diaSeleccionado != _hoy) resaltados = {_hoy};
      if (_pasoActual == 4 && _diaSeleccionado != 10) resaltados = {10};
    }
    final delDia = _diaSeleccionado == null
        ? <CaEvento>[]
        : _eventos
            .where((e) => e.mes == _mes && e.dia == _diaSeleccionado)
            .toList();

    return Column(
      children: [
        CaCabeceraMes(
          anio: _anio,
          mes: _mes,
          resaltarSiguiente: _pasoActual == 5 && !_fueANoviembre,
          resaltarAnterior: _pasoActual == 5 && _fueANoviembre && _mes == 11,
          onAnterior: () => _tocarEnSimulador('anterior'),
          onSiguiente: () => _tocarEnSimulador('siguiente'),
        ),
        GestureDetector(
          onHorizontalDragUpdate: (d) =>
              setState(() => _arrastre += d.delta.dx),
          onHorizontalDragEnd: (_) => _soltarMes(),
          child: Transform.translate(
            offset: Offset(_arrastre.clamp(-60.0, 60.0) * 0.5, 0),
            child: CaMes(
              anio: _anio,
              mes: _mes,
              hoy: _mes == 10 ? _hoy : null,
              seleccionado: _diaSeleccionado,
              puntos: _puntosDelMes(),
              resaltados: resaltados,
              onDia: (d) => _tocarEnSimulador('dia', dia: d),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF7F6FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.only(top: 8),
            child: _diaSeleccionado == null
                ? const Center(
                    child: Text('Toca un día para ver qué tienes',
                        style: TextStyle(
                            color: MnvColores.suave2, fontSize: 11.5)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                        child: Text(
                            '${caNombreDia(_anio, _mes, _diaSeleccionado!)} $_diaSeleccionado'
                                .toUpperCase(),
                            style: const TextStyle(
                                color: CaColores.acento,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                      if (delDia.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text('Día libre, no tienes nada anotado',
                              style: TextStyle(
                                  color: MnvColores.suave, fontSize: 12)),
                        )
                      else
                        ...delDia.map((e) => TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 400),
                              builder: (_, t, hijo) => Opacity(
                                opacity: t,
                                child: Transform.translate(
                                    offset: Offset(0, 14 * (1 - t)),
                                    child: hijo),
                              ),
                              child: CaFilaEvento(
                                evento: e,
                                onTap: () => _tocarEnSimulador('evento'),
                              ),
                            )),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgenda() {
    return ListView(
      padding: const EdgeInsets.only(top: 6),
      children: [
        _encabezadoAgenda('Hoy · martes 6'),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Text('Nada anotado para hoy',
              style: TextStyle(color: MnvColores.suave2, fontSize: 11.5)),
        ),
        ..._eventos.map((e) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _encabezadoAgenda(
                    '${caNombreDia(_anio, e.mes, e.dia)} ${e.dia} de ${caNombresMes[e.mes - 1]}'),
                CaFilaEvento(
                  evento: e,
                  onTap: () => _tocarEnSimulador('evento'),
                ),
              ],
            )),
      ],
    );
  }

  Widget _encabezadoAgenda(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Text(texto.toUpperCase(),
          style: const TextStyle(
              color: CaColores.acento,
              fontSize: 10.5,
              fontWeight: FontWeight.bold)),
    );
  }
}
