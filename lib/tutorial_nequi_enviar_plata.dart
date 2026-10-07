import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'nequi_simulador.dart';

const String _leccionId = 'nequi_enviar_plata';

// Datos de practica: regalo de cumpleanos para Andres, el nieto
const String _numeroAndres = '3205557788';
const String _nombreAndres = 'Andrés Gómez';
// El usuario decide cuanto enviar. Este valor solo se usa si reanuda
const int _montoPorDefecto = 20000;
const String _mensajePorDefecto = '¡Feliz cumpleaños, mijo!';

// Contactos guardados de practica
const List<Map<String, String>> _contactos = [
  {'id': 'andres', 'nombre': 'Andrés Gómez', 'detalle': 'Tu nieto', 'numero': _numeroAndres},
  {'id': 'gloria', 'nombre': 'Gloria Rojas', 'detalle': 'Vecina', 'numero': '3105551122'},
  {'id': 'maria', 'nombre': 'María López', 'detalle': 'Amiga', 'numero': '3005551234'},
];

class TutorialNequiEnviarPlataScreen extends StatefulWidget {
  final int pasoInicial; // para reanudar
  const TutorialNequiEnviarPlataScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialNequiEnviarPlataScreen> createState() => _TutorialNequiEnviarPlataScreenState();
}

