import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'nequi_simulador.dart';

const String _leccionId = 'nequi_conociendo';
const String _clavePractica = '1234';

class TutorialNequiConociendoScreen extends StatefulWidget {
  final int pasoInicial; // para reanudar
  const TutorialNequiConociendoScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialNequiConociendoScreen> createState() => _TutorialNequiConociendoScreenState();
}

class _TutorialNequiConociendoScreenState extends State<TutorialNequiConociendoScreen> {
  int _pasoActual = 0;
  bool _guardando = false;
  late ConfettiController _confettiController;

  // Estado del simulador
  String _pantalla = 'escritorio';
  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  String? _explicacion;
  String _nombre = 'amigo';
  String _claveEscrita = '';
  bool _saldoVisible = true;
  bool _saldoTocado = false;
  bool _salio = false;
  final Set<String> _botonesTocados = {};

  static const _botonesPrincipales = ['envia', 'pide', 'saca', 'recarga'];

  static const Map<String, String> _explicaciones = {
    'envia': 'Envía: le mandas plata a otra persona usando su número de celular.',
    'pide': 'Pide: le pides plata a alguien, por ejemplo a tu nieto.',
    'saca': 'Saca: te da un código para sacar efectivo en un cajero, sin tarjeta.',
    'recarga': 'Recarga: metes plata a tu Nequi, en una tienda o desde otro banco.',
    'qr': 'Paga con QR: pagas en tiendas escaneando un código. Lo practicaremos en otra lección.',
  };

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'info',
      'vista': 'billetera',
      'titulo': 'Tu billetera en el celular',
      'instruccion':
          'Nequi es como una billetera que vive en tu celular. Con ella guardas, envías y recibes plata sin cargar efectivo.',
      'consejo': 'Muchas familias en Colombia la usan para mandarse plata en segundos, sin hacer filas.',
    },
    {
      'tipo': 'info',
      'vista': 'seguro',
      'titulo': 'Aquí practicas tranquilo',
      'instruccion':
          'Este es un celular de práctica con plata de mentiras. Toca todo sin miedo: nada de lo que hagas aquí mueve plata de verdad.',
    },
    {
      'tipo': 'simulador',
      'pantalla': 'escritorio',
      'titulo': 'Abre Nequi',
      'instruccion': 'Busca el ícono de Nequi en la pantalla del celular y tócalo.',
      'objetivo': 'abrir_nequi',
      'resalta': 'app_nequi',
      'ayuda': 'Toca el ícono de Nequi',
    },
        {
      'tipo': 'simulador',
      'pantalla': 'clave',
      'titulo': 'Entra con tu clave',
      'instruccion':
          'Nequi te pide una clave de 4 números, como la del cajero: solo tú la sabes. Tu clave de práctica es 1 2 3 4. Escríbela número por número.',
      'objetivo': 'entrar',
      'ayuda': 'Escribe 1 2 3 4',
      'consejo': 'Nunca le digas tu clave a nadie, ni siquiera a alguien que diga ser de Nequi o del banco.',
    },
    {
      'tipo': 'simulador',
      'pantalla': 'inicio',
      'titulo': 'Tu pantalla principal',
      'instruccion':
          '¡Entraste! En la caja de colores ves tu saldo: la plata que tienes en Nequi. Tócala.',
      'objetivo': 'ver_saldo',
      'resalta': 'saldo',
      'ayuda': 'Toca la caja de tu saldo',
    },
    {
      'tipo': 'simulador',
      'pantalla': 'inicio',
      'titulo': 'Esconde tu saldo',
      'instruccion': 'Si estás en la calle o con gente alrededor, puedes taparlo. Toca el ojito.',
      'objetivo': 'ocultar_saldo',
      'resalta': 'ojo',
      'ayuda': 'Toca el ojito',
      'consejo': 'Esconder el saldo no mueve tu plata, solo la protege de miradas curiosas.',
    },
    {
      'tipo': 'simulador',
      'pantalla': 'inicio',
      'saldoVisible': false,
      'titulo': 'Muéstralo otra vez',
      'instruccion': 'Toca de nuevo el ojito para volver a ver tu plata.',
      'objetivo': 'mostrar_saldo',
      'resalta': 'ojo',
      'ayuda': 'Toca el ojito otra vez',
    },
    {
      'tipo': 'simulador',
      'pantalla': 'inicio',
      'titulo': 'Los 4 botones principales',
      'instruccion':
          'Toca cada botón para saber para qué sirve. Tranquilo: aquí solo te los explicamos, no se mueve plata.',
      'objetivo': 'tocar_botones',
    },
    {
      'tipo': 'simulador',
      'pantalla': 'inicio',
      'titulo': 'Tus movimientos',
      'instruccion': 'Aquí revisas quién te envió plata y en qué la gastaste. Toca "Movimientos".',
      'objetivo': 'ver_movimientos',
      'resalta': 'movimientos',
      'ayuda': 'Toca "Movimientos"',
    },
    {
      'tipo': 'simulador',
      'pantalla': 'movimientos',
      'titulo': 'Revisa y vuelve',
      'instruccion':
          'Mira: tu nieto Andrés te envió \$ 50.000. Cuando termines de mirar, toca la flecha para volver.',
      'objetivo': 'volver_inicio',
      'resalta': 'atras',
      'ayuda': 'Toca la flecha de atrás',
      'consejo':
          'Revisa tus movimientos de vez en cuando. Si ves algo que no reconoces, cuéntale a alguien de confianza.',
    },
    {
      'tipo': 'simulador',
      'pantalla': 'inicio',
      'titulo': 'Sal de forma segura',
      'instruccion': 'Cuando termines, sal de Nequi. Toca el botón de salir, arriba a la derecha.',
      'objetivo': 'salir',
      'resalta': 'salir',
      'ayuda': 'Toca el botón de salir',
      'consejo': 'Así, si alguien toma tu celular, no puede entrar a tu Nequi sin tu clave.',
    },
    {
      'tipo': 'celebracion',
      'vista': 'celebracion',
      'titulo': '¡Ya conoces Nequi!',
      'instruccion':
          'Aprendiste a abrirla, entrar con tu clave, ver y esconder tu saldo, revisar tus movimientos y salir seguro.',
    },
  ];

  Map<String, dynamic> get _paso => _pasos[_pasoActual];
  bool get _esSimulador => _paso['tipo'] == 'simulador';

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

  // Usa el nombre real del usuario dentro del simulador
  Future<void> _cargarNombre() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getString('nombre_usuario');
    if (n != null && n.trim().isNotEmpty && mounted) {
      setState(() => _nombre = n.trim().split(' ').first);
    }
  }

  // Deja el simulador listo para el paso actual
  void _prepararPaso() {
    _pantalla = (_paso['pantalla'] as String?) ?? 'escritorio';
    _saldoVisible = (_paso['saldoVisible'] as bool?) ?? true;
    _mensajeGuia = null;
    _explicacion = null;
    _claveEscrita = '';
    _saldoTocado = false;
    _salio = false;
    _botonesTocados.clear();
    _objetivoCumplido = !_esSimulador;
  }

  // Revisa si el estado actual cumple el objetivo del paso
  void _verificarObjetivo() {
    if (!_esSimulador) return;
    bool cumplido;
    switch (_paso['objetivo'] as String) {
      case 'abrir_nequi':
        cumplido = _pantalla == 'clave';
        break;
      case 'entrar':
      case 'volver_inicio':
        cumplido = _pantalla == 'inicio';
        break;
      case 'ver_saldo':
        cumplido = _saldoTocado;
        break;
      case 'ocultar_saldo':
        cumplido = !_saldoVisible;
        break;
      case 'mostrar_saldo':
        cumplido = _saldoVisible;
        break;
      case 'tocar_botones':
        cumplido = _botonesTocados.length == _botonesPrincipales.length;
        break;
      case 'ver_movimientos':
        cumplido = _pantalla == 'movimientos';
        break;
      case 'salir':
        cumplido = _salio;
        break;
      default:
        cumplido = false;
    }
    if (cumplido && !_objetivoCumplido) {
      HapticFeedback.lightImpact();
      _mensajeGuia = null;
    }
    _objetivoCumplido = cumplido;
  }

  // El cerebro: decide que pasa con cada toque en el celular
  void _tocarEnSimulador(String accion) {
    if (!_esSimulador) {
      setState(() => _mensajeGuia = 'Primero lee la caja morada y luego toca "Siguiente".');
      return;
    }
    // Si ya cumplio el objetivo, el celular espera al boton verde
    if (_objetivoCumplido) return;
    final resalta = _paso['resalta'] as String?;
    setState(() {
      _mensajeGuia = null;
      switch (_pantalla) {
        case 'escritorio':
          _tocarEscritorio(accion);
          break;
        case 'clave':
          _tocarClave(accion);
          break;
        case 'inicio':
          _tocarInicio(accion, resalta);
          break;
        case 'movimientos':
          _tocarMovimientos(accion, resalta);
          break;
      }
      _verificarObjetivo();
    });
  }

  void _tocarEscritorio(String accion) {
    if (accion == 'app_nequi') {
      _pantalla = 'clave';
      _claveEscrita = '';
    } else {
      _mensajeGuia = 'Esa es otra aplicación. Busca el ícono de Nequi, el que está brillando.';
    }
  }

  void _tocarClave(String tecla) {
    if (tecla == '⌫') {
      if (_claveEscrita.isNotEmpty) {
        _claveEscrita = _claveEscrita.substring(0, _claveEscrita.length - 1);
      }
      return;
    }
    if (_claveEscrita.length >= 4) return;
    _claveEscrita += tecla;

    if (!_clavePractica.startsWith(_claveEscrita)) {
      _mensajeGuia = 'Ese número no va. Tu clave de práctica es 1 2 3 4. Toca la tecla lila para borrar.';
    }
    if (_claveEscrita.length == 4) {
      if (_claveEscrita == _clavePractica) {
        _pantalla = 'inicio';
      } else {
        _claveEscrita = '';
        _mensajeGuia = 'Esa no es la clave, pero tranquilo, puedes intentar otra vez: 1 2 3 4.';
      }
    }
  }

  void _tocarInicio(String accion, String? resalta) {
    // Los botones solo explican, nunca mueven plata
    if (_explicaciones.containsKey(accion)) {
      _explicacion = _explicaciones[accion];
      if (_paso['objetivo'] == 'tocar_botones' && _botonesPrincipales.contains(accion)) {
        _botonesTocados.add(accion);
      }
      return;
    }
    switch (accion) {
      case 'saldo':
        _saldoTocado = true;
        _explicacion =
            'Esta es tu plata disponible: ${formatoPesos(saldoPractica)}. Recuerda: es plata de práctica.';
        break;
      case 'ojo':
        if (resalta == 'ojo') {
          _saldoVisible = !_saldoVisible;
          _explicacion = _saldoVisible ? 'Tu saldo se ve otra vez.' : 'Listo, tu saldo quedó escondido.';
        } else {
          _mensajeGuia = 'Ese ojito sirve para esconder tu saldo. Lo usaremos en un momento.';
        }
        break;
      case 'movimientos':
      case 'salir':
        if (resalta != accion) {
          _mensajeGuia = 'Muy bien explorando. Ahora toca lo que está brillando.';
        } else if (accion == 'movimientos') {
          _pantalla = 'movimientos';
          _explicacion = null;
        } else {
          _salio = true;
          _pantalla = 'clave';
          _claveEscrita = '';
          _explicacion = null;
        }
        break;
    }
  }

  void _tocarMovimientos(String accion, String? resalta) {
    if (accion != 'atras') return;
    if (resalta == 'atras') {
      _pantalla = 'inicio';
    } else {
      _mensajeGuia = 'Primero mira tus movimientos. En el siguiente paso volvemos.';
    }
  }

  // Que elemento brilla para guiarlo
  Set<String> get _resaltados {
    if (!_esSimulador || _objetivoCumplido) return <String>{};
    final objetivo = _paso['objetivo'];
    if (objetivo == 'entrar') {
      // Brilla el siguiente numero correcto, o borrar si se equivoco
      if (_clavePractica.startsWith(_claveEscrita) && _claveEscrita.length < 4) {
        return {_clavePractica[_claveEscrita.length]};
      }
      return {'⌫'};
    }
    if (objetivo == 'tocar_botones') {
      return _botonesPrincipales.where((b) => !_botonesTocados.contains(b)).toSet();
    }
    final r = _paso['resalta'] as String?;
    return r == null ? <String>{} : {r};
  }

  String get _textoBoton {
    if (_objetivoCumplido) {
      if (_pasoActual == _pasos.length - 1) return '¡Terminar!';
      return _esSimulador ? '¡Muy bien! Siguiente' : 'Siguiente';
    }
    if (_paso['objetivo'] == 'tocar_botones') {
      final faltan = _botonesPrincipales.length - _botonesTocados.length;
      return 'Te faltan $faltan ${faltan == 1 ? 'botón' : 'botones'}';
    }
    return (_paso['ayuda'] as String?) ?? 'Siguiente';
  }
    // Vuelve al paso anterior sin guardar nada
  void _retroceder() {
    if (_pasoActual == 0) return;
    FocusManager.instance.primaryFocus?.unfocus(); // esconde el teclado si estaba abierto
    setState(() {
      _pasoActual--;
      _prepararPaso();
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

  // ------------------------------------------------------------
  // CONSTRUCCION DE LA PANTALLA
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final consejo = _paso['consejo'] as String?;
    return Scaffold(
      backgroundColor: NequiColores.mnvFondo,
      appBar: AppBar(
        backgroundColor: NequiColores.mnvFondo,
        elevation: 0,
        foregroundColor: NequiColores.textoOscuro,
        title: const Text('Conociendo Nequi', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Expanded(child: Center(child: _buildIlustracion())),
                  const SizedBox(height: 10),
                  if (_mensajeGuia != null)
                    MensajeGuia(texto: _mensajeGuia!)
                  else if (_esSimulador && _objetivoCumplido)
                    const MensajeExito()
                  else if (consejo != null)
                    ConsejoCalido(texto: consejo),
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
    final vista = (_paso['vista'] as String?) ?? 'simulador';
    if (vista != 'simulador') return _buildEscena(vista);

    // FittedBox achica el celular si la pantalla es pequena
    return FittedBox(
      fit: BoxFit.contain,
      child: MarcoCelular(
        barraClara: _pantalla == 'escritorio' || _pantalla == 'clave',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          layoutBuilder: (actual, anteriores) => Stack(
            fit: StackFit.expand,
            children: [...anteriores, if (actual != null) actual],
          ),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_pantalla), child: _buildPantalla()),
        ),
      ),
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'clave':
        return NequiPantallaClave(
          nombre: _nombre,
          digitos: _claveEscrita.length,
          resaltados: _resaltados,
          onAccion: _tocarEnSimulador,
        );
      case 'inicio':
        return NequiInicio(
          nombre: _nombre,
          saldo: saldoPractica,
          saldoVisible: _saldoVisible,
          resaltados: _resaltados,
          tocados: _botonesTocados,
          explicacion: _explicacion,
          onAccion: _tocarEnSimulador,
        );
      case 'movimientos':
        return NequiMovimientos(resaltados: _resaltados, onAccion: _tocarEnSimulador);
      default:
        return NequiEscritorio(resaltados: _resaltados, onAccion: _tocarEnSimulador);
    }
  }

  // Escenas con emojis para los pasos de explicacion
  Widget _buildEscena(String vista) {
    Widget contenido;
    if (vista == 'billetera') {
      contenido = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('💵', style: TextStyle(fontSize: 64)),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded, size: 40, color: NequiColores.mnvMorado),
              SizedBox(width: 12),
              Text('📱', style: TextStyle(fontSize: 72)),
            ],
          ),
          const SizedBox(height: 20),
          _chip('Guarda, envía y recibe plata'),
        ],
      );
    } else if (vista == 'seguro') {
      contenido = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 90)),
          const SizedBox(height: 16),
          _chip('Plata de práctica: nada es real'),
        ],
      );
    } else {
      contenido = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              'Abrir Nequi',
              'Entrar con tu clave',
              'Ver y esconder el saldo',
              'Revisar movimientos',
              'Salir seguro',
            ].map(_chipLogro).toList(),
          ),
        ],
      );
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey(vista),
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: contenido,
    );
  }

  Widget _chip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: NequiColores.borde, width: 1.5),
      ),
      child: Text(texto,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
    );
  }

  Widget _chipLogro(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: NequiColores.mnvVerde.withOpacity(0.4), width: 1.5),
      ),
      child: FittedBox(fit: BoxFit.scaleDown, child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: NequiColores.mnvVerde, size: 18),
          const SizedBox(width: 6),
          Text(texto,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: NequiColores.textoOscuro)),
        ],
      )),
    );
  }
}