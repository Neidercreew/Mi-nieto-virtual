import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'nequi_simulador.dart';

const String _leccionId = 'nequi_meter_plata';

// El usuario decide cuanto meter. Este valor solo se usa si reanuda
const int _montoPorDefecto = 50000;
const int _montoMaximo = 500000; // tope para la practica

class TutorialNequiMeterPlataScreen extends StatefulWidget {
  final int pasoInicial; // para reanudar
  const TutorialNequiMeterPlataScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialNequiMeterPlataScreen> createState() => _TutorialNequiMeterPlataScreenState();
}

class _TutorialNequiMeterPlataScreenState extends State<TutorialNequiMeterPlataScreen> {
  int _pasoActual = 0;
  String _pantalla = 'inicio'; // en que pantalla esta el simulador
  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  bool _exito = false; // muestra el mensaje verde de "lo lograste"
  late ConfettiController _confettiController;

  // Datos del usuario
  String _nombre = 'Amigo';
  String _telefono = '3005551234';

  // Estado de la historia
  String _monto = ''; // lo que marca el cajero
  bool _plataRecibida = false;
  bool _saldoVisible = true;
  bool _mostrarNotificacion = false;
  Timer? _timerNotificacion;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Meter plata a tu Nequi',
      'instruccion': 'Hoy vas a aprender a poner billetes dentro de tu Nequi. Es más fácil de lo que parece.',
    },
    {
      'tipo': 'formas',
      'titulo': '¿Dónde meto la plata?',
      'instruccion': 'Puedes meter billetes en muchas tiendas y droguerías del barrio. Solo tienen que tener el aviso de Nequi.',
    },
    {
      'tipo': 'simulador',
      'titulo': 'Busca el botón "Recarga"',
      'instruccion': 'Este es tu Nequi. Tienes 250.000 pesos de práctica. Toca el botón "Recarga" que está brillando.',
      'inicio': 'inicio',
      'objetivo': 'opciones',
      'resalta': 'recarga',
      'ayuda': 'Toca "Recarga" en el celular',
      'guia': 'Ese botón es para otra cosa. Busca "Recarga", el que está brillando.',
    },
    {
      'tipo': 'simulador',
      'titulo': 'Elige "En efectivo"',
      'instruccion': 'Nequi te muestra cómo meter la plata. Vamos con billetes: toca "En efectivo".',
      'inicio': 'opciones',
      'objetivo': 'instrucciones',
      'resalta': 'efectivo',
      'ayuda': 'Toca "En efectivo"',
      'guia': 'Toca "En efectivo", el que está brillando.',
    },
    {
      'tipo': 'simulador',
      'titulo': 'Tu número es la llave',
      'instruccion': 'Para meter plata solo necesitas decirle al cajero tu número de celular. Cuando llegues a la tienda, toca el botón de abajo.',
      'inicio': 'instrucciones',
      'objetivo': 'tienda',
      'resalta': 'ir_tienda',
      'ayuda': 'Toca "Ya estoy en la tienda"',
      'guia': 'Toca el botón "Ya estoy en la tienda", abajo en el celular.',
    },
    {
      'tipo': 'simulador',
      'titulo': 'Dile cuánto vas a meter',
      'instruccion': 'Estás en la tienda y ya le diste tu número al cajero. Tú decides cuánta plata meter: márcala en el teclado y toca "Listo".',
      'inicio': 'tienda',
      'objetivo': 'monto_listo',
      'resalta': 'teclas',
      'ayuda': 'Marca el valor y toca "Listo"',
      'guia': 'Primero marca cuánta plata vas a meter y luego toca "Listo".',
    },
    {
      'tipo': 'simulador',
      'titulo': 'Revisa antes de confirmar',
      'instruccion': 'Mira con calma: ¿el número es el tuyo? ¿el valor es el que entregaste? Si todo está bien, toca "Sí, está bien".',
      'inicio': 'tienda_confirmar',
      'objetivo': 'entregado',
      'resalta': 'confirmar',
      'ayuda': 'Toca "Sí, está bien"',
      'guia': 'Los datos están bien esta vez. Si algo estuviera mal, ahí lo corriges. Toca "Sí, está bien".',
    },
    {
      'tipo': 'simulador',
      'titulo': '¡Llegó la notificación!',
      'instruccion': 'En unos segundos tu celular te avisa que la plata llegó. Toca el aviso de Nequi que aparece arriba.',
      'inicio': 'escritorio',
      'objetivo': 'inicio',
      'resalta': 'notificacion',
      'ayuda': 'Toca el aviso de Nequi',
      'guia': 'Toca mejor el aviso de arriba: te lleva directo a tu plata.',
    },
    {
      'tipo': 'simulador',
      'titulo': 'Mira tu nuevo saldo',
      'instruccion': 'Tu saldo está escondido. Toca el ojito para ver cuánta plata tienes ahora.',
      'inicio': 'inicio',
      'objetivo': 'saldo_visible',
      'resalta': 'ojo',
      'ayuda': 'Toca el ojito',
      'guia': 'Busca el ojito dentro de la tarjeta rosada, el que está brillando.',
      'burbujaFinal': true,
    },
    {
      'tipo': 'simulador',
      'titulo': 'Revisa tus movimientos',
      'instruccion': 'Aquí queda anotada cada plata que entra y sale. Toca "Movimientos".',
      'inicio': 'inicio',
      'objetivo': 'movimientos',
      'resalta': 'movimientos',
      'ayuda': 'Toca "Movimientos"',
      'guia': 'Busca la fila "Movimientos", la que está brillando.',
    },
    {
      'tipo': 'mirar',
      'titulo': 'Aquí está tu plata',
      'instruccion': 'El primer movimiento de la lista es la plata que acabas de meter. Tiene el signo + en verde porque es plata que entró.',
      'inicio': 'movimientos',
    },
    {
      'tipo': 'consejos',
      'titulo': 'Tres consejos de oro',
      'instruccion': 'Antes de terminar, guarda estos consejos para cuando lo hagas de verdad.',
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste!',
      'instruccion': 'Ya sabes meter plata a tu Nequi. Tu familia va a estar orgullosa.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _pasoActual = widget.pasoInicial.clamp(0, _pasos.length - 1); // .clamp evita RangeError
    _prepararPaso();
    _cargarDatos();
    if (_pasos[_pasoActual]['tipo'] == 'celebracion') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confettiController.play());
    }
  }

  @override
  void dispose() {
    _timerNotificacion?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nombre = prefs.getString('nombre_usuario') ?? _nombre;
      _telefono = prefs.getString('telefono_usuario') ?? _telefono;
    });
  }

  // Deja el simulador listo para el paso actual (sirve tambien al reanudar)
  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _exito = false;
    _timerNotificacion?.cancel();
    _mostrarNotificacion = false;

    // Estado de la historia segun el paso
    // Conserva el valor que marco; si reanuda, pone uno por defecto
    if (_pasoActual < 6) {
      _monto = '';
    } else if (_monto.isEmpty) {
      _monto = '$_montoPorDefecto';
    }
    _plataRecibida = _pasoActual >= 7;
    _saldoVisible = _pasoActual != 8; // en el paso 8 esta escondido

    // Paso para solo mirar una pantalla del celular
    if (paso['tipo'] == 'mirar') {
      _pantalla = paso['inicio'] as String;
      _objetivoCumplido = true;
      return;
    }

    if (paso['tipo'] != 'simulador') {
      _objetivoCumplido = true;
      return;
    }

    _objetivoCumplido = false;
    _pantalla = paso['inicio'] as String;

    // La notificacion llega un momento despues
    if (_pantalla == 'escritorio') {
      _timerNotificacion = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _mostrarNotificacion = true);
      });
    }
  }

  // El cerebro: decide que pasa con cada toque en el simulador
  void _tocarEnSimulador(String accion) {
    if (_objetivoCumplido) return;
    final paso = _pasos[_pasoActual];
    final objetivo = paso['objetivo'];
    final guia = paso['guia'] as String?;

    // Toque correcto en este paso
    final bool correcto;
    switch (_pantalla) {
      case 'inicio':
        correcto = accion == objetivo ||
            (accion == 'recarga' && objetivo == 'opciones') ||
            (accion == 'ojo' && objetivo == 'saldo_visible');
        break;
      case 'opciones':
        correcto = accion == 'efectivo';
        break;
      case 'instrucciones':
        correcto = accion == 'ir_tienda';
        break;
      case 'tienda':
        correcto = accion == 'listo_monto' && _valor > 0;
        break;
      case 'tienda_confirmar':
        correcto = accion == 'confirmar';
        break;
      case 'escritorio':
        correcto = accion == 'notificacion' && _mostrarNotificacion;
        break;
      default:
        correcto = false;
    }

    setState(() {
      _mensajeGuia = null;
      if (correcto) {
        // La pantalla NO cambia aqui: cambia cuando toque el boton verde
        _objetivoCumplido = true;
        _exito = true;
        // Resultados que si se ven en la misma pantalla
        if (accion == 'ojo') _saldoVisible = true;
        if (accion == 'confirmar') _pantalla = 'entregado';
      } else if (_pantalla == 'escritorio' && !_mostrarNotificacion) {
        _mensajeGuia = 'Espera un momentico, el aviso ya va a llegar.';
      } else {
        _mensajeGuia = guia;
      }
    });
  }

  // Teclado del cajero en la tienda: el usuario marca el valor que quiera
  void _tocarTeclaTienda(String tecla) {
    if (_objetivoCumplido) return;
    setState(() {
      _mensajeGuia = null;
      if (tecla == '⌫') {
        if (_monto.isNotEmpty) _monto = _monto.substring(0, _monto.length - 1);
      } else if (!(_monto.isEmpty && tecla == '0')) {
        final nuevo = _monto + tecla;
        if (int.parse(nuevo) > _montoMaximo) {
          _mensajeGuia = 'Para esta práctica, marca un valor de hasta ${formatoPesos(_montoMaximo)}.';
        } else {
          _monto = nuevo;
        }
      }
    });
  }

  // Valor que marco el usuario
  int get _valor => _monto.isEmpty ? 0 : int.parse(_monto);

  Set<String> get _resaltados {
    if (_objetivoCumplido) return {};
    final r = _pasos[_pasoActual]['resalta'] as String?;
    return r == null ? <String>{} : {r};
  }

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
    if (!_objetivoCumplido) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    final esUltimo = _pasoActual == _pasos.length - 1;
    if (userId != null) {
      await ApiService.guardarPaso(userId, _leccionId, _pasoActual + 1, completada: esUltimo);
    }
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
    if (_pasos[_pasoActual]['tipo'] == 'celebracion') _confettiController.play();
  }

  String _formatoTelefono(String t) {
    if (t.length != 10) return t;
    return '${t.substring(0, 3)} ${t.substring(3, 6)} ${t.substring(6)}';
  }

  // ------------------------------------------------------------
  // CONSTRUCCION DE LA PANTALLA
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_pasoActual];
    final esSimulador = paso['tipo'] == 'simulador';
    final esUltimo = _pasoActual == _pasos.length - 1;

    String textoBoton;
    if (esUltimo) {
      textoBoton = 'Terminar';
    } else if (esSimulador && !_objetivoCumplido) {
      textoBoton = paso['ayuda'] as String;
    } else if (esSimulador) {
      textoBoton = '¡Muy bien! Siguiente';
    } else {
      textoBoton = 'Siguiente';
    }

    return Scaffold(
      backgroundColor: NequiColores.mnvFondo,
      appBar: AppBar(
        backgroundColor: NequiColores.mnvFondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: NequiColores.textoOscuro),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Meter plata',
            style: TextStyle(color: NequiColores.textoOscuro, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
              child: Column(
                children: [
                  LeccionProgreso(paso: _pasoActual, total: _pasos.length),
                  const SizedBox(height: 12),
                  CajaInstruccion(
                    titulo: paso['titulo'] as String,
                    instruccion: paso['instruccion'] as String,
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildIlustracion()),
                  if (_mensajeGuia != null) ...[
                    const SizedBox(height: 10),
                    MensajeGuia(texto: _mensajeGuia!),
                  ],
                  if (_exito) ...[
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
                        child: BotonLeccion(texto: textoBoton, activo: _objetivoCumplido, onTap: _avanzar),
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
    switch (_pasos[_pasoActual]['tipo']) {
      case 'intro':
        return _ilustracionIntro();
      case 'formas':
        return _ilustracionFormas();
      case 'consejos':
        return _ilustracionConsejos();
      case 'celebracion':
        return _ilustracionCelebracion();
      default:
        // El simulador se encoge si la pantalla es pequena
        return Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: _buildSimulador()),
        );
    }
  }

  Widget _buildSimulador() {
    switch (_pantalla) {
      case 'opciones':
        return MarcoCelular(child: _pantallaOpciones());
      case 'instrucciones':
        return MarcoCelular(child: _pantallaInstrucciones());
      case 'tienda':
      case 'tienda_confirmar':
      case 'entregado':
        return _escenaTienda();
      case 'escritorio':
        return MarcoCelular(barraClara: true, child: _pantallaEscritorio());
      case 'movimientos':
        return MarcoCelular(
          child: NequiMovimientos(
            resaltados: const {},
            onAccion: (_) {},
            movimientos: [
              NequiMovimiento('Metiste plata en Tienda Don Pedro', _valor, 'Hoy', Icons.storefront_rounded),
              ...movimientosPractica,
            ],
          ),
        );
      default:
        final paso = _pasos[_pasoActual];
        return MarcoCelular(
          child: NequiInicio(
            nombre: _nombre,
            saldo: saldoPractica + (_plataRecibida ? _valor : 0),
            saldoVisible: _saldoVisible,
            resaltados: _resaltados,
            onAccion: _tocarEnSimulador,
            explicacion: _objetivoCumplido && paso['burbujaFinal'] == true
                ? 'Antes tenías ${formatoPesos(saldoPractica)}. Metiste ${formatoPesos(_valor)}. '
                    '¡Ahora tienes ${formatoPesos(saldoPractica + _valor)}!'
                : null,
          ),
        );
    }
  }

  // ------------------------------------------------------------
  // PANTALLAS DEL CELULAR
  // ------------------------------------------------------------

  Widget _encabezadoNequi(String titulo) {
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

  Widget _pantallaOpciones() {
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezadoNequi('Recarga tu Nequi'),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 14),
            child: Text('¿Cómo quieres meter la plata?',
                style: TextStyle(fontSize: 14, color: NequiColores.textoSuave)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: NequiPulso(
              activo: _resaltados.contains('efectivo'),
              radio: 18,
              escala: 1.05,
              child: _tarjetaOpcion('efectivo', Icons.payments_rounded, 'En efectivo',
                  'En una tienda o punto con el aviso de Nequi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaOpcion(String id, IconData icono, String titulo, String detalle) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _tocarEnSimulador(id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: NequiColores.rosaSuave,
                child: Icon(icono, color: NequiColores.magenta, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
                    const SizedBox(height: 2),
                    Text(detalle,
                        style: const TextStyle(fontSize: 12, color: NequiColores.textoSuave, height: 1.3)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: NequiColores.textoSuave),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pantallaInstrucciones() {
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        children: [
          _encabezadoNequi('En efectivo'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  // Tarjeta con el numero grande
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [NequiColores.magenta, NequiColores.morado],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text('Dile al cajero tu número:',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(_formatoTelefono(_telefono),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _pasoMini('1', 'Busca una tienda con el aviso de Nequi'),
                  _pasoMini('2', 'Dale tu número y los billetes'),
                  _pasoMini('3', 'Revisa los datos y espera el aviso'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NequiColores.mnvRojo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded, color: NequiColores.mnvRojo, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Nunca le digas tu clave al cajero.',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: NequiColores.mnvRojo)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 22),
            child: NequiPulso(
              activo: _resaltados.contains('ir_tienda'),
              radio: 16,
              escala: 1.05,
              child: Material(
                color: NequiColores.magenta,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _tocarEnSimulador('ir_tienda'),
                  child: const SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Center(
                      child: Text('Ya estoy en la tienda',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pasoMini(String numero, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: NequiColores.rosaSuave,
            child: Text(numero,
                style: const TextStyle(
                    color: NequiColores.magenta, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto,
                style: const TextStyle(fontSize: 13, color: NequiColores.textoOscuro, height: 1.3)),
          ),
        ],
      ),
    );
  }

  Widget _pantallaEscritorio() {
    final resaltar = _mostrarNotificacion && !_objetivoCumplido;
    return Stack(
      children: [
        Positioned.fill(
          child: NequiEscritorio(
            resaltados: const {},
            onAccion: (_) => _tocarEnSimulador('app'),
          ),
        ),
        // Aviso de Nequi que baja desde arriba
        AnimatedPositioned(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          top: _mostrarNotificacion ? 34 : -120,
          left: 10,
          right: 10,
          child: NequiPulso(
            activo: resaltar,
            radio: 18,
            escala: 1.05,
            child: GestureDetector(
              onTap: () => _tocarEnSimulador('notificacion'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)],
                ),
                child: Row(
                  children: [
                    const NequiLogo(tam: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nequi · ahora',
                              style: TextStyle(fontSize: 11, color: NequiColores.textoSuave)),
                          Text('Recibiste ${formatoPesos(_valor)}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
                          const Text('Metiste plata en Tienda Don Pedro',
                              style: TextStyle(fontSize: 11, color: NequiColores.textoSuave)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // ESCENA DE LA TIENDA (fuera del celular)
  // ------------------------------------------------------------

  Widget _escenaTienda() {
    String dialogo;
    if (_pantalla == 'tienda') {
      dialogo = '¡Buenas! Ya tengo su número. ¿Cuánto le va a meter a su Nequi?';
    } else if (_pantalla == 'tienda_confirmar') {
      dialogo = 'Mire la pantallita y dígame si todo está bien.';
    } else {
      dialogo = '¡Listo! Aquí tiene su recibo. Ya le debe llegar el aviso.';
    }

    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Letrero de la tienda
          Row(
            children: [
              const Text('🏪', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Tienda Don Pedro',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: NequiColores.magenta,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Nequi aquí',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Cajero hablando
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('👨🏽‍🦳', style: TextStyle(fontSize: 34)),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(dialogo),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NequiColores.mnvFondo,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(dialogo,
                        style: const TextStyle(fontSize: 14, color: NequiColores.textoOscuro, height: 1.35)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_pantalla == 'tienda') _cajaMonto(),
          if (_pantalla == 'tienda_confirmar') _pantallaConfirmar(),
          if (_pantalla == 'entregado') _recibo(),
        ],
      ),
    );
  }

  Widget _cajaMonto() {
    final valor = _valor;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: NequiColores.textoOscuro,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text('Para: ${_formatoTelefono(_telefono)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 4),
              Text(formatoPesos(valor),
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        NequiTeclado(resaltados: const {}, onTecla: _tocarTeclaTienda),
        const SizedBox(height: 12),
        Opacity(
          opacity: valor > 0 || _objetivoCumplido ? 1 : 0.5,
          child: NequiPulso(
            activo: valor > 0 && !_objetivoCumplido,
            radio: 14,
            escala: 1.05,
            child: Material(
              color: NequiColores.mnvVerde,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _tocarEnSimulador('listo_monto'),
                child: const SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Center(
                    child: Text('Listo',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pantallaConfirmar() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: NequiColores.mnvFondo,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NequiColores.borde, width: 1.5),
          ),
          child: Column(
            children: [
              const Text('Revisa antes de confirmar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
              const SizedBox(height: 10),
              _filaDato('Celular', _formatoTelefono(_telefono)),
              _filaDato('A nombre de', _nombre),
              _filaDato('Valor', formatoPesos(_valor)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _tocarEnSimulador('corregir'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  side: const BorderSide(color: NequiColores.textoSuave),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Corregir',
                    style: TextStyle(color: NequiColores.textoSuave, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NequiPulso(
                activo: _resaltados.contains('confirmar'),
                radio: 14,
                escala: 1.06,
                child: Material(
                  color: NequiColores.mnvVerde,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _tocarEnSimulador('confirmar'),
                    child: const SizedBox(
                      height: 50,
                      child: Center(
                        child: Text('Sí, está bien',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _filaDato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(etiqueta, style: const TextStyle(fontSize: 13, color: NequiColores.textoSuave)),
          const Spacer(),
          Text(valor,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
        ],
      ),
    );
  }

  Widget _recibo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NequiColores.mnvVerde.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NequiColores.mnvVerde, width: 1.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_rounded, color: NequiColores.mnvVerde, size: 36),
            const SizedBox(height: 6),
            const Text('Recibo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
            const SizedBox(height: 4),
            Text('${formatoPesos(_valor)} para ${_formatoTelefono(_telefono)}',
                style: const TextStyle(fontSize: 13, color: NequiColores.textoOscuro)),
            const SizedBox(height: 6),
            const Text('Guárdalo hasta ver la plata en tu Nequi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: NequiColores.textoSuave)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ILUSTRACIONES DE LOS PASOS SIN SIMULADOR
  // ------------------------------------------------------------

  Widget _ilustracionIntro() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('💵', style: TextStyle(fontSize: 64)),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded, size: 40, color: NequiColores.mnvMorado),
              SizedBox(width: 12),
              NequiLogo(tam: 80),
            ],
          ),
          const SizedBox(height: 28),
          const ConsejoCalido(
            texto: 'Meter plata a Nequi es como guardarla en una alcancía que llevas en el bolsillo. '
                'La plata sigue siendo tuya.',
          ),
          const SizedBox(height: 12),
          const ConsejoCalido(
            texto: 'Todo lo que veas aquí es de práctica. Puedes equivocarte sin miedo.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionFormas() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _tarjetaInfo('🏪', 'En la tienda del barrio',
              'Muchas tiendas, droguerías y misceláneas reciben plata para Nequi.',
              NequiColores.mnvVerde),
          const SizedBox(height: 12),
          _tarjetaInfo('🪧', 'Busca el aviso',
              'Si ves el aviso de Nequi en la puerta o en la caja, ahí te pueden ayudar.',
              NequiColores.mnvMoradoSec),
          const SizedBox(height: 16),
          const ConsejoCalido(
            texto: 'Solo necesitas dos cosas: tu número de celular y los billetes.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionConsejos() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _tarjetaInfo('🧾', 'Pide siempre el recibo',
              'Guárdalo hasta que veas la plata en tu Nequi.', NequiColores.mnvVerde),
          const SizedBox(height: 12),
          _tarjetaInfo('🔔', 'Espera el aviso',
              'No te vayas de la tienda hasta que llegue la notificación.', NequiColores.mnvAmarillo),
          const SizedBox(height: 12),
          _tarjetaInfo('🔒', 'Tu clave es solo tuya',
              'Al cajero solo le das tu número. NUNCA tu clave, ni aunque te la pida.', NequiColores.mnvRojo),
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
          const Text('¡Ya sabes meter plata a tu Nequi!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          const SizedBox(height: 20),
          _logro('Encontraste el botón Recarga'),
          _logro('Le diste tu número al cajero'),
          _logro('Revisaste los datos antes de confirmar'),
          _logro('Viste tu nuevo saldo y tus movimientos'),
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
                Text(titulo,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
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
            child: Text(texto,
                style: const TextStyle(fontSize: 15, color: NequiColores.textoOscuro)),
          ),
        ],
      ),
    );
  }
}