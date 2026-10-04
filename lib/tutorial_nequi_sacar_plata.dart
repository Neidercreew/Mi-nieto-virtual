import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'nequi_simulador.dart';

const String _leccionId = 'nequi_sacar_plata';

// Codigo de practica para el cajero
const String _codigoRetiro = '483920';
// Cada retiro tiene su propio codigo: este es para la tienda corresponsal
const String _codigoTienda = '715304';

// El usuario decide cuanto sacar. Este valor solo se usa si reanuda
const int _montoPorDefecto = 50000;

class TutorialNequiSacarPlataScreen extends StatefulWidget {
  final int pasoInicial; // para reanudar
  const TutorialNequiSacarPlataScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialNequiSacarPlataScreen> createState() => _TutorialNequiSacarPlataScreenState();
}

class _TutorialNequiSacarPlataScreenState extends State<TutorialNequiSacarPlataScreen> {
  int _pasoActual = 0;
  bool _guardando = false;
  String _pantalla = 'inicio'; // en que pantalla esta el simulador
  bool _objetivoCumplido = false;
  bool _exito = false; // muestra el mensaje verde
  String? _mensajeGuia;
  late ConfettiController _confettiController;

  String _nombre = 'Amigo';
  String _telefono = '3005551234';

  // Estado de la historia
  String _monto = '';
  String _numero = ''; // numero escrito en el cajero
  String _codigo = ''; // codigo escrito en el cajero
  String _codigoT = ''; // codigo escrito en el datafono de la tienda
  bool _retirado = false;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Sacar billetes de tu Nequi',
      'instruccion': 'Hoy vas a sacar plata de tu Nequi en un cajero automático. No necesitas tarjeta: solo tu celular.',
    },
    {
      'tipo': 'como',
      'titulo': '¿Cómo funciona?',
      'instruccion': 'Primero pides un código en Nequi. Luego, en el cajero, escribes tu número y ese código, y salen los billetes. Al final también verás cómo hacerlo en una tienda.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'inicio',
      'titulo': 'Toca "Saca"',
      'instruccion': 'Este es tu Nequi. Para sacar billetes, toca el botón "Saca" que está brillando.',
      'objetivo': 'saca',
      'ayuda': 'Toca "Saca" en el celular',
      'guia': 'Ese botón es para otra cosa. Busca "Saca", el que está brillando.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'donde',
      'titulo': '¿Dónde vas a sacar?',
      'instruccion': 'Nequi te pregunta dónde vas a recibir los billetes. Primero practicamos en el cajero: toca "Cajero automático".',
      'objetivo': 'cajero',
      'ayuda': 'Toca "Cajero automático"',
      'guia': 'Ese camino también sirve y lo practicaremos al final de la lección. Por ahora toca "Cajero automático".',
    },
    {
      'tipo': 'simulador',
      'inicio': 'valor',
      'titulo': '¿Cuánto vas a sacar?',
      'instruccion': 'Tú decides cuánta plata sacar. Como el cajero entrega billetes, escribe un valor redondo, como 20.000 o 50.000, y toca "Continuar".',
      'objetivo': 'monto_listo',
      'ayuda': 'Escribe el valor y toca "Continuar"',
      'guia': 'Primero escribe cuánta plata quieres sacar.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'revisar',
      'titulo': 'Revisa y pide tu código',
      'instruccion': 'Mira con calma el valor. Si está bien, toca "Generar código".',
      'objetivo': 'generar',
      'ayuda': 'Toca "Generar código"',
      'guia': 'Revisa el valor y toca el botón "Generar código", el que está brillando.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'codigo',
      'titulo': 'Este es tu código',
      'instruccion': 'Nequi te dio un código de 6 números: 483 920. Anótalo en un papel o apréndetelo. Cuando lo tengas, toca "Ya lo anoté".',
      'objetivo': 'anotado',
      'ayuda': 'Toca "Ya lo anoté"',
      'guia': 'Toca el botón "Ya lo anoté", abajo en el celular.',
    },
    {
      'tipo': 'superpoder',
      'titulo': 'Tu código es secreto',
      'instruccion': 'Ese código es como un billete: quien lo tenga puede sacar tu plata. Por eso no se lo muestras a nadie.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'cajero_menu',
      'titulo': 'Ya estás en el cajero',
      'instruccion': 'En la pantalla del cajero, toca la opción "Retiro con Nequi".',
      'objetivo': 'retiro',
      'ayuda': 'Toca "Retiro con Nequi"',
      'guia': 'Esa opción es para otra cosa. Busca "Retiro con Nequi", la que está brillando.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'cajero_numero',
      'titulo': 'Escribe tu número',
      'instruccion': 'El cajero te pide tu número de celular, el de tu Nequi: {telefono}. Escríbelo con el teclado del cajero.',
      'objetivo': 'numero_listo',
      'ayuda': 'Escribe tu número de celular',
      'guia': 'Ese número no va. Tranquilo: toca la tecla de borrar y sigue.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'cajero_codigo',
      'titulo': 'Escribe tu código',
      'instruccion': 'Ahora escribe el código que te dio Nequi: 4 8 3 9 2 0. Tápalo con la otra mano para que nadie lo vea.',
      'objetivo': 'codigo_listo',
      'ayuda': 'Escribe 483 920',
      'guia': 'Ese número no va. Tu código es 483 920. Toca la tecla de borrar y sigue.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'cajero_confirmar',
      'titulo': 'Confirma y recibe tus billetes',
      'instruccion': 'El cajero te muestra cuánto vas a sacar. Si está bien, toca "Confirmar" y recibe tus billetes.',
      'objetivo': 'confirmar',
      'ayuda': 'Toca "Confirmar"',
      'guia': 'Revisa el valor y toca "Confirmar", el que está brillando.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'inicio',
      'titulo': 'Mira tu saldo',
      'instruccion': 'Tu saldo bajó porque sacaste billetes. Ahora toca "Movimientos" para ver el retiro.',
      'objetivo': 'movimientos',
      'ayuda': 'Toca "Movimientos"',
      'guia': 'Busca la fila "Movimientos", la que está brillando.',
      'burbuja': true,
    },
    {
      'tipo': 'mirar',
      'inicio': 'movimientos',
      'titulo': 'Aquí quedó anotado',
      'instruccion': 'El primer movimiento es tu retiro en el cajero. Está en rojo con el signo menos porque es plata que salió.',
    },
    {
      'tipo': 'corresponsal',
      'titulo': 'También en la tienda del barrio',
      'instruccion': 'Si no tienes un cajero cerca, puedes sacar plata en una tienda corresponsal, con el mismo sistema de código.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'tienda_codigo',
      'titulo': 'Escribe tu código en el datáfono',
      'instruccion': 'Estás en la tienda de Don Pedro. Le dijiste "retiro con Nequi" y le diste tu número. Ahora escribe tú mismo tu código nuevo: 7 1 5 3 0 4.',
      'objetivo': 'codigo_tienda_listo',
      'ayuda': 'Escribe 715 304',
      'guia': 'Ese número no va. Tu código para la tienda es 715 304. Toca la tecla de borrar y sigue.',
    },
    {
      'tipo': 'consejos',
      'titulo': 'Tres consejos de oro',
      'instruccion': 'Antes de terminar, guarda estos consejos para cuando vayas al cajero de verdad.',
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste!',
      'instruccion': 'Ya sabes sacar billetes de tu Nequi sin tarjeta.',
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
    _cargarDatos();
    if (_paso['tipo'] == 'celebracion') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confettiController.play());
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final n = prefs.getString('nombre_usuario');
      if (n != null && n.trim().isNotEmpty) _nombre = n.trim().split(' ').first;
      final t = prefs.getString('telefono_usuario');
      if (t != null && t.length == 10) _telefono = t;
      // Si ya paso por el cajero, el numero queda escrito
      if (_pasoActual >= 10) _numero = _telefono;
    });
  }

  // Deja el simulador listo para el paso actual (sirve tambien al reanudar)
  void _prepararPaso() {
    _mensajeGuia = null;
    _exito = false;

    // Estado de la historia segun el paso
    if (_pasoActual < 5) {
      _monto = '';
    } else if (_monto.isEmpty) {
      _monto = '$_montoPorDefecto';
    }
    _numero = _pasoActual >= 10 ? _telefono : '';
    _codigo = _pasoActual >= 11 ? _codigoRetiro : '';
    _codigoT = _pasoActual >= 16 ? _codigoTienda : '';
    _retirado = _pasoActual >= 12;

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
        } else if (_valor % 10000 != 0) {
          _mensajeGuia = 'El cajero solo entrega billetes. Escribe un valor redondo, como 20.000 o 50.000.';
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

  // Teclado: el valor es libre; el numero y el codigo van guiados
  void _tocarTecla(String tecla) {
    if (!_esSimulador || _objetivoCumplido) return;
    final objetivo = _paso['objetivo'];
    setState(() {
      _mensajeGuia = null;
      if (objetivo == 'monto_listo') {
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
      } else if (objetivo == 'numero_listo') {
        _numero = _escribirGuiado(_numero, _telefono, tecla);
      } else if (objetivo == 'codigo_listo') {
        _codigo = _escribirGuiado(_codigo, _codigoRetiro, tecla);
      } else if (objetivo == 'codigo_tienda_listo') {
        _codigoT = _escribirGuiado(_codigoT, _codigoTienda, tecla);
      }
    });
  }

  // Escribe una tecla hacia una meta; avisa si se equivoca y logra al completar
  String _escribirGuiado(String actual, String meta, String tecla) {
    var nuevo = actual;
    if (tecla == '⌫') {
      if (nuevo.isNotEmpty) nuevo = nuevo.substring(0, nuevo.length - 1);
    } else if (nuevo.length < meta.length) {
      nuevo += tecla;
    }
    if (!meta.startsWith(nuevo)) _mensajeGuia = _paso['guia'] as String?;
    if (nuevo == meta) _lograr();
    return nuevo;
  }

  // Que tecla brilla: la siguiente correcta, o borrar si se equivoco
  Set<String> _teclasResaltadas(String meta, String actual) {
    if (_objetivoCumplido) return <String>{};
    if (!meta.startsWith(actual)) return {'⌫'};
    if (actual.length < meta.length) return {meta[actual.length]};
    return <String>{};
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

  // Convierte 3005551234 en "300 555 1234", aunque este a medias
  String _formatoTelefono(String t) {
    final b = StringBuffer();
    for (int i = 0; i < t.length; i++) {
      if (i == 3 || i == 6) b.write(' ');
      b.write(t[i]);
    }
    return b.toString();
  }

  // Convierte 483920 en "483 920", aunque este a medias
  String _formatoCodigo(String c) {
    if (c.length <= 3) return c;
    return '${c.substring(0, 3)} ${c.substring(3)}';
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
        title: const Text('Sacar plata', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    // {telefono} se cambia por el numero del usuario
                    instruccion: (_paso['instruccion'] as String)
                        .replaceAll('{telefono}', _formatoTelefono(_telefono)),
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
      case 'como':
        return _ilustracionComo();
      case 'superpoder':
        return _ilustracionSuperpoder();
      case 'corresponsal':
        return _ilustracionCorresponsal();
      case 'consejos':
        return _ilustracionConsejos();
      case 'celebracion':
        return _ilustracionCelebracion();
    }
    // La tienda corresponsal se ve fuera del celular
    if (_pantalla == 'tienda_codigo') {
      return Center(child: FittedBox(fit: BoxFit.scaleDown, child: _escenaTienda()));
    }
    // El cajero se ve fuera del celular
    if (_pantalla.startsWith('cajero')) {
      return Center(child: FittedBox(fit: BoxFit.scaleDown, child: _escenaCajero()));
    }
    // El celular se encoge si la pantalla es pequena
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: MarcoCelular(
          barraClara: _pantalla == 'codigo',
          child: _buildPantalla(),
        ),
      ),
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'donde':
        return _pantallaDonde();
      case 'valor':
        return _pantallaValor();
      case 'revisar':
        return _pantallaRevisar();
      case 'codigo':
        return _pantallaCodigo();
      case 'movimientos':
        return NequiMovimientos(
          resaltados: const {},
          onAccion: (_) {},
          movimientos: [
            NequiMovimiento('Retiro en cajero', -_valor, 'Hoy', Icons.local_atm_rounded),
            ...movimientosPractica,
          ],
        );
      default:
        return NequiInicio(
          nombre: _nombre,
          saldo: saldoPractica - (_retirado ? _valor : 0),
          saldoVisible: true,
          resaltados: _resalta('saca')
              ? {'saca'}
              : _resalta('movimientos')
                  ? {'movimientos'}
                  : <String>{},
          explicacion: _paso['burbuja'] == true
              ? 'Tenías ${formatoPesos(saldoPractica)}. Sacaste ${formatoPesos(_valor)}. '
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

  Widget _pantallaDonde() {
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezado('Saca plata'),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 14),
            child: Text('¿Dónde vas a sacar?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NequiColores.textoOscuro)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: NequiPulso(
              activo: _resalta('cajero'),
              radio: 18,
              escala: 1.05,
              child: _tarjetaOpcion('cajero', Icons.local_atm_rounded, 'Cajero automático',
                  'Sacas los billetes en un cajero, sin tarjeta'),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _tarjetaOpcion('corresponsal', Icons.storefront_rounded, 'Corresponsal o tienda',
                'Sacas los billetes en una tienda con el aviso de Nequi'),
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

  Widget _pantallaValor() {
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        children: [
          _encabezado('Saca plata'),
          const SizedBox(height: 6),
          const Text('¿Cuánto vas a sacar?',
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
          const SizedBox(height: 6),
          Text('Disponible: ${formatoPesos(saldoPractica)}',
              style: const TextStyle(fontSize: 12, color: NequiColores.textoSuave)),
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
          _encabezado('Revisa tu retiro'),
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
                  const Text('Vas a sacar', style: TextStyle(fontSize: 13, color: NequiColores.textoSuave)),
                  const SizedBox(height: 4),
                  Text(formatoPesos(_valor),
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold, color: NequiColores.magenta)),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_atm_rounded, color: NequiColores.textoSuave, size: 18),
                      SizedBox(width: 6),
                      Text('En un cajero, sin tarjeta',
                          style: TextStyle(fontSize: 13, color: NequiColores.textoSuave)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: _botonMagenta('generar', 'Generar código'),
          ),
        ],
      ),
    );
  }

  Widget _pantallaCodigo() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 46, 16, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [NequiColores.magenta, NequiColores.morado],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const Icon(Icons.local_atm_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                const Text('Tu código para el cajero',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Para sacar ${formatoPesos(_valor)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: NequiColores.rosaSuave,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NequiColores.magenta, width: 2),
              ),
              child: Text(_formatoCodigo(_codigoRetiro),
                  style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: NequiColores.magenta)),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, color: NequiColores.textoSuave, size: 18),
              SizedBox(width: 6),
              Text('Úsalo pronto: vence en un rato',
                  style: TextStyle(fontSize: 13, color: NequiColores.textoSuave)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: Text('No le muestres este código a nadie.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: NequiColores.mnvRojo)),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: _botonMagenta('anotado', 'Ya lo anoté'),
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

  // ------------------------------------------------------------
  // ESCENA DEL CAJERO (fuera del celular)
  // ------------------------------------------------------------

  Widget _escenaCajero() {
    final conTeclado = _pantalla == 'cajero_numero' || _pantalla == 'cajero_codigo';
    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A4A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.local_atm_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 6),
              Text('CAJERO AUTOMÁTICO',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 10),
          // Pantalla del cajero
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 170),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _pantallaCajero(),
          ),
          if (conTeclado) ...[
            const SizedBox(height: 12),
            NequiTeclado(
              resaltados: _pantalla == 'cajero_numero'
                  ? _teclasResaltadas(_telefono, _numero)
                  : _teclasResaltadas(_codigoRetiro, _codigo),
              onTecla: _tocarTecla,
            ),
          ],
          const SizedBox(height: 12),
          // Bandeja de los billetes
          _bandejaBilletes(),
        ],
      ),
    );
  }

  Widget _pantallaCajero() {
    switch (_pantalla) {
      case 'cajero_menu':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('¿Qué quieres hacer?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _opcionCajero('retiro', 'Retiro con Nequi'),
            _opcionCajero('tarjeta', 'Retiro con tarjeta'),
            _opcionCajero('consulta', 'Consultar saldo'),
          ],
        );
      case 'cajero_numero':
        return _pantallaCajeroDato('Escribe tu número de celular',
            _numero.isEmpty ? '' : _formatoTelefono(_numero));
      case 'cajero_codigo':
        // El codigo se muestra con puntos, como en un cajero de verdad
        return _pantallaCajeroDato('Escribe tu código de retiro', '● ' * _codigo.length);
      default:
        // Confirmar y entregar billetes
        return Column(
          children: [
            Text(_objetivoCumplido ? '¡Retira tu dinero!' : 'Vas a retirar',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(formatoPesos(_valor),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            if (!_objetivoCumplido)
              Row(
                children: [
                  Expanded(child: _botonCajero('cancelar', 'Cancelar', const Color(0xFF64748B))),
                  const SizedBox(width: 10),
                  Expanded(child: _botonCajero('confirmar', 'Confirmar', NequiColores.mnvVerde)),
                ],
              )
            else
              const Text('Cuenta tus billetes antes de irte',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        );
    }
  }

  Widget _pantallaCajeroDato(String titulo, String valor) {
    return Column(
      children: [
        Text(titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(valor.isEmpty ? ' ' : valor.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
        ),
      ],
    );
  }

  Widget _opcionCajero(String id, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NequiPulso(
        activo: id == 'retiro' && _resalta('retiro'),
        radio: 10,
        escala: 1.04,
        child: Material(
          color: Colors.white.withOpacity(id == 'retiro' && _objetivoCumplido ? 1 : 0.15),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _tocarEnSimulador(id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(texto,
                        style: TextStyle(
                            color: id == 'retiro' && _objetivoCumplido ? const Color(0xFF1E3A8A) : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: id == 'retiro' && _objetivoCumplido ? const Color(0xFF1E3A8A) : Colors.white70),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonCajero(String id, String texto, Color color) {
    return NequiPulso(
      activo: _resalta(id),
      radio: 10,
      escala: 1.06,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _tocarEnSimulador(id),
          child: SizedBox(
            height: 46,
            child: Center(
              child: Text(texto,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  // Ranura por donde salen los billetes
  Widget _bandejaBilletes() {
    final salen = _pantalla == 'cajero_confirmar' && _objetivoCumplido;
    return Column(
      children: [
        Container(
          width: 200,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF15151F),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          height: salen ? 46 : 0,
          child: salen
              ? const FittedBox(
                  child: Text('💵💵💵', style: TextStyle(fontSize: 34)),
                )
              : null,
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // ESCENA DE LA TIENDA CORRESPONSAL (fuera del celular)
  // ------------------------------------------------------------

  Widget _escenaTienda() {
    final listo = _objetivoCumplido;
    final dialogo = listo
        ? '¡Listo! Aquí tiene sus billetes. Cuéntelos antes de irse.'
        : 'Escriba usted mismo su código en el datáfono, que no lo vea nadie.';
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
          Row(
            children: [
              const Text('🏪', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Tienda Don Pedro',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: NequiColores.magenta,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Corresponsal',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tendero hablando
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
          // Datafono
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NequiColores.textoOscuro,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDEFE3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text('RETIRO NEQUI',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(formatoPesos(_valor),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Código: ${_codigoT.isEmpty ? '_ _ _ _ _ _' : ('● ' * _codigoT.length).trim()}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                NequiTeclado(
                  resaltados: _teclasResaltadas(_codigoTienda, _codigoT),
                  onTecla: _tocarTecla,
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            height: listo ? 50 : 0,
            child: listo
                ? const FittedBox(child: Text('💵💵💵', style: TextStyle(fontSize: 34)))
                : null,
          ),
        ],
      ),
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
          // FittedBox evita que se salga en pantallas angostas
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('📱', style: TextStyle(fontSize: 60)),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded, size: 40, color: NequiColores.mnvMorado),
              SizedBox(width: 12),
              Text('🏧', style: TextStyle(fontSize: 60)),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded, size: 40, color: NequiColores.mnvMorado),
              SizedBox(width: 12),
              Text('💵', style: TextStyle(fontSize: 56)),
            ],
          ),
          ),
          SizedBox(height: 28),
          ConsejoCalido(
            texto: 'Es útil cuando necesitas efectivo para el bus, la plaza o la tienda que no recibe Nequi.',
          ),
          SizedBox(height: 12),
          ConsejoCalido(
            texto: 'Todo lo que veas aquí es de práctica. Puedes equivocarte sin miedo.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionComo() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _pasoComo('1', '📱', 'Pides un código', 'En Nequi escribes cuánto vas a sacar y te da un código.'),
          _flechaAbajo(),
          _pasoComo('2', '🏧', 'Vas al cajero', 'Eliges "Retiro con Nequi" y escribes tu número y el código.'),
          _flechaAbajo(),
          _pasoComo('3', '💵', 'Recibes tus billetes', 'El cajero te entrega la plata y se descuenta de tu Nequi.'),
        ],
      ),
    );
  }

  Widget _pasoComo(String numero, String emoji, String titulo, String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NequiColores.borde, width: 1.5),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$numero. $titulo',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: NequiColores.mnvMorado)),
                const SizedBox(height: 2),
                Text(texto,
                    style: const TextStyle(fontSize: 13, color: NequiColores.textoOscuro, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _flechaAbajo() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Icon(Icons.arrow_downward_rounded, color: NequiColores.mnvMoradoSec, size: 24),
    );
  }

  Widget _ilustracionSuperpoder() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _tarjetaInfo('🔒', 'Nadie te pide tu código',
              'Ni Nequi, ni el banco, ni el vigilante. Si alguien te lo pide, es para robarte.',
              NequiColores.mnvRojo),
          const SizedBox(height: 12),
          _tarjetaInfo('🙅', 'No aceptes ayuda de extraños',
              'Si alguien en el cajero se ofrece a "ayudarte", dile que no, gracias. Mejor pide ayuda a alguien de confianza.',
              NequiColores.mnvAmarillo),
          const SizedBox(height: 16),
          const ConsejoCalido(
            texto: 'Al escribir el código en el cajero, tápalo con la otra mano.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionCorresponsal() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _pasoComo('1', '📱', 'Pides un código nuevo',
              'En Nequi tocas "Saca", eliges "Corresponsal o tienda" y te da un código.'),
          _flechaAbajo(),
          _pasoComo('2', '🏪', 'Vas a la tienda',
              'Busca una con el aviso de Nequi. Dile al tendero "retiro con Nequi" y dale tu número.'),
          _flechaAbajo(),
          _pasoComo('3', '🔢', 'Escribes tu código',
              'Tú mismo lo escribes en el datáfono, y el tendero te entrega los billetes.'),
          const SizedBox(height: 14),
          const ConsejoCalido(
            texto: 'Cada retiro tiene su propio código. Para esta práctica, Nequi te dio el 715 304.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionConsejos() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _tarjetaInfo('🏦', 'Usa cajeros en lugares seguros',
              'Mejor de día, dentro de un banco o un centro comercial.', NequiColores.mnvVerde),
          const SizedBox(height: 12),
          _tarjetaInfo('💵', 'Cuenta tus billetes',
              'Antes de irte, revisa que te dieron la plata completa y guárdala bien.', NequiColores.mnvAmarillo),
          const SizedBox(height: 12),
          _tarjetaInfo('🔒', 'Tu código es solo tuyo',
              'No lo compartas por mensaje ni por llamada. Quien lo tenga puede sacar tu plata.',
              NequiColores.mnvRojo),
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
          const Text('¡Ya sabes sacar plata sin tarjeta!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          const SizedBox(height: 20),
          _logro('Decidiste cuánto sacar'),
          _logro('Pediste tu código en Nequi'),
          _logro('Lo usaste en el cajero sin mostrárselo a nadie'),
          _logro('Recibiste tus billetes y viste tu saldo'),
          _logro('Practicaste el retiro en una tienda corresponsal'),
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