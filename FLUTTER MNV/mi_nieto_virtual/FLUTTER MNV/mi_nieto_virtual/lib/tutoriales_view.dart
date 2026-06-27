import 'package:shared_preferences/shared_preferences.dart';//permite guardar cambios pequeños, como el nivel del usuario, sin necesidad de una base de datos completa
import 'seleccion_nivel.dart';
import 'detalle_tutorial.dart';
import 'package:flutter/material.dart';
import 'tutorial_botones.dart';


//  MODELO DE TUTORIAL
class TutorialApp {
  final String nombre; // nombre de la app o función, ej: 'Gmail', 'Teléfono', etc.
  final String imagenAsset; // ruta a tu asset, ej: 'assets/icons/gmail.png'
  final Color fondo;
  final String nivel; 
  final VoidCallback? onTap;

  const TutorialApp({
    required this.nombre,
    required this.imagenAsset,
    required this.fondo,
    required this.nivel,
    this.onTap,
  });
}
//  PANTALLA PRINCIPAL
class TutorialesScreen extends StatefulWidget {
  const TutorialesScreen({super.key});

  @override
  State<TutorialesScreen> createState() => _TutorialesScreenState();
}

class _TutorialesScreenState extends State<TutorialesScreen> {
 
// ── Verificación de nivel al abrir la pantalla ──────────────
  @override
  void initState() {
    super.initState();
    _verificarNivel();
  }

Future<void> _verificarNivel() async {
    final prefs = await SharedPreferences.getInstance();
    final nivel = prefs.getString('nivel_usuario');

    if (nivel == null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SeleccionNivelScreen(),
        ),
      );
    } else {
      // ← ESTO ES LO NUEVO: carga el nivel en la variable
      setState(() {
        _nivelUsuario = nivel ?? 'basico';
      });
    }
  }
  String _nivelUsuario = 'basico'; 
  int _navIndex = 0;
  int _tabSeleccionado = 0;
 List<TutorialApp> get _apps => [
TutorialApp(
  nombre: 'Conociendo tu celular',
  imagenAsset: 'assets/icons/celular.png',
  fondo: const Color(0xFFFFFFFF),
  nivel: 'basico',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const TutorialBotonesScreen(),
    ),
  ),
),
  TutorialApp(
    nombre: 'Cómo navegar',
    imagenAsset: 'assets/icons/navegar.png',
    fondo: const Color(0xFFFFFFFF),
    nivel: 'basico',
  ),
  TutorialApp(
    nombre: 'Cámara de tu celular',
    imagenAsset: 'assets/icons/camara.png',
    fondo: const Color(0xFFFFFFFF),
    nivel: 'basico',
  ),
  TutorialApp(
    nombre: 'Teléfono de tu celular',
    imagenAsset: 'assets/icons/telefono.png',
    fondo: const Color(0xFFFFFFFF),
    nivel: 'basico',
  ),
  TutorialApp(
    nombre: 'Whatsapp',
    imagenAsset: 'assets/icons/whatsapp.png',
    fondo: const Color(0xFFFFFFFF),
    nivel: 'intermedio',
  ),
  TutorialApp(
    nombre: 'Gmail// correo',
    imagenAsset: 'assets/icons/gmail.png',
    fondo: const Color(0xFFFFFFFF),
    nivel: 'intermedio',
  ),
  TutorialApp(
    nombre: 'Mensajes de tu celular',
    imagenAsset: 'assets/icons/mensajes.png',
    fondo: const Color(0xFFFFFFFF),
    nivel: 'intermedio',
  ),
  TutorialApp(
    nombre: 'Calendario',
    imagenAsset: 'assets/icons/calendario.png',
    fondo: const Color(0xFFFFFFFF),
    nivel: 'intermedio',
  ),
  TutorialApp(
    nombre: 'Nequi',
    imagenAsset: 'assets/icons/nequi.png',
    fondo: const Color(0xFFFFFFFF),
    nivel: 'avanzado',
  ),
];
// Lista filtrada según nivel del usuario
List<TutorialApp> get _appsFiltradas {
    return _apps.where((a) => a.nivel == _nivelUsuario).toList();
  }
  // ── Colores de fondo de cada tarjeta (igual que en el prototipo) ──
  final List<Color> _coloresTarjeta = [
    const Color(0xFFE8F4FD), // gmail  – azul muy claro
    const Color(0xFFE8F8EE), // whatsapp – verde muy claro
    const Color(0xFFEAF5FF), // teléfono – azul
    const Color(0xFFF3EEFF), // nequi – lila
    const Color(0xFFE3F0FF), // mensajes – azul
    const Color(0xFFE3F0FF), // cámara – azul
  ];

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EEFF), // fondo lila suave
      // ── APP BAR ─────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EEFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF6B4EFF), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Tutoriales',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Botón para cambiar nivel
        IconButton(
          icon: const Icon(Icons.tune_rounded,
            color: Color(0xFF6B4EFF), size: 24),
          tooltip: 'Cambiar nivel',
          onPressed: () async {
            // Borra el nivel guardado
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('nivel_usuario');

            // Navega a selección de nivel
            if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SeleccionNivelScreen(),
                 ),
              );
            }
          },
        ),
          // Ícono de notificaciones (campana con punto rojo)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Color(0xFF1A1A2E), size: 26),
                  onPressed: () {},
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── CUERPO ──────────────────────────────────────────────
      body: Column(
        children: [
          // Subtítulo
          const Padding(
            padding: EdgeInsets.only(top: 2, bottom: 16),
            child: Text(
              '¿Sobre qué quieres aprender hoy?',
              style: TextStyle(
                color: Color(0xFF555577),
                fontSize: 25,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // ── TABS ──────────────────────────────────────────
          _buildTabs(),

          const SizedBox(height: 20),

          // ── CONTENIDO ──────────────────────────────────────
          Expanded(
            child: _tabSeleccionado == 0
                ? _buildGridAplicaciones()
                : _buildMiProgreso(),
          ),
        ],
      ),

      // ── BOTTOM NAV ──────────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── TABS ────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFDED8FF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _tabItem('Aplicaciones', 0),
          _tabItem('Mi Progreso', 1),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final selected = _tabSeleccionado == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabSeleccionado = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6B4EFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF6B4EFF),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // ── GRID DE APLICACIONES
  Widget _buildGridAplicaciones() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: _appsFiltradas.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, i) {
          return _buildTarjetaApp(_appsFiltradas[i], _coloresTarjeta[i % _coloresTarjeta.length]);
        },
      ),
    );
  }

  Widget _buildTarjetaApp(TutorialApp app, Color bgColor) {
    return GestureDetector(
      onTap: app.onTap ?? () => _abrirTutorial(app),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Ícono / imagen ──────────────────────────────
            SizedBox(
              width: 70,
              height: 70,
              child: Image.asset(
                app.imagenAsset,
                fit: BoxFit.contain,
                // Si el asset no existe en dev, muestra un placeholder:
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.apps_rounded,
                      size: 40, color: Color(0xFF6B4EFF)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── Nombre ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                app.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MI PROGRESO (placeholder) ────────────────────────────────────
  Widget _buildMiProgreso() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_rounded,
              size: 64, color: Color(0xFF6B4EFF)),
          SizedBox(height: 16),
          Text(
            'Aquí verás tu progreso\ncuando completes tutoriales',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF555577),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM NAV ──────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      height: 80, // un poco más alto para que el botón grande respire
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _navIcon(Icons.home_rounded, 0),
          _navIcon(Icons.calendar_today_rounded, 1),

          // ── BOTÓN CENTRAL: amarillo ámbar, más grande, escudo + lupa ──
          GestureDetector(
            onTap: () {
              // Aquí conectas la navegación al Detector de Fraude cuando lo tengas listo
              // Navigator.push(context, MaterialPageRoute(builder: (_) => DetectorFraudeScreen()));
            },
            child: Container(
              width: 68,   // más grande que el original (era 54)
              height: 68,
              decoration: BoxDecoration(
                // Amarillo ámbar
                color: const Color(0xFFFFB300),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withOpacity(0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              // Stack para superponer el escudo y la lupa
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Escudo de fondo
                  const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  // Lupa encima, desplazada un poco abajo-derecha para que se vea bien
                  Positioned(
                    bottom: 12,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB300), // mismo fondo para "recortar" el escudo
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _navIcon(Icons.menu_book_rounded, 3),
          _navIcon(Icons.person_rounded, 4),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    final selected = _navIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _navIndex = index),
      child: Icon(
        icon,
        size: 26,
        color: selected ? const Color(0xFF6B4EFF) : const Color(0xFFBBBBCC),
      ),
    );
  }

  // ── HELPER ──────────────────────────────────────────────────────
  void _abrirTutorial(TutorialApp app) {
    // Datos de prueba para ver cómo se ve — luego ponés el contenido real
    final pasosPrueba = [
      PasoTutorial(
        titulo: 'Paso 1: Bienvenido',
        descripcion:
            'En este tutorial aprenderás a usar ${app.nombre} de manera fácil y sencilla.',
        imagenAsset: 'assets/pasos/paso1.png',
      ),
      const PasoTutorial(
        titulo: 'Paso 2: Lo primero',
        descripcion:
            'Primero busca el ícono en tu pantalla principal y tócalo suavemente con tu dedo.',
        imagenAsset: 'assets/pasos/paso2.png',
      ),
      const PasoTutorial(
        titulo: 'Paso 3: ¡Lo lograste!',
        descripcion:
            '¡Muy bien! Ya sabes el primer paso. Sigue practicando y lo aprenderás rápido.',
        imagenAsset: 'assets/pasos/paso3.png',
      ),
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleTutorialScreen(
          nombreTutorial: app.nombre,
          pasos: pasosPrueba,
        ),
      ),
    );
  }
}