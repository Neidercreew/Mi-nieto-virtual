import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tutoriales_view.dart'; // 👈 IMPORTA LA PANTALLA DE TUTORIALES

class MenuPrincipalScreen extends StatefulWidget {
  const MenuPrincipalScreen({super.key});

  @override
  State<MenuPrincipalScreen> createState() => _MenuPrincipalScreenState();
}

class _MenuPrincipalScreenState extends State<MenuPrincipalScreen> {
  String nombreUsuario = "Usuario"; // Nombre por defecto

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _cargarNombre(); // Cargamos el nombre apenas se abra el menú
  }

  // Función para leer el nombre guardado
  Future<void> _cargarNombre() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 'nombre_usuario' debe ser el mismo nombre que usamos en registro_nombre.dart
      nombreUsuario = prefs.getString('nombre_usuario') ?? "Usuario";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        children: [
          // Piso uno: menú principal
          Column(
            children: [
              _buildHeader(nombreUsuario), // Pasamos el nombre al Header
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 👇 CAMBIO: se le agrega onTap para navegar a TutorialesScreen
                    _buildMenuCard(
                      context,
                      "Tutoriales",
                      "Aprende a usar tu celular paso a paso",
                      Icons.menu_book_rounded,
                      const Color(0xFF4CAF50),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TutorialesScreen(),
                          ),
                        );
                      },
                    ),
                    // Los demás botones sin cambios por ahora
                    _buildMenuCard(
                      context,
                      "Detector de Fraude",
                      "Verifica si un mensaje es peligroso",
                      Icons.security_update_warning_rounded,
                      const Color(0xFFE53935),
                    ),
                    _buildMenuCard(
                      context,
                      "Mensajes de Ánimo",
                      "Palabras para alegrar tu día",
                      Icons.volunteer_activism_rounded,
                      const Color(0xFFEC407A),
                    ),
                    _buildBannerProgreso(),
                  ],
                ),
              ),
            ],
          ),
          // Piso 2: pantalla de progreso
          _buildPantallaProgreso(),
        ],
      ),
    );
  }

  Widget _buildHeader(String nombre) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 30, right: 30, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6200EE), Color(0xFF3700B3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "¡Hola, $nombre!",
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "¿Qué vamos a\nhacer hoy?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // 👇 CAMBIO: se agrega el parámetro opcional onTap
  Widget _buildMenuCard(
    BuildContext context,
    String titulo,
    String subtitulo,
    IconData icono,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        // 👇 Si le pasan onTap lo usa, si no imprime en consola
        onTap: onTap ?? () => print("Tap en $titulo"),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icono, size: 45, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerProgreso() {
    return GestureDetector(
      onTap: () {
        // Sube a la pantalla de progreso
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF6200EE),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          "Toca aquí para ver tu progreso",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // La pantalla que aparece al subir con scroll vertical
  Widget _buildPantallaProgreso() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Interface de Progreso",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            ),
            child: const Text("Volver al Menú"),
          ),
        ],
      ),
    );
  }
}