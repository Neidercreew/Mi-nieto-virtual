import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'nequi_simulador.dart';

const String _leccionId = 'nequi_pedir_plata';

// Datos de practica: Gloria, la vecina, devuelve lo del mercado
const String _numeroGloria = '3105551122';
const String _nombreGloria = 'Gloria Rojas';
// El usuario decide cuanto pedir. Estos valores solo se usan si reanuda o como tope
const int _montoPorDefecto = 15000;
const int _montoMaximo = 500000;
const String _mensajePorDefecto = 'Lo del mercado';

// Contactos guardados de practica (los mismos de Enviar plata)
const List<Map<String, String>> _contactos = [
  {'id': 'andres', 'nombre': 'Andrés Gómez', 'detalle': 'Tu nieto', 'numero': '3205557788'},
  {'id': 'gloria', 'nombre': 'Gloria Rojas', 'detalle': 'Vecina', 'numero': _numeroGloria},
  {'id': 'maria', 'nombre': 'María López', 'detalle': 'Amiga', 'numero': '3005551234'},
];

class TutorialNequiPedirPlataScreen extends StatefulWidget {
  final int pasoInicial; // para reanudar
  const TutorialNequiPedirPlataScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialNequiPedirPlataScreen> createState() => _TutorialNequiPedirPlataScreenState();
}

class _TutorialNequiPedirPlataScreenState extends State<TutorialNequiPedirPlataScreen> {
  int _pasoActual = 0;
  bool _guardando = false;
  String _pantalla = 'inicio'; // en que pantalla esta el simulador
  bool _objetivoCumplido = false;
  bool _exito = false; // muestra el mensaje verde
  String? _mensajeGuia;
  late ConfettiController _confettiController;

  String _nombre = 'Amigo';

