import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_mensajes.dart';

const String _leccionId = 'mensajes_codigos';

class TutorialMensajesCodigosScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialMensajesCodigosScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialMensajesCodigosScreen> createState() =>
      _TutorialMensajesCodigosScreenState();
}

class _TutorialMensajesCodigosScreenState
    extends State<TutorialMensajesCodigosScreen> {
  int _pasoActual = 0;

  // pantalla: app_eps | sms_codigo | sms_estafa
  String _pantalla = 'app_eps';
  bool _notificacion = false;
  String _codigoEscrito = '';
  String _codigoCorrecto = '482913';
  bool _entro = false;
  bool _usoAtajo = false;
  bool _volvioConAtras = false;
  bool _vioSms = false;
  bool _tecladoEstafa = false;
  bool _dialogoBorrar = false;
  bool _borrada = false;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const String _codigo1 = '482913';
  static const String _codigo2 = '731506';

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Códigos de verificación 🔢',
      'instruccion':
          'Cuando entras a la app de la EPS, del banco o a WhatsApp, te llega por mensaje un código de 6 números.\n\nEse código es como la llave de tu casa: sirve para entrar y es SOLO para ti.',
      'icono': Icons.dialpad_rounded,
      'colorIcono': MnvColores.morado,
    },
    {
      'tipo': 'sim',
      'titulo': 'Llegó el código 📩',
      'instruccion':
          'Estás entrando a la app "Mi EPS" y te pide un código. Arriba bajó una notificación de Mensajes.\n\nTócala para ver el mensaje completo.',
      'objetivo': 'notif_abierta',
      'ayuda': 'Toca la notificación de arriba',
    },
    {
      'tipo': 'sim',
      'titulo': 'Vuelve a la app ◁',
      'instruccion':
          'Ahí está el código. Ahora hay que regresar a "Mi EPS" para escribirlo.\n\nAbajo, en la barra negra, toca la flechita ◁ (atrás): te devuelve a donde estabas.',
      'objetivo': 'volver_app',
      'ayuda': 'Toca la flechita ◁ de la barra negra',
    },
    {
      'tipo': 'sim',
      'titulo': 'Escribe el código ✍️',
      'instruccion':
          'El código era 482 913. Escríbelo en las cajitas con el teclado de números.\n\nSi se te olvida, toca "Ver el mensaje otra vez".',
      'objetivo': 'codigo_ok',
      'ayuda': 'Escribe 4 8 2 9 1 3',
    },
    {
      'tipo': 'sim',
      'titulo': 'El atajo del teclado ⚡',
      'instruccion':
          'Pediste un código nuevo. Muchos celulares lo leen solos y lo ponen ENCIMA del teclado.\n\nToca la barrita que dice "Código de Mensajes" y se escribe solo.',
      'objetivo': 'codigo_auto',
      'ayuda': 'Toca la barrita del código encima del teclado',
    },
    {
      'tipo': 'sim',
      'titulo': '¡Te piden el código! 🚨',
      'instruccion':
          'Un número desconocido dice ser de la EPS y te pide que le dictes el código.\n\nNO respondas. Borra esa conversación con el basurero de arriba.',
      'objetivo': 'no_compartir',
      'ayuda': 'Toca el basurero de arriba y confirma',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Nadie te pide tu código',
      'instruccion':
          'Ni la EPS, ni el banco, ni WhatsApp, ni la empresa de celular te van a pedir ese código por llamada o por mensaje.\n\nSi alguien te lo pide, es para robarte. Cuelga y borra.',
      'icono': Icons.do_not_disturb_on_rounded,
      'colorIcono': MnvColores.rojo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'La próxima vez que una app te pida un código, mira la notificación o la barrita encima del teclado.\n\nY si alguien te lo pide, dile "no" con toda la tranquilidad.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': MnvColores.morado,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Tu llave está segura! 🏆',
      'instruccion':
          'Lees el código, vuelves a la app, lo escribes o usas el atajo, y nunca se lo das a nadie.\n\nEso te protege de los robos más comunes. 🔐👏',
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

    _pantalla = 'app_eps';
    _notificacion = false;
    _codigoEscrito = '';
    _codigoCorrecto = _codigo1;
    _entro = false;
    _usoAtajo = false;
    _volvioConAtras = false;
    _vioSms = false;
    _tecladoEstafa = false;
    _dialogoBorrar = false;
    _borrada = false;

    switch (_pasoActual) {
      case 1:
        _notificacion = true;
        break;
      case 2:
        _pantalla = 'sms_codigo';
        break;
      case 3:
        break;
      case 4:
        _codigoCorrecto = _codigo2;
        break;
      case 5:
        _pantalla = 'sms_estafa';
        break;
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'notif_abierta':
        cumple = _vioSms;
        break;
      case 'volver_app':
        cumple = _volvioConAtras && _pantalla == 'app_eps';
        break;
      case 'codigo_ok':
        cumple = _entro;
        break;
      case 'codigo_auto':
        cumple = _entro;
        break;
      case 'no_compartir':
        cumple = _borrada;
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
        case 'notificacion':
          _notificacion = false;
          _pantalla = 'sms_codigo';
          _vioSms = true;
          break;
        case 'cajitas':
          if (_pasoActual == 1) {
            _mensajeGuia = 'Primero mira el código: toca la notificación de arriba';
          }
          break;

        case 'nav_atras':
          if (_pantalla == 'sms_codigo') {
            _pantalla = 'app_eps';
            _volvioConAtras = true;
          } else if (_pantalla == 'sms_estafa') {
            _mensajeGuia = 'Antes de salir, borra esa conversación';
          } else {
            _mensajeGuia = 'Ya estás en Mi EPS';
          }
          break;
        case 'nav_otro':
          _mensajeGuia = 'Ese botón te saca al inicio. Usa la flechita ◁';
          break;
        case 'ver_mensaje':
          _pantalla = 'sms_codigo';
          break;

        case 'numero':
          if (_entro || _pasoActual < 3) {
            if (_pasoActual < 3) {
              _mensajeGuia = 'Sigue primero la instrucción de la cajita morada';
            }
            break;
          }
          if (_codigoEscrito.length < 6) _codigoEscrito += valor;
          if (!_codigoCorrecto.startsWith(_codigoEscrito)) {
            _mensajeGuia = 'Ese número no va. Toca ⌫ para borrarlo';
          } else if (_codigoEscrito == _codigoCorrecto) {
            _entro = true;
            if (_pasoActual == 4) {
              _mensajeGuia = '¡También sirve! Pero la barrita de arriba es más fácil';
            }
          }
          break;
        case 'borrar':
          if (_codigoEscrito.isNotEmpty && !_entro) {
            _codigoEscrito =
                _codigoEscrito.substring(0, _codigoEscrito.length - 1);
          }
          break;
        case 'atajo':
          if (_pasoActual == 4 && !_entro) {
            _codigoEscrito = _codigo2;
            _usoAtajo = true;
            _entro = true;
          }
          break;

        case 'caja_estafa':
          _tecladoEstafa = true;
          break;
        case 'sugerencia_estafa':
          if (valor == _codigo2) {
            _mensajeGuia = '¡Alto! Ese código es tu llave. Nadie de verdad te lo pide. Borra la conversación 🗑️';
          } else {
            _mensajeGuia = 'Mejor no le contestes nada. Solo bórralo con el basurero de arriba';
          }
          break;
        case 'enviar_estafa':
          _mensajeGuia = 'No le contestes. Borra la conversación con el basurero de arriba';
          break;
        case 'basurero':
          _dialogoBorrar = true;
          _tecladoEstafa = false;
          break;
        case 'cancelar_borrar':
          _dialogoBorrar = false;
          break;
        case 'confirmar_borrar':
          _dialogoBorrar = false;
          _borrada = true;
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
      tituloLeccion: 'Códigos de verificación',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '🔐',
      textoTrofeo: '¡Tu llave está segura!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    switch (_pantalla) {
      case 'sms_codigo':
        return 'MENSAJES · MI EPS';
      case 'sms_estafa':
        return 'MENSAJES · NÚMERO DESCONOCIDO';
      default:
        return _entro ? 'APP MI EPS · ADENTRO' : 'APP MI EPS · CÓDIGO';
    }
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: Column(
        children: [
          Expanded(child: _buildPantalla()),
          MsBarraNavegacion(
            resaltarAtras: _pasoActual == 2 && _pantalla == 'sms_codigo',
            onAtras: () => _tocarEnSimulador('nav_atras'),
            onInicio: () => _tocarEnSimulador('nav_otro'),
            onRecientes: () => _tocarEnSimulador('nav_otro'),
          ),
        ],
      ),
      encima: [
        if (_notificacion && _pantalla == 'app_eps')
          MnvNotificacion(
            icono: Icons.sms_rounded,
            color: MsColores.acento,
            app: 'Mensajes',
            titulo: 'MiEPS',
            texto: 'Tu código es $_codigo1. No lo compartas con nadie.',
            resaltada: true,
            onTap: () => _tocarEnSimulador('notificacion'),
          ),
        if (_dialogoBorrar)
          MnvDialogoSim(
            titulo: '¿Borrar esta conversación?',
            mensaje: 'Se eliminan los mensajes de este número de tu celular.',
            textoConfirmar: 'Borrar',
            onCancelar: () => _tocarEnSimulador('cancelar_borrar'),
            onConfirmar: () => _tocarEnSimulador('confirmar_borrar'),
          ),
      ],
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'sms_codigo':
        return _buildSmsCodigo();
      case 'sms_estafa':
        return _buildSmsEstafa();
      default:
        return _buildAppEps();
    }
  }

  // App ficticia de la EPS que pide el codigo
  Widget _buildAppEps() {
    if (_entro) {
      return Container(
        color: Colors.white,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, t, hijo) => Transform.scale(scale: t, child: hijo),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                      color: MnvColores.verde, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 46),
                ),
                const SizedBox(height: 14),
                const Text('¡Entraste a Mi EPS!',
                    style: TextStyle(
                        color: MnvColores.texto,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    _usoAtajo
                        ? 'El código se puso solito ⚡'
                        : 'Escribiste bien el código',
                    style: const TextStyle(
                        color: MnvColores.suave, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    final mostrarTeclado = _pasoActual == 3 || _pasoActual == 4;
    final esperado = _pasoActual == 3 &&
            _codigoEscrito.length < 6 &&
            _codigoCorrecto.startsWith(_codigoEscrito)
        ? _codigoCorrecto[_codigoEscrito.length]
        : null;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 46,
            color: const Color(0xFF0F766E),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Row(
              children: [
                Icon(Icons.local_hospital_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Flexible(child: Text('Mi EPS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Escribe el código',
              style: TextStyle(
                  color: MnvColores.texto,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Te lo enviamos por mensaje al 300 *** 1234',
              style: TextStyle(color: MnvColores.suave, fontSize: 11.5)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _tocarEnSimulador('cajitas'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final lleno = i < _codigoEscrito.length;
                final actual = i == _codigoEscrito.length && mostrarTeclado;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 42,
                  margin: EdgeInsets.only(left: 3, right: i == 2 ? 12 : 3),
                  decoration: BoxDecoration(
                    color: lleno ? MnvColores.lila : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: actual ? const Color(0xFF0F766E) : MnvColores.borde,
                        width: actual ? 2 : 1.5),
                  ),
                  child: Center(
                    child: Text(lleno ? _codigoEscrito[i] : '',
                        style: const TextStyle(
                            color: MnvColores.texto,
                            fontSize: 19,
                            fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          if (_pasoActual == 3)
            GestureDetector(
              onTap: () => _tocarEnSimulador('ver_mensaje'),
              child: const Text('Ver el mensaje otra vez',
                  style: TextStyle(
                      color: Color(0xFF0F766E),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline)),
            )
          else
            const Text('¿No te llegó? Reenviar código',
                style: TextStyle(color: MnvColores.suave2, fontSize: 11.5)),
          const Spacer(),
          if (mostrarTeclado)
            MnvTecladoNumerico(
              onNumero: (n) => _tocarEnSimulador('numero', valor: n),
              onBorrar: () => _tocarEnSimulador('borrar'),
              numeroEsperado: esperado,
              encima: _pasoActual == 4 ? _barraAtajo() : null,
            ),
        ],
      ),
    );
  }

  // Sugerencia de autocompletar el codigo encima del teclado
  Widget _barraAtajo() {
    return GestureDetector(
      onTap: () => _tocarEnSimulador('atajo'),
      child: MnvResalte(
        activo: true,
        radio: 12,
        escala: 1.04,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.sms_rounded, color: MsColores.acento, size: 17),
              const SizedBox(width: 6),
              Flexible(child: const Text('Código de Mensajes: ',
                  style: TextStyle(color: MnvColores.suave, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(_codigo2,
                  style: const TextStyle(
                      color: MnvColores.texto,
                      fontSize: 13,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmsCodigo() {
    return Container(
      color: MsColores.fondo,
      child: Column(
        children: [
          MsCabeceraConversacion(
            nombre: 'MiEPS',
            inicial: 'M',
            color: const Color(0xFF0F766E),
            subtitulo: 'Mensaje automático',
            onAtras: () => _tocarEnSimulador('nav_atras'),
          ),
          const SizedBox(height: 10),
          const MsBurbuja(
              texto: 'Tu código es 482913. No lo compartas con nadie. MiEPS',
              mia: false,
              hora: 'Ahora'),
          const SizedBox(height: 14),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MnvColores.amarilloSuave,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MnvColores.amarillo, width: 1.5),
            ),
            child: Row(
              children: [
                const Text('🔑', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tu código:',
                          style:
                              TextStyle(color: MnvColores.suave, fontSize: 11)),
                      Text(
                          '${_codigo1.substring(0, 3)} ${_codigo1.substring(3)}',
                          style: const TextStyle(
                              color: MnvColores.texto,
                              fontSize: 24,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSmsEstafa() {
    if (_borrada) {
      return Container(
        color: MsColores.fondo,
        child: Column(
          children: [
            MsCabeceraLista(
              onBuscar: () {},
              onBorrar: () {},
              onCancelarSeleccion: () {},
            ),
            MsFilaConversacion(
              nombre: 'MiEPS',
              inicial: 'M',
              color: const Color(0xFF0F766E),
              ultimo: 'Tu código es 731506. No lo compartas...',
              hora: '9:12',
              onTap: () {},
            ),
            MsFilaConversacion(
              nombre: 'María',
              inicial: 'M',
              color: MnvColores.verde,
              ultimo: 'Nos vemos el sábado 😊',
              hora: 'Ayer',
              onTap: () {},
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                  '🗑️ Conversación borrada. El estafador se quedó sin nada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: MnvColores.verde,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    return Container(
      color: MsColores.fondo,
      child: Column(
        children: [
          MsCabeceraConversacion(
            nombre: '+57 312 444 8890',
            inicial: '?',
            color: MnvColores.suave2,
            subtitulo: 'No está en tus contactos',
            onAtras: () => _tocarEnSimulador('nav_atras'),
            acciones: [
              GestureDetector(
                onTap: () => _tocarEnSimulador('basurero'),
                child: MnvResalte(
                  activo: _pasoActual == 5,
                  radio: 18,
                  escala: 1.2,
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(Icons.delete_outline_rounded,
                        color: MnvColores.rojo, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const MsBurbuja(
              texto:
                  'Buenas, le hablamos de su EPS. Por un error del sistema le llegó un código de 6 números.',
              mia: false,
              hora: '9:14'),
          const MsBurbuja(
              texto:
                  'Por favor DÍCTEME ese código YA para no cancelar su cita médica.',
              mia: false,
              hora: '9:14'),
          const Spacer(),
          MsCajaEscribir(
            texto: '',
            enfocada: _tecladoEstafa,
            onCaja: () => _tocarEnSimulador('caja_estafa'),
            onEnviar: () => _tocarEnSimulador('enviar_estafa'),
          ),
          if (_tecladoEstafa)
            MnvTecladoLetras(
              onLetra: (_) => _tocarEnSimulador('enviar_estafa'),
              onBorrar: () {},
              sugerencias: const [_codigo2, 'Ya se lo doy', '¿Quién habla?'],
              onSugerencia: (s) =>
                  _tocarEnSimulador('sugerencia_estafa', valor: s),
            ),
        ],
      ),
    );
  }
}