class _TutorialNequiEnviarPlataScreenState extends State<TutorialNequiEnviarPlataScreen> {
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
  bool _verContactos = false; // lista de contactos abierta en el paso del numero
  final TextEditingController _mensajeController = TextEditingController();
  bool _enviado = false;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Mandar plata desde tu casa',
      'instruccion': 'Hoy es el cumpleaños de Andrés, tu nieto. Le vas a mandar un regalo en plata, sin salir de la casa.',
    },
    {
      'tipo': 'necesitas',
      'titulo': 'Solo necesitas una cosa',
      'instruccion': 'Para mandarle plata a alguien por Nequi, solo necesitas su número de celular.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'inicio',
      'titulo': 'Toca "Envía"',
      'instruccion': 'Este es tu Nequi. Para mandar plata, toca el botón "Envía" que está brillando.',
      'objetivo': 'envia',
      'ayuda': 'Toca "Envía" en el celular',
      'guia': 'Ese botón es para otra cosa. Busca "Envía", el que está brillando.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'numero',
      'titulo': '¿A quién le envías?',
      'instruccion': 'Tienes dos caminos: escribir el número de Andrés (320 555 7788) o buscarlo en tus contactos guardados. Elige el que prefieras.',
      'objetivo': 'numero_listo',
      'ayuda': 'Escribe el número o busca a Andrés',
      'guia': 'Ese número no va. Tranquilo: toca la tecla de borrar y sigue.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'destinatario',
      'titulo': '¿Sí es Andrés?',
      'instruccion': 'Nequi te muestra el nombre del dueño de ese número. Léelo con calma. ¿Es tu nieto? Toca "Sí, es él".',
      'objetivo': 'si_es',
      'ayuda': 'Toca "Sí, es él"',
      'guia': 'En la vida real, si el nombre no es el que esperas, tocas "No es" y no envías nada. Aquí sí es Andrés: toca "Sí, es él".',
    },
    {
      'tipo': 'superpoder',
      'titulo': 'Tu superpoder: revisar el nombre',
      'instruccion': 'Antes de mandar plata, mira siempre el nombre. Si no es la persona que esperas, NO envíes.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'valor',
      'titulo': '¿Cuánto le envías?',
      'instruccion': 'Tú decides cuánto mandarle a Andrés de regalo. Escribe el valor con el teclado y toca "Continuar".',
      'objetivo': 'monto_listo',
      'ayuda': 'Escribe el valor y toca "Continuar"',
      'guia': 'Primero escribe cuánta plata le quieres mandar.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'mensaje',
      'titulo': 'Un mensajito de cariño',
      'instruccion': 'Escríbele unas palabras a Andrés. Toca la cajita blanca, escribe tu mensaje y luego toca "Listo".',
      'objetivo': 'mensaje_listo',
      'ayuda': 'Escribe tu mensaje y toca "Listo"',
      'guia': 'Primero escribe tu mensaje en la cajita blanca. Si no se te ocurre nada, mira las ideas.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'revisar',
      'titulo': 'Revisa antes de enviar',
      'instruccion': 'Mira todo con calma: nombre, número y valor. Si todo está bien, toca "Enviar".',
      'objetivo': 'enviar',
      'ayuda': 'Toca "Enviar"',
      'guia': 'Revisa los datos y toca el botón "Enviar", el que está brillando.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'exito',
      'titulo': '¡Plata enviada!',
      'instruccion': 'Este es tu comprobante: Andrés ya recibió tu regalo. Toca "Ir al inicio" para ver tu saldo.',
      'objetivo': 'ir_inicio',
      'ayuda': 'Toca "Ir al inicio"',
      'guia': 'Toca el botón "Ir al inicio", abajo en el celular.',
    },
    {
      'tipo': 'simulador',
      'inicio': 'inicio',
      'titulo': 'Mira tu saldo',
      'instruccion': 'Tu saldo bajó porque enviaste plata. Ahora toca "Movimientos" para ver el envío.',
      'objetivo': 'movimientos',
      'ayuda': 'Toca "Movimientos"',
      'guia': 'Busca la fila "Movimientos", la que está brillando.',
      'burbuja': true,
    },
    {
      'tipo': 'mirar',
      'inicio': 'movimientos',
      'titulo': 'Aquí quedó anotado',
      'instruccion': 'El primer movimiento es tu regalo para Andrés. Está en rojo con el signo menos porque es plata que salió.',
    },
    {
      'tipo': 'consejos',
      'titulo': 'Tres consejos de oro',
      'instruccion': 'Antes de terminar, guarda estos consejos para cuando lo hagas de verdad.',
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste!',
      'instruccion': 'Ya sabes mandar plata por Nequi. Andrés va a estar feliz con su regalo.',
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

    // Estado de la historia segun el paso
    _numero = _pasoActual >= 4 ? _numeroAndres : '';
    // Conserva el valor que escribio; si reanuda, pone uno por defecto
    if (_pasoActual < 7) {
      _monto = '';
    } else if (_monto.isEmpty) {
      _monto = '$_montoPorDefecto';
    }
    // Conserva el mensaje que eligio; si reanuda, pone uno por defecto
    if (_pasoActual >= 8) {
      _mensaje ??= _mensajePorDefecto;
    } else {
      _mensaje = null;
    }
    _enviado = _pasoActual >= 9;

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
      if (objetivo == 'numero_listo' && accion == 'abrir_contactos') {
        _verContactos = true;
      } else if (objetivo == 'numero_listo' && _verContactos && accion == 'atras') {
        _verContactos = false;
      } else if (objetivo == 'numero_listo' && accion.startsWith('contacto_')) {
        if (accion == 'contacto_andres') {
          // Eligio a Andres: el numero queda escrito solo
          _numero = _numeroAndres;
          _verContactos = false;
          _lograr();
        } else {
          _mensajeGuia = 'Ese contacto es de otra persona. Hoy le enviamos a Andrés, tu nieto.';
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
        } else if (nuevo.length < _numeroAndres.length) {
          nuevo += tecla;
        }
        if (!_numeroAndres.startsWith(nuevo)) _mensajeGuia = _paso['guia'] as String?;
        _numero = nuevo;
        if (nuevo == _numeroAndres) _lograr();
      });
    } else if (objetivo == 'monto_listo') {
      setState(() {
        _mensajeGuia = null;
        if (tecla == '⌫') {
          if (_monto.isNotEmpty) _monto = _monto.substring(0, _monto.length - 1);
        } else if (!(_monto.isEmpty && tecla == '0')) {
          final nuevo = _monto + tecla;
          if (int.parse(nuevo) > saldoPractica) {
            _mensajeGuia = 'No te alcanza: tienes \$ 250.000 de práctica. Prueba con menos.';
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

  // Convierte 3205557788 en "320 555 7788", aunque este a medias
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
        title: const Text('Enviar plata', style: TextStyle(fontWeight: FontWeight.bold)),
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
      case 'necesitas':
        return _ilustracionNecesitas();
      case 'superpoder':
        return _ilustracionSuperpoder();
      case 'consejos':
        return _ilustracionConsejos();
      case 'celebracion':
        return _ilustracionCelebracion();
      default:
        // El celular se encoge si la pantalla es pequena
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: MarcoCelular(
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
          titulo: 'Envía plata',
          pregunta: '¿A qué número le envías?',
          valor: _numero.isEmpty ? 'Número de celular' : _formatoTelefono(_numero),
          vacio: _numero.isEmpty,
          resaltados: _teclasResaltadas(_numeroAndres, _numero),
          extra: _botonContactos(),
        );
      case 'destinatario':
        return _pantallaDestinatario();
      case 'valor':
        return _pantallaTeclado(
          titulo: 'Envía plata',
          pregunta: '¿Cuánto le envías a Andrés?',
          valor: formatoPesos(_valor),
          vacio: _monto.isEmpty,
          detalle: 'Disponible: ${formatoPesos(saldoPractica)}',
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
      case 'exito':
        return _pantallaExito();
      case 'movimientos':
        return NequiMovimientos(
          resaltados: const {},
          onAccion: (_) {},
          movimientos: [
            NequiMovimiento('Le enviaste a Andrés', -_valor, 'Hoy', Icons.send_rounded),
            ...movimientosPractica,
          ],
        );
      default:
        return NequiInicio(
          nombre: _nombre,
          saldo: saldoPractica - (_enviado ? _valor : 0),
          saldoVisible: true,
          resaltados: _resalta('envia')
              ? {'envia'}
              : _resalta('movimientos')
                  ? {'movimientos'}
                  : <String>{},
          explicacion: _paso['burbuja'] == true
              ? 'Tenías ${formatoPesos(saldoPractica)}. Enviaste ${formatoPesos(_valor)}. '
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
          Flexible(child: Text(titulo,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
    String? detalle,
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
          if (detalle != null) ...[
            const SizedBox(height: 6),
            Text(detalle, style: const TextStyle(fontSize: 12, color: NequiColores.textoSuave)),
          ],
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
                  Flexible(child: Text('Buscar en mis contactos',
                      style: TextStyle(color: NequiColores.magenta, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
            child: Text('Toca a la persona a la que le quieres enviar',
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
    final esAndres = c['id'] == 'andres';
    final nombre = c['nombre']!;
    return NequiPulso(
      activo: esAndres && _resalta('numero_listo'),
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
          _encabezado('Envía plata'),
          const Spacer(),
          const CircleAvatar(
            radius: 40,
            backgroundColor: NequiColores.rosaSuave,
            child: Text('A',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: NequiColores.magenta)),
          ),
          const SizedBox(height: 14),
          const Text('Le vas a enviar a:', style: TextStyle(fontSize: 13, color: NequiColores.textoSuave)),
          const SizedBox(height: 4),
          const Text(_nombreAndres,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          const SizedBox(height: 4),
          Text(_formatoTelefono(_numeroAndres),
              style: const TextStyle(fontSize: 15, color: NequiColores.textoSuave)),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('¿Es la persona a la que le quieres enviar?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: NequiColores.textoOscuro)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _tocarEnSimulador('no_es'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: NequiColores.textoSuave),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('No es',
                        style: TextStyle(color: NequiColores.textoSuave, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _botonMagenta('si_es', 'Sí, es él')),
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
          _encabezado('Envía plata'),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 10),
            child: Text('Escribe un mensaje para Andrés',
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
                  Text('• ¡Feliz cumpleaños, mijo!', style: TextStyle(fontSize: 13, color: NequiColores.textoOscuro)),
                  Text('• Con mucho cariño', style: TextStyle(fontSize: 13, color: NequiColores.textoOscuro)),
                  Text('• Para un detallito', style: TextStyle(fontSize: 13, color: NequiColores.textoOscuro)),
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
          _encabezado('Revisa tu envío'),
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
                  _filaDato('Para', _nombreAndres),
                  _filaDato('Celular', _formatoTelefono(_numeroAndres)),
                  _filaDato('Mensaje', _mensaje ?? 'Sin mensaje'),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: _botonMagenta('enviar', 'Enviar'),
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
          const Text('¡Plata enviada!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          const SizedBox(height: 8),
          Text(formatoPesos(_valor),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: NequiColores.magenta)),
          const SizedBox(height: 4),
          const Text('para $_nombreAndres',
              style: TextStyle(fontSize: 15, color: NequiColores.textoSuave)),
          if (_mensaje != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: NequiColores.rosaSuave,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_mensaje!,
                  style: const TextStyle(fontSize: 13, color: NequiColores.textoOscuro)),
            ),
          ],
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
              Text('💌', style: TextStyle(fontSize: 60)),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded, size: 40, color: NequiColores.mnvMorado),
              SizedBox(width: 12),
              Text('👦🏽🎂', style: TextStyle(fontSize: 56)),
            ],
          ),
          SizedBox(height: 28),
          ConsejoCalido(
            texto: 'Mandar plata por Nequi es como entregar un sobre con un regalo, pero sin salir de la casa.',
          ),
          SizedBox(height: 12),
          ConsejoCalido(
            texto: 'Todo lo que veas aquí es de práctica. Puedes equivocarte sin miedo.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionNecesitas() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          _tarjetaInfo('📱', 'Su número de celular',
              'El mismo número con el que lo llamas. Con eso Nequi sabe a quién le llega la plata.',
              NequiColores.mnvMorado),
          const SizedBox(height: 16),
          const ConsejoCalido(
            texto: 'Si tienes el número anotado en un papel o en tus contactos, mejor: así no te equivocas.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionSuperpoder() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _tarjetaInfo('✅', 'Sale el nombre que esperas',
              'Escribiste el número de Andrés y sale "Andrés Gómez". Puedes enviar tranquilo.',
              NequiColores.mnvVerde),
          const SizedBox(height: 12),
          _tarjetaInfo('🛑', 'Sale un nombre que no conoces',
              'NO envíes. Revisa el número, o llama a la persona para confirmar.',
              NequiColores.mnvRojo),
          const SizedBox(height: 16),
          const ConsejoCalido(
            texto: 'Revisar el nombre te protege de errores y de personas que quieren engañarte.',
          ),
        ],
      ),
    );
  }

  Widget _ilustracionConsejos() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _tarjetaInfo('👀', 'Revisa siempre el nombre',
              'Antes de enviar, confirma que es la persona correcta.', NequiColores.mnvVerde),
          const SizedBox(height: 12),
          _tarjetaInfo('⏳', 'Enviar no tiene deshacer',
              'Si mandas plata a otra persona, recuperarla es muy difícil. Por eso, calma y revisa.',
              NequiColores.mnvAmarillo),
          const SizedBox(height: 12),
          _tarjetaInfo('🚫', 'Nadie de Nequi te pide plata',
              'Si alguien te llama pidiendo que le envíes plata o tu clave, cuelga y pregunta a alguien de confianza.',
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
          const Text('¡Ya sabes mandar plata por Nequi!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
          const SizedBox(height: 20),
          _logro('Encontraste el número de Andrés'),
          _logro('Revisaste el nombre antes de enviar'),
          _logro('Decidiste cuánto enviar y escribiste tu mensaje'),
          _logro('Viste el comprobante y tu nuevo saldo'),
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