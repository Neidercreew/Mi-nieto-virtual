import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'nequi_simulador.dart';

const String _leccionId = 'nequi_anti_estafas';

// Datos de los casos de practica (todo es inventado)
const String _numeroFalsoLlamada = '+57 601 555 0142';
const String _numeroFalsoSms = '89 123';
const String _numeroFalsoPlata = '+57 312 555 0198';
const String _numeroFalsoNieto = '+57 321 555 4477';
const int _plataFalsa = 300000;
const int _plataPedida = 400000;

// Preguntas del mini-quiz: texto del caso y si es estafa
const List<Map<String, dynamic>> _quiz = [
  {
    'emoji': '📞',
    'texto': 'Te llaman: "Soy de Nequi, dígame su clave para desbloquear su cuenta".',
    'estafa': true,
    'explica': 'Nequi nunca te llama a pedir tu clave. Eso es estafa.',
  },
  {
    'emoji': '📱',
    'texto': 'Abres TU app de Nequi y en Movimientos ves que Andrés te envió \$ 50.000.',
    'estafa': false,
    'explica': 'Lo viste dentro de tu propia app, así que es seguro.',
  },
  {
    'emoji': '🎁',
    'texto': 'Te llega un mensaje: "Ganaste \$ 2.000.000, entra a este link para reclamarlo".',
    'estafa': true,
    'explica': 'Nadie regala plata por mensaje. Los premios con link son estafa.',
  },
  {
    'emoji': '🥐',
    'texto': 'Pagas en la panadería con QR y la app muestra el nombre de la panadería.',
    'estafa': false,
    'explica': 'El nombre coincide con la tienda donde estás. Es seguro.',
  },
];

class TutorialNequiAntiEstafasScreen extends StatefulWidget {
  final int pasoInicial; // para reanudar
  const TutorialNequiAntiEstafasScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialNequiAntiEstafasScreen> createState() => _TutorialNequiAntiEstafasScreenState();
}

class _TutorialNequiAntiEstafasScreenState extends State<TutorialNequiAntiEstafasScreen> {
  int _pasoActual = 0;
  bool _guardando = false;
  String _pantalla = 'inicio'; // en que pantalla esta el simulador
  bool _objetivoCumplido = false;
  bool _exito = false; // muestra el mensaje verde
  String? _mensajeGuia;
  late ConfettiController _confettiController;

  String _nombre = 'Amigo';

