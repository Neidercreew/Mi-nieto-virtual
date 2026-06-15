import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';

// LECCION 3: Moviendote en tu celular
// Ensena al adulto mayor a navegar dentro del celular sin perderse
// Pasos: 0=intro, 1=teoria inicio, 2=teoria atras, 3=teoria recientes,
//        4=teoria notificaciones, 5=practica inicio, 6=practica atras,
//        7=practica recientes, 8=practica notificaciones, 9=final

class TutorialMoviendoteScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialMoviendoteScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialMoviendoteScreen> createState() =>
      _TutorialMoviendoteScreenState();
}

class _TutorialMoviendoteScreenState extends State<TutorialMoviendoteScreen>
    with TickerProviderStateMixin {

  // Estado general del paso actual y si ya se completo
  int _pasoActual = 0;
  bool _mostrarFelicitacion = false;
  bool _pasoCompletado = false;

  // Animacion de pulso para botones interactivos
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Animacion del check verde al completar un gesto
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  // Estado de confirmacion de cada practica de boton
  bool _botonInicioPresionado = false;
  bool _botonAtrasPresionado = false;
  bool _botonRecientesPresionado = false;

  // Altura del panel de notificaciones en la practica 4
  // Se actualiza en tiempo real mientras el usuario desliza
  double _panelAltura = 0;
  // Posicion Y donde empezo el dedo en la practica de notificaciones
  double? _yInicioPanel;

  // Definicion de los 10 pasos de la leccion
  final List<Map<String, String>> _pasos = [
    {
      'instruccion': 'Leccion 3\nMoviendote en\ntu celular\n\nAprenderas a\nnavegar sin\nperderte',
      'tipo': 'intro',
    },
    {
      'instruccion': 'El boton de\nINICIO te lleva\nsiempre a la\npantalla principal\ndel celular',
      'tipo': 'teoria_inicio',
    },
    {
      'instruccion': 'El boton de\nATRAS te regresa\na la pantalla\nanterior sin\ncerrar todo',
      'tipo': 'teoria_atras',
    },
    {
      'instruccion': 'El boton de\nAPPS RECIENTES\nte muestra todo\nlo que tienes\nabierto',
      'tipo': 'teoria_recientes',
    },
    {
      'instruccion': 'Las NOTIFICACIONES\naparecen arriba.\nDesliza hacia\nabajo para verlas',
      'tipo': 'teoria_notificaciones',
    },
    {
      'instruccion': 'PRACTICA 1\nToca el boton\nde INICIO en\ntu celular real\ny confirma',
      'tipo': 'practica_inicio',
    },
    {
      'instruccion': 'PRACTICA 2\nToca el boton\nde ATRAS en\ntu celular real\ny confirma',
      'tipo': 'practica_atras',
    },
    {
      'instruccion': 'PRACTICA 3\nToca el boton\nde APPS en\ntu celular real\ny confirma',
      'tipo': 'practica_recientes',
    },
    {
      'instruccion': 'PRACTICA 4\nDesliza desde\narriba hacia\nabajo para ver\ntus notificaciones',
      'tipo': 'practica_notificaciones',
    },
    {
      'instruccion': 'Felicitaciones\nYa sabes moverte\nen tu celular\nsin perderte',
      'tipo': 'final',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial;

    // Animacion de pulso para resaltar botones interactivos
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animacion del check que aparece al completar cada paso
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  // Guarda el progreso en el backend y avanza al siguiente paso
  Future<void> _completarPaso() async {
    if (_pasoCompletado) return;

    setState(() => _pasoCompletado = true);
    setState(() => _mostrarFelicitacion = true);
    _checkController.forward(from: 0);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    if (userId != null) {
      await ApiService.guardarPaso(
        userId,
        'moviendote_celular',
        _pasoActual + 1,
      );
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _mostrarFelicitacion = false;
        _pasoCompletado = false;
        _botonInicioPresionado = false;
        _botonAtrasPresionado = false;
        _botonRecientesPresionado = false;
        _panelAltura = 0;
        if (_pasoActual < _pasos.length - 1) _pasoActual++;
      });
      _checkController.reset();
    }
  }

  // Guarda la leccion como completada y regresa al mapa
  Future<void> _terminarLeccion() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    if (userId != null) {
      await ApiService.guardarPaso(
        userId,
        'moviendote_celular',
        _pasos.length,
        completada: true,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_pasoActual];
    final esPrimerPaso = _pasoActual == 0;
    final esUltimoPaso = _pasoActual == _pasos.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF0EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EFFE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF6B4EFF)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Moviendote en tu celular',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildProgreso(),
              const SizedBox(height: 16),
              _buildInstruccion(paso['instruccion']!),
              const SizedBox(height: 24),
              Expanded(
                child: Center(child: _buildAreaInteractiva(paso['tipo']!)),
              ),
              if (esPrimerPaso || esUltimoPaso)
                _buildBotonPrincipal(esUltimoPaso),
            ],
          ),
          if (_mostrarFelicitacion) _buildOverlayFelicitacion(),
        ],
      ),
    );
  }

  // Barra de progreso superior con numero de paso actual
  Widget _buildProgreso() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Text(
            'Paso ${_pasoActual + 1} de ${_pasos.length}',
            style: const TextStyle(
              color: Color(0xFF6B4EFF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_pasoActual + 1) / _pasos.length,
              backgroundColor: const Color(0xFFDED8FF),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // Caja morada con la instruccion del paso actual
  Widget _buildInstruccion(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF6B4EFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // Boton principal — verde al terminar, morado en la intro
  Widget _buildBotonPrincipal(bool esUltimo) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: esUltimo
            ? _terminarLeccion
            : () => setState(() => _pasoActual++),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: esUltimo
                ? const Color(0xFF059669)
                : const Color(0xFF6B4EFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              esUltimo ? 'Terminar leccion' : 'Siguiente',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Selecciona el widget interactivo segun el tipo de paso
  Widget _buildAreaInteractiva(String tipo) {
    switch (tipo) {
      case 'intro':
        return _buildIntro();
      case 'teoria_inicio':
        return _buildTeoriaBoton(
          icono: Icons.circle_outlined,
          nombre: 'Inicio',
          descripcion: 'Siempre te lleva\na la pantalla principal',
          color: const Color(0xFF059669),
        );
      case 'teoria_atras':
        return _buildTeoriaBoton(
          icono: Icons.arrow_back_rounded,
          nombre: 'Atras',
          descripcion: 'Regresa a la pantalla\nque estabas viendo',
          color: const Color(0xFF6B4EFF),
        );
      case 'teoria_recientes':
        return _buildTeoriaBoton(
          icono: Icons.crop_square_rounded,
          nombre: 'Apps recientes',
          descripcion: 'Muestra todo lo\nque tienes abierto',
          color: const Color(0xFF3B82F6),
        );
      case 'teoria_notificaciones':
        return _buildTeoriaNoti();
      case 'practica_inicio':
        return _buildPracticaBoton(
          icono: Icons.circle_outlined,
          nombre: 'Inicio',
          color: const Color(0xFF059669),
          presionado: _botonInicioPresionado,
          ubicacion: 'centro',
          descripcionReal:
              'El boton de INICIO es el circulo\nque esta en el centro\nde la barra inferior de tu celular',
          onTap: () {
            setState(() => _botonInicioPresionado = true);
            _completarPaso();
          },
        );
      case 'practica_atras':
        return _buildPracticaBoton(
          icono: Icons.arrow_back_rounded,
          nombre: 'Atras',
          color: const Color(0xFF6B4EFF),
          presionado: _botonAtrasPresionado,
          ubicacion: 'izquierda',
          descripcionReal:
              'El boton de ATRAS es la flecha\nque esta a la izquierda\nen la barra inferior de tu celular',
          onTap: () {
            setState(() => _botonAtrasPresionado = true);
            _completarPaso();
          },
        );
      case 'practica_recientes':
        return _buildPracticaBoton(
          icono: Icons.crop_square_rounded,
          nombre: 'Apps recientes',
          color: const Color(0xFF3B82F6),
          presionado: _botonRecientesPresionado,
          ubicacion: 'derecha',
          descripcionReal:
              'El boton de APPS RECIENTES es el cuadrado\nque esta a la derecha\nen la barra inferior de tu celular',
          onTap: () {
            setState(() => _botonRecientesPresionado = true);
            _completarPaso();
          },
        );
      case 'practica_notificaciones':
        return _buildPracticaNotificaciones();
      case 'final':
        return _buildFinal();
      default:
        return const SizedBox();
    }
  }

  // Pantalla de introduccion con icono central
  Widget _buildIntro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: const BoxDecoration(
            color: Color(0xFFDED8FF),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.navigation_rounded,
                size: 80, color: Color(0xFF6B4EFF)),
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Con estos tres botones\npuedes moverte por\ntodo tu celular sin perderte',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF555577),
              fontSize: 18,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // Muestra el boton de navegacion con animacion y descripcion
  Widget _buildTeoriaBoton({
    required IconData icono,
    required String nombre,
    required String descripcion,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Boton animado que representa visualmente el boton del celular
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Icon(icono, color: Colors.white, size: 60),
          ),
        ),
        const SizedBox(height: 24),
        // Nombre del boton
        Text(
          nombre,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Para que sirve el boton
        Text(
          descripcion,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF555577),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        // Boton para avanzar al siguiente paso de teoria
        GestureDetector(
          onTap: () => setState(() => _pasoActual++),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Entendido, siguiente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Muestra como se ven las notificaciones con ejemplo visual
  Widget _buildTeoriaNoti() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Simulacion de pantalla con notificacion visible
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // Barra de estado superior
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('10:30',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Row(children: const [
                      Icon(Icons.wifi, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Icon(Icons.battery_full,
                          color: Colors.white, size: 16),
                    ]),
                  ],
                ),
              ),
              // Ejemplo de notificacion
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4EFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.message_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nuevo mensaje',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          Text('Maria te escribio',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Las notificaciones te avisan\ncuando alguien te escribe\no cuando pasa algo importante',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF555577),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => setState(() => _pasoActual++),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF6B4EFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Entendido, siguiente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Muestra el boton real de Android y pide al usuario que lo toque en su celular
  // El usuario confirma tocando "Lo hice" para avanzar
  Widget _buildPracticaBoton({
    required IconData icono,
    required String nombre,
    required Color color,
    required bool presionado,
    required VoidCallback onTap,
    required String ubicacion,
    required String descripcionReal,
  }) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // Simulacion visual del celular con barra de navegacion Android
          Container(
            width: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDED8FF), width: 2),
            ),
            child: Column(
              children: [
                // Pantalla oscura del celular
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Pantalla de tu celular',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Barra de navegacion de Android con los tres botones
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Boton atras — resaltado si es la practica de atras
                      _buildBotonNavBar(
                        Icons.arrow_back_rounded,
                        nombre == 'Atras',
                        color,
                      ),
                      // Boton inicio — resaltado si es la practica de inicio
                      _buildBotonNavBar(
                        Icons.circle_outlined,
                        nombre == 'Inicio',
                        color,
                      ),
                      // Boton recientes — resaltado si es la practica de recientes
                      _buildBotonNavBar(
                        Icons.crop_square_rounded,
                        nombre == 'Apps recientes',
                        color,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Etiqueta que indica cual boton tocar
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Toca este boton en tu celular',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Descripcion de donde esta el boton fisicamente en el celular
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              descripcionReal,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF555577),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Boton de confirmacion — el usuario lo toca despues de hacer el gesto real
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 18),
              decoration: BoxDecoration(
                color: presionado ? const Color(0xFF059669) : color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (presionado
                            ? const Color(0xFF059669)
                            : color)
                        .withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    presionado
                        ? Icons.check_rounded
                        : Icons.touch_app_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    presionado ? 'Perfecto' : 'Lo hice',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dibuja un boton individual de la barra de navegacion Android
  // Lo resalta en color si es el boton que el usuario debe tocar
  Widget _buildBotonNavBar(IconData icono, bool resaltado, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: resaltado ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: resaltado ? Border.all(color: color, width: 2) : null,
      ),
      child: Icon(
        icono,
        color: resaltado ? color : Colors.white54,
        size: 24,
      ),
    );
  }

  // Practica de notificaciones con carril de deslizamiento
  // El panel baja en tiempo real sincronizado con el dedo del usuario
  Widget _buildPracticaNotificaciones() {
    const double alturaCarril = 260;
    const double umbral = alturaCarril * 0.40;
  

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Desliza hacia abajo para ver las notificaciones',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF555577), fontSize: 15),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Pantalla simulada del celular con panel que baja en tiempo real
            Container(
              width: 220,
              height: alturaCarril,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: const Color(0xFFDED8FF), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [

                    // Fondo oscuro del celular con hora y texto guia
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('10:30',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Row(children: [
                                Icon(Icons.wifi,
                                    color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Icon(Icons.battery_full,
                                    color: Colors.white, size: 13),
                              ]),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Text('Desliza desde arriba',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11)),
                        const Spacer(),
                      ],
                    ),

                    // Panel de notificaciones animado que crece con _panelAltura
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      height: _panelAltura,
                      decoration: const BoxDecoration(
                        color: Color(0xF0F0EEFF),
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(20)),
                      ),
                      child: _panelAltura > 60
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  // Icono de la notificacion simulada
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6B4EFF),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                        Icons.message_rounded,
                                        color: Colors.white,
                                        size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  // Texto de la notificacion simulada
                                  const Expanded(
                                    child: Text('Maria te escribio',
                                        style: TextStyle(
                                            color: Color(0xFF1A1A2E),
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.bold)),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Carril de deslizamiento con zona de inicio y zona destino
            SizedBox(
              width: 70,
              height: alturaCarril,
              child: Stack(
                alignment: Alignment.center,
                children: [

                  // Linea central del carril
                  Container(
                    width: 6,
                    height: alturaCarril,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDED8FF),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Zona destino abajo con icono y etiqueta
                  Positioned(
                    bottom: 0,
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF6B4EFF)
                                .withOpacity(0.15),
                            border: Border.all(
                                color: const Color(0xFF6B4EFF), width: 3),
                          ),
                          child: const Center(
                            child: Text('🎯',
                                style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const Text('Llega\naqui',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF6B4EFF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // Zona inicio arriba con GestureDetector
                  // Detecta el arrastre y actualiza _panelAltura en tiempo real
                  Positioned(
                    top: 0,
                    child: Column(
                      children: [
                        GestureDetector(
                          onVerticalDragStart: (d) {
                           _yInicioPanel = d.globalPosition.dy;
                          },
                          onVerticalDragUpdate: (d) {
                          if (_yInicioPanel == null) return;
                          final delta = d.globalPosition.dy - _yInicioPanel!;
                            // Mueve el panel proporcionalmente al arrastre
                            if (delta > 0) {
                              setState(() {
                                _panelAltura =
                                    (delta * 0.6).clamp(0, 130);
                              });
                            }
                            // Si llego al umbral completa el paso
                            if (delta >= umbral && !_pasoCompletado) {
                              _completarPaso();
                            }
                          },
                          onVerticalDragEnd: (_) {
                            _yInicioPanel = null;
                            // Si no completo, cierra el panel suavemente
                            if (!_pasoCompletado) {
                              setState(() => _panelAltura = 0);
                            }
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF059669),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669)
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('👆',
                                  style: TextStyle(fontSize: 22)),
                            ),
                          ),
                        ),
                        const Text('Empieza\naqui',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Usa el carril de la derecha\npara deslizar hacia abajo',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Color(0xFF9999BB), fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  // Pantalla final de celebracion al terminar la leccion
  Widget _buildFinal() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: const BoxDecoration(
            color: Color(0xFFD1FAE5),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🏅', style: TextStyle(fontSize: 80)),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ya sabes moverte\npor tu celular',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF059669),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Practicaste: inicio, atras,\napps recientes y notificaciones',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF555577),
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Overlay de felicitacion que aparece al completar cada gesto
  Widget _buildOverlayFelicitacion() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: ScaleTransition(
            scale: _checkAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎉', style: TextStyle(fontSize: 60)),
                  SizedBox(height: 16),
                  Text(
                    'Muy bien',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lo hiciste perfecto',
                    style: TextStyle(
                      color: Color(0xFF555577),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}