import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'seleccion_nivel.dart';
import 'detalle_tutorial.dart';
import 'tutorial_botones.dart';
import 'mapa_lecciones.dart';
import 'proximamente_screen.dart';
import 'tutorial_pantalla_tactil.dart';
import 'tutorial_moviendote.dart';
import 'tutorial_configuraciones.dart';
import 'tutorial_bateria.dart';
import 'tutorial_reconociendo_iconos.dart';
import 'tutorial_abrir_cerrar_apps.dart';

class TutorialApp {
  final String nombre;
  final String imagenAsset;
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

class TutorialesScreen extends StatefulWidget {
  const TutorialesScreen({super.key});

  @override
  State<TutorialesScreen> createState() => _TutorialesScreenState();
}

class _TutorialesScreenState extends State<TutorialesScreen> {
  String _nivelUsuario = 'basico';
  int _navIndex = 0;
  int _tabSeleccionado = 0;

  late Future<Map<String, dynamic>?> _progresoFuture;

  @override
  void initState() {
    super.initState();
    _verificarNivel();
    _progresoFuture = _cargarProgreso();
  }

  Future<void> _verificarNivel() async {
    final prefs = await SharedPreferences.getInstance();
    final nivel = prefs.getString('nivel_usuario');
    if (nivel == null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SeleccionNivelScreen()),
      );
    } else {
      setState(() {
        _nivelUsuario = nivel ?? 'basico';
      });
    }
  }

  List<TutorialApp> get _apps => [
    TutorialApp(
      nombre: 'Conociendo tu celular',
      imagenAsset: 'assets/icons/celular.png',
      fondo: const Color(0xFFFFFFFF),
      nivel: 'basico',
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => MapaLeccionesScreen(
          moduloTitulo: 'Conociendo tu celular',
          lecciones: [
            LeccionMapa(
              leccionId: 'conociendo_tu_celular',
              titulo: 'Botones físicos',
              emoji: '📱',
              builder: () => const TutorialBotonesScreen(),
              builderDesde: (paso) => TutorialBotonesScreen(pasoInicial: paso),
            ),
            LeccionMapa(
              leccionId: 'pantalla_tactil',
              titulo: 'La pantalla táctil',
              emoji: '👆',
              builder: () => const TutorialPantallaTactilScreen(),
              builderDesde: (paso) => TutorialPantallaTactilScreen(pasoInicial: paso),
            ),
            LeccionMapa(
              leccionId: 'moviendote_celular',
              titulo: 'Moviendote en tu celular',
              emoji: '🧭',
              builder: () => const TutorialMoviendoteScreen(),
              builderDesde: (paso) => TutorialMoviendoteScreen(pasoInicial: paso),
            ),
            LeccionMapa(
              leccionId: 'configuraciones_esenciales',
              titulo: 'Configuraciones esenciales',
              emoji: '⚙️',
              builder: () => const TutorialConfiguracionesScreen(),
              builderDesde: (paso) => TutorialConfiguracionesScreen(pasoInicial: paso),
            ),
            LeccionMapa(
              leccionId: 'bateria_y_cuidado',
              titulo: 'Batería y cuidado',
              emoji: '🔋',
              builder: () => const TutorialBateriaScreen(),
              builderDesde: (paso) => TutorialBateriaScreen(pasoInicial: paso),
            ),
          ],
        ),
      )),
    ),

    TutorialApp(
      nombre: 'Cómo navegar',
      imagenAsset: 'assets/icons/navegar.png',
      fondo: const Color(0xFFFFFFFF),
      nivel: 'basico',
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => MapaLeccionesScreen(
          moduloTitulo: 'Cómo navegar',
          lecciones: [
            LeccionMapa(
              leccionId: 'reconociendo_iconos',
              titulo: 'Reconociendo íconos',
              emoji: '📱',
              builder: () => const TutorialReconociendoIconosScreen(),
              builderDesde: (paso) => TutorialReconociendoIconosScreen(pasoInicial: paso),
            ),
            LeccionMapa(
              leccionId: 'abrir_cerrar_apps',
              titulo: 'Abriendo y cerrando apps',
              emoji: '📲',
              builder: () => const TutorialAbrirCerrarAppsScreen(),
              builderDesde: (paso) => TutorialAbrirCerrarAppsScreen(pasoInicial: paso),
            ),
            LeccionMapa(
              leccionId: 'cambiando_apps',
              titulo: 'Cambiando entre apps',
              emoji: '🔄',
              builder: () => const ProximamenteScreen(titulo: 'Cambiando entre apps'),
            ),
            LeccionMapa(
              leccionId: 'buscar_descargar',
              titulo: 'Buscando y descargando apps',
              emoji: '🔍',
              builder: () => const ProximamenteScreen(titulo: 'Buscando y descargando apps'),
            ),
          ],
        ),
      )),
    ),

    TutorialApp(
      nombre: 'Cámara de tu celular',
      imagenAsset: 'assets/icons/camara.png',
      fondo: const Color(0xFFFFFFFF),
      nivel: 'basico',
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => MapaLeccionesScreen(
          moduloTitulo: 'Cámara de tu celular',
          lecciones: [
            LeccionMapa(
              leccionId: 'camara_leccion1',
              titulo: 'Tomar una foto',
              emoji: '📷',
              builder: () => const ProximamenteScreen(titulo: 'Tomar una foto'),
            ),
            LeccionMapa(
              leccionId: 'camara_leccion2',
              titulo: 'Ver tus fotos',
              emoji: '🖼️',
              builder: () => const ProximamenteScreen(titulo: 'Ver tus fotos'),
            ),
          ],
        ),
      )),
    ),

    TutorialApp(
      nombre: 'Teléfono de tu celular',
      imagenAsset: 'assets/icons/telefono.png',
      fondo: const Color(0xFFFFFFFF),
      nivel: 'basico',
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => MapaLeccionesScreen(
          moduloTitulo: 'Teléfono de tu celular',
          lecciones: [
            LeccionMapa(
              leccionId: 'telefono_leccion1',
              titulo: 'Hacer una llamada',
              emoji: '📞',
              builder: () => const ProximamenteScreen(titulo: 'Hacer una llamada'),
            ),
            LeccionMapa(
              leccionId: 'telefono_leccion2',
              titulo: 'Guardar contactos',
              emoji: '👤',
              builder: () => const ProximamenteScreen(titulo: 'Guardar contactos'),
            ),
          ],
        ),
      )),
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

  List<TutorialApp> get _appsFiltradas {
    return _apps.where((a) => a.nivel == _nivelUsuario).toList();
  }

  final List<Color> _coloresTarjeta = [
    const Color(0xFFE8F4FD),
    const Color(0xFFE8F8EE),
    const Color(0xFFEAF5FF),
    const Color(0xFFF3EEFF),
    const Color(0xFFE3F0FF),
    const Color(0xFFE3F0FF),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EEFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF6B4EFF), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Tutoriales',
          style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF6B4EFF), size: 24),
            tooltip: 'Cambiar nivel',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('nivel_usuario');
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SeleccionNivelScreen()),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1A1A2E), size: 26),
                  onPressed: () {},
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 9, height: 9,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, bottom: 16),
            child: Text(
              '¿Sobre qué quieres aprender hoy?',
              style: TextStyle(color: Color(0xFF555577), fontSize: 25, fontWeight: FontWeight.w400),
            ),
          ),
          _buildTabs(),
          const SizedBox(height: 20),
          Expanded(
            child: _tabSeleccionado == 0
                ? _buildGridAplicaciones()
                : _buildMiProgreso(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

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
        onTap: () => setState(() {
          _tabSeleccionado = index;
          if (index == 1) {
            _progresoFuture = _cargarProgreso();
          }
        }),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 70, height: 70,
              child: Image.asset(
                app.imagenAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
                  ),
                  child: const Icon(Icons.apps_rounded, size: 40, color: Color(0xFF6B4EFF)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                app.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dashboard de progreso del usuario con todas sus lecciones
  Widget _buildMiProgreso() {
    final modulos = [
      {
        'titulo': '📱 Conociendo tu celular',
        'lecciones': [
          {'id': 'conociendo_tu_celular', 'titulo': 'Botones físicos', 'emoji': '🔘', 'pasos': 7},
          {'id': 'pantalla_tactil', 'titulo': 'La pantalla táctil', 'emoji': '👆', 'pasos': 14},
          {'id': 'moviendote_celular', 'titulo': 'Moviendote en tu celular', 'emoji': '🧭', 'pasos': 10},
          {'id': 'configuraciones_esenciales', 'titulo': 'Configuraciones esenciales', 'emoji': '⚙️', 'pasos': 36},
          {'id': 'bateria_y_cuidado', 'titulo': 'Batería y cuidado', 'emoji': '🔋', 'pasos': 14},
        ],
      },
      {
        'titulo': '🧭 Cómo navegar',
        'lecciones': [
          {'id': 'reconociendo_iconos', 'titulo': 'Reconociendo íconos', 'emoji': '📱', 'pasos': 11},
          {'id': 'abrir_cerrar_apps', 'titulo': 'Abriendo y cerrando apps', 'emoji': '📲', 'pasos': 13},
          {'id': 'cambiando_apps', 'titulo': 'Cambiando entre apps', 'emoji': '🔄', 'pasos': 10},
          {'id': 'me_equivoque', 'titulo': 'Me equivoqué, ¿y ahora qué?', 'emoji': '🆘', 'pasos': 10},
          {'id': 'buscar_descargar', 'titulo': 'Buscando y descargando apps', 'emoji': '🔍', 'pasos': 10},
        ],
      },
      {
        'titulo': '📷 Cámara de tu celular',
        'lecciones': [
          {'id': 'camara_leccion1', 'titulo': 'Tomar una foto', 'emoji': '📷', 'pasos': 10},
          {'id': 'camara_leccion2', 'titulo': 'Ver tus fotos', 'emoji': '🖼️', 'pasos': 10},
        ],
      },
      {
        'titulo': '📞 Teléfono de tu celular',
        'lecciones': [
          {'id': 'telefono_leccion1', 'titulo': 'Hacer una llamada', 'emoji': '📞', 'pasos': 10},
          {'id': 'telefono_leccion2', 'titulo': 'Guardar contactos', 'emoji': '👤', 'pasos': 10},
        ],
      },
    ];

    return FutureBuilder<Map<String, dynamic>?>(
      future: _progresoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF)));
        }

        final data = snapshot.data;
        final progresoList = data?['progreso'] as List<dynamic>? ?? [];

        final Map<String, dynamic> progresoMap = {};
        for (var item in progresoList) {
          progresoMap[item['leccionId']] = item;
        }

        int totalLecciones = 0;
        int totalCompletadas = 0;
        for (var modulo in modulos) {
          final lecciones = modulo['lecciones'] as List;
          totalLecciones += lecciones.length;
          for (var l in lecciones) {
            final p = progresoMap[(l as Map)['id']];
            if (p?['completada'] == true) totalCompletadas++;
          }
        }
        final porcentajeGeneral = totalLecciones == 0 ? 0.0 : totalCompletadas / totalLecciones;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta de progreso general
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B4EFF), Color(0xFF3700B3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90, height: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 90, height: 90,
                            child: CircularProgressIndicator(
                              value: porcentajeGeneral,
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Text(
                            '${(porcentajeGeneral * 100).toInt()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nivel Básico',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('$totalCompletadas de $totalLecciones lecciones completadas',
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: porcentajeGeneral,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Un bloque por cada modulo
              ...modulos.map((modulo) {
                final lecciones = modulo['lecciones'] as List;
                final completadasModulo = lecciones
                    .where((l) => progresoMap[(l as Map)['id']]?['completada'] == true)
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titulo del modulo con contador
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(modulo['titulo'] as String,
                            style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('$completadasModulo/${lecciones.length}',
                            style: const TextStyle(color: Color(0xFF6B4EFF), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Tarjetas de cada leccion
                    ...lecciones.asMap().entries.map((entry) {
                      final i = entry.key;
                      final l = entry.value as Map;
                      final p = progresoMap[l['id']];
                      final completada = p?['completada'] == true;
                      final pasoActual = p?['paso'] ?? -1;
                      final totalPasos = l['pasos'] as int;
                    // La primera leccion de cada modulo solo esta disponible
                    // si es el primer modulo, o si TODAS las lecciones del modulo anterior estan completas
                  bool disponible;
                  if (i == 0){
                  // primera leccion del modulo: revisar si es el primer modulo
                      final indiceMod = modulos.indexOf(modulo);
                      if (indiceMod == 0) {
                        disponible = true;
                       } else {
                        final leccionesModAnterior = (modulos[indiceMod - 1]['lecciones'] as List);
                        disponible = leccionesModAnterior.every(
                          (l) => progresoMap[(l as Map)['id']]?['completada'] == true,
                        );
                      }
                    } else {
                      disponible = progresoMap[(lecciones[i - 1] as Map)['id']]?['completada'] == true;
                    }
                      return _buildTarjetaLeccion(
                        numero: i + 1,
                        titulo: l['titulo'] as String,
                        emoji: l['emoji'] as String,
                        pasoActual: pasoActual,
                        totalPasos: totalPasos,
                        completada: completada,
                        disponible: disponible,
                      );
                    }),

                    const SizedBox(height: 20),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Tarjeta individual de progreso de cada leccion en el dashboard
  Widget _buildTarjetaLeccion({
    required int numero,
    required String titulo,
    required String emoji,
    required int pasoActual,
    required int totalPasos,
    required bool completada,
    required bool disponible,
  }) {
    final porcentaje = pasoActual < 0 ? 0.0 : (pasoActual + 1) / totalPasos;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completada ? const Color(0xFF059669).withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: completada
              ? const Color(0xFF059669).withOpacity(0.3)
              : disponible
                  ? const Color(0xFFDED8FF)
                  : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56, height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56, height: 56,
                  child: CircularProgressIndicator(
                    value: disponible ? porcentaje : 0,
                    strokeWidth: 5,
                    backgroundColor: completada
                        ? const Color(0xFF059669).withOpacity(0.2)
                        : const Color(0xFFDED8FF),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completada ? const Color(0xFF059669) : const Color(0xFF6B4EFF),
                    ),
                  ),
                ),
                Text(
                  completada ? '✅' : disponible ? emoji : '🔒',
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lección $numero: $titulo',
                  style: TextStyle(
                    color: disponible ? const Color(0xFF1A1A2E) : const Color(0xFF9999BB),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  completada
                      ? '¡Completada! 🎉'
                      : disponible
                          ? pasoActual < 0
                              ? 'Aún no has empezado'
                              : '${(porcentaje * 100).toInt()}% — Paso ${pasoActual + 1} de $totalPasos'
                          : 'Próximamente',
                  style: TextStyle(
                    color: completada ? const Color(0xFF059669) : const Color(0xFF9999BB),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _cargarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    if (userId == null) return null;
    return ApiService.obtenerProgreso(userId);
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -3))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _navIcon(Icons.home_rounded, 0),
          _navIcon(Icons.calendar_today_rounded, 1),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFFFFB300).withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 5))],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.shield_rounded, color: Colors.white, size: 40),
                  Positioned(
                    bottom: 12, right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Color(0xFFFFB300), shape: BoxShape.circle),
                      child: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
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
      child: Icon(icon, size: 26, color: selected ? const Color(0xFF6B4EFF) : const Color(0xFFBBBBCC)),
    );
  }

  void _abrirTutorial(TutorialApp app) {
    final pasosPrueba = [
      PasoTutorial(
        titulo: 'Paso 1: Bienvenido',
        descripcion: 'En este tutorial aprenderás a usar ${app.nombre} de manera fácil y sencilla.',
        imagenAsset: 'assets/pasos/paso1.png',
      ),
      const PasoTutorial(
        titulo: 'Paso 2: Lo primero',
        descripcion: 'Primero busca el ícono en tu pantalla principal y tócalo suavemente con tu dedo.',
        imagenAsset: 'assets/pasos/paso2.png',
      ),
      const PasoTutorial(
        titulo: 'Paso 3: ¡Lo lograste!',
        descripcion: '¡Muy bien! Ya sabes el primer paso. Sigue practicando y lo aprenderás rápido.',
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