  // Respuestas correctas del quiz (indice de la pregunta)
  final Set<int> _quizBien = {};

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Nequi seguro',
      'instruccion': 'Hay personas que inventan cuentos para quedarse con tu plata. Hoy vas a aprender a reconocer sus trampas.',
    },
    {
      'tipo': 'regla',
      'titulo': 'La regla de oro',
      'instruccion': 'Antes de empezar, guarda esta regla en tu corazón. Con ella te salvas de casi todas las estafas.',
    },
    // CASO 1: llamada falsa
    {
      'tipo': 'simulador',
      'inicio': 'llamada_entrante',
      'titulo': 'Caso 1: una llamada',
      'instruccion': 'Te llama un número que no conoces. Dice que es "Asesor Nequi". Vamos a contestar para conocer la trampa. Toca el botón verde.',
      'objetivo': 'contestar',
      'ayuda': 'Toca el botón verde para contestar',
      'guia': '¡Buen instinto! Colgarle a un número desconocido está bien. Aquí vamos a contestar para conocer la trampa: toca el botón verde.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'llamada_en_curso',
      'titulo': 'Escucha con atención',
      'instruccion': 'Lee lo que te dicen. Te piden un código que te llegó por mensaje. ¿Qué haces? Cuelga con el botón rojo.',
      'objetivo': 'colgar',
      'ayuda': 'Toca el botón rojo para colgar',
      'guia': '¡Ojo! Nequi nunca te pide códigos ni claves. Con ese código pueden entrar a tu cuenta. Toca el botón rojo para colgar.',
    },
    {
      'tipo': 'caso_llamada',
      'titulo': '¡Era una estafa!',
      'instruccion': 'Muy bien hecho. Mira las pistas que te mostraban que esa llamada era falsa.',
    },
    // CASO 2: mensaje con link
    {
      'tipo': 'simulador',
      'inicio': 'sms_link',
      'titulo': 'Caso 2: un mensaje',
      'instruccion': 'Te llega un mensaje que dice que van a bloquear tu cuenta. Trae un link. No lo toques: toca "Borrar mensaje".',
      'objetivo': 'borrar_sms',
      'ayuda': 'Toca "Borrar mensaje"',
      'guia': '¡Cuidado! Ese link lleva a una página falsa que se parece a Nequi y te roba la clave. No lo toques: toca "Borrar mensaje".',
    },
    {
      'tipo': 'caso_sms',
      'titulo': 'Las pistas del mensaje falso',
      'instruccion': 'Estos mensajes siempre se parecen. Aprende a reconocerlos.',
    },
    // CASO 3: "te mande plata por error"
    {
      'tipo': 'simulador',
      'inicio': 'sms_plata',
      'titulo': 'Caso 3: "Le mandé plata por error"',
      'instruccion': 'Te llega un mensaje que dice que recibiste plata, y luego te piden que la devuelvas. Antes de hacer nada, toca "Revisar en mi Nequi".',
      'objetivo': 'revisar_nequi',
      'ayuda': 'Toca "Revisar en mi Nequi"',
      'guia': 'Espera. Antes de devolver plata, revisa SIEMPRE dentro de tu app si de verdad te llegó. Toca "Revisar en mi Nequi".',
    },
    {
      'tipo': 'simulador',
      'inicio': 'inicio',
      'titulo': 'Mira tu saldo',
      'instruccion': 'Tu saldo sigue igual. Para estar seguro, toca "Movimientos" y busca esos \$ 300.000.',
      'objetivo': 'movimientos',
      'ayuda': 'Toca "Movimientos"',
      'guia': 'Busca la fila "Movimientos", la que está brillando.',
      'burbuja': true,
    },
    {
      'tipo': 'mirar',
      'inicio': 'movimientos',
      'titulo': 'No llegó nada',
      'instruccion': 'No hay ningún movimiento de \$ 300.000. El mensaje era falso: querían que les mandaras TU plata.',
    },
    // CASO 4: el falso familiar
    {
      'tipo': 'simulador',
      'inicio': 'chat_nieto',
      'titulo': 'Caso 4: "Soy tu nieto"',
      'instruccion': 'Alguien con un número nuevo dice ser Andrés, tu nieto, y te pide plata urgente. Antes de mandar nada, llama a Andrés a su número de siempre.',
      'objetivo': 'llamar_real',
      'ayuda': 'Toca "Llamar a Andrés"',
      'guia': 'Espera. Primero confirma que de verdad es él. Toca "Llamar a Andrés a su número de siempre".',
    },
    {
      'tipo': 'mirar',
      'inicio': 'llamada_nieto',
      'titulo': '¡Qué bueno que llamaste!',
      'instruccion': 'Andrés está bien y nunca cambió de número. Por llamar, no le mandaste plata a un estafador.',
    },
    // REPASO
    {
      'tipo': 'quiz',
      'titulo': '¿Estafa o seguro?',
      'instruccion': 'Lee cada caso y toca "Estafa" o "Seguro". Si te equivocas, no pasa nada: te explico y vuelves a intentar.',
    },
    {
      'tipo': 'consejos',
      'titulo': 'Tus reglas de oro',
      'instruccion': 'Guarda estos consejos. Si algún día dudas, vuelve a leerlos.',
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste!',
      'instruccion': 'Ya sabes reconocer las trampas más comunes. Ahora tu plata está más protegida.',
    },
  ];

  Map<String, dynamic> get _paso => _pasos[_pasoActual];
  bool get _esSimulador => _paso['tipo'] == 'simulador';
  bool get _esQuiz => _paso['tipo'] == 'quiz';

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _pasoActual = widget.pasoInicial.clamp(0, _pasos.length - 1); // evita RangeError
    _prepararPaso();
    _cargarNombre();
    if (_paso['tipo'] == 'celebracion') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confettiController.play());
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _cargarNombre() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getString('nombre_usuario');
    if (n != null && n.trim().isNotEmpty && mounted) {
      setState(() => _nombre = n.trim().split(' ').first);
    }
  }

  // Deja el simulador listo para el paso actual (sirve tambien al reanudar)
  void _prepararPaso() {
    _mensajeGuia = null;
    _exito = false;
    _quizBien.clear();

    final tipo = _paso['tipo'];
    if (tipo == 'simulador' || tipo == 'mirar') {
      _pantalla = _paso['inicio'] as String;
    }
    // El simulador y el quiz se deben completar para seguir
    _objetivoCumplido = !(_esSimulador || _esQuiz);
  }

  // Marca el paso como logrado. La pantalla NO cambia hasta el boton verde
  void _lograr() {
    _objetivoCumplido = true;
    _exito = true;
    _mensajeGuia = null;
  }

  // El cerebro: decide que pasa con cada toque en el simulador
  void _tocarEnSimulador(String accion) {
    if (!_esSimulador || _objetivoCumplido) return;
    final objetivo = _paso['objetivo'] as String;
    setState(() {
      _mensajeGuia = null;
      if (accion == objetivo) {
        _lograr();
      } else {
        _mensajeGuia = _paso['guia'] as String?;
      }
    });
  }

  // Respuesta del quiz: si acierta se marca, si no se explica
  void _responderQuiz(int i, bool diceEstafa) {
    if (!_esQuiz || _quizBien.contains(i)) return;
    final pregunta = _quiz[i];
    setState(() {
      if (pregunta['estafa'] == diceEstafa) {
        _quizBien.add(i);
        _mensajeGuia = null;
        if (_quizBien.length == _quiz.length) _lograr();
      } else {
        _mensajeGuia = 'Casi. ${pregunta['explica']} Inténtalo otra vez.';
      }
    });
  }

  bool _resalta(String id) => _esSimulador && !_objetivoCumplido && _paso['objetivo'] == id;

  // Vuelve al paso anterior sin guardar nada
  void _retroceder() {
    if (_pasoActual == 0) return;
    setState(() {
      _pasoActual--;
      _prepararPaso();
    });
  }

  Future<void> _avanzar() async {
    if (!_objetivoCumplido || _guardando) return;
    _guardando = true;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    final esUltimo = _pasoActual == _pasos.length - 1;
    if (userId != null) {
      // Se guarda el siguiente paso para reanudar bien
      await ApiService.guardarPaso(userId, _leccionId, _pasoActual + 1, completada: esUltimo);
    }
    _guardando = false;
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
    if (_paso['tipo'] == 'celebracion') _confettiController.play();
  }

  String get _textoBoton {
    if (_pasoActual == _pasos.length - 1) return '¡Terminar!';
    if (_esSimulador && !_objetivoCumplido) return _paso['ayuda'] as String;
    if (_esQuiz && !_objetivoCumplido) return 'Responde los ${_quiz.length} casos';
    return (_esSimulador || _esQuiz) ? '¡Muy bien! Siguiente' : 'Siguiente';
  }

  // ------------------------------------------------------------
  // CONSTRUCCION DE LA PANTALLA
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NequiColores.mnvFondo,
      appBar: AppBar(
        backgroundColor: NequiColores.mnvFondo,
        elevation: 0,
        foregroundColor: NequiColores.textoOscuro,
        title: const Text('Nequi seguro', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  LeccionProgreso(paso: _pasoActual, total: _pasos.length),
                  const SizedBox(height: 12),
                  CajaInstruccion(
                    titulo: _paso['titulo'] as String,
                    instruccion: _paso['instruccion'] as String,
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildIlustracion()),
                  if (_mensajeGuia != null) ...[
                    const SizedBox(height: 10),
                    MensajeGuia(texto: _mensajeGuia!),
                  ] else if (_exito) ...[
                    const SizedBox(height: 10),
                    const MensajeExito(),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_pasoActual > 0) ...[
                        BotonPasoAnterior(onTap: _retroceder),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: BotonLeccion(texto: _textoBoton, activo: _objetivoCumplido, onTap: _avanzar),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.1,
              colors: const [
                Color(0xFF6B4EFF),
                Color(0xFFFFB300),
                Color(0xFF059669),
                Color(0xFF8B5CF6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIlustracion() {
    switch (_paso['tipo']) {
      case 'intro':
        return _ilustracionIntro();
      case 'regla':
        return _ilustracionRegla();
      case 'caso_llamada':
        return _ilustracionCasoLlamada();
      case 'caso_sms':
        return _ilustracionCasoSms();
      case 'quiz':
        return _ilustracionQuiz();
      case 'consejos':
        return _ilustracionConsejos();
      case 'celebracion':
        return _ilustracionCelebracion();
    }
    // Barra de estado blanca sobre fondos oscuros o de color
    final oscura = _pantalla != 'inicio' && _pantalla != 'movimientos';
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: MarcoCelular(
          barraClara: oscura,
          child: _buildPantalla(),
        ),
      ),
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'llamada_entrante':
        return _pantallaLlamadaEntrante();
      case 'llamada_en_curso':
        return _pantallaLlamadaEnCurso();
      case 'sms_link':
        return _pantallaSmsLink();
      case 'sms_plata':
        return _pantallaSmsPlata();
      case 'chat_nieto':
        return _pantallaChatNieto();
      case 'llamada_nieto':
        return _pantallaLlamadaNieto();
      case 'movimientos':
        return NequiMovimientos(resaltados: const {}, onAccion: (_) {});
      default:
        return NequiInicio(
          nombre: _nombre,
          saldo: saldoPractica,
          saldoVisible: true,
          resaltados: _resalta('movimientos') ? {'movimientos'} : <String>{},
          explicacion: _paso['burbuja'] == true
              ? 'Tienes ${formatoPesos(saldoPractica)}, lo mismo de antes. '
                  'Si te hubieran mandado ${formatoPesos(_plataFalsa)}, tendrías más.'
              : null,
          onAccion: _tocarEnSimulador,
        );
    }
  }

  // ------------------------------------------------------------
  // PANTALLAS DEL CELULAR: LLAMADAS
  // ------------------------------------------------------------

  // Fondo oscuro comun a las pantallas de llamada
  BoxDecoration get _fondoLlamada => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2A45), Color(0xFF1A1A2E)],
        ),
      );

  Widget _avatarLlamada(IconData icono, Color color) {
    return CircleAvatar(
      radius: 42,
      backgroundColor: color.withOpacity(0.25),
      child: Icon(icono, size: 44, color: Colors.white),
    );
  }

  // Boton redondo de llamada (verde contestar, rojo colgar)
  Widget _botonRedondo(String id, IconData icono, Color color, String texto) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NequiPulso(
          activo: _resalta(id),
          radio: 34,
          escala: 1.15,
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _tocarEnSimulador(id),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Icon(icono, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(texto, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _pantallaLlamadaEntrante() {
    return Container(
      decoration: _fondoLlamada,
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Text('Llamada entrante', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          _avatarLlamada(Icons.person_rounded, NequiColores.mnvMoradoSec),
          const SizedBox(height: 14),
          const Text(_numeroFalsoLlamada,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Número no guardado',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _botonRedondo('rechazar', Icons.call_end_rounded, NequiColores.mnvRojo, 'Rechazar'),
                _botonRedondo('contestar', Icons.call_rounded, NequiColores.mnvVerde, 'Contestar'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pantallaLlamadaEnCurso() {
    final colgada = _objetivoCumplido;
    return Container(
      decoration: _fondoLlamada,
      child: Column(
        children: [
          const SizedBox(height: 46),
          const Text(_numeroFalsoLlamada,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(colgada ? 'Llamada terminada' : 'En llamada  00:24',
              style: TextStyle(
                  color: colgada ? NequiColores.mnvRojo : Colors.white70,
                  fontSize: 13,
                  fontWeight: colgada ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(height: 18),
          // Lo que dice el estafador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _globoVoz(
              'Buenas, le hablo del área de seguridad de Nequi. Su cuenta va a ser bloqueada hoy. '
              'Para evitarlo, dígame el código de 6 números que le acaba de llegar por mensaje.',
            ),
          ),
          const Spacer(),
          if (colgada)
            const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  Icon(Icons.verified_user_rounded, color: NequiColores.mnvVerde, size: 48),
                  SizedBox(height: 6),
                  Text('¡Colgaste! Tu plata está a salvo',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _botonOscuro('dar_codigo', 'Darle el código'),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _botonRedondo('colgar', Icons.call_end_rounded, NequiColores.mnvRojo, 'Colgar'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pantallaLlamadaNieto() {
    return Container(
      decoration: _fondoLlamada,
      child: Column(
        children: [
          const SizedBox(height: 46),
          _avatarLlamada(Icons.favorite_rounded, NequiColores.magenta),
          const SizedBox(height: 10),
          const Text('Andrés (tu nieto)',
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('En llamada  00:41', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _globoVoz(
              '¡Hola! No, yo no he cambiado de número y estoy muy bien. '
              'Ese mensaje no es mío, es de un estafador. ¡Qué bueno que me llamaste!',
              color: NequiColores.mnvVerde,
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(bottom: 36),
            child: Text('💚 Tu familia está bien y tu plata también',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // Globo con lo que dice la otra persona en la llamada
  Widget _globoVoz(String texto, {Color color = NequiColores.mnvAmarillo}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.record_voice_over_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('"$texto"',
                style: const TextStyle(
                    fontSize: 13, height: 1.35, color: NequiColores.textoOscuro, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PANTALLAS DEL CELULAR: MENSAJES Y CHAT
  // ------------------------------------------------------------

  Widget _encabezadoChat(String titulo, String subtitulo, Color fondo) {
    return Container(
      color: fondo,
      padding: const EdgeInsets.fromLTRB(6, 38, 12, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _tocarEnSimulador('atras'),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const CircleAvatar(
            radius: 17,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text(subtitulo, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Globo de mensaje recibido. Si trae link, se puede tocar
  Widget _globoMensaje(String texto, {String? link, String hora = '10:28'}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(texto, style: const TextStyle(fontSize: 13, height: 1.35, color: NequiColores.textoOscuro)),
            if (link != null) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _tocarEnSimulador('link'),
                child: Text(link,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0EA5E9),
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(hora, style: const TextStyle(fontSize: 10, color: NequiColores.textoSuave)),
            ),
          ],
        ),
      ),
    );
  }

  // Aviso verde dentro del celular cuando hizo lo correcto
  Widget _avisoListo(String texto) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NequiColores.mnvVerde,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _pantallaSmsLink() {
    final borrado = _objetivoCumplido;
    return Container(
      color: const Color(0xFFEFF3F8),
      child: Column(
        children: [
          _encabezadoChat(_numeroFalsoSms, 'Mensaje de texto', const Color(0xFF0EA5E9)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: borrado
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_sweep_rounded, color: NequiColores.textoSuave, size: 48),
                          SizedBox(height: 8),
                          Text('Mensaje borrado',
                              style: TextStyle(color: NequiColores.textoSuave, fontSize: 14)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _globoMensaje(
                          'NEQUI: Su cuenta sera BLOQUEADA HOY por seguridad. '
                          'Actualice sus datos en este enlace o perdera su dinero:',
                          link: 'nequi-actualiza-datos.co/xk9',
                        ),
                      ],
                    ),
            ),
          ),
          if (borrado)
            _avisoListo('No tocaste el link. ¡Así se hace!')
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
              child: _botonPeligro('borrar_sms', 'Borrar mensaje', Icons.delete_rounded),
            ),
        ],
      ),
    );
  }

  Widget _pantallaSmsPlata() {
    return Container(
      color: const Color(0xFFEFF3F8),
      child: Column(
        children: [
          _encabezadoChat(_numeroFalsoPlata, 'Mensaje de texto', const Color(0xFF0EA5E9)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _globoMensaje('Nequi: Recibiste ${formatoPesos(_plataFalsa)} de CARLOS R. '
                    'Tu nuevo saldo es ${formatoPesos(saldoPractica + _plataFalsa)}.'),
                _globoMensaje(
                  'Hola, qué pena con usted. Le mandé esos ${formatoPesos(_plataFalsa)} por error. '
                  'Era para la droga de mi mamá. ¿Me los devuelve a este Nequi, por favor? Es urgente 🙏',
                  hora: '10:29',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: _botonOscuroClaro('devolver', 'Devolver la plata'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
            child: _botonMagenta('revisar_nequi', 'Revisar en mi Nequi'),
          ),
        ],
      ),
    );
  }

  Widget _pantallaChatNieto() {
    return Container(
      color: const Color(0xFFECE5DD),
      child: Column(
        children: [
          _encabezadoChat(_numeroFalsoNieto, 'Número nuevo', NequiColores.mnvVerde),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _globoMensaje('Hola, soy Andrés, tu nieto. Cambié de número, guarda este 😊'),
                _globoMensaje(
                  'Estoy en un problema y me da pena con mis papás. '
                  '¿Me mandas ${formatoPesos(_plataPedida)} a este Nequi YA? Mañana te los devuelvo. '
                  'No le digas a nadie, porfa.',
                  hora: '10:31',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: _botonOscuroClaro('enviar_plata', 'Enviar la plata'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
            child: _botonVerde('llamar_real', 'Llamar a Andrés a su número de siempre'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTONES DEL CELULAR
  // ------------------------------------------------------------

  // Boton magenta de Nequi, brilla cuando es el objetivo
  Widget _botonMagenta(String id, String texto) {
    return _botonLleno(id, texto, NequiColores.magenta);
  }

  Widget _botonVerde(String id, String texto) {
    return _botonLleno(id, texto, NequiColores.mnvVerde, icono: Icons.call_rounded);
  }

  Widget _botonPeligro(String id, String texto, IconData icono) {
    return _botonLleno(id, texto, NequiColores.mnvRojo, icono: icono);
  }

  Widget _botonLleno(String id, String texto, Color color, {IconData? icono}) {
    return NequiPulso(
      activo: _resalta(id),
      radio: 14,
      escala: 1.06,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _tocarEnSimulador(id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icono != null) ...[
                  Icon(icono, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(texto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Boton de la opcion tentadora sobre fondo claro (no brilla nunca)
  Widget _botonOscuroClaro(String id, String texto) {
    return OutlinedButton(
      onPressed: () => _tocarEnSimulador(id),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 46),
        backgroundColor: Colors.white,
        side: const BorderSide(color: NequiColores.textoSuave),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(texto,
          style: const TextStyle(color: NequiColores.textoSuave, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  // Boton de la opcion tentadora sobre fondo oscuro (no brilla nunca)
  Widget _botonOscuro(String id, String texto) {
    return OutlinedButton(
      onPressed: () => _tocarEnSimulador(id),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 46),
        side: const BorderSide(color: Colors.white38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(texto,
          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  // ------------------------------------------------------------
  // ILUSTRACIONES DE LOS PASOS SIN SIMULADOR
  // ------------------------------------------------------------

  Widget _ilustracionIntro() {
    return const SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
          Text('🛡️', style: TextStyle(fontSize: 80)),
          SizedBox(height: 24),
          ConsejoCalido(
            texto: 'Vas a ver 4 trampas de verdad: una llamada, un mensaje con link, '
                'un "le mandé plata por error" y un falso familiar.',
          ),
          SizedBox(height: 12),
          ConsejoCalido(
            texto: 'Todo es de práctica. Nadie te está llamando de verdad y tu plata real no se toca.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionRegla() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [NequiColores.magenta, NequiColores.morado],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: [
                Text('🔐', style: TextStyle(fontSize: 50)),
                SizedBox(height: 10),
                Text('Tu clave y los códigos que te llegan son SOLO TUYOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, height: 1.3)),
                SizedBox(height: 10),
                Text('Nequi nunca te va a llamar ni escribir para pedírtelos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ConsejoCalido(
            texto: 'Es como el PIN de tu tarjeta en el cajero: no se lo dices a nadie, '
                'ni siquiera a alguien que diga ser del banco.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionCasoLlamada() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _tarjetaInfo('📵', 'Número que no conoces',
              'Dijo ser de Nequi, pero llamó desde un número cualquiera.', NequiColores.mnvAmarillo),
          const SizedBox(height: 12),
          _tarjetaInfo('⏰', 'Te metió afán',
              '"Su cuenta va a ser bloqueada HOY". El susto es para que no pienses.', NequiColores.mnvAmarillo),
          const SizedBox(height: 12),
          _tarjetaInfo('🔢', 'Te pidió un código',
              'Esa es la señal más clara. Nequi NUNCA te pide códigos ni claves.', NequiColores.mnvRojo),
          const SizedBox(height: 16),
          const ConsejoCalido(
            texto: 'Si te queda la duda, cuelga y entra tú mismo a la app de Nequi. '
                'Allí ves si de verdad pasa algo con tu cuenta.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionCasoSms() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _tarjetaInfo('😱', 'Te asusta',
              '"BLOQUEADA", "perderá su dinero". Quieren que actúes sin pensar.', NequiColores.mnvAmarillo),
          const SizedBox(height: 12),
          _tarjetaInfo('🔗', 'Trae un link raro',
              'Te lleva a una página que se parece a Nequi pero es falsa. Allí te roban la clave.',
              NequiColores.mnvRojo),
          const SizedBox(height: 12),
          _tarjetaInfo('✍️', 'Tiene errores',
              'Palabras sin tilde, mayúsculas por todos lados, números raros.', NequiColores.mnvAmarillo),
          const SizedBox(height: 16),
          const ConsejoCalido(
            texto: 'Para entrar a Nequi usa SIEMPRE la app que tienes instalada. Nunca un link que te manden.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionQuiz() {
    return ListView.builder(
      itemCount: _quiz.length,
      itemBuilder: (_, i) {
        final p = _quiz[i];
        final bien = _quizBien.contains(i);
        final esEstafa = p['estafa'] as bool;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: bien
                  ? (esEstafa ? NequiColores.mnvRojo : NequiColores.mnvVerde)
                  : NequiColores.borde,
              width: bien ? 2 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['emoji'] as String, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(p['texto'] as String,
                        style: const TextStyle(fontSize: 15, color: NequiColores.textoOscuro, height: 1.35)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (bien)
                Row(
                  children: [
                    Icon(esEstafa ? Icons.gpp_bad_rounded : Icons.verified_user_rounded,
                        color: esEstafa ? NequiColores.mnvRojo : NequiColores.mnvVerde),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(p['explica'] as String,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: esEstafa ? NequiColores.mnvRojo : NequiColores.mnvVerde)),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: _botonQuiz(i, true)),
                    const SizedBox(width: 10),
                    Expanded(child: _botonQuiz(i, false)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _botonQuiz(int i, bool estafa) {
    final color = estafa ? NequiColores.mnvRojo : NequiColores.mnvVerde;
    return OutlinedButton(
      onPressed: () => _responderQuiz(i, estafa),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        side: BorderSide(color: color, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(estafa ? '🛑 Estafa' : '✅ Seguro',
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _ilustracionConsejos() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _tarjetaInfo('🔐', 'Tu clave es solo tuya',
              'Nunca la digas, ni los códigos que te llegan por mensaje. A nadie.', NequiColores.mnvRojo),
          const SizedBox(height: 12),
          _tarjetaInfo('📱', 'Revisa en tu app',
              'Si te dicen que te mandaron plata o que hay un problema, míralo tú mismo en tu Nequi.',
              NequiColores.mnvMorado),
          const SizedBox(height: 12),
          _tarjetaInfo('📞', 'Llama al número de siempre',
              'Si un familiar te pide plata desde otro número, llámalo a su número de siempre antes de enviar.',
              NequiColores.mnvVerde),
          const SizedBox(height: 12),
          _tarjetaInfo('🐢', 'El afán es sospechoso',
              'Si te presionan para hacerlo YA, detente. Lo que es de verdad puede esperar.',
              NequiColores.mnvAmarillo),
          const SizedBox(height: 16),
          const ConsejoCalido(
            texto: 'Si crees que te estafaron, entra a la app de Nequi y busca la opción de Ayuda, '
                'y cuéntale a alguien de tu familia. Pedir ayuda no da pena.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionCelebracion() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text('🛡️🎉', style: TextStyle(fontSize: 70)),
          const SizedBox(height: 12),
          Text('¡$_nombre, ya no te cogen de sorpresa!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          const SizedBox(height: 20),
          _logro('Le colgaste al falso asesor'),
          _logro('Borraste el mensaje sin tocar el link'),
          _logro('Revisaste tu Nequi antes de devolver plata'),
          _logro('Llamaste a tu nieto a su número de siempre'),
          _logro('Terminaste todas las lecciones de Nequi'),
        ],
      ),
    );
  }

  Widget _tarjetaInfo(String emoji, String titulo, String texto, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(texto,
                    style: const TextStyle(fontSize: 14, color: NequiColores.textoOscuro, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logro(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 13,
            backgroundColor: NequiColores.mnvVerde,
            child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: const TextStyle(fontSize: 15, color: NequiColores.textoOscuro)),
          ),
        ],
      ),
    );
  }
}