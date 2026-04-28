import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────
//  MODELO DE TUTORIAL
// ─────────────────────────────────────────────────────────────────
class TutorialApp {
  final String nombre;
  final String imagenAsset; // ruta a tu asset, ej: 'assets/icons/gmail.png'
  final Color fondo;
  final VoidCallback? onTap;

  const TutorialApp({
    required this.nombre,
    required this.imagenAsset,
    required this.fondo,
    this.onTap,
  });
}

//pantalla principal
class TutorialesScreen extends StatefulWidget {
  const TutorialesScreen({super.key});

  @override
  State<TutorialesScreen> createState() => _TutorialesScreenState();
}

class _TutorialesScreenState extends State<TutorialesScreen> {
  int _tabSeleccionado = 0; // 0 = Aplicaciones, 1 = Mi Progreso
  int _navIndex = 0;

  // ── Lista de apps ─────────────────────────────────────────────
  // Reemplaza 'imagenAsset' con la ruta real de tus imágenes/íconos.
  // Si usas iconos de paquetes (font_awesome_flutter, etc.) adapta el widget.
  final List<TutorialApp> _apps = [
    TutorialApp(
      nombre: 'Gmail// correo',
      imagenAsset: 'assets/icons/gmail.png',
      fondo: const Color(0xFFFFFFFF),
    ),
    TutorialApp(
      nombre: 'Whatsapp',
      imagenAsset: 'assets/icons/whatsapp.png',
      fondo: const Color(0xFFFFFFFF),
    ),
    TutorialApp(
      nombre: 'Teléfono de tu celular',
      imagenAsset: 'assets/icons/telefono.png',
      fondo: const Color(0xFFFFFFFF),
    ),
    TutorialApp(
      nombre: 'Nequi',
      imagenAsset: 'assets/icons/nequi.png',
      fondo: const Color(0xFFFFFFFF),
    ),
    TutorialApp(
      nombre: 'Mensajes de tu celular',
      imagenAsset: 'assets/icons/mensajes.png',
      fondo: const Color(0xFFFFFFFF),
    ),
    TutorialApp(
      nombre: 'Cámara de tu celular',
      imagenAsset: 'assets/icons/camara.png',
      fondo: const Color(0xFFFFFFFF),
    ),
  ];

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
                color: Color.fromARGB(255, 27, 27, 29),
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
              fontSize: 23,
            ),
          ),
        ),
      ),
    );
  }

  // ── GRID DE APLICACIONES ────────────────────────────────────────
  Widget _buildGridAplicaciones() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: _apps.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, i) {
          return _buildTarjetaApp(_apps[i], _coloresTarjeta[i]);
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
      height: 72,
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
        children: [
          _navIcon(Icons.home_rounded, 0),
          _navIcon(Icons.calendar_today_rounded, 1),
          // Botón central morado
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFF6B4EFF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x446B4EFF),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 30),
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
    // Navega a la pantalla del tutorial específico
    // Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleTutorialScreen(app: app)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo tutorial: ${app.nombre}'),
        backgroundColor: const Color(0xFF6B4EFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}