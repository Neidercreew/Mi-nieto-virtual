import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_whatsapp.dart';

const String _leccionId = 'whatsapp_seguro';

class TutorialWhatsappSeguroScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialWhatsappSeguroScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialWhatsappSeguroScreen> createState() =>
      _TutorialWhatsappSeguroScreenState();
}

class _TutorialWhatsappSeguroScreenState
    extends State<TutorialWhatsappSeguroScreen> {
  int _pasoActual = 0;

  // pantalla: chats | chat_desconocido | chat_carlos | llamada | chat_familia
  String _pantalla = 'chats';
  bool _leidoDesconocido = false;
  final Set<String> _banderas = {};
  String? _explicacionBandera;
  // llamada: marcando | contesto
  String _estadoLlamada = 'marcando';
  bool _verificado = false;
  bool _dialogoBloquear = false;
  bool _bloqueado = false;
  bool _vioEtiqueta = false;
  Timer? _timerLlamada;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const String _numeroRaro = '+57 321 555 0198';

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'WhatsApp seguro 🛡️',
      'instruccion':
          'Los estafadores también usan WhatsApp. El truco más común: "Hola, soy tu hijo, cambié de número".\n\nHoy aprendes a reconocerlo, a confirmar y a bloquear. Tú tienes el control.',
      'icono': Icons.shield_rounded,
      'colorIcono': MnvColores.verde,
    },
    {
      'tipo': 'sim',
      'titulo': 'Un número que no conoces 🤔',
      'instruccion':
          'Arriba de tu lista apareció un chat que no tiene nombre, solo un número.\n\nÁbrelo para ver qué dice. Leer no es peligroso.',
      'objetivo': 'abrir_desconocido',
      'ayuda': 'Toca el chat del número sin nombre',
    },
    {
      'tipo': 'sim',
      'titulo': 'Busca las banderas rojas 🚩',
      'instruccion':
          'Toca los mensajes que te parezcan raros. Hay 3 banderas rojas:\n\nalgo que te APURA, algo que te pide PLATA y algo que te pide SECRETO.',
      'objetivo': 'banderas_3',
      'ayuda': 'Toca los 3 mensajes sospechosos',
    },
    {
      'tipo': 'sim',
      'titulo': 'Confirma por otro lado ☎️',
      'instruccion':
          'Antes de creer, llama a Carlos a SU número de siempre, el que tienes guardado.\n\nVuelve a la lista, abre "Carlos (hijo)" y toca el teléfono de arriba.',
      'objetivo': 'verificado',
      'ayuda': 'Vuelve, abre Carlos (hijo) y toca el teléfono',
    },
    {
      'tipo': 'sim',
      'titulo': 'Bloquéalo sin pena 🚫',
      'instruccion':
          'Ya sabes que era una estafa. En el chat del número raro toca "Bloquear" y confirma.\n\nAsí no te puede volver a escribir.',
      'objetivo': 'bloqueado',
      'ayuda': 'Toca Bloquear y confirma',
    },
    {
      'tipo': 'sim',
      'titulo': 'Las cadenas ⏩⏩',
      'instruccion':
          'En el grupo de la familia llegó un mensaje que muchos reenvían.\n\nNo toques el link. Toca la etiqueta gris de arriba del mensaje que dice "Reenviado muchas veces".',
      'objetivo': 'etiqueta_reenviado',
      'ayuda': 'Toca la etiqueta "Reenviado muchas veces"',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 El código de 6 números',
      'instruccion':
          'Si alguien te pide "el código que te llegó por mensaje", NO se lo des. Con ese código te roban tu WhatsApp.\n\nNi WhatsApp, ni el banco, ni tu familia te lo van a pedir nunca.',
      'icono': Icons.lock_rounded,
      'colorIcono': MnvColores.rojo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Una palabra clave familiar 🔑',
      'instruccion':
          'Acuerda con tu familia una palabra secreta (por ejemplo, el nombre de una mascota vieja).\n\nSi alguien te pide plata "de urgencia", pídele la palabra. El estafador no la sabe.',
      'icono': Icons.vpn_key_rounded,
      'colorIcono': MnvColores.verde,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡A ti no te tumban! 🏆',
      'instruccion':
          'Reconoces las banderas rojas, confirmas por otro lado, bloqueas y no caes en cadenas.\n\nEres el guardián de tu familia. 🛡️👏',
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
    _timerLlamada?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _timerLlamada?.cancel();
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    _banderas.clear();
    _explicacionBandera = null;
    _estadoLlamada = 'marcando';
    _verificado = false;
    _dialogoBloquear = false;
    _vioEtiqueta = false;
    _leidoDesconocido = _pasoActual >= 2;
    _bloqueado = _pasoActual >= 5;

    switch (_pasoActual) {
      case 1:
        _pantalla = 'chats';
        break;
      case 2:
      case 3:
      case 4:
        _pantalla = 'chat_desconocido';
        break;
      case 5:
        _pantalla = 'chat_familia';
        break;
      default:
        _pantalla = 'chats';
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'abrir_desconocido':
        cumple = _pantalla == 'chat_desconocido';
        break;
      case 'banderas_3':
        cumple = _banderas.length == 3;
        break;
      case 'verificado':
        cumple = _verificado;
        break;
      case 'bloqueado':
        cumple = _bloqueado;
        break;
      case 'etiqueta_reenviado':
        cumple = _vioEtiqueta;
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // ─────────────────────────────────────────────
  // CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────
  void _tocarEnSimulador(String accion) {
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'chat_desconocido':
          if (_pasoActual == 3) {
            _mensajeGuia = 'Ahora no. Abre el chat de Carlos (hijo), el de siempre';
          } else {
            _leidoDesconocido = true;
            _pantalla = 'chat_desconocido';
          }
          break;
        case 'chat_carlos':
          if (_pasoActual == 1) {
            _mensajeGuia = 'Primero miremos el número sin nombre de arriba';
          } else {
            _pantalla = 'chat_carlos';
          }
          break;
        case 'chat_otro':
          _mensajeGuia = 'Sigue la instrucción de la cajita morada';
          break;
        case 'atras':
          _pantalla = 'chats';
          break;

        case 'bandera_urgente':
        case 'bandera_plata':
        case 'bandera_secreto':
          if (_pasoActual == 2) {
            _banderas.add(accion);
            _explicacionBandera = accion;
          }
          break;
        case 'msg_presentacion':
          if (_pasoActual == 2) {
            _mensajeGuia = 'Cualquiera puede decir "soy Carlos". Por eso luego vamos a confirmar. Busca las 3 banderas';
          }
          break;
        case 'msg_normal':
          if (_pasoActual == 2) {
            _mensajeGuia = 'Saludar es normal. Busca lo que te APURA, te pide PLATA o te pide SECRETO';
          }
          break;

        case 'llamar_carlos':
          if (_pasoActual != 3) {
            _mensajeGuia = 'Sigue la instrucción de la cajita morada';
            break;
          }
          _pantalla = 'llamada';
          _estadoLlamada = 'marcando';
          _timerLlamada?.cancel();
          _timerLlamada = Timer(const Duration(milliseconds: 1800), () {
            if (!mounted) return;
            setState(() {
              _estadoLlamada = 'contesto';
              _verificado = true;
              _revisarObjetivo();
            });
          });
          break;
        case 'colgar':
          _timerLlamada?.cancel();
          _pantalla = 'chat_carlos';
          break;

        case 'bloquear':
          if (_pasoActual < 4) {
            _mensajeGuia = _pasoActual == 2
                ? 'Muy bien pensado. Primero encontremos las banderas'
                : 'Primero confirmemos con Carlos';
          } else if (!_bloqueado) {
            _dialogoBloquear = true;
          }
          break;
        case 'agregar':
          _mensajeGuia = '¡No lo guardes! Todavía no sabes quién es';
          break;
        case 'cancelar_bloqueo':
          _dialogoBloquear = false;
          break;
        case 'confirmar_bloqueo':
          _dialogoBloquear = false;
          _bloqueado = true;
          break;

        case 'etiqueta':
          _vioEtiqueta = true;
          break;
        case 'link':
          _mensajeGuia = '¡Bien que dudes! Los links de cadenas NO se abren. Toca la etiqueta gris de arriba';
          break;
        case 'msg_cadena':
          _mensajeGuia = 'Fíjate en la etiqueta gris de arriba del mensaje';
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
    _timerLlamada?.cancel();
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
      tituloLeccion: 'WhatsApp seguro',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '🛡️',
      textoTrofeo: '¡A ti no te tumban!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    switch (_pantalla) {
      case 'chat_desconocido':
        return 'CHAT CON NÚMERO DESCONOCIDO';
      case 'chat_carlos':
        return 'CHAT CON CARLOS (EL DE SIEMPRE)';
      case 'llamada':
        return 'LLAMANDO A CARLOS';
      case 'chat_familia':
        return 'GRUPO FAMILIA';
      default:
        return 'WHATSAPP · CHATS';
    }
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: _buildPantalla(),
      encima: [
        if (_dialogoBloquear && _pantalla == 'chat_desconocido')
          MnvDialogoSim(
            titulo: '¿Bloquear a $_numeroRaro?',
            mensaje:
                'No podrá llamarte ni escribirte. También se va a reportar como estafa.',
            textoConfirmar: 'Bloquear',
            onCancelar: () => _tocarEnSimulador('cancelar_bloqueo'),
            onConfirmar: () => _tocarEnSimulador('confirmar_bloqueo'),
          ),
      ],
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'chat_desconocido':
        return _buildChatDesconocido();
      case 'chat_carlos':
        return _buildChatCarlos();
      case 'llamada':
        return _buildLlamada();
      case 'chat_familia':
        return _buildChatFamilia();
      default:
        return _buildChats();
    }
  }

  Widget _buildChats() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const WaCabeceraLista(),
          WaFilaChat(
            nombre: _numeroRaro,
            inicial: '?',
            color: MnvColores.suave2,
            ultimo: 'No le digas a nadie, después te explico',
            hora: '7:42',
            noLeidos: _leidoDesconocido ? 0 : 5,
            resaltada: _pasoActual == 1,
            onTap: () => _tocarEnSimulador('chat_desconocido'),
          ),
          WaFilaChat(
            nombre: 'Carlos (hijo)',
            inicial: 'C',
            color: MnvColores.azul,
            ultimo: 'Te quiero mucho, cuídate ❤️',
            hora: 'Ayer',
            resaltada: _pasoActual == 3,
            onTap: () => _tocarEnSimulador('chat_carlos'),
          ),
          WaFilaChat(
            nombre: 'Familia 💛',
            inicial: 'F',
            color: MnvColores.amarillo,
            ultimo: 'Tía Rosa: URGENTE: El gobierno regala...',
            hora: 'Ayer',
            onTap: () => _tocarEnSimulador('chat_otro'),
          ),
          WaFilaChat(
            nombre: 'Lucía (nieta)',
            inicial: 'L',
            color: MnvColores.morado,
            ultimo: 'Abue, ¿cómo amaneciste? 💕',
            hora: 'Ayer',
            onTap: () => _tocarEnSimulador('chat_otro'),
          ),
          const Spacer(),
          WaPestanas(
            activa: 'chats',
            onPestana: (_) => _tocarEnSimulador('chat_otro'),
          ),
        ],
      ),
    );
  }

  // Mensaje del estafador que se puede marcar como bandera roja
  Widget _mensajeSospechoso(String texto, String hora, String accion) {
    final marcada = _banderas.contains(accion);
    final buscar = _pasoActual == 2 && !marcada;
    return GestureDetector(
      onTap: () => _tocarEnSimulador(accion),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: const BoxConstraints(maxWidth: 200),
            padding: const EdgeInsets.fromLTRB(9, 6, 9, 5),
            decoration: BoxDecoration(
              color: marcada ? MnvColores.rojoSuave : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: marcada
                      ? MnvColores.rojo
                      : (buscar ? MnvColores.borde : Colors.transparent),
                  width: marcada ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (marcada)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text('🚩 Bandera roja',
                        style: TextStyle(
                            color: MnvColores.rojo,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                Text(texto,
                    style: const TextStyle(
                        color: MnvColores.texto, fontSize: 12.5, height: 1.3)),
                const SizedBox(height: 2),
                Text(hora,
                    style:
                        const TextStyle(color: MnvColores.suave2, fontSize: 9.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatDesconocido() {
    return Container(
      color: WaColores.fondoChat,
      child: Column(
        children: [
          WaCabeceraChat(
            nombre: _numeroRaro,
            inicial: '?',
            color: MnvColores.suave2,
            subtitulo: _bloqueado ? 'bloqueado' : 'en línea',
            resaltarAtras: _pasoActual == 3,
            onAtras: () => _tocarEnSimulador('atras'),
          ),
          _buildAvisoDesconocido(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              children: [
                GestureDetector(
                  onTap: () => _tocarEnSimulador('msg_presentacion'),
                  child: const WaBurbuja(
                      texto:
                          'Hola, soy Carlos 👋 Se me dañó el celular, este es mi número nuevo',
                      mia: false,
                      hora: '7:38'),
                ),
                GestureDetector(
                  onTap: () => _tocarEnSimulador('msg_normal'),
                  child: const WaBurbuja(
                      texto: '¿Cómo estás?', mia: false, hora: '7:38'),
                ),
                _mensajeSospechoso('Necesito un favor URGENTE, es para ya 😥',
                    '7:40', 'bandera_urgente'),
                _mensajeSospechoso(
                    'Préstame \$500.000 y mañana te los devuelvo. Te paso el número de cuenta',
                    '7:41',
                    'bandera_plata'),
                _mensajeSospechoso('No le digas a nadie, después te explico',
                    '7:42', 'bandera_secreto'),
              ],
            ),
          ),
          if (_explicacionBandera != null && _pasoActual == 2)
            _buildExplicacionBandera(),
        ],
      ),
    );
  }

  // Franja de WhatsApp para numeros que no tienes guardados
  Widget _buildAvisoDesconocido() {
    if (_bloqueado) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.block_rounded, color: MnvColores.rojo, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text('Bloqueaste este número. Ya no te puede escribir.',
                  style: TextStyle(
                      color: MnvColores.texto,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('Este número no está en tus contactos',
              style: TextStyle(
                  color: MnvColores.suave,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _tocarEnSimulador('bloquear'),
                  child: MnvResalte(
                    activo: _pasoActual == 4,
                    radio: 10,
                    escala: 1.05,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: MnvColores.rojoSuave,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('🚫 Bloquear',
                            style: TextStyle(
                                color: MnvColores.rojo,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _tocarEnSimulador('agregar'),
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: MnvColores.verdeSuave,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('Agregar',
                          style: TextStyle(
                              color: MnvColores.verde,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplicacionBandera() {
    String titulo;
    String texto;
    switch (_explicacionBandera) {
      case 'bandera_urgente':
        titulo = '🚩 Te APURA';
        texto = 'Te meten afán para que no pienses ni preguntes.';
        break;
      case 'bandera_plata':
        titulo = '🚩 Te pide PLATA';
        texto = 'Un familiar de verdad te llamaría, no te mandaría un número de cuenta.';
        break;
      default:
        titulo = '🚩 Te pide SECRETO';
        texto = 'Quieren que no le cuentes a nadie para que nadie te avise que es mentira.';
    }
    return Container(
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
              Text('${_banderas.length} de 3',
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
    );
  }

  Widget _buildChatCarlos() {
    return Container(
      color: WaColores.fondoChat,
      child: Column(
        children: [
          WaCabeceraChat(
            nombre: 'Carlos (hijo)',
            inicial: 'C',
            color: MnvColores.azul,
            subtitulo: 'últ. vez hoy a las 7:00',
            onAtras: () => _tocarEnSimulador('atras'),
            accion: GestureDetector(
              onTap: () => _tocarEnSimulador('llamar_carlos'),
              child: MnvResalte(
                activo: _pasoActual == 3 && !_verificado,
                radio: 18,
                escala: 1.2,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: const Icon(Icons.call_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
          const WaSeparadorFecha(texto: 'AYER'),
          const WaBurbuja(
              texto: 'Te quiero mucho, cuídate ❤️', mia: false, hora: '8:40 p. m.'),
          const WaBurbuja(
              texto: 'Igual mijo, bendiciones',
              mia: true,
              hora: '8:41 p. m.',
              estado: 'leido'),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded,
                    color: MnvColores.verde, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Este es el Carlos que tienes guardado de siempre.',
                      style: TextStyle(color: MnvColores.suave, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLlamada() {
    final contesto = _estadoLlamada == 'contesto';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WaColores.verdeOscuro, MnvColores.verde],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 26),
          const Icon(Icons.lock_rounded, color: Colors.white54, size: 13),
          const Text('Llamada de WhatsApp',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 16),
          const MnvAvatar(texto: 'C', color: Colors.white, tam: 74),
          const SizedBox(height: 10),
          const Text('Carlos (hijo)',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(contesto ? '00:04' : 'Llamando...',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: contesto
                ? Container(
                    key: const ValueKey('respuesta'),
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                        '🗣️ "¿Cuál número nuevo? Mi celular está bien. ¡Eso es una estafa, no le mandes nada!"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: MnvColores.texto,
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600)),
                  )
                : const SizedBox(key: ValueKey('nada'), height: 10),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _tocarEnSimulador('colgar'),
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  color: MnvColores.rojo, shape: BoxShape.circle),
              child: const Icon(Icons.call_end_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
  }

  Widget _buildChatFamilia() {
    return Container(
      color: WaColores.fondoChat,
      child: Column(
        children: [
          WaCabeceraChat(
            nombre: 'Familia 💛',
            inicial: 'F',
            color: MnvColores.amarillo,
            subtitulo: 'Tía Rosa, Carlos, Lucía, tú',
            onAtras: () => _tocarEnSimulador('chat_otro'),
          ),
          const WaSeparadorFecha(texto: 'AYER'),
          const WaBurbuja(
              texto: 'Feliz día a todos 🌸', mia: false, hora: '7:05'),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: GestureDetector(
                onTap: () => _tocarEnSimulador('msg_cadena'),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 215),
                  padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Tía Rosa',
                          style: TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      GestureDetector(
                        onTap: () => _tocarEnSimulador('etiqueta'),
                        child: MnvResalte(
                          activo: _pasoActual == 5 && !_vioEtiqueta,
                          radio: 8,
                          escala: 1.06,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F0F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fast_forward_rounded,
                                    size: 14, color: MnvColores.suave2),
                                SizedBox(width: 3),
                                Text('Reenviado muchas veces',
                                    style: TextStyle(
                                        color: MnvColores.suave2,
                                        fontSize: 10.5,
                                        fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                          'URGENTE‼️ El gobierno regala un subsidio de \$800.000 a los mayores de 60. Inscríbete YA antes de que se acabe:',
                          style: TextStyle(
                              color: MnvColores.texto,
                              fontSize: 12,
                              height: 1.3)),
                      const SizedBox(height: 3),
                      GestureDetector(
                        onTap: () => _tocarEnSimulador('link'),
                        child: const Text('subsidio-ya-gratis.co/registro',
                            style: TextStyle(
                                color: MnvColores.azul,
                                fontSize: 12,
                                decoration: TextDecoration.underline)),
                      ),
                      const SizedBox(height: 2),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text('7:12',
                            style: TextStyle(
                                color: MnvColores.suave2, fontSize: 9.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (_vioEtiqueta)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 350),
              builder: (_, t, hijo) => Opacity(opacity: t, child: hijo),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MnvColores.amarilloSuave,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MnvColores.amarillo, width: 1.5),
                ),
                child: const Text(
                    '⏩⏩ "Reenviado muchas veces" quiere decir que nadie de la familia lo escribió: viene pasando de celular en celular.\n\nNo es fuente confiable. No abras el link ni lo reenvíes.',
                    style: TextStyle(
                        color: MnvColores.texto, fontSize: 11.5, height: 1.4)),
              ),
            ),
        ],
      ),
    );
  }
}
