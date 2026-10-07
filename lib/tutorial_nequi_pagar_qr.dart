import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'nequi_simulador.dart';

const String _leccionId = 'nequi_pagar_qr';
const String _nombreTienda = 'Panadería La Espiga';

// El usuario decide cuanto pagar. Este valor solo se usa si reanuda
const int _montoPorDefecto = 8500;

class TutorialNequiPagarQrScreen extends StatefulWidget {
  final int pasoInicial; // para reanudar
  const TutorialNequiPagarQrScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialNequiPagarQrScreen> createState() => _TutorialNequiPagarQrScreenState();
}

class _TutorialNequiPagarQrScreenState extends State<TutorialNequiPagarQrScreen> {
  int _pasoActual = 0;
  bool _guardando = false;
  String _pantalla = 'inicio'; // en que pantalla esta el simulador
  bool _objetivoCumplido = false;
  bool _exito = false; // muestra el mensaje verde
  String? _mensajeGuia;
  late ConfettiController _confettiController;

  String _nombre = 'Amigo';

  // Estado de la historia
  String _monto = '';
  bool _pagado = false;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Pagar sin sacar billetes',
      'instruccion': 'Hoy vas a la Panadería La Espiga a comprar el algo. Vas a pagar con tu Nequi usando la cámara del celular.',
    },
    {
      'tipo': 'que_es',
      'titulo': '¿Qué es un QR?',
      'instruccion': 'Es un cuadrito lleno de puntos que las tiendas pegan en la caja. Tu celular lo lee y así sabe a quién le pagas.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'inicio',
      'titulo': 'Toca "Paga con QR"',
      'instruccion': 'Ya escogiste lo que vas a llevar y es hora de pagar. Abre tu Nequi y toca la fila "Paga con QR" que está brillando.',
      'objetivo': 'qr',
      'ayuda': 'Toca "Paga con QR"',
      'guia': 'Ese botón es para otra cosa. Busca "Paga con QR", el que está brillando.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'camara',
      'titulo': 'Lee el QR de la caja',
      'instruccion': 'Se abrió la cámara. Apunta al cuadrito QR pegado en la caja y tócalo para leerlo.',
      'objetivo': 'escanear',
      'ayuda': 'Toca el QR de la caja',
      'guia': 'Toca el cuadrito QR, el que está brillando dentro de la cámara.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'comercio',
      'titulo': '¿Sí es la panadería?',
      'instruccion': 'Nequi te muestra el nombre de la tienda a la que le vas a pagar. Léelo con calma. ¿Es donde estás comprando?',
      'objetivo': 'si_es',
      'ayuda': 'Toca "Sí, es aquí"',
      'guia': 'En la vida real, si el nombre no es el de la tienda, tocas "No es" y le preguntas a la cajera. Aquí sí es la panadería: toca "Sí, es aquí".',
    },
    {
      'tipo': 'superpoder',
      'titulo': 'Tu superpoder: revisar la tienda',
      'instruccion': 'Antes de pagar, mira siempre el nombre de la tienda. Si no coincide, no pagues.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'valor',
      'titulo': 'Escribe el valor de tu compra',
      'instruccion': 'La cajera te dice cuánto es tu compra. Escribe ese valor con el teclado y toca "Continuar".',
      'objetivo': 'monto_listo',
      'ayuda': 'Escribe el valor y toca "Continuar"',
      'guia': 'Primero escribe el valor de tu compra.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'revisar',
      'titulo': 'Revisa antes de pagar',
      'instruccion': 'Mira con calma: la tienda y el valor. Si todo está bien, toca "Pagar".',
      'objetivo': 'pagar',
      'ayuda': 'Toca "Pagar"',
      'guia': 'Revisa los datos y toca el botón "Pagar", el que está brillando.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'exito',
      'titulo': '¡Pago exitoso!',
      'instruccion': 'Listo, ya pagaste. Este es tu comprobante: muéstraselo a la cajera. Luego toca "Ir al inicio".',
      'objetivo': 'ir_inicio',
      'ayuda': 'Toca "Ir al inicio"',
      'guia': 'Toca el botón "Ir al inicio", abajo en el celular.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'inicio',
      'titulo': 'Mira tu saldo',
      'instruccion': 'Tu saldo bajó porque pagaste tu compra. Ahora toca "Movimientos" para ver el pago.',
      'objetivo': 'movimientos',
      'ayuda': 'Toca "Movimientos"',
      'guia': 'Busca la fila "Movimientos", la que está brillando.',
      'burbuja': true,
    },
    {
      'tipo': 'mirar',
      'inicio': 'movimientos',
      'titulo': 'Aquí quedó anotado',
      'instruccion': 'El primer movimiento es tu pago en la panadería. Está en rojo con el signo menos porque es plata que salió.',
    },
    {
      'tipo': 'consejos',
      'titulo': 'Tres consejos de oro',
      'instruccion': 'Antes de terminar, guarda estos consejos para cuando pagues de verdad.',
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste!',
      'instruccion': 'Ya sabes pagar con QR. La próxima vez que vayas a la tienda, puedes dejar los billetes en la casa.',
    },
  ];

  Map<String, dynamic> get _paso => _pasos[_pasoActual];
  bool get _esSimulador => _paso['tipo'] == 'simulador';

  int get _valor => _monto.isEmpty ? 0 : int.parse(_monto);

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

    // Estado de la historia segun el paso
    // Conserva el valor que escribio; si reanuda, pone uno por defecto
    if (_pasoActual < 7) {
      _monto = '';
    } else if (_monto.isEmpty) {
      _monto = '$_montoPorDefecto';
    }
    _pagado = _pasoActual >= 8;

    final tipo = _paso['tipo'];
    if (tipo == 'simulador' || tipo == 'mirar') {
      _pantalla = _paso['inicio'] as String;
    }
    _objetivoCumplido = !_esSimulador;
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
      if (objetivo == 'monto_listo' && accion == 'continuar_valor') {
        if (_valor == 0) {
          _mensajeGuia = _paso['guia'] as String?;
        } else {
          _lograr();
        }
      } else if (accion == objetivo) {
        _lograr();
      } else {
        _mensajeGuia = _paso['guia'] as String?;
      }
    });
  }

  // Teclado del valor: el usuario lo escribe
  void _tocarTecla(String tecla) {
    if (!_esSimulador || _objetivoCumplido || _paso['objetivo'] != 'monto_listo') return;
    setState(() {
      _mensajeGuia = null;
      if (tecla == '⌫') {
        if (_monto.isNotEmpty) _monto = _monto.substring(0, _monto.length - 1);
      } else if (!(_monto.isEmpty && tecla == '0')) {
        final nuevo = _monto + tecla;
        if (int.parse(nuevo) > saldoPractica) {
          _mensajeGuia = 'No te alcanza: tienes ${formatoPesos(saldoPractica)} de práctica. Prueba con menos.';
        } else {
          _monto = nuevo;
        }
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

  String get _textoBoton {
    if (_pasoActual == _pasos.length - 1) return '¡Terminar!';
    if (_esSimulador && !_objetivoCumplido) return _paso['ayuda'] as String;
    return _esSimulador ? '¡Muy bien! Siguiente' : 'Siguiente';
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
        title: const Text('Pagar con QR', style: TextStyle(fontWeight: FontWeight.bold)),
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
      case 'que_es':
        return _ilustracionQueEs();
      case 'superpoder':
        return _ilustracionSuperpoder();
      case 'consejos':
        return _ilustracionConsejos();
      case 'celebracion':
        return _ilustracionCelebracion();
    }
    // El celular se encoge si la pantalla es pequena
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: MarcoCelular(
          barraClara: _pantalla == 'camara',
          child: _buildPantalla(),
        ),
      ),
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'camara':
        return _pantallaCamara();
      case 'comercio':
        return _pantallaComercio();
      case 'valor':
        return _pantallaValor();
      case 'revisar':
        return _pantallaRevisar();
      case 'exito':
        return _pantallaExito();
      case 'movimientos':
        return NequiMovimientos(
          resaltados: const {},
          onAccion: (_) {},
          movimientos: [
            NequiMovimiento('Pago en $_nombreTienda', -_valor, 'Hoy', Icons.bakery_dining_rounded),
            ...movimientosPractica,
          ],
        );
      default:
        return NequiInicio(
          nombre: _nombre,
          saldo: saldoPractica - (_pagado ? _valor : 0),
          saldoVisible: true,
          resaltados: _resalta('qr')
              ? {'qr'}
              : _resalta('movimientos')
                  ? {'movimientos'}
                  : <String>{},
          explicacion: _paso['burbuja'] == true
              ? 'Tenías ${formatoPesos(saldoPractica)}. Pagaste ${formatoPesos(_valor)}. '
                  'Ahora tienes ${formatoPesos(saldoPractica - _valor)}.'
              : null,
          onAccion: _tocarEnSimulador,
        );
    }
  }

  // ------------------------------------------------------------
  // PANTALLAS DEL CELULAR
  // ------------------------------------------------------------

  Widget _encabezado(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 40, 16, 8),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _tocarEnSimulador('atras'),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_rounded, color: NequiColores.textoOscuro),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
        ],
      ),
    );
  }

  // Camara abierta apuntando a la caja de la panaderia
  Widget _pantallaCamara() {
    return Container(
      color: const Color(0xFF2A2A35),
      child: Column(
        children: [
          const SizedBox(height: 46),
          const Text('Apunta al código QR',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Ubícalo dentro del cuadro', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          // Visor con esquinas
          SizedBox(
            width: 230,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: CustomPaint(painter: _EsquinasPainter())),
                // Letrero de la caja con el QR
                NequiPulso(
                  activo: _resalta('escanear'),
                  radio: 16,
                  escala: 1.06,
                  child: GestureDetector(
                    onTap: () => _tocarEnSimulador('escanear'),
                    child: Container(
                      width: 170,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Paga aquí',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
                          const SizedBox(height: 8),
                          const SizedBox(width: 120, height: 120, child: CustomPaint(painter: _QrPainter())),
                          const SizedBox(height: 8),
                          Text(_nombreTienda,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, color: NequiColores.textoSuave)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_objetivoCumplido)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: NequiColores.mnvVerde,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('¡QR leído!',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(bottom: 30),
            child: Icon(Icons.flashlight_off_rounded, color: Colors.white70, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _pantallaComercio() {
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        children: [
          _encabezado('Paga con QR'),
          const Spacer(),
          const CircleAvatar(
            radius: 40,
            backgroundColor: NequiColores.rosaSuave,
            child: Icon(Icons.storefront_rounded, size: 40, color: NequiColores.magenta),
          ),
          const SizedBox(height: 14),
          const Text('Le vas a pagar a:', style: TextStyle(fontSize: 13, color: NequiColores.textoSuave)),
          const SizedBox(height: 4),
          const Text(_nombreTienda,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('¿Es la tienda donde estás comprando?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: NequiColores.textoOscuro)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: Row(
              children: [
                Expanded(child: _botonGris('no_es', 'No es')),
                const SizedBox(width: 10),
                Expanded(child: _botonMagenta('si_es', 'Sí, es aquí')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pantallaValor() {
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        children: [
          _encabezado('Paga con QR'),
          const SizedBox(height: 6),
          const Text('¿Cuánto vas a pagar?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NequiColores.textoOscuro)),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NequiColores.magenta.withOpacity(0.4), width: 1.5),
            ),
            child: Text(
              formatoPesos(_valor),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _monto.isEmpty ? 16 : 26,
                fontWeight: _monto.isEmpty ? FontWeight.w400 : FontWeight.bold,
                color: _monto.isEmpty ? NequiColores.textoSuave : NequiColores.textoOscuro,
              ),
            ),
          ),
          const Spacer(),
          NequiTeclado(resaltados: const {}, onTecla: _tocarTecla),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            child: Opacity(
              opacity: _valor > 0 || _objetivoCumplido ? 1 : 0.5,
              child: _botonMagenta('continuar_valor', 'Continuar', brilla: _valor > 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pantallaRevisar() {
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        children: [
          _encabezado('Revisa tu pago'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text(formatoPesos(_valor),
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold, color: NequiColores.magenta)),
                  const SizedBox(height: 12),
                  _filaDato('Tienda', _nombreTienda),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: _botonMagenta('pagar', 'Pagar'),
          ),
        ],
      ),
    );
  }

  Widget _filaDato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(fontSize: 13, color: NequiColores.textoSuave)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(valor,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          ),
        ],
      ),
    );
  }

  Widget _pantallaExito() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: NequiColores.mnvVerde, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
            ),
          ),
          const SizedBox(height: 18),
          const Text('¡Pago exitoso!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          const SizedBox(height: 8),
          Text(formatoPesos(_valor),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: NequiColores.magenta)),
          const SizedBox(height: 4),
          const Text('a $_nombreTienda', style: TextStyle(fontSize: 15, color: NequiColores.textoSuave)),
          const SizedBox(height: 14),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: NequiColores.rosaSuave,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('🧾 Muéstrale este comprobante a la cajera',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: NequiColores.textoOscuro)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: _botonMagenta('ir_inicio', 'Ir al inicio'),
          ),
        ],
      ),
    );
  }

  // Boton magenta del celular, brilla cuando es el objetivo
  Widget _botonMagenta(String id, String texto, {bool brilla = true}) {
    return NequiPulso(
      activo: _resalta(id) && brilla,
      radio: 14,
      escala: 1.06,
      child: Material(
        color: NequiColores.magenta,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _tocarEnSimulador(id),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: Center(
              child: Text(texto,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  // Boton gris de borde, para la opcion que no es
  Widget _botonGris(String id, String texto) {
    return OutlinedButton(
      onPressed: () => _tocarEnSimulador(id),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: NequiColores.textoSuave),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(texto,
          style: const TextStyle(color: NequiColores.textoSuave, fontSize: 15, fontWeight: FontWeight.bold)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🥐', style: TextStyle(fontSize: 56)),
              SizedBox(width: 12),
              Icon(Icons.add_rounded, size: 36, color: NequiColores.mnvMorado),
              SizedBox(width: 12),
              Text('📱', style: TextStyle(fontSize: 60)),
            ],
          ),
          SizedBox(height: 28),
          ConsejoCalido(
            texto: 'Pagar con QR es rápido: no necesitas billetes ni esperar las vueltas.',
          ),
          SizedBox(height: 12),
          ConsejoCalido(
            texto: 'Todo lo que veas aquí es de práctica. Puedes equivocarte sin miedo.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionQueEs() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NequiColores.borde, width: 1.5),
            ),
            child: const SizedBox(width: 140, height: 140, child: CustomPaint(painter: _QrPainter())),
          ),
          const SizedBox(height: 18),
          const ConsejoCalido(
            texto: 'Lo encuentras pegado en la caja de muchas tiendas, con un letrero que dice "Paga aquí".',
          ),
          const SizedBox(height: 12),
          const ConsejoCalido(
            texto: 'No tienes que entender los puntos: tu celular los lee por ti.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionSuperpoder() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _tarjetaInfo('✅', 'Sale el nombre de la tienda',
              'Estás en la panadería y sale "Panadería La Espiga". Puedes pagar tranquilo.',
              NequiColores.mnvVerde),
          const SizedBox(height: 12),
          _tarjetaInfo('🛑', 'Sale otro nombre, o el QR se ve raro',
              'Si el nombre no es el de la tienda, o el QR parece pegado encima de otro, NO pagues y pregúntale a la cajera.',
              NequiColores.mnvRojo),
          const SizedBox(height: 16),
          const ConsejoCalido(
            texto: 'Algunas personas pegan su propio QR encima del de la tienda para quedarse con la plata. Revisar el nombre te protege.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionConsejos() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _tarjetaInfo('🧾', 'Muestra el comprobante',
              'Enséñale a la cajera la pantalla de "Pago exitoso" antes de irte.', NequiColores.mnvVerde),
          const SizedBox(height: 12),
          _tarjetaInfo('👀', 'Revisa el nombre de la tienda',
              'Antes de pagar, confirma que el nombre es el de la tienda donde estás.', NequiColores.mnvAmarillo),
          const SizedBox(height: 12),
          _tarjetaInfo('🚫', 'Cuidado con los QR por WhatsApp',
              'Nunca escanees un QR que te manden por mensaje prometiendo premios o regalos.', NequiColores.mnvRojo),
        ],
      ),
    );
  }

  Widget _ilustracionCelebracion() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text('🎉', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 12),
          const Text('¡Ya sabes pagar con QR!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          const SizedBox(height: 20),
          _logro('Escribiste el valor de tu compra'),
          _logro('Leíste el QR con la cámara'),
          _logro('Revisaste el nombre de la tienda'),
          _logro('Pagaste y viste el comprobante'),
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

// ------------------------------------------------------------
// DIBUJOS: un QR de mentiras y las esquinas del visor
// ------------------------------------------------------------

// Dibuja un QR de practica (no se puede leer de verdad)
class _QrPainter extends CustomPainter {
  const _QrPainter();

  static const int _n = 21; // cuadritos por lado

  @override
  void paint(Canvas canvas, Size size) {
    final celda = size.width / _n;
    final negro = Paint()..color = const Color(0xFF1A1A2E);
    final random = Random(7); // siempre el mismo dibujo

    // Cuadritos al azar, menos en las esquinas grandes
    for (int f = 0; f < _n; f++) {
      for (int c = 0; c < _n; c++) {
        if (_esEsquina(f, c)) continue;
        if (random.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(c * celda, f * celda, celda, celda), negro);
        }
      }
    }
    // Las tres esquinas grandes que tienen todos los QR
    _cuadroEsquina(canvas, 0, 0, celda, negro);
    _cuadroEsquina(canvas, 0, _n - 7, celda, negro);
    _cuadroEsquina(canvas, _n - 7, 0, celda, negro);
  }

  bool _esEsquina(int f, int c) =>
      (f < 8 && c < 8) || (f < 8 && c >= _n - 8) || (f >= _n - 8 && c < 8);

  void _cuadroEsquina(Canvas canvas, int f, int c, double celda, Paint negro) {
    final blanco = Paint()..color = Colors.white;
    final x = c * celda;
    final y = f * celda;
    canvas.drawRect(Rect.fromLTWH(x, y, celda * 7, celda * 7), negro);
    canvas.drawRect(Rect.fromLTWH(x + celda, y + celda, celda * 5, celda * 5), blanco);
    canvas.drawRect(Rect.fromLTWH(x + celda * 2, y + celda * 2, celda * 3, celda * 3), negro);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Esquinas blancas del visor de la camara
class _EsquinasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 30.0;
    final w = size.width;
    final h = size.height;
    // Arriba izquierda, arriba derecha, abajo izquierda, abajo derecha
    canvas.drawLine(const Offset(0, 0), const Offset(l, 0), p);
    canvas.drawLine(const Offset(0, 0), const Offset(0, l), p);
    canvas.drawLine(Offset(w, 0), Offset(w - l, 0), p);
    canvas.drawLine(Offset(w, 0), Offset(w, l), p);
    canvas.drawLine(Offset(0, h), Offset(l, h), p);
    canvas.drawLine(Offset(0, h), Offset(0, h - l), p);
    canvas.drawLine(Offset(w, h), Offset(w - l, h), p);
    canvas.drawLine(Offset(w, h), Offset(w, h - l), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}