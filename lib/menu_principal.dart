import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tutoriales_view.dart';
import 'perfil_screen.dart';

class MenuPrincipalScreen extends StatefulWidget {
  const MenuPrincipalScreen({super.key});

  @override
  State<MenuPrincipalScreen> createState() => _MenuPrincipalScreenState();
}

class _MenuPrincipalScreenState extends State<MenuPrincipalScreen> {
  // Paleta oficial del proyecto (la misma de las lecciones y el perfil)
  static const Color _morado = Color(0xFF6B4EFF);
  static const Color _amarillo = Color(0xFFFFB300);
  static const Color _rojo = Color(0xFFE53E3E);
  static const Color _fondo = Color(0xFFF0EEFF);
  static const Color _texto = Color(0xFF1A1A2E);
  static const Color _suave = Color(0xFF555577);
  static const Color _borde = Color(0xFFDED8FF);

  // Tonos suaves para los fondos de iconos y el consejo
  static const Color _rojoSuave = Color(0xFFFDECEC);
  static const Color _amarilloSuave = Color(0xFFFFF4DA);
  static const Color _amarilloBorde = Color(0xFFFFE08A);
  static const Color _amarilloOscuro = Color(0xFF8A5F00);
  static const Color _amarilloTexto = Color(0xFF5C4000);
  static const Color _lilaClaro = Color(0xFFE9E4FF);

  // Consejos de seguridad: cambia uno cada dia
  static const List<String> _consejos = [
    "Si alguien te pide dinero por teléfono, cuelga sin culpa.",
    "Tu banco nunca te pide tu clave por mensaje ni por llamada.",
    "Si un mensaje te apura o te asusta, detente y pregunta a alguien de confianza.",
    "Si te ofrecen un premio que no pediste, es mejor desconfiar.",
  ];

  String nombreUsuario = "Usuario";

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  // Lee el nombre guardado al entrar
  Future<void> _cargarNombre() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      nombreUsuario = prefs.getString('nombre_usuario') ?? "Usuario";
    });
  }

  String get _consejoDelDia =>
      _consejos[DateTime.now().day % _consejos.length];

  // Aviso amable para las secciones que aun no existen
  void _muyPronto(String seccion) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _texto,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          "$seccion llega muy pronto",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Future<void> _abrirPerfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerfilScreen()),
    );
    _cargarNombre();
  }

  void _abrirTutoriales() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TutorialesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEncabezado(),
              const SizedBox(height: 20),
              _buildTarjetaTutoriales(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildTarjetaPequena(
                      titulo: "Detector de Fraude",
                      subtitulo: "¿Es seguro este mensaje?",
                      icono: Icons.gpp_maybe_rounded,
                      color: _rojo,
                      fondoIcono: _rojoSuave,
                      onTap: () => _muyPronto("El Detector de Fraude"),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTarjetaPequena(
                      titulo: "Mensajes de Ánimo",
                      subtitulo: "Palabras para tu día",
                      icono: Icons.favorite_rounded,
                      color: const Color(0xFFB37D00),
                      fondoIcono: _amarilloSuave,
                      onTap: () => _muyPronto("Mensajes de Ánimo"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildConsejo(),
            ],
          ),
        ),
      ),
    );
  }

  // Saludo a la izquierda y boton de perfil a la derecha, sin franja morada
  Widget _buildEncabezado() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "¡Hola, $nombreUsuario!",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: _suave,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "¿Qué vamos a hacer hoy?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _texto,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Boton de perfil: mismo tamano de antes (68), icono centrado
          Material(
            color: _morado,
            shape: const CircleBorder(
              side: BorderSide(color: _borde, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _abrirPerfil,
              child: const SizedBox(
                width: 68,
                height: 68,
                child: Center(
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 36),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta grande y protagonista: lo que mas usa el adulto mayor
  Widget _buildTarjetaTutoriales() {
    return Material(
      color: _morado,
      borderRadius: BorderRadius.circular(32),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _abrirTutoriales,
        child: Container(
          height: 250,
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Tutoriales",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Aprende a usar tu celular paso a paso",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _lilaClaro,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Circulo amarillo: invita a tocar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: _amarillo,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: _texto,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjetas cuadradas para las secciones secundarias
  Widget _buildTarjetaPequena({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required Color fondoIcono,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: _borde, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: fondoIcono,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icono, color: color, size: 32),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _texto,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _suave,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Consejo del dia: semilla del Detector de Fraude
  Widget _buildConsejo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _amarilloSuave,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _amarilloBorde, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: _amarilloOscuro, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _consejoDelDia,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _amarilloTexto,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}