  // Estado de la historia
  String _numero = '';
  String _monto = '';
  String? _mensaje;
  bool _pagado = false; // Gloria ya pago
  bool _verContactos = false; // lista de contactos abierta en el paso del numero
  bool _mostrarNotificacion = false;
  Timer? _timerNotificacion;
  final TextEditingController _mensajeController = TextEditingController();

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Pedir plata por Nequi',
      'instruccion': 'Le prestaste plata a Gloria, tu vecina, para el mercado. Ella te dijo: "Mándame la solicitud por Nequi y te pago".',
    },
    {
      'tipo': 'como',
      'titulo': '¿Cómo funciona?',
      'instruccion': 'Tú le pides la plata, a Gloria le llega un aviso y ella decide pagar. Tu plata no se mueve para nada.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'inicio',
      'titulo': 'Toca "Pide"',
      'instruccion': 'Este es tu Nequi. Para pedirle plata a alguien, toca el botón "Pide" que está brillando.',
      'objetivo': 'pide',
      'ayuda': 'Toca "Pide" en el celular',
      'guia': 'Ese botón es para otra cosa. Busca "Pide", el que está brillando.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'numero',
      'titulo': '¿A quién le pides?',
      'instruccion': 'Escribe el número de Gloria (310 555 1122) o búscala en tus contactos guardados. Elige el camino que prefieras.',
      'objetivo': 'numero_listo',
      'ayuda': 'Escribe el número o busca a Gloria',
      'guia': 'Ese número no va. Tranquilo: toca la tecla de borrar y sigue.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'destinatario',
      'titulo': '¿Sí es Gloria?',
      'instruccion': 'Nequi te muestra el nombre del dueño de ese número. Léelo con calma. ¿Es tu vecina? Toca "Sí, es ella".',
      'objetivo': 'si_es',
      'ayuda': 'Toca "Sí, es ella"',
      'guia': 'En la vida real, si el nombre no es el que esperas, tocas "No es" y no sigues. Aquí sí es Gloria: toca "Sí, es ella".',
    },
    {
      'tipo': 'simulador',
      'inicio': 'valor',
      'titulo': '¿Cuánto le pides?',
      'instruccion': 'Tú decides cuánto pedirle a Gloria: lo que le prestaste. Escribe el valor con el teclado y toca "Continuar".',
      'objetivo': 'monto_listo',
      'ayuda': 'Escribe el valor y toca "Continuar"',
      'guia': 'Primero escribe cuánta plata le quieres pedir.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'mensaje',
      'titulo': 'Dile para qué es',
      'instruccion': 'Un mensajito ayuda a que Gloria recuerde de qué es la plata. Toca la cajita blanca, escribe y luego toca "Listo".',
      'objetivo': 'mensaje_listo',
      'ayuda': 'Escribe tu mensaje y toca "Listo"',
      'guia': 'Primero escribe tu mensaje en la cajita blanca. Si no se te ocurre nada, mira las ideas.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'revisar',
      'titulo': 'Revisa antes de pedir',
      'instruccion': 'Mira todo con calma: nombre, número y valor. Si todo está bien, toca "Pedir".',
      'objetivo': 'pedir',
      'ayuda': 'Toca "Pedir"',
      'guia': 'Revisa los datos y toca el botón "Pedir", el que está brillando.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'enviada',
      'titulo': 'Solicitud enviada',
      'instruccion': 'Listo, a Gloria ya le llegó tu solicitud. Ahora hay que esperar a que ella pague. Toca "Entendido".',
      'objetivo': 'entendido',
      'ayuda': 'Toca "Entendido"',
      'guia': 'Toca el botón "Entendido", abajo en el celular.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'escritorio',
      'titulo': '¡Gloria te pagó!',
      'instruccion': 'Un rato después, tu celular te avisa que Gloria pagó. Toca el aviso de Nequi que aparece arriba.',
      'objetivo': 'notificacion',
      'ayuda': 'Toca el aviso de Nequi',
      'guia': 'Toca mejor el aviso de arriba: te lleva directo a tu plata.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'inicio',
      'titulo': 'Mira tu saldo',
      'instruccion': 'Tu saldo subió porque Gloria te pagó. Ahora toca "Movimientos" para ver el pago.',
      'objetivo': 'movimientos',
      'ayuda': 'Toca "Movimientos"',
      'guia': 'Busca la fila "Movimientos", la que está brillando.',
      'burbuja': true,
    },
    {
      'tipo': 'mirar',
      'inicio': 'movimientos',
      'titulo': 'Aquí quedó anotado',
      'instruccion': 'El primer movimiento es el pago de Gloria. Está en verde con el signo + porque es plata que entró.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'extrana',
      'titulo': '¡Cuidado al revés!',
      'instruccion': 'A ti también te pueden pedir plata. Si te llega una solicitud que no esperabas o de alguien que no conoces, NO la pagues. Toca "Rechazar".',
      'objetivo': 'rechazar',
      'ayuda': 'Toca "Rechazar"',
      'guia': '¡Espera! No conoces a esta persona y no esperabas este cobro. Pagarlo es regalar tu plata. Toca "Rechazar".',
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste!',
      'instruccion': 'Ya sabes pedir plata por Nequi y también sabes decir que no a un cobro sospechoso.',
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
    _timerNotificacion?.cancel();
    _mensajeController.dispose();
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
    _verContactos = false;
    _timerNotificacion?.cancel();
    _mostrarNotificacion = false;

    // Estado de la historia segun el paso
    _numero = _pasoActual >= 4 ? _numeroGloria : '';
    // Conserva el valor que escribio; si reanuda, pone uno por defecto
    if (_pasoActual < 6) {
      _monto = '';
    } else if (_monto.isEmpty) {
      _monto = '$_montoPorDefecto';
    }
    // Conserva el mensaje que escribio; si reanuda, pone uno por defecto
    if (_pasoActual >= 7) {
      _mensaje ??= _mensajePorDefecto;
    } else {
      _mensaje = null;
    }
    _pagado = _pasoActual >= 10;

    final tipo = _paso['tipo'];
    if (tipo == 'simulador' || tipo == 'mirar') {
      _pantalla = _paso['inicio'] as String;
    }
    _objetivoCumplido = !_esSimulador;

    // El aviso de pago llega un momento despues
    if (_pantalla == 'escritorio' && _esSimulador) {
      _timerNotificacion = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _mostrarNotificacion = true);
      });
    }
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
      if (objetivo == 'numero_listo' && accion == 'abrir_contactos') {
        _verContactos = true;
      } else if (objetivo == 'numero_listo' && _verContactos && accion == 'atras') {
        _verContactos = false;
      } else if (objetivo == 'numero_listo' && accion.startsWith('contacto_')) {
        if (accion == 'contacto_gloria') {
          // Eligio a Gloria: el numero queda escrito solo
          _numero = _numeroGloria;
          _verContactos = false;
          _lograr();
        } else {
          _mensajeGuia = 'Ese contacto es de otra persona. Hoy le pedimos a Gloria, tu vecina.';
        }
      } else if (accion == 'mensaje_listo' && objetivo == 'mensaje_listo') {
        // Solo avanza si escribio algo
        final texto = _mensajeController.text.trim();
        if (texto.isEmpty) {
          _mensajeGuia = _paso['guia'] as String?;
        } else {
          _mensaje = texto;
          FocusManager.instance.primaryFocus?.unfocus(); // esconde el teclado
          _lograr();
        }
      } else if (objetivo == 'notificacion' && !_mostrarNotificacion) {
        _mensajeGuia = 'Espera un momentico, el aviso ya va a llegar.';
      } else if (objetivo == 'monto_listo' && accion == 'continuar_valor') {
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

  // Teclado: el numero va guiado, el valor lo decide el usuario
  void _tocarTecla(String tecla) {
    if (!_esSimulador || _objetivoCumplido) return;
    final objetivo = _paso['objetivo'];
    if (objetivo == 'numero_listo') {
      setState(() {
        _mensajeGuia = null;
        var nuevo = _numero;
        if (tecla == '⌫') {
          if (nuevo.isNotEmpty) nuevo = nuevo.substring(0, nuevo.length - 1);
        } else if (nuevo.length < _numeroGloria.length) {
          nuevo += tecla;
        }
        if (!_numeroGloria.startsWith(nuevo)) _mensajeGuia = _paso['guia'] as String?;
        _numero = nuevo;
        if (nuevo == _numeroGloria) _lograr();
      });
    } else if (objetivo == 'monto_listo') {
      setState(() {
        _mensajeGuia = null;
        if (tecla == '⌫') {
          if (_monto.isNotEmpty) _monto = _monto.substring(0, _monto.length - 1);
        } else if (!(_monto.isEmpty && tecla == '0')) {
          final nuevo = _monto + tecla;
          if (int.parse(nuevo) > _montoMaximo) {
            _mensajeGuia = 'Para esta práctica, pide un valor de hasta \$ 500.000.';
          } else {
            _monto = nuevo;
          }
        }
      });
    }
  }

  // Valor que escribio el usuario
  int get _valor => _monto.isEmpty ? 0 : int.parse(_monto);

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
    FocusManager.instance.primaryFocus?.unfocus(); // esconde el teclado si estaba abierto
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

  // Convierte 3105551122 en "310 555 1122", aunque este a medias
  String _formatoTelefono(String t) {
    final b = StringBuffer();
    for (int i = 0; i < t.length; i++) {
      if (i == 3 || i == 6) b.write(' ');
      b.write(t[i]);
    }
    return b.toString();
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
        title: const Text('Pedir plata', style: TextStyle(fontWeight: FontWeight.bold)),
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
      case 'como':
        return _ilustracionComo();
      case 'celebracion':
        return _ilustracionCelebracion();
      default:
        // El celular se encoge si la pantalla es pequena
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: MarcoCelular(
              barraClara: _pantalla == 'escritorio',
              child: _buildPantalla(),
            ),
          ),
        );
    }
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'numero':
        if (_verContactos) return _pantallaContactos();
        return _pantallaTeclado(
          titulo: 'Pide plata',
          pregunta: '¿A qué número le pides?',
          valor: _numero.isEmpty ? 'Número de celular' : _formatoTelefono(_numero),
          vacio: _numero.isEmpty,
          resaltados: _teclasResaltadas(_numeroGloria, _numero),
          extra: _botonContactos(),
        );
      case 'destinatario':
        return _pantallaDestinatario();
      case 'valor':
        return _pantallaTeclado(
          titulo: 'Pide plata',
          pregunta: '¿Cuánto le pides a Gloria?',
          valor: formatoPesos(_valor),
          vacio: _monto.isEmpty,
          resaltados: const {},
          boton: Opacity(
            opacity: _valor > 0 || _objetivoCumplido ? 1 : 0.5,
            child: _botonMagenta('continuar_valor', 'Continuar', brilla: _valor > 0),
          ),
        );
      case 'mensaje':
        return _pantallaMensaje();
      case 'revisar':
        return _pantallaRevisar();
      case 'enviada':
        return _pantallaEnviada();
      case 'escritorio':
        return _pantallaEscritorio();
      case 'extrana':
        return _pantallaSolicitudExtrana();
      case 'movimientos':
        return NequiMovimientos(
          resaltados: const {},
          onAccion: (_) {},
          movimientos: [
            NequiMovimiento('Gloria Rojas te pagó', _valor, 'Hoy', Icons.call_received_rounded),
            ...movimientosPractica,
          ],
        );
      default:
        return NequiInicio(
          nombre: _nombre,
          saldo: saldoPractica + (_pagado ? _valor : 0),
          saldoVisible: true,
          resaltados: _resalta('pide')
              ? {'pide'}
              : _resalta('movimientos')
                  ? {'movimientos'}
                  : <String>{},
          explicacion: _paso['burbuja'] == true
              ? 'Tenías ${formatoPesos(saldoPractica)}. Gloria te pagó ${formatoPesos(_valor)}. '
                  'Ahora tienes ${formatoPesos(saldoPractica + _valor)}.'
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

  // Pantalla con teclado: numero de celular o valor
  Widget _pantallaTeclado({
    required String titulo,
    required String pregunta,
    required String valor,
    required bool vacio,
    required Set<String> resaltados,
    Widget? extra,
    Widget? boton,
  }) {
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        children: [
          _encabezado(titulo),
          const SizedBox(height: 6),
          Text(pregunta,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NequiColores.textoOscuro)),
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
              valor,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: vacio ? 16 : 26,
                fontWeight: vacio ? FontWeight.w400 : FontWeight.bold,
                color: vacio ? NequiColores.textoSuave : NequiColores.textoOscuro,
              ),
            ),
          ),
          if (extra != null) ...[
            const SizedBox(height: 10),
            extra,
          ],
          const Spacer(),
          NequiTeclado(resaltados: resaltados, onTecla: _tocarTecla),
          if (boton != null)
            Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), child: boton)
          else
            const SizedBox(height: 18),
        ],
      ),
    );
  }

  // Boton para buscar en los contactos guardados
  Widget _botonContactos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: NequiPulso(
        activo: _resalta('numero_listo') && _numero.isEmpty,
        radio: 14,
        escala: 1.04,
        child: Material(
          color: NequiColores.rosaSuave,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _tocarEnSimulador('abrir_contactos'),
            child: const SizedBox(
              width: double.infinity,
              height: 42,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.contacts_rounded, color: NequiColores.magenta, size: 20),
                  SizedBox(width: 8),
                  Text('Buscar en mis contactos',
                      style: TextStyle(color: NequiColores.magenta, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pantallaContactos() {
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezado('Mis contactos'),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: Text('Toca a la persona a la que le quieres pedir',
                style: TextStyle(fontSize: 13, color: NequiColores.textoSuave)),
          ),
          for (final c in _contactos)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: _filaContacto(c),
            ),
        ],
      ),
    );
  }

  Widget _filaContacto(Map<String, String> c) {
    final esGloria = c['id'] == 'gloria';
    final nombre = c['nombre']!;
    return NequiPulso(
      activo: esGloria && _resalta('numero_listo'),
      radio: 16,
      escala: 1.04,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _tocarEnSimulador('contacto_${c['id']}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: NequiColores.rosaSuave,
                  child: Text(nombre[0],
                      style: const TextStyle(color: NequiColores.magenta, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
                      Text('${c['detalle']} · ${_formatoTelefono(c['numero']!)}',
                          style: const TextStyle(fontSize: 12, color: NequiColores.textoSuave)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: NequiColores.textoSuave),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pantallaDestinatario() {
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        children: [
          _encabezado('Pide plata'),
          const Spacer(),
          const CircleAvatar(
            radius: 40,
            backgroundColor: NequiColores.rosaSuave,
            child: Text('G',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: NequiColores.magenta)),
          ),
          const SizedBox(height: 14),
          const Text('Le vas a pedir a:', style: TextStyle(fontSize: 13, color: NequiColores.textoSuave)),
          const SizedBox(height: 4),
          const Text(_nombreGloria,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          const SizedBox(height: 4),
          Text(_formatoTelefono(_numeroGloria),
              style: const TextStyle(fontSize: 15, color: NequiColores.textoSuave)),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('¿Es la persona a la que le quieres pedir?',
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
                Expanded(child: _botonMagenta('si_es', 'Sí, es ella')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pantallaMensaje() {
    final hayTexto = _mensajeController.text.trim().isNotEmpty;
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezado('Pide plata'),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 10),
            child: Text('Escribe un mensaje para Gloria',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NequiColores.textoOscuro)),
          ),
          // Cajita donde escribe el usuario
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: NequiPulso(
              activo: _resalta('mensaje_listo') && !hayTexto,
              radio: 16,
              escala: 1.03,
              child: TextField(
                controller: _mensajeController,
                enabled: !_objetivoCumplido,
                maxLength: 40,
                maxLines: 2,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() => _mensajeGuia = null),
                style: const TextStyle(fontSize: 16, color: NequiColores.textoOscuro),
                decoration: InputDecoration(
                  hintText: 'Toca aquí para escribir',
                  hintStyle: const TextStyle(color: NequiColores.textoSuave),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: NequiColores.magenta.withOpacity(0.4), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: NequiColores.magenta.withOpacity(0.4), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: NequiColores.magenta, width: 2),
                  ),
                ),
              ),
            ),
          ),
          // Ideas de que escribir (solo se leen, el usuario escribe)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NequiColores.rosaSuave,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 Ideas para escribir:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: NequiColores.magenta)),
                  SizedBox(height: 6),
                  Text('• Lo del mercado', style: TextStyle(fontSize: 13, color: NequiColores.textoOscuro)),
                  Text('• Gracias, vecina', style: TextStyle(fontSize: 13, color: NequiColores.textoOscuro)),
                  Text('• Lo que te presté', style: TextStyle(fontSize: 13, color: NequiColores.textoOscuro)),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: Opacity(
              opacity: hayTexto || _objetivoCumplido ? 1 : 0.5,
              child: _botonMagenta('mensaje_listo', 'Listo', brilla: hayTexto),
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
          _encabezado('Revisa tu solicitud'),
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
                  _filaDato('Le pides a', _nombreGloria),
                  _filaDato('Celular', _formatoTelefono(_numeroGloria)),
                  _filaDato('Mensaje', _mensaje ?? 'Sin mensaje'),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: _botonMagenta('pedir', 'Pedir'),
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

  // Comprobante: la solicitud quedo esperando a Gloria
  Widget _pantallaEnviada() {
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
              decoration: const BoxDecoration(color: NequiColores.mnvAmarillo, shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 54),
            ),
          ),
          const SizedBox(height: 18),
          const Text('¡Solicitud enviada!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          const SizedBox(height: 8),
          Text(formatoPesos(_valor),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: NequiColores.magenta)),
          const SizedBox(height: 4),
          const Text('a $_nombreGloria', style: TextStyle(fontSize: 15, color: NequiColores.textoSuave)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: NequiColores.mnvAmarillo.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('⏳ Esperando a que Gloria pague',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NequiColores.textoConsejo)),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Tu plata no se ha movido. Te avisaremos cuando ella pague.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: NequiColores.textoSuave, height: 1.35)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: _botonMagenta('entendido', 'Entendido'),
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
          top: _mostrarNotificacion || _objetivoCumplido ? 34 : -120,
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
                          Text('Gloria te pagó ${formatoPesos(_valor)}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
                          Text('Pagó tu solicitud: ${_mensaje ?? _mensajePorDefecto}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: NequiColores.textoSuave)),
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

  // Practica: una solicitud de cobro sospechosa
  Widget _pantallaSolicitudExtrana() {
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        children: [
          _encabezado('Te pidieron plata'),
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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: NequiColores.mnvRojo.withOpacity(0.12),
                    child: const Text('?',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: NequiColores.mnvRojo)),
                  ),
                  const SizedBox(height: 10),
                  const Text('Número desconocido',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
                  const Text('300 555 9876', style: TextStyle(fontSize: 13, color: NequiColores.textoSuave)),
                  const SizedBox(height: 10),
                  const Text('te pide', style: TextStyle(fontSize: 13, color: NequiColores.textoSuave)),
                  Text(formatoPesos(200000),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: NequiColores.magenta)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: NequiColores.mnvFondo,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('"Paga para reclamar tu premio 🎁"',
                        style: TextStyle(fontSize: 13, color: NequiColores.textoOscuro)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('¿Conoces a esta persona? ¿Esperabas este cobro?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: NequiColores.textoOscuro)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: _objetivoCumplido
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NequiColores.mnvVerde.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: NequiColores.mnvVerde),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Solicitud rechazada. Tu plata está a salvo.',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold, color: NequiColores.mnvVerde)),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(child: _botonGris('pagar', 'Pagar')),
                      const SizedBox(width: 10),
                      Expanded(child: _botonMagenta('rechazar', 'Rechazar')),
                    ],
                  ),
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
              Text('👵🏽', style: TextStyle(fontSize: 60)),
              SizedBox(width: 10),
              Text('🛒', style: TextStyle(fontSize: 50)),
              SizedBox(width: 10),
              Text('🏠', style: TextStyle(fontSize: 56)),
            ],
          ),
          SizedBox(height: 28),
          ConsejoCalido(
            texto: 'Pedir plata por Nequi es como pasar una cuenta de cobro, pero con amabilidad y sin tener que ir a tocar la puerta.',
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
          _pasoComo('1', '📩', 'Tú le pides', 'Le mandas una solicitud a Gloria por la plata que le prestaste.'),
          _flechaAbajo(),
          _pasoComo('2', '🔔', 'A ella le llega un aviso', 'Gloria ve tu solicitud en su celular.'),
          _flechaAbajo(),
          _pasoComo('3', '✅', 'Ella decide pagar', 'Cuando paga, la plata llega a tu Nequi.'),
          const SizedBox(height: 14),
          const ConsejoCalido(
            texto: 'Pedir no mueve tu plata. Solo le envías un recordatorio amable a la otra persona.',
          ),
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

  Widget _ilustracionCelebracion() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text('🎉', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 12),
          const Text('¡Ya sabes pedir plata por Nequi!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          const SizedBox(height: 20),
          _logro('Le pediste a Gloria el valor que tú decidiste'),
          _logro('Revisaste el nombre antes de pedir'),
          _logro('Recibiste el pago y lo viste en tus movimientos'),
          _logro('Rechazaste un cobro sospechoso'),
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