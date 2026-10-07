import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'services/api_service.dart';

const String _leccionId = 'telefono_guardar_contacto';

class TutorialGuardarContactoScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialGuardarContactoScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialGuardarContactoScreen> createState() =>
      _TutorialGuardarContactoScreenState();
}

class _TutorialGuardarContactoScreenState
    extends State<TutorialGuardarContactoScreen> with TickerProviderStateMixin {
  // Paleta oficial
  static const Color _morado = Color(0xFF6B4EFF);
  static const Color _verde = Color(0xFF059669);
  static const Color _amarillo = Color(0xFFFFB300);
  static const Color _azul = Color(0xFF0EA5E9);
  static const Color _rojo = Color(0xFFE53E3E);
  static const Color _fondo = Color(0xFFF0EEFF);
  static const Color _texto = Color(0xFF1A1A2E);

  int _pasoActual = 0;

  // pantalla: inicio | telefono | contactos | nuevo | ficha | editar
  String _pantalla = 'inicio';

  // Agenda simulada. Empieza con dos contactos para que parezca real
  List<Map<String, String>> _contactos = [];

  String _nombreNuevo = '';
  String _numeroNuevo = '';
  String _campoActivo = ''; // nombre | numero | busqueda | (vacio)
  String _busqueda = '';
  int? _contactoAbierto;
  bool _confirmandoBorrado = false;
  int? _filaReciente; // para la animacion de entrada
  bool _mostrarCheck = false;

  static const String _numeroObjetivo = '3005551234';
  static const String _numeroCorregido = '3005551235';

  bool _objetivoCumplido = false;
  String? _mensajeGuia;

  late AnimationController _pulsoController;
  late Animation<double> _pulsoAnimation;
  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Tu agenda de\ncontactos 📒',
      'instruccion':
          'Tu celular tiene una libreta de teléfonos adentro.\n\nGuardas a una persona una sola vez, y después la llamas por su nombre. Nunca más tienes que acordarte del número.',
      'icono': Icons.contacts_rounded,
      'colorIcono': Color(0xFF6B4EFF),
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 1\nEntra a Contactos 👥',
      'instruccion':
          'Abre el teléfono y toca abajo donde dice "Contactos".\n\nAbajo hay tres pestañas: Recientes, Contactos y Teclado. Son como las divisiones de un cuaderno.',
      'objetivo': 'contactos',
      'ayuda': 'Abre el Teléfono y toca la pestaña Contactos',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 2\nAgrega a alguien ➕',
      'instruccion':
          'Esta es tu agenda. Ya tiene dos personas guardadas, en orden alfabético.\n\nPara agregar a alguien nuevo, toca el botón morado con el signo +',
      'objetivo': 'nuevo',
      'ayuda': 'Toca el botón + para agregar',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 3\nEscribe el nombre ✍️',
      'instruccion':
          'Vamos a guardar a María.\n\nToca la casilla "Nombre" y escribe M-a-r-í-a. La primera letra sale en mayúscula sola, no te preocupes por eso.',
      'objetivo': 'nombre_listo',
      'ayuda': 'Escribe María en la casilla del nombre',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 4\nAhora el número 🔢',
      'instruccion':
          'Toca la casilla "Número" y marca: 300 555 1234\n\nFíjate: el teclado cambia solo. Para el nombre salen letras, para el número salen números.',
      'objetivo': 'numero_listo',
      'ayuda': 'Toca la casilla Número y marca 300 555 1234',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 5\nGuarda a María 💾',
      'instruccion':
          'Ya tienes el nombre y el número.\n\nToca "Guardar" arriba a la derecha. Si no guardas, no queda nada: es como escribir en la libreta y no cerrarla.',
      'objetivo': 'guardado',
      'ayuda': 'Toca Guardar arriba a la derecha',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 6\nEncuéntrala 🔍',
      'instruccion':
          '¡Ahí está María, en la letra M!\n\nCuando tengas muchos contactos, buscar es más rápido que bajar la lista. Toca la lupa y escribe "ma".',
      'objetivo': 'busqueda_ok',
      'ayuda': 'Toca el buscador y escribe ma',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 7\nAbre su ficha 👤',
      'instruccion':
          'Toca el nombre de María para ver su ficha.\n\nAhí está todo lo de ella: su número y los botones para llamarla o escribirle.',
      'objetivo': 'ficha',
      'ayuda': 'Toca a María en la lista',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 8\nCorrige el número ✏️',
      'instruccion':
          'María se cambió de número: ahora termina en 5, no en 4.\n\nToca "Editar", borra el último número con ⌫ y pon el 5. Después toca Guardar. Equivocarse no rompe nada.',
      'objetivo': 'editado',
      'ayuda': 'Toca Editar, cambia el último número por 5 y guarda',
    },
    {
      'tipo': 'sim',
      'titulo': 'PRÁCTICA 9\nBorra lo que no usas 🗑️',
      'instruccion':
          'La pizzería ya cerró, no la necesitas.\n\nÁbrela, toca "Borrar contacto" y confirma. Siempre te pregunta antes, así que no hay peligro de borrar sin querer.',
      'objetivo': 'borrado',
      'ayuda': 'Abre la Pizzería Don Luis y bórrala',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 Un consejo',
      'instruccion':
          'Guarda a las personas con el nombre que TÚ usas para ellas.\n\n"María hija", "Doctor Pérez", "Vecina Ana". Así los encuentras rápido cuando los necesites.',
      'icono': Icons.lightbulb_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Guarda un contacto de verdad: un familiar, tu vecino o tu médico.\n\nAbre el teléfono, entra a Contactos y toca el +. Tú ya sabes hacerlo.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': Color(0xFF059669),
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste! 🏆',
      'instruccion':
          'Ya sabes guardar, buscar, corregir y borrar contactos.\n\nTu agenda es tuya y la manejas tú. 👏',
      'icono': Icons.emoji_events_rounded,
      'colorIcono': Color(0xFFFFB300),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial.clamp(0, _pasos.length - 1);

    _pulsoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _pulsoAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulsoController, curve: Curves.easeInOut),
    );

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    _prepararPaso();
  }

  @override
  void dispose() {
    _pulsoController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Lista base de la agenda, siempre en el mismo orden
  List<Map<String, String>> _agendaBase() {
    return [
      {'nombre': 'Ana vecina', 'numero': '3012223344'},
      {'nombre': 'Pizzería Don Luis', 'numero': '3109998877'},
    ];
  }

  void _ordenarAgenda() {
    _contactos.sort((a, b) => a['nombre']!.compareTo(b['nombre']!));
  }

  int _indiceDe(String textoEnNombre) {
    return _contactos.indexWhere((c) =>
        c['nombre']!.toLowerCase().contains(textoEnNombre.toLowerCase()));
  }

  // Deja el simulador listo para el paso actual, aunque el usuario reingrese
  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;
    _confirmandoBorrado = false;
    _filaReciente = null;
    _mostrarCheck = false;
    _busqueda = '';
    _campoActivo = '';
    _contactoAbierto = null;
    _contactos = _agendaBase();

    switch (_pasoActual) {
      case 1:
        _pantalla = 'inicio';
        _nombreNuevo = '';
        _numeroNuevo = '';
        break;
      case 2:
        _pantalla = 'contactos';
        _nombreNuevo = '';
        _numeroNuevo = '';
        break;
      case 3:
        _pantalla = 'nuevo';
        _nombreNuevo = '';
        _numeroNuevo = '';
        _campoActivo = 'nombre';
        break;
      case 4:
        _pantalla = 'nuevo';
        _nombreNuevo = 'María';
        _numeroNuevo = '';
        _campoActivo = 'numero';
        break;
      case 5:
        _pantalla = 'nuevo';
        _nombreNuevo = 'María';
        _numeroNuevo = _numeroObjetivo;
        break;
      case 6:
      case 7:
        _pantalla = 'contactos';
        _contactos.add({'nombre': 'María', 'numero': _numeroObjetivo});
        _ordenarAgenda();
        if (_pasoActual == 7) _busqueda = '';
        break;
      case 8:
        _contactos.add({'nombre': 'María', 'numero': _numeroObjetivo});
        _ordenarAgenda();
        _pantalla = 'ficha';
        _contactoAbierto = _indiceDe('mar');
        break;
      case 9:
        _contactos.add({'nombre': 'María', 'numero': _numeroCorregido});
        _ordenarAgenda();
        _pantalla = 'contactos';
        break;
      default:
        _pantalla = 'inicio';
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;

    switch (objetivo) {
      case 'contactos':
        cumple = _pantalla == 'contactos';
        break;
      case 'nuevo':
        cumple = _pantalla == 'nuevo';
        break;
      case 'nombre_listo':
        final n = _nombreNuevo.trim().toLowerCase();
        cumple = n == 'maría' || n == 'maria';
        break;
      case 'numero_listo':
        cumple = _numeroNuevo == _numeroObjetivo;
        break;
      case 'guardado':
        cumple = _indiceDe('mar') != -1 && _pantalla == 'contactos';
        break;
      case 'busqueda_ok':
        cumple = _busqueda.toLowerCase().startsWith('ma');
        break;
      case 'ficha':
        cumple = _pantalla == 'ficha' &&
            _contactoAbierto != null &&
            _contactos[_contactoAbierto!]['nombre']!
                .toLowerCase()
                .contains('mar');
        break;
      case 'editado':
        final i = _indiceDe('mar');
        cumple = i != -1 && _contactos[i]['numero'] == _numeroCorregido;
        break;
      case 'borrado':
        cumple = _indiceDe('pizz') == -1;
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // ─────────────────────────────────────────────
  // EL CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────
  void _tocarEnSimulador(String accion, {String? valor}) {
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'icono_telefono':
          if (_pantalla == 'inicio') _pantalla = 'telefono';
          break;

        case 'pestana_contactos':
          _pantalla = 'contactos';
          break;

        case 'pestana_teclado':
          _pantalla = 'telefono';
          break;

        case 'boton_mas':
          _pantalla = 'nuevo';
          _nombreNuevo = '';
          _numeroNuevo = '';
          _campoActivo = 'nombre';
          break;

        case 'campo_nombre':
          _campoActivo = 'nombre';
          break;

        case 'campo_numero':
          _campoActivo = 'numero';
          break;

        case 'buscador':
          _campoActivo = 'busqueda';
          break;

        case 'letra':
          if (valor == null) break;
          if (_campoActivo == 'nombre') {
            // La primera letra entra en mayuscula, como en el celular real
            final letra =
                _nombreNuevo.isEmpty ? valor.toUpperCase() : valor;
            if (_nombreNuevo.length < 20) _nombreNuevo += letra;
          } else if (_campoActivo == 'busqueda') {
            if (_busqueda.length < 15) _busqueda += valor;
          }
          break;

        case 'numero':
          if (valor == null) break;
          if (_campoActivo == 'numero' && _numeroNuevo.length < 10) {
            _numeroNuevo += valor;
          }
          break;

        case 'borrar':
          if (_campoActivo == 'nombre' && _nombreNuevo.isNotEmpty) {
            _nombreNuevo =
                _nombreNuevo.substring(0, _nombreNuevo.length - 1);
          } else if (_campoActivo == 'numero' && _numeroNuevo.isNotEmpty) {
            _numeroNuevo =
                _numeroNuevo.substring(0, _numeroNuevo.length - 1);
          } else if (_campoActivo == 'busqueda' && _busqueda.isNotEmpty) {
            _busqueda = _busqueda.substring(0, _busqueda.length - 1);
          }
          break;

        case 'guardar':
          if (_nombreNuevo.trim().isEmpty) {
            _mensajeGuia = 'Escribe primero el nombre';
            break;
          }
          if (_numeroNuevo.length < 10) {
            _mensajeGuia = 'El número debe tener 10 dígitos';
            break;
          }
          if (_pantalla == 'nuevo') {
            _contactos.add({
              'nombre': _nombreNuevo.trim(),
              'numero': _numeroNuevo,
            });
            _ordenarAgenda();
            _filaReciente = _indiceDe(_nombreNuevo.trim());
            _pantalla = 'contactos';
          } else if (_pantalla == 'editar' && _contactoAbierto != null) {
            _contactos[_contactoAbierto!] = {
              'nombre': _nombreNuevo.trim(),
              'numero': _numeroNuevo,
            };
            _pantalla = 'ficha';
          }
          _campoActivo = '';
          _mostrarCheck = true;
          _esconderCheckLuego();
          break;

        case 'cancelar':
          _pantalla = _pantalla == 'editar' ? 'ficha' : 'contactos';
          _campoActivo = '';
          break;

        case 'abrir_ficha':
          if (valor == null) break;
          _contactoAbierto = int.tryParse(valor);
          _pantalla = 'ficha';
          break;

        case 'volver_contactos':
          _pantalla = 'contactos';
          _contactoAbierto = null;
          break;

        case 'boton_editar':
          if (_contactoAbierto == null) break;
          _nombreNuevo = _contactos[_contactoAbierto!]['nombre']!;
          _numeroNuevo = _contactos[_contactoAbierto!]['numero']!;
          _campoActivo = 'numero';
          _pantalla = 'editar';
          break;

        case 'boton_borrar':
          _confirmandoBorrado = true;
          break;

        case 'cancelar_borrado':
          _confirmandoBorrado = false;
          break;

        case 'confirmar_borrado':
          if (_contactoAbierto != null) {
            _contactos.removeAt(_contactoAbierto!);
            _contactoAbierto = null;
          }
          _confirmandoBorrado = false;
          _pantalla = 'contactos';
          break;

        case 'boton_llamar':
          _mensajeGuia = 'Llamar lo practicamos en la próxima lección';
          break;

        case 'boton_mensaje':
          _mensajeGuia = 'Escribir mensajes lo vemos más adelante';
          break;
      }

      _revisarObjetivo();
    });
  }

  Future<void> _esconderCheckLuego() async {
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _mostrarCheck = false);
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
      await ApiService.guardarPaso(
        userId,
        _leccionId,
        _pasoActual + 1,
        completada: esUltimo,
      );
    }

    if (esUltimo) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _pasoActual++;
      _prepararPaso();
    });

    if (_pasos[_pasoActual]['tipo'] == 'celebracion') {
      _confettiController.play();
    }
  }
    // ─────────────────────────────────────────────
  // LA PANTALLA DE LA LECCION
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_pasoActual];

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _morado),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Guardar un contacto',
            style: TextStyle(
                color: _texto, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              _buildProgreso(),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCajaInstruccion(paso),
              ),
              const SizedBox(height: 12),
              Expanded(child: Center(child: _buildIlustracion(paso))),
              if (_mensajeGuia != null) _buildMensajeGuia(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _buildBoton(paso),
              ),
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            gravity: 0.1,
            colors: const [_morado, _amarillo, _verde, Color(0xFF8B5CF6)],
          ),
        ],
      ),
    );
  }

  Widget _buildProgreso() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Text('Paso ${_pasoActual + 1} de ${_pasos.length}',
              style: const TextStyle(
                  color: _morado, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (_pasoActual + 1) / _pasos.length),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (_, valor, __) => LinearProgressIndicator(
                value: valor,
                backgroundColor: const Color(0xFFDED8FF),
                valueColor: const AlwaysStoppedAnimation<Color>(_morado),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCajaInstruccion(Map<String, dynamic> paso) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _morado,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(paso['titulo'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3)),
          const SizedBox(height: 8),
          Text(paso['instruccion'],
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 14,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildMensajeGuia() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _amarillo.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amarillo, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_rounded, color: _amarillo, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(_mensajeGuia!,
                style: const TextStyle(
                    color: Color(0xFF854F0B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildIlustracion(Map<String, dynamic> paso) {
    final tipo = paso['tipo'] as String;

    if (tipo == 'sim') {
      return SingleChildScrollView(child: _buildSimulador());
    } else if (tipo == 'celebracion') {
      return _buildTrofeo();
    } else {
      final icono = paso['icono'] as IconData;
      final color = paso['colorIcono'] as Color;
      return Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.3), width: 3),
        ),
        child: Center(child: Icon(icono, size: 70, color: color)),
      );
    }
  }

  // ═════════════════════════════════════════════
  // EL SIMULADOR
  // ═════════════════════════════════════════════
  Widget _buildSimulador() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _verde.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('📱 Teléfono de práctica — toca sin miedo',
              style: TextStyle(
                  color: _verde, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        Container(
          width: 270,
          decoration: BoxDecoration(
            color: _texto,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 520,
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOut,
                    transitionBuilder: (hijo, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.97, end: 1.0)
                            .animate(anim),
                        child: hijo,
                      ),
                    ),
                    child: Container(
                      key: ValueKey(_pantalla),
                      child: _buildPantallaSim(),
                    ),
                  ),
                  if (_confirmandoBorrado) _buildConfirmacion(),
                  if (_mostrarCheck) _buildCheckGuardado(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPantallaSim() {
    switch (_pantalla) {
      case 'inicio':
        return _buildInicio();
      case 'telefono':
        return _buildTelefono();
      case 'contactos':
        return _buildContactos();
      case 'nuevo':
      case 'editar':
        return _buildFormulario();
      case 'ficha':
        return _buildFicha();
      default:
        return const SizedBox();
    }
  }

  // Escritorio del celular
  Widget _buildInicio() {
    final resaltado = _pasoActual == 1;
    return Container(
      color: const Color(0xFF111122),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulsoAnimation,
          builder: (_, __) => Transform.scale(
            scale: resaltado ? _pulsoAnimation.value : 1.0,
            child: GestureDetector(
              onTap: () => _tocarEnSimulador('icono_telefono'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _verde,
                      border: resaltado
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: resaltado
                          ? [
                              BoxShadow(
                                  color: _verde.withOpacity(0.7),
                                  blurRadius: 18,
                                  spreadRadius: 2)
                            ]
                          : null,
                    ),
                    child: const Icon(Icons.phone_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 8),
                  const Text('Teléfono',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Pestaña del teclado, solo para que vea de dónde viene
  Widget _buildTelefono() {
    return Container(
      color: _texto,
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text('Teléfono',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Aquí marcas números sueltos.\n\nPara ver a tus personas guardadas, toca Contactos abajo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ),
          ),
          _buildPestanas('teclado'),
        ],
      ),
    );
  }

  // Barra inferior de pestañas
  Widget _buildPestanas(String activa) {
    final resaltar = _pasoActual == 1 && activa == 'teclado';
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: Color(0xFF13131F),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          _pestana(Icons.access_time_rounded, 'Recientes',
              activa == 'recientes', null),
          _pestana(Icons.person_rounded, 'Contactos', activa == 'contactos',
              'pestana_contactos',
              resaltada: resaltar),
          _pestana(Icons.dialpad_rounded, 'Teclado', activa == 'teclado',
              'pestana_teclado'),
        ],
      ),
    );
  }

  Widget _pestana(IconData icono, String texto, bool activa, String? accion,
      {bool resaltada = false}) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _pulsoAnimation,
        builder: (_, __) => Transform.scale(
          scale: resaltada ? _pulsoAnimation.value : 1.0,
          child: GestureDetector(
            onTap: accion == null
                ? () => setState(() =>
                    _mensajeGuia = 'Esa pestaña la vemos en otra lección')
                : () => _tocarEnSimulador(accion),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: resaltada
                          ? _amarillo.withOpacity(0.25)
                          : Colors.transparent,
                      border: resaltada
                          ? Border.all(color: _amarillo, width: 2)
                          : null,
                    ),
                    child: Icon(icono,
                        size: 22,
                        color: activa
                            ? _morado
                            : (resaltada ? _amarillo : Colors.white54)),
                  ),
                  const SizedBox(height: 2),
                  Text(texto,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              activa ? FontWeight.bold : FontWeight.normal,
                          color: activa ? _morado : Colors.white54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // La lista de contactos
  Widget _buildContactos() {
    final filtrados = <int>[];
    for (int i = 0; i < _contactos.length; i++) {
      if (_busqueda.isEmpty ||
          _contactos[i]['nombre']!
              .toLowerCase()
              .contains(_busqueda.toLowerCase())) {
        filtrados.add(i);
      }
    }
    final buscando = _campoActivo == 'busqueda';

    return Container(
      color: const Color(0xFFF7F6FF),
      child: Column(
        children: [
          // Barra superior
          Container(
            padding: const EdgeInsets.fromLTRB(16, 22, 12, 10),
            color: Colors.white,
            child: Row(
              children: [
                const Expanded(
                  child: Text('Contactos',
                      style: TextStyle(
                          color: _texto,
                          fontSize: 19,
                          fontWeight: FontWeight.bold)),
                ),
                _botonMas(),
              ],
            ),
          ),
          // Buscador
          GestureDetector(
            onTap: () => _tocarEnSimulador('buscador'),
            child: AnimatedBuilder(
              animation: _pulsoAnimation,
              builder: (_, __) => Transform.scale(
                scale: (_pasoActual == 6 && !buscando)
                    ? _pulsoAnimation.value
                    : 1.0,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: buscando
                            ? _morado
                            : (_pasoActual == 6
                                ? _amarillo
                                : const Color(0xFFDED8FF)),
                        width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          size: 18,
                          color: buscando ? _morado : const Color(0xFF777799)),
                      const SizedBox(width: 8),
                      Text(
                        _busqueda.isEmpty ? 'Buscar' : _busqueda,
                        style: TextStyle(
                            fontSize: 14,
                            color: _busqueda.isEmpty
                                ? const Color(0xFF777799)
                                : _texto,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Lista
          Expanded(
            child: filtrados.isEmpty
                ? const Center(
                    child: Text('Sin resultados',
                        style: TextStyle(
                            color: Color(0xFF777799), fontSize: 13)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: filtrados.length,
                    itemBuilder: (_, pos) => _filaContacto(filtrados[pos]),
                  ),
          ),
          // Teclado de letras cuando busca
          AnimatedSlide(
            offset: buscando ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            child: buscando
                ? _buildTecladoLetras()
                : const SizedBox(width: double.infinity),
          ),
          if (!buscando) _buildPestanas('contactos'),
        ],
      ),
    );
  }

  Widget _botonMas() {
    final resaltado = _pasoActual == 2;
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) => Transform.scale(
        scale: resaltado ? _pulsoAnimation.value : 1.0,
        child: GestureDetector(
          onTap: () => _tocarEnSimulador('boton_mas'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _morado,
              border:
                  resaltado ? Border.all(color: _amarillo, width: 3) : null,
              boxShadow: resaltado
                  ? [
                      BoxShadow(
                          color: _morado.withOpacity(0.6),
                          blurRadius: 14,
                          spreadRadius: 1)
                    ]
                  : null,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  // Una fila de la lista, con animacion de entrada si es la recien guardada
  Widget _filaContacto(int indice) {
    final contacto = _contactos[indice];
    final nombre = contacto['nombre']!;
    final esReciente = _filaReciente == indice;
    final resaltada = (_pasoActual == 7 && nombre.toLowerCase().contains('mar')) ||
        (_pasoActual == 9 && nombre.toLowerCase().contains('pizz'));

    final fila = GestureDetector(
      onTap: () => _tocarEnSimulador('abrir_ficha', valor: '$indice'),
      child: AnimatedBuilder(
        animation: _pulsoAnimation,
        builder: (_, __) => Transform.scale(
          scale: resaltada ? _pulsoAnimation.value.clamp(1.0, 1.04) : 1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: resaltada ? _amarillo : const Color(0xFFEDEAFF),
                  width: resaltada ? 2 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _morado.withOpacity(0.12),
                  ),
                  child: Center(
                    child: Text(nombre[0].toUpperCase(),
                        style: const TextStyle(
                            color: _morado,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(nombre,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _texto,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFBBB6D8), size: 20),
              ],
            ),
          ),
        ),
      ),
    );

    if (!esReciente) return fila;

    // Entra deslizandose con un destello verde
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, t, hijo) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 26 * (1 - t)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _verde.withOpacity(0.35 * (1 - t)),
            ),
            child: hijo,
          ),
        ),
      ),
      child: fila,
    );
  }
    // Formulario de nuevo contacto y de editar
  Widget _buildFormulario() {
    final editando = _pantalla == 'editar';
    final inicial = _nombreNuevo.trim().isEmpty
        ? '?'
        : _nombreNuevo.trim()[0].toUpperCase();

    return Container(
      color: const Color(0xFFF7F6FF),
      child: Column(
        children: [
          // Barra superior con Cancelar y Guardar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 22, 12, 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _tocarEnSimulador('cancelar'),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Color(0xFF777799), fontSize: 13)),
                ),
                Text(editando ? 'Editar' : 'Nuevo contacto',
                    style: const TextStyle(
                        color: _texto,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                _botonGuardar(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Avatar con la inicial, crece a medida que escribe
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _nombreNuevo.isEmpty ? 56 : 66,
            height: _nombreNuevo.isEmpty ? 56 : 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _morado.withOpacity(0.12),
              border: Border.all(color: _morado.withOpacity(0.35), width: 2),
            ),
            child: Center(
              child: Text(inicial,
                  style: const TextStyle(
                      color: _morado,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 14),
          _campo('Nombre', _nombreNuevo, 'nombre', _pasoActual == 3),
          _campo(
              'Número',
              _numeroNuevo.isEmpty ? '' : _numeroFormateado(_numeroNuevo),
              'numero',
              _pasoActual == 4 || (_pasoActual == 8 && _pantalla == 'editar')),
          const Spacer(),
          // El teclado cambia segun la casilla activa
          AnimatedSlide(
            offset: _campoActivo.isEmpty ? const Offset(0, 1) : Offset.zero,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            child: _campoActivo == 'nombre'
                ? _buildTecladoLetras()
                : _campoActivo == 'numero'
                    ? _buildTecladoNumeros()
                    : const SizedBox(width: double.infinity, height: 1),
          ),
        ],
      ),
    );
  }

  Widget _campo(String etiqueta, String valor, String clave, bool resaltar) {
    final activo = _campoActivo == clave;
    return GestureDetector(
      onTap: () => _tocarEnSimulador('campo_$clave'),
      child: AnimatedBuilder(
        animation: _pulsoAnimation,
        builder: (_, __) => Transform.scale(
          scale: (resaltar && !activo) ? _pulsoAnimation.value : 1.0,
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: activo
                      ? _morado
                      : (resaltar ? _amarillo : const Color(0xFFDED8FF)),
                  width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta,
                    style: const TextStyle(
                        color: Color(0xFF777799), fontSize: 11)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(valor.isEmpty ? 'Toca aquí' : valor,
                        style: TextStyle(
                            color: valor.isEmpty
                                ? const Color(0xFFBBB6D8)
                                : _texto,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    if (activo)
                      Container(
                        width: 2,
                        height: 18,
                        margin: const EdgeInsets.only(left: 2),
                        color: _morado,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonGuardar() {
    final resaltado = _pasoActual == 5 ||
        (_pasoActual == 8 && _numeroNuevo == _numeroCorregido);
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) => Transform.scale(
        scale: resaltado ? _pulsoAnimation.value : 1.0,
        child: GestureDetector(
          onTap: () => _tocarEnSimulador('guardar'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _verde,
              borderRadius: BorderRadius.circular(14),
              border:
                  resaltado ? Border.all(color: _amarillo, width: 2) : null,
            ),
            child: const Text('Guardar',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // Ficha del contacto
  Widget _buildFicha() {
    if (_contactoAbierto == null ||
        _contactoAbierto! >= _contactos.length) {
      return const SizedBox();
    }
    final contacto = _contactos[_contactoAbierto!];
    final nombre = contacto['nombre']!;
    final resaltarEditar = _pasoActual == 8;
    final resaltarBorrar = _pasoActual == 9;

    return Container(
      color: const Color(0xFFF7F6FF),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 22, 12, 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _tocarEnSimulador('volver_contactos'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left_rounded,
                          color: _morado, size: 22),
                      Text('Contactos',
                          style: TextStyle(color: _morado, fontSize: 13)),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _pulsoAnimation,
                  builder: (_, __) => Transform.scale(
                    scale: resaltarEditar ? _pulsoAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: () => _tocarEnSimulador('boton_editar'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: resaltarEditar
                              ? _amarillo.withOpacity(0.2)
                              : Colors.transparent,
                          border: resaltarEditar
                              ? Border.all(color: _amarillo, width: 2)
                              : null,
                        ),
                        child: const Text('Editar',
                            style: TextStyle(
                                color: _morado,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (_, t, hijo) => Transform.scale(scale: t, child: hijo),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _morado.withOpacity(0.12),
                border: Border.all(color: _morado.withOpacity(0.35), width: 3),
              ),
              child: Center(
                child: Text(nombre[0].toUpperCase(),
                    style: const TextStyle(
                        color: _morado,
                        fontSize: 36,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _texto, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(_numeroFormateado(contacto['numero']!),
              style: const TextStyle(color: Color(0xFF555577), fontSize: 15)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _accionFicha(Icons.phone_rounded, 'Llamar', _verde,
                  'boton_llamar'),
              const SizedBox(width: 26),
              _accionFicha(Icons.message_rounded, 'Mensaje', _azul,
                  'boton_mensaje'),
            ],
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulsoAnimation,
            builder: (_, __) => Transform.scale(
              scale: resaltarBorrar ? _pulsoAnimation.value : 1.0,
              child: GestureDetector(
                onTap: () => _tocarEnSimulador('boton_borrar'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _rojo, width: 2),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: _rojo, size: 20),
                      SizedBox(width: 8),
                      Text('Borrar contacto',
                          style: TextStyle(
                              color: _rojo,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accionFicha(
      IconData icono, String texto, Color color, String accion) {
    return GestureDetector(
      onTap: () => _tocarEnSimulador(accion),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.35), blurRadius: 10)
              ],
            ),
            child: Icon(icono, color: Colors.white, size: 25),
          ),
          const SizedBox(height: 6),
          Text(texto,
              style: const TextStyle(
                  color: Color(0xFF555577),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Aviso antes de borrar
  Widget _buildConfirmacion() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (_, t, hijo) => Transform.scale(scale: t, child: hijo),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 22),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline_rounded,
                    color: _rojo, size: 34),
                const SizedBox(height: 10),
                const Text('¿Borrar este contacto?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _texto,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Esto no se puede deshacer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF777799), fontSize: 12)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _tocarEnSimulador('cancelar_borrado'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _morado,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('No, dejarlo',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _tocarEnSimulador('confirmar_borrado'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Center(
                      child: Text('Sí, borrar',
                          style: TextStyle(
                              color: _rojo,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Check verde que confirma que se guardo
  Widget _buildCheckGuardado() {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (_, t, hijo) => Transform.scale(scale: t, child: hijo),
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _verde,
              boxShadow: [
                BoxShadow(color: _verde.withOpacity(0.5), blurRadius: 24)
              ],
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 46),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TECLADOS
  // ─────────────────────────────────────────────
  Widget _buildTecladoLetras() {
    const fila1 = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
    const fila2 = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ñ'];
    const fila3 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];
    const acentos = ['á', 'é', 'í', 'ó', 'ú'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      color: const Color(0xFFE6E4F0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: acentos.map((l) => _teclaLetra(l)).toList(),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: fila1.map((l) => _teclaLetra(l)).toList(),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: fila2.map((l) => _teclaLetra(l)).toList(),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...fila3.map((l) => _teclaLetra(l)),
              _teclaEspecial(Icons.backspace_rounded, 'borrar'),
            ],
          ),
        ],
      ),
    );
  }

  // La letra que sigue se resalta sola
  String? _letraEsperada() {
    if (_campoActivo == 'nombre' && _pasoActual == 3) {
      const objetivo = 'maría';
      if (_nombreNuevo.length < objetivo.length) {
        return objetivo[_nombreNuevo.length];
      }
    }
    if (_campoActivo == 'busqueda' && _pasoActual == 6) {
      const objetivo = 'ma';
      if (_busqueda.length < objetivo.length) {
        return objetivo[_busqueda.length];
      }
    }
    return null;
  }

  Widget _teclaLetra(String letra) {
    final esperada = _letraEsperada() == letra;
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) => Transform.scale(
        scale: esperada ? _pulsoAnimation.value : 1.0,
        child: GestureDetector(
          onTap: () => _tocarEnSimulador('letra', valor: letra),
          child: Container(
            width: 23,
            height: 34,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: esperada ? _amarillo : Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 2,
                    offset: Offset(0, 1))
              ],
            ),
            child: Center(
              child: Text(letra,
                  style: TextStyle(
                      color: esperada ? Colors.white : _texto,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _teclaEspecial(IconData icono, String accion) {
    return GestureDetector(
      onTap: () => _tocarEnSimulador(accion),
      child: Container(
        width: 44,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFCFCCE0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icono, size: 16, color: _texto),
      ),
    );
  }

  Widget _buildTecladoNumeros() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      color: const Color(0xFFE6E4F0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filaNumeros(['1', '2', '3']),
          _filaNumeros(['4', '5', '6']),
          _filaNumeros(['7', '8', '9']),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 54),
              _teclaNumero('0'),
              GestureDetector(
                onTap: () => _tocarEnSimulador('borrar'),
                child: Container(
                  width: 54,
                  height: 36,
                  margin: const EdgeInsets.all(2),
                  alignment: Alignment.center,
                  child: const Icon(Icons.backspace_rounded,
                      size: 20, color: Color(0xFF555577)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filaNumeros(List<String> numeros) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numeros.map((n) => _teclaNumero(n)).toList(),
    );
  }

  // El numero que sigue se resalta solo
  String? _numeroEsperado() {
    if (_campoActivo != 'numero') return null;
    if (_pasoActual == 4 && _numeroNuevo.length < _numeroObjetivo.length) {
      return _numeroObjetivo[_numeroNuevo.length];
    }
    if (_pasoActual == 8 && _numeroNuevo.length == 9) {
      return '5';
    }
    return null;
  }

  Widget _teclaNumero(String numero) {
    final esperado = _numeroEsperado() == numero;
    return AnimatedBuilder(
      animation: _pulsoAnimation,
      builder: (_, __) => Transform.scale(
        scale: esperado ? _pulsoAnimation.value : 1.0,
        child: GestureDetector(
          onTap: () => _tocarEnSimulador('numero', valor: numero),
          child: Container(
            width: 54,
            height: 40,
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: esperado ? _amarillo : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 2,
                    offset: Offset(0, 1))
              ],
            ),
            child: Center(
              child: Text(numero,
                  style: TextStyle(
                      color: esperado ? Colors.white : _texto,
                      fontSize: 19,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  // 3005551234 se muestra como 300 555 1234
  String _numeroFormateado(String n) {
    if (n.length <= 3) return n;
    if (n.length <= 6) return '${n.substring(0, 3)} ${n.substring(3)}';
    return '${n.substring(0, 3)} ${n.substring(3, 6)} ${n.substring(6)}';
  }

  Widget _buildTrofeo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFAEEDA),
            border: Border.all(color: const Color(0xFFEF9F27), width: 3),
            boxShadow: [
              BoxShadow(
                  color: _amarillo.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 4)
            ],
          ),
          child: const Center(
              child: Text('📒', style: TextStyle(fontSize: 60))),
        ),
        const SizedBox(height: 16),
        const Text('¡La agenda es tuya!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF854F0B),
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBoton(Map<String, dynamic> paso) {
    final tipo = paso['tipo'] as String;
    final esUltimo = _pasoActual == _pasos.length - 1;
    final esSimulador = tipo == 'sim';

    String texto;
    Color color;

    if (esUltimo) {
      texto = '¡Terminé! 🎉';
      color = _verde;
    } else if (esSimulador && !_objetivoCumplido) {
      texto = paso['ayuda'] as String? ?? 'Practica en el teléfono de arriba';
      color = const Color(0xFFBBBBCC);
    } else if (esSimulador) {
      texto = '¡Lo lograste! Siguiente →';
      color = _verde;
    } else if (tipo == 'accion_real') {
      texto = 'Ya practiqué, siguiente →';
      color = _morado;
    } else {
      texto = 'Entendido, siguiente →';
      color = _morado;
    }

    final habilitado = !esSimulador || _objetivoCumplido;

    return GestureDetector(
      onTap: habilitado ? _avanzar : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: habilitado
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5))
                ]
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}