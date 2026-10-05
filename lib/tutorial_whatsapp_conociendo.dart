import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_whatsapp.dart';

const String _leccionId = 'whatsapp_conociendo';

class TutorialWhatsappConociendoScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialWhatsappConociendoScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialWhatsappConociendoScreen> createState() =>
      _TutorialWhatsappConociendoScreenState();
}

class _TutorialWhatsappConociendoScreenState
    extends State<TutorialWhatsappConociendoScreen> {
  int _pasoActual = 0;

  // pantalla: inicio | chats | chat_lucia | chat_maria | llamadas
  String _pantalla = 'inicio';
  bool _leidoLucia = false;
  bool _vioLlamadas = false;
  bool _volvioDeLlamadas = false;
  final Set<String> _palomitasVistas = {};
  String? _explicacion;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'WhatsApp: tu familia\nen el bolsillo 💬',
      'instruccion':
          'Con WhatsApp mandas mensajes, audios, fotos y haces llamadas usando internet.\n\nHoy vas a aprender a ubicarte: saber quién te escribió y si ya leyeron lo que mandaste.',
      'icono': Icons.chat_rounded,
      'colorIcono': MnvColores.verde,
    },
    {
      'tipo': 'sim',
      'titulo': 'Abre WhatsApp 📲',
      'instruccion':
          'En la pantalla de inicio busca el cuadro verde con una burbujita que dice WhatsApp y tócalo.',
      'objetivo': 'abrir_app',
      'ayuda': 'Toca el cuadro verde de WhatsApp',
    },
    {
      'tipo': 'sim_info',
      'titulo': 'Esta es tu lista de chats 📋',
      'instruccion':
          'Cada fila es una persona: a la izquierda su foto, en el medio su nombre y lo último que dijeron, y a la derecha la hora.\n\nLos más nuevos siempre quedan arriba.',
    },
    {
      'tipo': 'sim',
      'titulo': '¿Quién te escribió? 🟢',
      'instruccion':
          'El circulito verde con un número dice cuántos mensajes NO has leído.\n\nBusca el chat que tiene circulito y ábrelo.',
      'objetivo': 'abrir_no_leido',
      'ayuda': 'Toca el chat que tiene el circulito verde',
    },
    {
      'tipo': 'sim',
      'titulo': 'Lee y vuelve ⬅️',
      'instruccion':
          'Ya leíste lo que te mandó Lucía, tu nieta.\n\nPara volver a la lista toca la flecha de arriba a la izquierda. Fíjate que el circulito verde desaparece.',
      'objetivo': 'volver_lista',
      'ayuda': 'Toca la flecha ← de arriba',
    },
    {
      'tipo': 'sim',
      'titulo': 'Las palomitas ✔️✔️',
      'instruccion':
          'En el chat con María, al lado de la hora de TUS mensajes hay chulitos.\n\nToca tus tres mensajes verdes para descubrir qué significa cada uno.',
      'objetivo': 'palomitas_vistas',
      'ayuda': 'Toca cada mensaje verde (tus mensajes)',
    },
    {
      'tipo': 'sim',
      'titulo': 'Las pestañas de abajo 🗂️',
      'instruccion':
          'Abajo hay tres lugares: Chats, Novedades y Llamadas.\n\nEntra a Llamadas para ver con quién has hablado, y después regresa a Chats.',
      'objetivo': 'pestanas_exploradas',
      'ayuda': 'Toca Llamadas y luego vuelve a Chats',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 ¿Un relojito en tu mensaje?',
      'instruccion':
          'Si en vez de chulitos ves un relojito 🕓, tu celular no tiene internet en ese momento.\n\nNo pasa nada: el mensaje sale solito cuando vuelva el internet o el wifi.',
      'icono': Icons.schedule_rounded,
      'colorIcono': MnvColores.amarillo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Abre tu WhatsApp. Mira quién tiene circulito verde y lee ese chat.\n\nLuego busca un mensaje tuyo y fíjate si los chulitos están azules.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': MnvColores.verde,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Ya te ubicas en WhatsApp! 🏆',
      'instruccion':
          'Sabes abrirlo, ver quién te escribió, leer, volver y entender si leyeron tus mensajes.\n\nEso es lo que más se usa todos los días. 👏',
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

  // Deja el simulador exactamente como debe verse en cada paso
  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;
    _vioLlamadas = false;
    _volvioDeLlamadas = false;
    _palomitasVistas.clear();
    _explicacion = null;

    switch (_pasoActual) {
      case 1:
        _pantalla = 'inicio';
        _leidoLucia = false;
        break;
      case 2:
      case 3:
        _pantalla = 'chats';
        _leidoLucia = false;
        break;
      case 4:
        _pantalla = 'chat_lucia';
        _leidoLucia = true;
        break;
      case 5:
        _pantalla = 'chat_maria';
        _leidoLucia = true;
        break;
      case 6:
        _pantalla = 'chats';
        _leidoLucia = true;
        break;
      default:
        _pantalla = 'inicio';
        _leidoLucia = false;
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'abrir_app':
        cumple = _pantalla == 'chats';
        break;
      case 'abrir_no_leido':
        cumple = _pantalla == 'chat_lucia';
        break;
      case 'volver_lista':
        cumple = _pantalla == 'chats';
        break;
      case 'palomitas_vistas':
        cumple = _palomitasVistas.length == 3;
        break;
      case 'pestanas_exploradas':
        cumple = _vioLlamadas && _volvioDeLlamadas && _pantalla == 'chats';
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // ─────────────────────────────────────────────
  // CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────
  void _tocarEnSimulador(String accion) {
    final esInfo = _pasos[_pasoActual]['tipo'] == 'sim_info';
    setState(() {
      _mensajeGuia = null;

      if (esInfo) {
        _mensajeGuia = 'Aquí solo mira. Toca "Entendido" abajo para seguir';
        return;
      }

      switch (accion) {
        case 'app_whatsapp':
          _pantalla = 'chats';
          break;
        case 'app_otra':
          _mensajeGuia = 'Esa es otra app. WhatsApp es el cuadro verde con burbujita';
          break;

        case 'chat_lucia':
          if (_pasoActual == 6) {
            _mensajeGuia = 'Ahora practicamos las pestañas de abajo';
          } else {
            _leidoLucia = true;
            _pantalla = 'chat_lucia';
          }
          break;
        case 'chat_maria':
          if (_pasoActual == 3) {
            _mensajeGuia = 'Ese chat no tiene circulito: ya lo leíste. Busca el de Lucía';
          } else if (_pasoActual == 6) {
            _mensajeGuia = 'Ahora practicamos las pestañas de abajo';
          } else {
            _pantalla = 'chat_maria';
          }
          break;
        case 'chat_otro':
          _mensajeGuia = _pasoActual == 3
              ? 'Ese ya lo leíste. Busca el que tiene el circulito verde'
              : 'Sigue la instrucción de la cajita morada';
          break;

        case 'atras':
          _pantalla = 'chats';
          break;

        case 'palomita_enviado':
        case 'palomita_entregado':
        case 'palomita_leido':
          _palomitasVistas.add(accion);
          _explicacion = accion;
          break;
        case 'burbuja_maria':
          _mensajeGuia = 'Ese lo escribió María. Tus mensajes son los verdes de la derecha';
          break;

        case 'pestana_llamadas':
          _vioLlamadas = true;
          _pantalla = 'llamadas';
          break;
        case 'pestana_chats':
          if (_pantalla == 'llamadas') _volvioDeLlamadas = true;
          _pantalla = 'chats';
          if (!_vioLlamadas) {
            _mensajeGuia = 'Ya estás en Chats. Primero entra a Llamadas';
          }
          break;
        case 'pestana_novedades':
          _mensajeGuia = 'En Novedades la gente pone fotos que duran un día. Hoy buscamos Llamadas';
          break;
      }

      _revisarObjetivo();
    });
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
      tituloLeccion: 'Conociendo WhatsApp',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '💬',
      textoTrofeo: '¡Ya te ubicas en WhatsApp!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    switch (_pantalla) {
      case 'chats':
        return 'WHATSAPP · CHATS';
      case 'chat_lucia':
        return 'CHAT CON LUCÍA';
      case 'chat_maria':
        return 'CHAT CON MARÍA';
      case 'llamadas':
        return 'WHATSAPP · LLAMADAS';
      default:
        return 'PANTALLA DE INICIO';
    }
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: _buildPantalla(),
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'chats':
        return _buildChats();
      case 'chat_lucia':
        return _buildChatLucia();
      case 'chat_maria':
        return _buildChatMaria();
      case 'llamadas':
        return _buildLlamadas();
      default:
        return MnvPantallaInicio(
          apps: MnvPantallaInicio.appsBase,
          resaltada: _pasoActual == 1 ? 'whatsapp' : null,
          onApp: (clave) =>
              _tocarEnSimulador(clave == 'whatsapp' ? 'app_whatsapp' : 'app_otra'),
        );
    }
  }

  Widget _buildChats() {
    final resaltaLucia = _pasoActual == 3;
    final infoFila = _pasoActual == 2;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const WaCabeceraLista(),
          WaFilaChat(
            nombre: 'Lucía (nieta)',
            inicial: 'L',
            color: MnvColores.morado,
            ultimo: 'Te mando un abrazo grande 🤗',
            hora: '9:30',
            noLeidos: _leidoLucia ? 0 : 2,
            resaltada: resaltaLucia,
            onTap: () => _tocarEnSimulador('chat_lucia'),
          ),
          WaFilaChat(
            nombre: 'María',
            inicial: 'M',
            color: MnvColores.verde,
            ultimo: '¿A qué hora te queda bien?',
            hora: '8:11',
            estadoMio: 'enviado',
            resaltada: infoFila,
            onTap: () => _tocarEnSimulador('chat_maria'),
          ),
          WaFilaChat(
            nombre: 'Carlos (hijo)',
            inicial: 'C',
            color: MnvColores.azul,
            ultimo: '¿Vienes a almorzar el domingo?',
            hora: 'Ayer',
            onTap: () => _tocarEnSimulador('chat_otro'),
          ),
          WaFilaChat(
            nombre: 'Familia 💛',
            inicial: 'F',
            color: MnvColores.amarillo,
            ultimo: 'Tía Rosa: Feliz día a todos 🌸',
            hora: 'Ayer',
            onTap: () => _tocarEnSimulador('chat_otro'),
          ),
          WaFilaChat(
            nombre: 'Consultorio Dr. Ramírez',
            inicial: 'D',
            color: MnvColores.rojo,
            ultimo: 'Recuerde traer sus exámenes',
            hora: 'Lunes',
            onTap: () => _tocarEnSimulador('chat_otro'),
          ),
          const Spacer(),
          WaPestanas(
            activa: 'chats',
            resaltada: _pasoActual == 6 && !_vioLlamadas ? 'llamadas' : null,
            onPestana: (p) => _tocarEnSimulador('pestana_$p'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatLucia() {
    return Container(
      color: WaColores.fondoChat,
      child: Column(
        children: [
          WaCabeceraChat(
            nombre: 'Lucía (nieta)',
            inicial: 'L',
            color: MnvColores.morado,
            resaltarAtras: _pasoActual == 4,
            onAtras: () => _tocarEnSimulador('atras'),
          ),
          const WaSeparadorFecha(texto: 'HOY'),
          const WaBurbuja(
              texto: 'Abue, ¿cómo amaneciste? 💕', mia: false, hora: '9:28'),
          const WaBurbuja(
              texto: 'Te mando un abrazo grande 🤗', mia: false, hora: '9:30'),
          const Spacer(),
          _cajaQuieta(),
        ],
      ),
    );
  }

  Widget _buildChatMaria() {
    final resaltar = _pasoActual == 5;
    return Container(
      color: WaColores.fondoChat,
      child: Column(
        children: [
          WaCabeceraChat(
            nombre: 'María',
            inicial: 'M',
            color: MnvColores.verde,
            subtitulo: 'últ. vez hoy a las 8:06',
            onAtras: () => _tocarEnSimulador('atras'),
          ),
          const WaSeparadorFecha(texto: 'HOY'),
          WaBurbuja(
            texto: 'Hola María, ¿cómo sigues?',
            mia: true,
            hora: '8:02',
            estado: 'leido',
            resaltada: resaltar && !_palomitasVistas.contains('palomita_leido'),
            onTap: () => _tocarEnSimulador('palomita_leido'),
          ),
          WaBurbuja(
            texto: '¡Mejor, gracias! 😊',
            mia: false,
            hora: '8:05',
            onTap: () => _tocarEnSimulador('burbuja_maria'),
          ),
          WaBurbuja(
            texto: 'Te llevo arepas el sábado',
            mia: true,
            hora: '8:10',
            estado: 'entregado',
            resaltada:
                resaltar && !_palomitasVistas.contains('palomita_entregado'),
            onTap: () => _tocarEnSimulador('palomita_entregado'),
          ),
          WaBurbuja(
            texto: '¿A qué hora te queda bien?',
            mia: true,
            hora: '8:11',
            estado: 'enviado',
            resaltada: resaltar && !_palomitasVistas.contains('palomita_enviado'),
            onTap: () => _tocarEnSimulador('palomita_enviado'),
          ),
          const Spacer(),
          if (_explicacion != null) _buildExplicacion() else _cajaQuieta(),
        ],
      ),
    );
  }

  // Tarjeta que explica la palomita que se acaba de tocar
  Widget _buildExplicacion() {
    String titulo;
    String texto;
    switch (_explicacion) {
      case 'palomita_enviado':
        titulo = '✓ Un chulito gris';
        texto = 'Tu mensaje salió de tu celular, pero todavía no le llega a María (puede tener el celular apagado).';
        break;
      case 'palomita_entregado':
        titulo = '✓✓ Dos chulitos grises';
        texto = 'Ya le llegó a su celular, pero María todavía no lo ha leído.';
        break;
      default:
        titulo = '✓✓ Dos chulitos azules';
        texto = 'María ya lo leyó.';
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey(_explicacion),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (_, t, hijo) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: hijo),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        padding: const EdgeInsets.all(12),
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
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
                Text('${_palomitasVistas.length} de 3',
                    style: const TextStyle(
                        color: MnvColores.cafe,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(texto,
                style: const TextStyle(
                    color: MnvColores.suave, fontSize: 12, height: 1.35)),
          ],
        ),
      ),
    );
  }

  // Caja de escribir que en esta leccion no se usa
  Widget _cajaQuieta() {
    return WaCajaEscribir(
      texto: '',
      enfocada: false,
      onCaja: () => setState(() =>
          _mensajeGuia = 'Escribir lo practicamos en la siguiente lección'),
      onEmoji: () => setState(() =>
          _mensajeGuia = 'Los emojis los practicamos en la siguiente lección'),
      onClip: () => setState(() =>
          _mensajeGuia = 'Enviar fotos lo practicamos más adelante'),
      botonDerecho: WaBotonRedondo(
        icono: Icons.mic_rounded,
        onTap: () => setState(() =>
            _mensajeGuia = 'Los audios tienen su propia lección'),
      ),
    );
  }

  Widget _buildLlamadas() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const WaCabeceraLista(titulo: 'Llamadas'),
          const SizedBox(height: 6),
          _filaLlamada('María', 'M', MnvColores.verde, 'Hoy, 7:40',
              Icons.call_made_rounded, MnvColores.verde, Icons.call_rounded),
          _filaLlamada('Carlos (hijo)', 'C', MnvColores.azul, 'Ayer, 6:15 p. m.',
              Icons.call_received_rounded, MnvColores.verde,
              Icons.videocam_rounded),
          _filaLlamada('Lucía (nieta)', 'L', MnvColores.morado,
              'Domingo, 11:02', Icons.call_missed_rounded, MnvColores.rojo,
              Icons.call_rounded),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
                'Las llamadas por WhatsApp usan internet, no los minutos de tu plan.',
                style: TextStyle(
                    color: MnvColores.suave.withValues(alpha: 0.9),
                    fontSize: 11.5,
                    height: 1.35)),
          ),
          const Spacer(),
          WaPestanas(
            activa: 'llamadas',
            resaltada: _pasoActual == 6 ? 'chats' : null,
            onPestana: (p) => _tocarEnSimulador('pestana_$p'),
          ),
        ],
      ),
    );
  }

  Widget _filaLlamada(String nombre, String inicial, Color color, String cuando,
      IconData flecha, Color colorFlecha, IconData tipo) {
    return GestureDetector(
      onTap: () => setState(() => _mensajeGuia =
          'Desde aquí podrías devolver la llamada. Hoy solo exploramos'),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            MnvAvatar(texto: inicial, color: color, tam: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: TextStyle(
                          color: colorFlecha == MnvColores.rojo
                              ? MnvColores.rojo
                              : MnvColores.texto,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Icon(flecha, size: 13, color: colorFlecha),
                      const SizedBox(width: 3),
                      Text(cuando,
                          style: const TextStyle(
                              color: MnvColores.suave2, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(tipo, color: WaColores.verde, size: 21),
          ],
        ),
      ),
    );
  }
}
