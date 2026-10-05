import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_mensajes.dart';

const String _leccionId = 'mensajes_organizar';

class TutorialMensajesOrganizarScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialMensajesOrganizarScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialMensajesOrganizarScreen> createState() =>
      _TutorialMensajesOrganizarScreenState();
}

// Una conversacion de la lista
class _Conversacion {
  final String clave;
  final String nombre;
  final String inicial;
  final Color color;
  final String ultimo;
  final String hora;
  final bool promo;
  const _Conversacion(this.clave, this.nombre, this.inicial, this.color,
      this.ultimo, this.hora,
      {this.promo = false});
}

class _TutorialMensajesOrganizarScreenState
    extends State<TutorialMensajesOrganizarScreen> {
  int _pasoActual = 0;

  // pantalla: lista | buscar | conversacion
  String _pantalla = 'lista';
  String _busqueda = '';
  bool _modoSeleccion = false;
  final Set<String> _seleccionadas = {};
  bool _dialogoBorrar = false;
  bool _promosBorradas = false;
  bool _llegoFalso = false;
  bool _menuFalso = false;
  bool _dialogoBloquear = false;
  bool _falsoBloqueado = false;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const Set<String> _promos = {'ofertas', 'operador', 'super'};

  static const List<_Conversacion> _todas = [
    _Conversacion('ofertas', 'Mundo Ofertas', 'T', Color(0xFFF97316),
        '¡Solo hoy! 50% en todo, responde SI', '11:30 a. m.',
        promo: true),
    _Conversacion('maria', 'María', 'M', MnvColores.verde,
        'Nos vemos el sábado 😊', '10:15 a. m.'),
    _Conversacion('operador', 'Operador Móvil', 'O', Color(0xFF777799),
        'Recarga \$20.000 y gana 2 GB. Responde 1', '9:40 a. m.',
        promo: true),
    _Conversacion('carlos', 'Carlos (hijo)', 'C', MnvColores.azul,
        'Te llamo más tarde', 'Ayer'),
    _Conversacion('super', 'Supermercado Ahorro', 'S', Color(0xFF16A34A),
        'Ofertas de la semana en frutas 🍌', 'Ayer',
        promo: true),
    _Conversacion('eps', 'MiEPS', 'M', Color(0xFF0F766E),
        'Su cita fue confirmada', 'Lunes'),
  ];

  static const _Conversacion _falso = _Conversacion(
      'falso',
      '890 123',
      '!',
      MnvColores.rojo,
      'Banco Andino: su cuenta fue bloqueada. Ingrese a bit.ly/andino-seguro',
      'Ahora');

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Ordena tus mensajes 🧹',
      'instruccion':
          'Con el tiempo, Mensajes se llena de publicidad y es difícil encontrar lo importante.\n\nHoy buscas una conversación, borras varias promociones de una vez y bloqueas un mensaje falso.',
      'icono': Icons.cleaning_services_rounded,
      'colorIcono': MnvColores.morado,
    },
    {
      'tipo': 'sim',
      'titulo': 'Busca a Carlos 🔎',
      'instruccion':
          'En vez de bajar y bajar, toca la lupa de arriba y elige "Carlos".\n\nLuego abre su conversación.',
      'objetivo': 'abrir_carlos',
      'ayuda': 'Toca la lupa, elige Carlos y ábrelo',
    },
    {
      'tipo': 'sim',
      'titulo': 'Deja el dedo quieto ✋',
      'instruccion':
          'Para escoger varias cosas, NO toques rápido: deja el dedo quieto un momento sobre "Mundo Ofertas".\n\nAparece un chulito y arriba dice "1 seleccionado".',
      'objetivo': 'modo_seleccion',
      'ayuda': 'Mantén el dedo sobre Mundo Ofertas',
    },
    {
      'tipo': 'sim',
      'titulo': 'Marca las otras promociones ☑️',
      'instruccion':
          'Ahora sí, toques normales: toca "Operador Móvil" y "Supermercado Ahorro" para marcarlas también.\n\nOjo: María y Carlos NO son publicidad.',
      'objetivo': 'tres_promos',
      'ayuda': 'Marca solo las 3 promociones',
    },
    {
      'tipo': 'sim',
      'titulo': 'Bórralas todas juntas 🗑️',
      'instruccion':
          'Toca el basurero de arriba. Te va a preguntar si estás seguro: confirma con "Eliminar".',
      'objetivo': 'borradas',
      'ayuda': 'Toca el basurero y confirma',
    },
    {
      'tipo': 'sim',
      'titulo': 'Un mensaje falso del "banco" 🚨',
      'instruccion':
          'Llegó un mensaje que te asusta y trae un link. No lo abras.\n\nDeja el dedo quieto sobre él y elige "Bloquear y reportar".',
      'objetivo': 'bloqueado_spam',
      'ayuda': 'Mantén el dedo sobre el mensaje del 890 123',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Los links de los mensajes',
      'instruccion':
          'Un banco de verdad no te manda links por mensaje para "desbloquear" tu cuenta.\n\nSi te preocupa, llama al número que está detrás de tu tarjeta. Nunca al que viene en el mensaje.',
      'icono': Icons.link_off_rounded,
      'colorIcono': MnvColores.rojo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'En tu app de Mensajes, mantén el dedo sobre una promoción, marca otras y bórralas juntas.\n\nUsa la lupa para encontrar a alguien de tu familia.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': MnvColores.morado,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Mensajes en orden! 🏆',
      'instruccion':
          'Buscas, seleccionas varias, borras de una vez y bloqueas lo sospechoso.\n\nTu celular quedó limpio y seguro. ✨👏',
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

    _pantalla = 'lista';
    _busqueda = '';
    _modoSeleccion = false;
    _seleccionadas.clear();
    _dialogoBorrar = false;
    _menuFalso = false;
    _dialogoBloquear = false;
    _falsoBloqueado = false;
    _promosBorradas = _pasoActual >= 5;
    _llegoFalso = _pasoActual >= 5;

    switch (_pasoActual) {
      case 3:
        _modoSeleccion = true;
        _seleccionadas.add('ofertas');
        break;
      case 4:
        _modoSeleccion = true;
        _seleccionadas.addAll(_promos);
        break;
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'abrir_carlos':
        cumple = _pantalla == 'conversacion';
        break;
      case 'modo_seleccion':
        cumple = _modoSeleccion && _seleccionadas.contains('ofertas');
        break;
      case 'tres_promos':
        cumple = _seleccionadas.length == 3 &&
            _seleccionadas.containsAll(_promos);
        break;
      case 'borradas':
        cumple = _promosBorradas;
        break;
      case 'bloqueado_spam':
        cumple = _falsoBloqueado;
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
        case 'lupa':
          if (_pasoActual == 1) {
            _pantalla = 'buscar';
          } else {
            _mensajeGuia = 'Buscar ya lo practicaste. Sigue la cajita morada';
          }
          break;
        case 'sugerencia':
          _busqueda = valor;
          if (valor != 'Carlos') {
            _mensajeGuia = 'Así también busca. Para seguir, elige "Carlos"';
          }
          break;
        case 'letra':
          _mensajeGuia = 'Es más fácil tocar la palabra de arriba del teclado';
          break;
        case 'cerrar_busqueda':
          _pantalla = 'lista';
          _busqueda = '';
          break;
        case 'atras_conversacion':
          _pantalla = 'lista';
          break;

        case 'toque':
          _toqueFila(valor);
          break;
        case 'mantener':
          _mantenerFila(valor);
          break;

        case 'cancelar_seleccion':
          if (_pasoActual >= 3 && _pasoActual <= 4) {
            _mensajeGuia = 'Si cancelas se pierde lo marcado. Sigue la cajita morada';
          } else {
            _modoSeleccion = false;
            _seleccionadas.clear();
          }
          break;
        case 'basurero':
          if (_pasoActual < 4) {
            _mensajeGuia = 'Primero marca las 3 promociones';
          } else if (_seleccionadas.isNotEmpty) {
            _dialogoBorrar = true;
          }
          break;
        case 'cancelar_borrar':
          _dialogoBorrar = false;
          break;
        case 'confirmar_borrar':
          _dialogoBorrar = false;
          if (_seleccionadas.length == 3 &&
              _seleccionadas.containsAll(_promos)) {
            _promosBorradas = true;
            _modoSeleccion = false;
            _seleccionadas.clear();
          } else {
            _mensajeGuia = 'Revisa: deja marcadas solo las 3 promociones';
          }
          break;

        case 'bloquear_reportar':
          _menuFalso = false;
          _dialogoBloquear = true;
          break;
        case 'otra_opcion_menu':
          _mensajeGuia = 'Mejor "Bloquear y reportar", así no te vuelve a escribir';
          break;
        case 'cerrar_menu':
          _menuFalso = false;
          break;
        case 'cancelar_bloqueo':
          _dialogoBloquear = false;
          break;
        case 'confirmar_bloqueo':
          _dialogoBloquear = false;
          _falsoBloqueado = true;
          break;
      }

      _revisarObjetivo();
    });
  }

  // Toque normal sobre una fila
  void _toqueFila(String clave) {
    if (_modoSeleccion) {
      if (_seleccionadas.contains(clave)) {
        _seleccionadas.remove(clave);
      } else {
        _seleccionadas.add(clave);
        if (!_promos.contains(clave)) {
          _mensajeGuia = 'Esa no es publicidad. Tócala otra vez para quitarle el chulito';
        }
      }
      return;
    }
    if (_pantalla == 'buscar' && clave == 'carlos') {
      _pantalla = 'conversacion';
      return;
    }
    switch (_pasoActual) {
      case 1:
        _mensajeGuia = 'Usa la lupa de arriba para encontrarlo rápido';
        break;
      case 2:
        _mensajeGuia = clave == 'ofertas'
            ? 'Ese fue un toque rápido. Deja el dedo QUIETO un momento'
            : 'Mantén el dedo sobre "Mundo Ofertas"';
        break;
      case 5:
        _mensajeGuia = clave == 'falso'
            ? 'No hace falta abrirlo. Deja el dedo quieto encima para ver opciones'
            : 'Busca el mensaje del 890 123';
        break;
      default:
        _mensajeGuia = 'Sigue la instrucción de la cajita morada';
    }
  }

  // Pulsacion larga sobre una fila
  void _mantenerFila(String clave) {
    if (_pasoActual == 2) {
      if (clave == 'ofertas') {
        _modoSeleccion = true;
        _seleccionadas
          ..clear()
          ..add('ofertas');
      } else {
        _mensajeGuia = 'Así se hace. Pero esta vez hazlo sobre "Mundo Ofertas"';
      }
    } else if (_pasoActual == 5) {
      if (clave == 'falso') {
        _menuFalso = true;
      } else {
        _mensajeGuia = 'Hazlo sobre el mensaje sospechoso del 890 123';
      }
    } else if (_modoSeleccion) {
      _toqueFila(clave);
    }
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
      tituloLeccion: 'Ordenar tus mensajes',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '🧹',
      textoTrofeo: '¡Mensajes en orden!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    if (_pantalla == 'buscar') return 'MENSAJES · BUSCANDO';
    if (_pantalla == 'conversacion') return 'MENSAJES · CON CARLOS';
    if (_modoSeleccion) return 'MENSAJES · SELECCIONANDO';
    return 'MENSAJES · CONVERSACIONES';
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: _buildPantalla(),
      encima: [
        if (_dialogoBorrar)
          MnvDialogoSim(
            titulo: '¿Eliminar ${_seleccionadas.length} conversaciones?',
            mensaje: 'Se borran de tu celular. Esto no se puede deshacer.',
            textoConfirmar: 'Eliminar',
            onCancelar: () => _tocarEnSimulador('cancelar_borrar'),
            onConfirmar: () => _tocarEnSimulador('confirmar_borrar'),
          ),
        if (_menuFalso) _buildMenuFalso(),
        if (_dialogoBloquear)
          MnvDialogoSim(
            titulo: '¿Bloquear el 890 123?',
            mensaje:
                'No te volverán a llegar mensajes ni llamadas de este número y se reporta como spam.',
            textoConfirmar: 'Bloquear',
            onCancelar: () => _tocarEnSimulador('cancelar_bloqueo'),
            onConfirmar: () => _tocarEnSimulador('confirmar_bloqueo'),
          ),
      ],
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'buscar':
        return _buildBuscar();
      case 'conversacion':
        return _buildConversacion();
      default:
        return _buildLista();
    }
  }

  List<_Conversacion> _visibles() {
    final lista = <_Conversacion>[];
    if (_llegoFalso && !_falsoBloqueado) lista.add(_falso);
    for (final c in _todas) {
      if (_promosBorradas && c.promo) continue;
      lista.add(c);
    }
    return lista;
  }

  Widget _fila(_Conversacion c) {
    final resaltar = (_pasoActual == 2 && c.clave == 'ofertas' && !_modoSeleccion) ||
        (_pasoActual == 3 &&
            c.promo &&
            !_seleccionadas.contains(c.clave)) ||
        (_pasoActual == 5 && c.clave == 'falso' && !_menuFalso);
    return MsFilaConversacion(
      nombre: c.nombre,
      inicial: c.inicial,
      color: c.color,
      ultimo: c.ultimo,
      hora: c.hora,
      noLeido: c.clave == 'falso' || c.clave == 'ofertas',
      modoSeleccion: _modoSeleccion,
      seleccionada: _seleccionadas.contains(c.clave),
      resaltada: resaltar,
      onTap: () => _tocarEnSimulador('toque', valor: c.clave),
      onLongPress: () => _tocarEnSimulador('mantener', valor: c.clave),
    );
  }

  Widget _buildLista() {
    return Container(
      color: MsColores.fondo,
      child: Column(
        children: [
          MsCabeceraLista(
            modoSeleccion: _modoSeleccion,
            seleccionados: _seleccionadas.length,
            resaltarBuscar: _pasoActual == 1,
            resaltarBorrar: _pasoActual == 4,
            onBuscar: () => _tocarEnSimulador('lupa'),
            onBorrar: () => _tocarEnSimulador('basurero'),
            onCancelarSeleccion: () => _tocarEnSimulador('cancelar_seleccion'),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _visibles().map(_fila).toList(),
            ),
          ),
          if (_promosBorradas && _pasoActual == 4)
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MnvColores.verdeSuave,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('✨ 3 promociones borradas de una sola vez',
                  style: TextStyle(
                      color: MnvColores.verde,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          if (_falsoBloqueado)
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MnvColores.verdeSuave,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🚫 Número bloqueado y reportado. Ya no molesta.',
                  style: TextStyle(
                      color: MnvColores.verde,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildBuscar() {
    final resultados = _busqueda.isEmpty
        ? const <_Conversacion>[]
        : _todas
            .where((c) => c.nombre.toLowerCase().contains(_busqueda.toLowerCase()))
            .toList();
    return Container(
      color: MsColores.fondo,
      child: Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _tocarEnSimulador('cerrar_busqueda'),
                  child: const SizedBox(
                    width: 38,
                    height: 40,
                    child: Icon(Icons.arrow_back_rounded,
                        color: MnvColores.texto, size: 22),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: MnvColores.lila,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: MsColores.acento, width: 1.5),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                        _busqueda.isEmpty ? 'Buscar mensajes' : _busqueda,
                        style: TextStyle(
                            color: _busqueda.isEmpty
                                ? MnvColores.suave2
                                : MnvColores.texto,
                            fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: resultados
                  .map((c) => MsFilaConversacion(
                        nombre: c.nombre,
                        inicial: c.inicial,
                        color: c.color,
                        ultimo: c.ultimo,
                        hora: c.hora,
                        resaltada: c.clave == 'carlos',
                        onTap: () =>
                            _tocarEnSimulador('toque', valor: c.clave),
                      ))
                  .toList(),
            ),
          ),
          MnvTecladoLetras(
            onLetra: (_) => _tocarEnSimulador('letra'),
            onBorrar: () => _tocarEnSimulador('sugerencia', valor: ''),
            sugerencias: const ['Carlos', 'María', 'MiEPS'],
            sugerenciaResaltada: _busqueda.isEmpty ? 'Carlos' : null,
            onSugerencia: (s) => _tocarEnSimulador('sugerencia', valor: s),
          ),
        ],
      ),
    );
  }

  Widget _buildConversacion() {
    return Container(
      color: MsColores.fondo,
      child: Column(
        children: [
          MsCabeceraConversacion(
            nombre: 'Carlos (hijo)',
            inicial: 'C',
            color: MnvColores.azul,
            subtitulo: '310 555 7788',
            onAtras: () => _tocarEnSimulador('atras_conversacion'),
          ),
          const SizedBox(height: 8),
          const MsBurbuja(
              texto: '¿Ya almorzaste?', mia: false, hora: 'Ayer 12:30'),
          const MsBurbuja(
              texto: 'Sí mijo, sancocho 🍲', mia: true, hora: 'Ayer 12:41'),
          const MsBurbuja(
              texto: 'Te llamo más tarde', mia: false, hora: 'Ayer 12:45'),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MnvColores.verdeSuave,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🔎 Lo encontraste sin bajar por toda la lista',
                style: TextStyle(
                    color: MnvColores.verde,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Menu que sale al mantener el dedo sobre el mensaje falso
  Widget _buildMenuFalso() {
    final opciones = [
      ['bloquear', 'Bloquear y reportar spam', Icons.block_rounded, MnvColores.rojo],
      ['archivar', 'Archivar', Icons.archive_outlined, MnvColores.texto],
      ['borrar', 'Eliminar', Icons.delete_outline_rounded, MnvColores.texto],
    ];
    return Positioned.fill(
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _tocarEnSimulador('cerrar_menu'),
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            builder: (_, t, hijo) =>
                Transform.translate(offset: Offset(0, 200 * t), child: hijo),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: opciones.map((o) {
                  final clave = o[0] as String;
                  final texto = o[1] as String;
                  final icono = o[2] as IconData;
                  final color = o[3] as Color;
                  return GestureDetector(
                    onTap: () => _tocarEnSimulador(clave == 'bloquear'
                        ? 'bloquear_reportar'
                        : 'otra_opcion_menu'),
                    child: MnvResalte(
                      activo: clave == 'bloquear',
                      radio: 12,
                      escala: 1.03,
                      child: Container(
                        height: 46,
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: clave == 'bloquear'
                              ? MnvColores.rojoSuave
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(icono, color: color, size: 21),
                            const SizedBox(width: 12),
                            Text(texto,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
