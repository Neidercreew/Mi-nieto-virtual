import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';

// ══════════════════════════════════════════════════════════
// LECCIÓN 2: La pantalla táctil
// Enseña al adulto mayor los gestos básicos de la pantalla
// Pasos: 0=intro, 1=toque simple, 2=toque objetivo,
//        3=toque largo, 4=deslizar arriba, 5=deslizar abajo,
//        6=doble toque, 7=felicitación
// ══════════════════════════════════════════════════════════

class TutorialPantallaTactilScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialPantallaTactilScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialPantallaTactilScreen> createState() =>
      _TutorialPantallaTactilScreenState();
}

class _TutorialPantallaTactilScreenState
    extends State<TutorialPantallaTactilScreen>
    with TickerProviderStateMixin {

  // ── Estado general ──────────────────────────────────────
  int _pasoActual = 0;
  bool _mostrarFelicitacion = false; // controla el popup "¡Muy bien!"
  bool _pasoCompletado = false;      // true cuando el usuario hizo el gesto correcto

  // ── Animación del círculo en paso 1 ────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Animación de feedback (✓ verde) ────────────────────
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  // ── Estado específico por paso ──────────────────────────
  int _opcionSeleccionada = -1;   // paso 2: qué botón tocó
// paso 4: flecha arriba activa
// paso 5: flecha abajo activa
  bool _cuadroPresionado = false; // paso 3: cuadro de toque largo
  // ── Animación del dedo demostrativo (pasos 4 y 5) ──────
  late AnimationController _fingerController;
  late Animation<double> _fingerAnimation;
  //scroll ejemplo para el adulto
  // Controllers para las prácticas de scroll
final ScrollController _scrollContactos = ScrollController();
double _panelAltura = 0;
  final List<Map<String, String>> _pasos = [
  {
    'instruccion': '¡Bienvenido a la\nLección 2! 👆\nHoy aprenderás a\nusar la pantalla\ncon tus dedos.',
    'tipo': 'intro',
  },
  {
    'instruccion': 'La pantalla responde\na tu toque.\n¡Toca el círculo\ngrande! 👇',
    'tipo': 'toque_simple',
  },
  {
    'instruccion': 'Ahora toca solo\nel ícono del\n☀️ SOL',
    'tipo': 'toque_objetivo',
  },
  {
    'instruccion': 'Mantén tu dedo\npresionado sobre\nel cuadro hasta\nque cambie de color ⏳',
    'tipo': 'toque_largo',
  },
  {
    'instruccion': 'Desliza tu dedo\nhacia ARRIBA ⬆️\nsobre la pantalla\ndel celular',
    'tipo': 'deslizar_arriba',
  },
  {
    'instruccion': 'Ahora desliza tu\ndedo hacia ABAJO ⬇️\nsobre la pantalla\ndel celular',
    'tipo': 'deslizar_abajo',
  },
  {
    'instruccion': 'Toca DOS VECES\nMUY RÁPIDO\nel círculo 👆👆',
    'tipo': 'doble_toque',
  },
  // ── TRANSICIÓN ──────────────────────────────────────
  {
    'instruccion': '¡Muy bien! 💪\nAhora vamos a\npracticar todo\nlo que aprendiste',
    'tipo': 'transicion',
  },
  // ── PRÁCTICAS ───────────────────────────────────────
  {
    'instruccion': 'PRÁCTICA 1\nToca el ícono\nde Llamadas 📞\ncomo si fueras\na llamar a alguien',
    'tipo': 'practica_llamada',
  },
  {
    'instruccion': 'PRÁCTICA 2\nMantén presionada\nuna aplicación\nhasta que vibre 📳',
    'tipo': 'practica_mantener',
  },
  {
    'instruccion': 'PRÁCTICA 3\nDesliza hacia arriba\npara ver más\ncontactos ⬆️',
    'tipo': 'practica_scroll',
  },
  {
    'instruccion': 'PRÁCTICA 4\nBaja el panel\ndeslizando desde\narriba ⬇️',
    'tipo': 'practica_panel',
  },
  {
    'instruccion': 'PRÁCTICA 5\nToca DOS VECES\nla foto para\nagrandarla 🔍',
    'tipo': 'practica_zoom',
  },
  // ── FINAL ───────────────────────────────────────────
  {
    'instruccion': '🎉 ¡Lo lograste!\nYa sabes usar\nla pantalla táctil\ncomo un experto.',
    'tipo': 'final',
  },
];

  // ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial;

    // Animación de pulso para el círculo del paso 1
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animación del check verde al completar un gesto
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    // Dedo animado que demuestra el gesto en loop continuo
    _fingerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: false);

  _fingerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(parent: _fingerController, curve: Curves.easeInOut),
);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    _fingerController.dispose();
    _scrollContactos.dispose();
    super.dispose();
  }

  // ── Guarda el paso en el backend y avanza ───────────────
  Future<void> _completarPaso() async {
    if (_pasoCompletado) return; // evita doble ejecución

    setState(() => _pasoCompletado = true);

    // Muestra el popup "¡Muy bien!" por 1.5 segundos
    setState(() => _mostrarFelicitacion = true);
    _checkController.forward(from: 0);

    // Guarda en el backend el paso actual
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    if (userId != null) {
      await ApiService.guardarPaso(
        userId,
        'pantalla_tactil',
        _pasoActual + 1, // guarda el siguiente paso (progreso real)
      );
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _mostrarFelicitacion = false;
        _pasoCompletado = false;
        _opcionSeleccionada = -1;
        // Avanza al siguiente paso
        if (_pasoActual < _pasos.length - 1) _pasoActual++;
      });
      _checkController.reset();
    }
  }

  // ── Guarda completada:true al terminar toda la lección ──
  Future<void> _terminarLeccion() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    if (userId != null) {
      await ApiService.guardarPaso(
        userId,
        'pantalla_tactil',
        _pasos.length,
        completada: true,
      );
    }
    if (mounted) Navigator.pop(context); // regresa al mapa
  }

  // ════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ════════════════════════════════════════════════════════
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
          'La pantalla táctil',
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
              // Barra de progreso arriba
              _buildProgreso(),
              const SizedBox(height: 16),

              // Caja morada con la instrucción del paso actual
              _buildInstruccion(paso['instruccion']!),
              const SizedBox(height: 24),

              // Área interactiva — cambia según el paso
              Expanded(
                child: Center(child: _buildAreaInteractiva(paso['tipo']!)),
              ),

              // Botón inferior — solo en intro y final
              if (esPrimerPaso || esUltimoPaso)
                _buildBotonPrincipal(esUltimoPaso),
            ],
          ),

          // Overlay "¡Muy bien!" que aparece al completar cada gesto
          if (_mostrarFelicitacion) _buildOverlayFelicitacion(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // WIDGETS DE UI
  // ════════════════════════════════════════════════════════

  // Barra de progreso superior
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
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // Caja morada con instrucción
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

  // Botón verde "¡Terminé!" o morado "Siguiente"
  Widget _buildBotonPrincipal(bool esUltimo) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: esUltimo ? _terminarLeccion : () => setState(() => _pasoActual++),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: esUltimo ? const Color(0xFF059669) : const Color(0xFF6B4EFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              esUltimo ? '¡Terminé! 🎉' : 'Siguiente →',
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

  // ════════════════════════════════════════════════════════
  // ÁREA INTERACTIVA — un widget por tipo de paso
  // ════════════════════════════════════════════════════════
  Widget _buildAreaInteractiva(String tipo) {
    switch (tipo) {
      case 'intro':
        return _buildIntro();
      case 'toque_simple':
        return _buildToqueSimple();
      case 'toque_objetivo':
        return _buildToqueObjetivo();
      case 'toque_largo':
        return _buildToqueLargo();
      case 'deslizar_arriba':
        return _buildDeslizar(esArriba: true);
      case 'deslizar_abajo':
        return _buildDeslizar(esArriba: false);
      case 'doble_toque':
        return _buildDobleToque();
      case 'transicion':
        return _buildTransicion();
      case 'practica_llamada':
        return _buildPracticaLlamada();
      case 'practica_mantener':
        return _buildPracticaMantener();
      case 'practica_scroll':
        return _buildPracticaScroll();
      case 'practica_panel':
        return _buildPracticaPanel();
      case 'practica_zoom':
        return _buildPracticaZoom();
      case 'final':
        return _buildFinal();
      default:
  return const SizedBox();
    }
  }

  // PASO 0 — Pantalla de introducción con imagen ilustrativa
  Widget _buildIntro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mano tocando pantalla ilustración
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFDED8FF),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('👆', style: TextStyle(fontSize: 80)),
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'La pantalla de tu celular\nreacciona cuando la tocas\ncon el dedo.',
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

  // PASO 1 — Círculo grande que pulsa, el usuario lo toca
  Widget _buildToqueSimple() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¡Toca el círculo!',
          style: TextStyle(
            color: Color(0xFF555577),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        // Círculo animado con pulso
        ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: _completarPaso, // detecta el toque
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6B4EFF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4EFF).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Text('👆', style: TextStyle(fontSize: 60)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Toca el círculo morado',
          style: TextStyle(color: Color(0xFF9999BB), fontSize: 14),
        ),
      ],
    );
  }

  // PASO 2 — Tres íconos, el usuario debe tocar el sol
  Widget _buildToqueObjetivo() {
    // Opciones: sol (correcto), lluvia, luna
    final opciones = [
      {'emoji': '🌧️', 'correcto': false, 'label': 'Lluvia'},
      {'emoji': '☀️', 'correcto': true,  'label': 'Sol'},
      {'emoji': '🌙', 'correcto': false, 'label': 'Luna'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Toca solo el ☀️ Sol',
          style: TextStyle(color: Color(0xFF555577), fontSize: 16),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(opciones.length, (i) {
            final op = opciones[i];
            final seleccionado = _opcionSeleccionada == i;
            final esCorrecto = op['correcto'] as bool;

            return GestureDetector(
              onTap: () {
                if (_pasoCompletado) return;
                setState(() => _opcionSeleccionada = i);
                if (esCorrecto) {
                  // Tocó el correcto → avanza
                  _completarPaso();
                } else {
                  // Tocó el incorrecto → feedback visual y resetea
                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (mounted) setState(() => _opcionSeleccionada = -1);
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: seleccionado
                      ? (esCorrecto
                          ? const Color(0xFF059669).withOpacity(0.2)
                          : const Color(0xFFE53E3E).withOpacity(0.2))
                      : const Color(0xFFDED8FF),
                  border: Border.all(
                    color: seleccionado
                        ? (esCorrecto
                            ? const Color(0xFF059669)
                            : const Color(0xFFE53E3E))
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    op['emoji'] as String,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        const Text(
          'Busca el sol entre las opciones',
          style: TextStyle(color: Color(0xFF9999BB), fontSize: 14),
        ),
      ],
    );
  }

  // PASO 3 — Cuadro que cambia de color al mantener presionado
Widget _buildToqueLargo() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'Mantén presionado el cuadro',
        style: TextStyle(color: Color(0xFF555577), fontSize: 16),
      ),
      const SizedBox(height: 32),
      GestureDetector(
        onLongPress: () {
          setState(() => _cuadroPresionado = true);
          _completarPaso();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: _cuadroPresionado
                ? const Color(0xFF059669)
                : const Color(0xFF6B4EFF),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: (_cuadroPresionado
                        ? const Color(0xFF059669)
                        : const Color(0xFF6B4EFF))
                    .withOpacity(0.4),
                blurRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _cuadroPresionado ? '✅' : '👇',
              style: const TextStyle(fontSize: 60),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Pon el dedo y no lo sueltes',
        style: TextStyle(color: Color(0xFF9999BB), fontSize: 14),
      ),
    ],
  );
}

// PASO 4 y 5 — Deslizar arriba o abajo
// Detecta por distancia recorrida, no por velocidad
// El dedo animado demuestra el gesto en loop para que el adulto mayor vea qué hacer
Widget _buildDeslizar({required bool esArriba}) {
  const double alturaCarril = 320;
  const double umbral = alturaCarril * 0.65; // debe recorrer el 65% del carril

  double? yInicio; // guardamos dónde empezó el dedo

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Instrucción con flecha
      Text(
        esArriba ? '⬆️ Desliza hacia ARRIBA' : '⬇️ Desliza hacia ABAJO',
        style: const TextStyle(
          color: Color(0xFF555577),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),

      // El carril donde ocurre todo
      SizedBox(
        width: 160,
        height: alturaCarril,
        child: Stack(
          alignment: Alignment.center,
          children: [

            // ── Línea vertical central (el "camino") ──────────
            Container(
              width: 6,
              height: alturaCarril,
              decoration: BoxDecoration(
                color: const Color(0xFFDED8FF),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // ── Zona DESTINO arriba o abajo según dirección ───
            Positioned(
              top: esArriba ? 0 : null,
              bottom: esArriba ? null : 0,
              child: Column(
                children: [
                  if (!esArriba)
                    const Text(
                      '¡Llega\naquí!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B4EFF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6B4EFF).withOpacity(0.15),
                      border: Border.all(color: const Color(0xFF6B4EFF), width: 3),
                    ),
                    child: const Center(
                      child: Text('🎯', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  if (esArriba)
                    const Text(
                      '¡Llega\naquí!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B4EFF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

            // ── Zona INICIO con GestureDetector ───────────────
            Positioned(
              top: esArriba ? null : 0,
              bottom: esArriba ? 0 : null,
              child: Column(
                children: [
                  if (esArriba)
                    const Text(
                      'Empieza\naquí',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  GestureDetector(
                    onVerticalDragStart: (details) {
                      // Guardamos la posición Y donde el usuario puso el dedo
                      yInicio = details.globalPosition.dy;
                    },
                    onVerticalDragUpdate: (details) {
                      if (yInicio == null) return;
                      // Calculamos cuánto se movió desde el inicio
                      final delta = details.globalPosition.dy - yInicio!;
                      // Para arriba: el delta es negativo (sube), lo invertimos
                      // Para abajo: el delta es positivo (baja)
                      final recorrido = esArriba ? -delta : delta;
                      // Si llegó al umbral y no había completado ya → completar
                      if (recorrido >= umbral && !_pasoCompletado) {
                        _completarPaso();
                      }
                    },
                    onVerticalDragEnd: (_) {
                      yInicio = null; // limpiamos al soltar
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF059669),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('👆', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  ),
                  if (!esArriba)
                    const Text(
                      'Empieza\naquí',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

            // ── Dedo animado que demuestra el gesto ───────────
            // Se mueve en loop para que el adulto mayor vea qué hacer
            AnimatedBuilder(
              animation: _fingerAnimation,
              builder: (context, child) {
                final t = _fingerAnimation.value; // va de 0.0 a 1.0

                // Si es arriba: el dedo va de abajo (260px) hacia arriba (40px)
                // Si es abajo: el dedo va de arriba (40px) hacia abajo (260px)
                final yPos = esArriba
                    ? 260 - (220 * t)   // 260 → 40
                    : 40 + (220 * t);   // 40  → 260

                // Fade in al inicio, fade out al final para que el loop se vea suave
                final opacity = t < 0.1
                    ? t / 0.1
                    : t > 0.85
                        ? (1.0 - t) / 0.15
                        : 1.0;

                return Positioned(
                  top: yPos,
                  right: 10, // al lado de la línea central
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: const Text('👆', style: TextStyle(fontSize: 26)),
                  ),
                );
              },
            ),

          ],
        ),
      ),

      const SizedBox(height: 16),
      // Instrucción de texto debajo
      Text(
        esArriba
            ? 'Pon el dedo en el círculo verde\ny desliza hacia arriba'
            : 'Pon el dedo en el círculo verde\ny desliza hacia abajo',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF9999BB),
          fontSize: 13,
          height: 1.4,
        ),
      ),
    ],
  );
}

  // PASO 6 — Doble toque en círculo
  Widget _buildDobleToque() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Toca DOS veces muy rápido',
          style: TextStyle(color: Color(0xFF555577), fontSize: 16),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onDoubleTap: _completarPaso, // detecta el doble toque
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6B4EFF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4EFF).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Text('👆👆', style: TextStyle(fontSize: 50)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Tap — Tap, ¡rápido!',
          style: TextStyle(color: Color(0xFF9999BB), fontSize: 14),
        ),
      ],
    );
  }

  // PASO 7 — Pantalla final de celebración
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
          '¡Ahora sabes usar\nla pantalla táctil!',
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
          'Practicaste: tocar, mantener,\ndeslizar y doble toque 👏',
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

  // ════════════════════════════════════════════════════════
  // OVERLAY — popup "¡Muy bien!" que aparece al completar gesto
  // ════════════════════════════════════════════════════════
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
                    '¡Muy bien!',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lo hiciste perfecto 👏',
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
// ── TRANSICIÓN — pantalla entre teoría y práctica ──────
Widget _buildTransicion() {
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
          child: Text('💪', style: TextStyle(fontSize: 80)),
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        '¡Excelente!\nAprendiste los gestos básicos',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF3C3489),
          fontSize: 22,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Ahora vamos a practicar\ncada uno en situaciones reales',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF555577),
          fontSize: 16,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 32),
      // Botón para continuar a las prácticas
      GestureDetector(
        onTap: () => setState(() => _pasoActual++),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF6B4EFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            '¡Vamos a practicar! →',
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

// ── PRÁCTICA 1 — Toca el ícono de llamadas ─────────────
Widget _buildPracticaLlamada() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'Toca el ícono verde de llamadas',
        style: TextStyle(color: Color(0xFF555577), fontSize: 16),
      ),
      const SizedBox(height: 8),
      // Dedito animado indicando dónde tocar
      const Text('👆', style: TextStyle(fontSize: 32)),
      const SizedBox(height: 16),
      // Simulación de pantalla de apps
      Container(
        width: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDED8FF), width: 2),
        ),
        child: Column(
          children: [
            const Text(
              'Aplicaciones',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Ícono correcto — llamadas
                GestureDetector(
                  onTap: _completarPaso,
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withOpacity(0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.phone_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 6),
                      const Text('Llamadas',
                          style: TextStyle(fontSize: 11, color: Color(0xFF555577))),
                    ],
                  ),
                ),
                // Ícono incorrecto — cámara
                Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 6),
                    const Text('Cámara',
                        style: TextStyle(fontSize: 11, color: Color(0xFF555577))),
                  ],
                ),
                // Ícono incorrecto — mensajes
                Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.message_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 6),
                    const Text('Mensajes',
                        style: TextStyle(fontSize: 11, color: Color(0xFF555577))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

// ── PRÁCTICA 2 — Mantener presionada una app ───────────
Widget _buildPracticaMantener() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'Mantén presionada la app',
        style: TextStyle(color: Color(0xFF555577), fontSize: 16),
      ),
      const SizedBox(height: 8),
      const Text('👇', style: TextStyle(fontSize: 32)),
      const SizedBox(height: 16),
      Container(
        width: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDED8FF), width: 2),
        ),
        child: Column(
          children: [
            const Text(
              'Mantén presionado hasta que vibre',
              style: TextStyle(color: Color(0xFF555577), fontSize: 13),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onLongPress: _completarPaso,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4EFF),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B4EFF).withOpacity(0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.grid_view_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 6),
                  const Text('Configuración',
                      style: TextStyle(fontSize: 12, color: Color(0xFF555577))),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// PRÁCTICA 3 — Scroll lista de contactos
// La lista se mueve en tiempo real mientras el usuario arrastra el carril
Widget _buildPracticaScroll() {
  const double alturaCarril = 260;
  const double umbral = alturaCarril * 0.65;
  double? yInicio;

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'Desliza hacia arriba para ver más',
        style: TextStyle(color: Color(0xFF555577), fontSize: 16),
      ),
      const SizedBox(height: 12),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Lista de contactos con scroll real ───────────
          Container(
            width: 220,
            height: alturaCarril,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDED8FF), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  // Cabecera morada fija
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: const Color(0xFF6B4EFF),
                    child: const Row(
                      children: [
                        Icon(Icons.contacts_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text('Contactos',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  // Lista scrolleable con más contactos de los visibles
                  Expanded(
                    child: ListView(
                      controller: _scrollContactos, // 👈 controlamos el scroll desde el carril
                      physics: const NeverScrollableScrollPhysics(), // el usuario NO scrollea aquí directamente
                      children: [
                        ('👴', 'Abuelo Carlos'),
                        ('👩', 'María López'),
                        ('👨', 'Juan Pérez'),
                        ('👵', 'Rosa Martínez'),
                        ('👦', 'Pedro Gómez'),
                        ('👧', 'Ana Ruiz'),
                        ('🧓', 'Luis Herrera'),
                      ].map((c) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Color(0xFFF0EEFF))),
                            ),
                            child: Row(
                              children: [
                                Text(c.$1, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Text(c.$2,
                                    style: const TextStyle(
                                        color: Color(0xFF1A1A2E), fontSize: 13)),
                              ],
                            ),
                          )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Carril de deslizamiento ───────────────────────
          SizedBox(
            width: 70,
            height: alturaCarril,
            child: Stack(
              alignment: Alignment.center,
              children: [

                // Línea central
                Container(
                  width: 6,
                  height: alturaCarril,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDED8FF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                // Zona destino arriba
                Positioned(
                  top: 0,
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6B4EFF).withOpacity(0.15),
                          border: Border.all(color: const Color(0xFF6B4EFF), width: 3),
                        ),
                        child: const Center(
                          child: Text('🎯', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      const Text(
                        '¡Llega\naquí!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B4EFF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Zona inicio abajo con GestureDetector
                Positioned(
                  bottom: 0,
                  child: Column(
                    children: [
                      const Text(
                        'Empieza\naquí',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onVerticalDragStart: (details) {
                          yInicio = details.globalPosition.dy;
                        },
                        onVerticalDragUpdate: (details) {
                          if (yInicio == null) return;
                          final delta = details.globalPosition.dy - yInicio!;
                          final subio = -delta; // positivo cuando sube

                          // Mueve la lista en tiempo real proporcional al arrastre
                          // Multiplicamos por 1.5 para que el scroll se note bien
                          if (subio > 0 && _scrollContactos.hasClients) {
                            _scrollContactos.jumpTo(
                              (subio * 1.5).clamp(
                                0,
                                _scrollContactos.position.maxScrollExtent,
                              ),
                            );
                          }

                          // Si llegó al umbral → completar
                          if (subio >= umbral && !_pasoCompletado) {
                            _completarPaso();
                          }
                        },
                        onVerticalDragEnd: (_) => yInicio = null,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF059669),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF059669).withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('👆', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Dedo animado demostrativo
                AnimatedBuilder(
                  animation: _fingerAnimation,
                  builder: (context, child) {
                    final t = _fingerAnimation.value;
                    final yPos = 200 - (160 * t);
                    final opacity = t < 0.1
                        ? t / 0.1
                        : t > 0.85
                            ? (1.0 - t) / 0.15
                            : 1.0;
                    return Positioned(
                      top: yPos,
                      right: 2,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: const Text('👆', style: TextStyle(fontSize: 22)),
                      ),
                    );
                  },
                ),

              ],
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),
      const Text(
        'Usa el carril de la derecha\npara deslizar hacia arriba',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF9999BB), fontSize: 13, height: 1.4),
      ),
    ],
  );
}

// ── PRÁCTICA 4 — Panel de notificaciones simulado ──────
// PRÁCTICA 4 — Panel de notificaciones
// El panel aparece deslizándose hacia abajo en tiempo real mientras el usuario arrastra
Widget _buildPracticaPanel() {
  const double alturaCarril = 260;
  const double alturaMaxPanel = 130; // altura máxima que alcanza el panel al abrirse
  const double umbral = alturaCarril * 0.65;
  double? yInicio;

  return StatefulBuilder(
    // StatefulBuilder porque _panelAltura cambia localmente mientras arrastra
    builder: (context, setLocalState) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Desliza hacia abajo para ver el panel',
            style: TextStyle(color: Color(0xFF555577), fontSize: 16),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Pantalla simulada con panel que se abre ───
              Container(
                width: 220,
                height: alturaCarril,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDED8FF), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [

                      // Fondo — pantalla del celular
                      Column(
                        children: [
                          // Barra de estado
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('10:30',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Row(
                                  children: [
                                    const Icon(Icons.wifi,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.battery_full,
                                        color: Colors.white, size: 14),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Hint en el centro
                          const Text(
                            '☝️ Desliza desde arriba',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                          const Spacer(),
                        ],
                      ),

                      // Panel de notificaciones que baja en tiempo real
                      // Su altura es _panelAltura que crece mientras el usuario arrastra
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        height: _panelAltura,
                        decoration: const BoxDecoration(
                          color: Color(0xF0F0EEFF),
                          borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(20)),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20)),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildIconoPanel(Icons.wifi, 'WiFi',
                                        const Color(0xFF059669)),
                                    _buildIconoPanel(Icons.bluetooth,
                                        'Bluetooth', const Color(0xFF3B82F6)),
                                    _buildIconoPanel(Icons.do_not_disturb,
                                        'Silencio', const Color(0xFFE53E3E)),
                                    _buildIconoPanel(Icons.brightness_6,
                                        'Brillo', const Color(0xFFFFB300)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ── Carril de deslizamiento ───────────────────
              SizedBox(
                width: 70,
                height: alturaCarril,
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    // Línea central
                    Container(
                      width: 6,
                      height: alturaCarril,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDED8FF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    // Zona destino abajo
                    Positioned(
                      bottom: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF6B4EFF).withOpacity(0.15),
                              border: Border.all(
                                  color: const Color(0xFF6B4EFF), width: 3),
                            ),
                            child: const Center(
                              child: Text('🎯', style: TextStyle(fontSize: 20)),
                            ),
                          ),
                          const Text(
                            '¡Llega\naquí!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF6B4EFF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Zona inicio arriba con GestureDetector
                    Positioned(
                      top: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF059669),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF059669).withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onVerticalDragStart: (details) {
                                yInicio = details.globalPosition.dy;
                              },
                              onVerticalDragUpdate: (details) {
                                if (yInicio == null) return;
                                final delta =
                                    details.globalPosition.dy - yInicio!;
                                // delta positivo = bajó el dedo

                                // Mueve el panel en tiempo real proporcional al arrastre
                                if (delta > 0) {
                                  setLocalState(() {
                                    _panelAltura =
                                        (delta * 0.6).clamp(0, alturaMaxPanel);
                                  });
                                }

                                // Si llegó al umbral → completar
                                if (delta >= umbral && !_pasoCompletado) {
                                  _completarPaso();
                                }
                              },
                              onVerticalDragEnd: (_) {
                                yInicio = null;
                                // Si no completó, cierra el panel suavemente
                                if (!_pasoCompletado) {
                                  setLocalState(() => _panelAltura = 0);
                                }
                              },
                              child: const Center(
                                child:
                                    Text('👆', style: TextStyle(fontSize: 22)),
                              ),
                            ),
                          ),
                          const Text(
                            'Empieza\naquí',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dedo animado demostrativo (va de arriba hacia abajo)
                    AnimatedBuilder(
                      animation: _fingerAnimation,
                      builder: (context, child) {
                        final t = _fingerAnimation.value;
                        final yPos = 40 + (160 * t); // 40 → 200
                        final opacity = t < 0.1
                            ? t / 0.1
                            : t > 0.85
                                ? (1.0 - t) / 0.15
                                : 1.0;
                        return Positioned(
                          top: yPos,
                          right: 2,
                          child: Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: const Text('👆',
                                style: TextStyle(fontSize: 22)),
                          ),
                        );
                      },
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
    },
  );
}

// Ícono pequeño para el panel de notificaciones
Widget _buildIconoPanel(IconData icon, String label, Color color) {
  return Column(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF555577))),
    ],
  );
}

// ── PRÁCTICA 5 — Doble toque para agrandar foto ────────
Widget _buildPracticaZoom() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'Toca DOS VECES la foto',
        style: TextStyle(color: Color(0xFF555577), fontSize: 16),
      ),
      const SizedBox(height: 8),
      const Text('👆👆', style: TextStyle(fontSize: 32)),
      const SizedBox(height: 16),
      GestureDetector(
        onDoubleTap: _completarPaso,
        child: Container(
          width: 240,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFFDED8FF),
            border: Border.all(color: const Color(0xFF6B4EFF), width: 2),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🌅', style: TextStyle(fontSize: 80)),
              SizedBox(height: 8),
              Text(
                'Toca dos veces para\nagrandar la foto',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF555577), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}  
}