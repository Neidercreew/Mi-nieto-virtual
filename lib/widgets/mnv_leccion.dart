import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import '../services/api_service.dart';

// Piezas visuales compartidas por las lecciones del nivel intermedio.
// Copian el estilo de las lecciones basicas para que todo se vea igual.
// La logica de cada leccion (pasos, objetivos, simulador) sigue viviendo
// en su propio archivo tutorial_*.dart.

class MnvColores {
  static const Color morado = Color(0xFF6B4EFF);
  static const Color morado2 = Color(0xFF8B5CF6);
  static const Color verde = Color(0xFF059669);
  static const Color amarillo = Color(0xFFFFB300);
  static const Color azul = Color(0xFF0EA5E9);
  static const Color rojo = Color(0xFFE53E3E);
  static const Color fondo = Color(0xFFF0EEFF);
  static const Color texto = Color(0xFF1A1A2E);
  static const Color suave = Color(0xFF555577);
  static const Color suave2 = Color(0xFF777799);
  static const Color borde = Color(0xFFDED8FF);
  static const Color cafe = Color(0xFF854F0B);
  static const Color lila = Color(0xFFEDEAFF);
  static const Color rojoSuave = Color(0xFFFDECEC);
  static const Color amarilloSuave = Color(0xFFFFF4DA);
  static const Color verdeSuave = Color(0xFFE3F5EE);
  static const Color azulSuave = Color(0xFFE6F6FD);
}

// Guarda el paso con el mecanismo existente (POST /usuarios/:id/paso)
Future<void> mnvGuardarPaso(String leccionId, int pasoSiguiente,
    {required bool completada}) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('usuario_id');
  if (userId == null) return;
  await ApiService.guardarPaso(userId, leccionId, pasoSiguiente,
      completada: completada);
}

// ─────────────────────────────────────────────
// MARCO DE LA LECCION
// ─────────────────────────────────────────────

// Arma la pantalla completa de una leccion: progreso, caja morada,
// simulador o icono, guia amarilla, boton grande y confeti.
class MnvLeccionLayout extends StatelessWidget {
  final String tituloLeccion;
  final int pasoActual;
  final int totalPasos;
  final Map<String, dynamic> paso;
  final Widget Function() construirSimulador;
  final String? mensajeGuia;
  final bool objetivoCumplido;
  final VoidCallback onAvanzar;
  final ConfettiController confetti;
  final String emojiTrofeo;
  final String textoTrofeo;

  const MnvLeccionLayout({
    super.key,
    required this.tituloLeccion,
    required this.pasoActual,
    required this.totalPasos,
    required this.paso,
    required this.construirSimulador,
    required this.mensajeGuia,
    required this.objetivoCumplido,
    required this.onAvanzar,
    required this.confetti,
    required this.emojiTrofeo,
    required this.textoTrofeo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MnvColores.fondo,
      appBar: AppBar(
        backgroundColor: MnvColores.fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: MnvColores.morado),
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(tituloLeccion,
            style: const TextStyle(
                color: MnvColores.texto,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              MnvProgresoLeccion(paso: pasoActual, total: totalPasos),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MnvCajaInstruccion(
                  titulo: paso['titulo'] as String,
                  instruccion: paso['instruccion'] as String,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: Center(child: _ilustracion())),
              if (mensajeGuia != null) MnvMensajeGuia(texto: mensajeGuia!),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: MnvBotonLeccion(
                  tipo: paso['tipo'] as String,
                  esUltimo: pasoActual == totalPasos - 1,
                  objetivoCumplido: objetivoCumplido,
                  ayuda: paso['ayuda'] as String?,
                  onTap: onAvanzar,
                ),
              ),
            ],
          ),
          ConfettiWidget(
            confettiController: confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            gravity: 0.1,
            colors: const [
              MnvColores.morado,
              MnvColores.amarillo,
              MnvColores.verde,
              MnvColores.morado2,
            ],
          ),
        ],
      ),
    );
  }

  Widget _ilustracion() {
    final tipo = paso['tipo'] as String;
    if (tipo == 'sim' || tipo == 'sim_info') {
      return SingleChildScrollView(child: construirSimulador());
    }
    if (tipo == 'celebracion') {
      return MnvTrofeo(emoji: emojiTrofeo, texto: textoTrofeo);
    }
    return MnvIconoPaso(
      icono: paso['icono'] as IconData? ?? Icons.lightbulb_rounded,
      color: paso['colorIcono'] as Color? ?? MnvColores.morado,
    );
  }
}

class MnvProgresoLeccion extends StatelessWidget {
  final int paso;
  final int total;
  const MnvProgresoLeccion(
      {super.key, required this.paso, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Text('Paso ${paso + 1} de $total',
              style: const TextStyle(
                  color: MnvColores.morado,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (paso + 1) / total),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor: MnvColores.borde,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(MnvColores.morado),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MnvCajaInstruccion extends StatelessWidget {
  final String titulo;
  final String instruccion;
  const MnvCajaInstruccion(
      {super.key, required this.titulo, required this.instruccion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: MnvColores.morado, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3)),
          const SizedBox(height: 8),
          Text(instruccion,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 14,
                  height: 1.5)),
        ],
      ),
    );
  }
}

class MnvMensajeGuia extends StatelessWidget {
  final String texto;
  const MnvMensajeGuia({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: MnvColores.amarillo.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MnvColores.amarillo, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_rounded,
              color: MnvColores.amarillo, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(texto,
                style: const TextStyle(
                    color: MnvColores.cafe,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class MnvBotonLeccion extends StatelessWidget {
  final String tipo;
  final bool esUltimo;
  final bool objetivoCumplido;
  final String? ayuda;
  final VoidCallback onTap;

  const MnvBotonLeccion({
    super.key,
    required this.tipo,
    required this.esUltimo,
    required this.objetivoCumplido,
    required this.ayuda,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final esPractica = tipo == 'sim';
    String texto;
    Color color;

    if (esUltimo) {
      texto = '¡Terminé! 🎉';
      color = MnvColores.verde;
    } else if (esPractica && !objetivoCumplido) {
      texto = ayuda ?? 'Practica en el teléfono de arriba';
      color = const Color(0xFFBBBBCC);
    } else if (esPractica) {
      texto = '¡Lo lograste! Siguiente →';
      color = MnvColores.verde;
    } else if (tipo == 'accion_real') {
      texto = 'Ya practiqué, siguiente →';
      color = MnvColores.morado;
    } else {
      texto = 'Entendido, siguiente →';
      color = MnvColores.morado;
    }

    final habilitado = !esPractica || objetivoCumplido;

    return Semantics(
      button: true,
      enabled: habilitado,
      label: texto,
      child: GestureDetector(
        onTap: habilitado ? onTap : null,
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
                        color: color.withValues(alpha: 0.35),
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
      ),
    );
  }
}

class MnvIconoPaso extends StatelessWidget {
  final IconData icono;
  final Color color;
  const MnvIconoPaso({super.key, required this.icono, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
      ),
      child: Center(child: Icon(icono, size: 70, color: color)),
    );
  }
}

class MnvTrofeo extends StatelessWidget {
  final String emoji;
  final String texto;
  const MnvTrofeo({super.key, required this.emoji, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (_, t, hijo) => Transform.scale(scale: t, child: hijo),
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFAEEDA),
              border: Border.all(color: const Color(0xFFEF9F27), width: 3),
              boxShadow: [
                BoxShadow(
                    color: MnvColores.amarillo.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4)
              ],
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 60))),
          ),
        ),
        const SizedBox(height: 16),
        Text(texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: MnvColores.cafe,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// RESALTE (pulso amarillo)
// ─────────────────────────────────────────────

// Envuelve cualquier elemento del simulador. Si activo es true late
// suavemente con borde amarillo, igual que en las lecciones basicas.
class MnvResalte extends StatefulWidget {
  final bool activo;
  final Widget child;
  final double radio;
  final double escala;
  final bool circular;

  const MnvResalte({
    super.key,
    required this.activo,
    required this.child,
    this.radio = 14,
    this.escala = 1.08,
    this.circular = false,
  });

  @override
  State<MnvResalte> createState() => _MnvResalteState();
}

class _MnvResalteState extends State<MnvResalte>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (widget.activo) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant MnvResalte oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activo && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.activo && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      child: widget.child,
      builder: (_, hijo) {
        final activo = widget.activo;
        final escala = activo ? 1 + (widget.escala - 1) * _anim.value : 1.0;
        final forma = widget.circular ? BoxShape.circle : BoxShape.rectangle;
        final radio =
            widget.circular ? null : BorderRadius.circular(widget.radio);
        return Transform.scale(
          scale: escala,
          child: Container(
            decoration: activo
                ? BoxDecoration(
                    shape: forma,
                    borderRadius: radio,
                    boxShadow: [
                      BoxShadow(
                          color: MnvColores.amarillo
                              .withValues(alpha: 0.35 + 0.3 * _anim.value),
                          blurRadius: 14,
                          spreadRadius: 1),
                    ],
                  )
                : null,
            foregroundDecoration: activo
                ? BoxDecoration(
                    shape: forma,
                    borderRadius: radio,
                    border: Border.all(color: MnvColores.amarillo, width: 2.5),
                  )
                : null,
            child: hijo,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// TELEFONO DE PRACTICA (chasis + barra de ubicacion)
// ─────────────────────────────────────────────

class MnvTelefonoPractica extends StatelessWidget {
  final String ubicacion;
  final String clavePantalla;
  final Widget pantalla;
  final List<Widget> encima;
  final double alto;

  const MnvTelefonoPractica({
    super.key,
    required this.ubicacion,
    required this.clavePantalla,
    required this.pantalla,
    this.encima = const [],
    this.alto = 520,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: MnvColores.verde.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
          child: const Text('📱 Teléfono de práctica — toca sin miedo',
              style: TextStyle(
                  color: MnvColores.verde,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
        Container(
          width: 270,
          decoration: BoxDecoration(
            color: MnvColores.texto,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: alto,
              child: Column(
                children: [
                  MnvBarraUbicacion(texto: ubicacion),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (hijo, anim) => FadeTransition(
                              opacity: anim,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.97, end: 1.0)
                                    .animate(anim),
                                child: hijo,
                              ),
                            ),
                            child: KeyedSubtree(
                              key: ValueKey(clavePantalla),
                              child: pantalla,
                            ),
                          ),
                        ),
                        ...encima,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Franja morada "Estas en: ..." que destella en ambar al cambiar de lugar
class MnvBarraUbicacion extends StatelessWidget {
  final String texto;
  const MnvBarraUbicacion({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('ubi_$texto'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, t, __) {
        final color = Color.lerp(MnvColores.amarillo, MnvColores.morado, t)!;
        return Container(
          width: double.infinity,
          height: 31,
          color: color,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.place_rounded,
                  size: 15, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Estás en: $texto',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Pantalla de inicio del celular de practica con una rejilla de apps.
// La app objetivo se resalta; las demas dan una guia al tocarlas.
class MnvAppInicio {
  final String clave;
  final String nombre;
  final IconData icono;
  final Color color;
  const MnvAppInicio(this.clave, this.nombre, this.icono, this.color);
}

class MnvPantallaInicio extends StatelessWidget {
  final List<MnvAppInicio> apps;
  final String? resaltada;
  final ValueChanged<String> onApp;
  final String hora;
  final String fecha;

  const MnvPantallaInicio({
    super.key,
    required this.apps,
    required this.resaltada,
    required this.onApp,
    this.hora = '9:41',
    this.fecha = 'martes, 6 de octubre',
  });

  static const List<MnvAppInicio> appsBase = [
    MnvAppInicio('telefono', 'Teléfono', Icons.phone_rounded, MnvColores.verde),
    MnvAppInicio('mensajes', 'Mensajes', Icons.sms_rounded, MnvColores.morado),
    MnvAppInicio(
        'whatsapp', 'WhatsApp', Icons.chat_rounded, Color(0xFF16A34A)),
    MnvAppInicio('correo', 'Correo', Icons.mail_rounded, MnvColores.rojo),
    MnvAppInicio('calendario', 'Calendario', Icons.calendar_month_rounded,
        MnvColores.azul),
    MnvAppInicio('camara', 'Cámara', Icons.photo_camera_rounded,
        Color(0xFF555577)),
    MnvAppInicio(
        'fotos', 'Fotos', Icons.photo_library_rounded, MnvColores.amarillo),
    MnvAppInicio('ajustes', 'Ajustes', Icons.settings_rounded,
        Color(0xFF777799)),
    MnvAppInicio('tienda', 'Tienda', Icons.shop_rounded, MnvColores.morado2),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B2B52), Color(0xFF6B4EFF)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 22),
          Text(hora,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w300)),
          Text(fecha,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 14,
              children: apps.map(_app).toList(),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _app(MnvAppInicio app) {
    final resaltar = app.clave == resaltada;
    return GestureDetector(
      onTap: () => onApp(app.clave),
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MnvResalte(
              activo: resaltar,
              radio: 16,
              escala: 1.12,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: app.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(app.icono, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 5),
            Text(app.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: resaltar ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TECLADOS
// ─────────────────────────────────────────────

// Teclado de letras con barra de sugerencias opcional.
// letraEsperada pinta de amarillo la tecla que sigue.
class MnvTecladoLetras extends StatelessWidget {
  final ValueChanged<String> onLetra;
  final VoidCallback onBorrar;
  final VoidCallback? onEspacio;
  final String? letraEsperada;
  final List<String> sugerencias;
  final ValueChanged<String>? onSugerencia;
  final String? sugerenciaResaltada;
  final bool resaltarBorrar;

  const MnvTecladoLetras({
    super.key,
    required this.onLetra,
    required this.onBorrar,
    this.onEspacio,
    this.letraEsperada,
    this.sugerencias = const [],
    this.onSugerencia,
    this.sugerenciaResaltada,
    this.resaltarBorrar = false,
  });

  static const List<String> _fila1 = [
    'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'
  ];
  static const List<String> _fila2 = [
    'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ñ'
  ];
  static const List<String> _fila3 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(3, 4, 3, 8),
      color: const Color(0xFFE6E4F0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sugerencias.isNotEmpty) ...[
            MnvBarraSugerencias(
              sugerencias: sugerencias,
              onSugerencia: onSugerencia,
              resaltada: sugerenciaResaltada,
            ),
            const SizedBox(height: 4),
          ],
          _fila(_fila1),
          const SizedBox(height: 5),
          _fila(_fila2),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._fila3.map(_tecla),
              const SizedBox(width: 4),
              _teclaBorrar(),
            ],
          ),
          if (onEspacio != null) ...[
            const SizedBox(height: 5),
            GestureDetector(
              onTap: onEspacio,
              child: Container(
                width: 150,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 2,
                        offset: Offset(0, 1))
                  ],
                ),
                child: const Center(
                  child: Text('espacio',
                      style: TextStyle(color: MnvColores.suave2, fontSize: 11)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fila(List<String> letras) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letras.map(_tecla).toList(),
    );
  }

  Widget _tecla(String letra) {
    final esperada = letraEsperada == letra;
    return GestureDetector(
      onTap: () => onLetra(letra),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 23,
        height: 33,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          color: esperada ? MnvColores.amarillo : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: esperada
              ? Border.all(color: const Color(0xFFEF9F27), width: 1.5)
              : null,
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000), blurRadius: 2, offset: Offset(0, 1))
          ],
        ),
        child: Center(
          child: Text(letra,
              style: TextStyle(
                  color: esperada ? Colors.white : MnvColores.texto,
                  fontSize: 14,
                  fontWeight: esperada ? FontWeight.w800 : FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _teclaBorrar() {
    return GestureDetector(
      onTap: onBorrar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 33,
        decoration: BoxDecoration(
          color: resaltarBorrar ? MnvColores.amarillo : const Color(0xFFCFCCE0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.backspace_rounded,
            size: 17,
            color: resaltarBorrar ? Colors.white : MnvColores.texto),
      ),
    );
  }
}

// Fila de sugerencias encima del teclado (respuestas o palabras)
class MnvBarraSugerencias extends StatelessWidget {
  final List<String> sugerencias;
  final ValueChanged<String>? onSugerencia;
  final String? resaltada;

  const MnvBarraSugerencias({
    super.key,
    required this.sugerencias,
    required this.onSugerencia,
    required this.resaltada,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        children: sugerencias.map((s) {
          final resaltar = s == resaltada;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: onSugerencia == null ? null : () => onSugerencia!(s),
                child: MnvResalte(
                  activo: resaltar,
                  radio: 12,
                  escala: 1.05,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: resaltar ? MnvColores.amarilloSuave : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: resaltar
                              ? MnvColores.amarillo
                              : const Color(0xFFCFCCE0)),
                    ),
                    child: Center(
                      child: Text(s,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: MnvColores.texto,
                              fontSize: 10.5,
                              height: 1.15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Teclado numerico 3x4. encima permite poner una barra (por ejemplo
// la sugerencia de pegar un codigo).
class MnvTecladoNumerico extends StatelessWidget {
  final ValueChanged<String> onNumero;
  final VoidCallback onBorrar;
  final String? numeroEsperado;
  final Widget? encima;

  const MnvTecladoNumerico({
    super.key,
    required this.onNumero,
    required this.onBorrar,
    this.numeroEsperado,
    this.encima,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      color: const Color(0xFFE6E4F0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (encima != null) ...[encima!, const SizedBox(height: 4)],
          _fila(['1', '2', '3']),
          _fila(['4', '5', '6']),
          _fila(['7', '8', '9']),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60),
              _tecla('0'),
              GestureDetector(
                onTap: onBorrar,
                child: Container(
                  width: 60,
                  height: 36,
                  margin: const EdgeInsets.all(2),
                  alignment: Alignment.center,
                  child: const Icon(Icons.backspace_rounded,
                      size: 20, color: MnvColores.suave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fila(List<String> numeros) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numeros.map(_tecla).toList(),
    );
  }

  Widget _tecla(String numero) {
    final esperado = numeroEsperado == numero;
    return GestureDetector(
      onTap: () => onNumero(numero),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 36,
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: esperado ? MnvColores.amarillo : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000), blurRadius: 2, offset: Offset(0, 1))
          ],
        ),
        child: Center(
          child: Text(numero,
              style: TextStyle(
                  color: esperado ? Colors.white : MnvColores.texto,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PIEZAS QUE VAN ENCIMA DE LA PANTALLA
// ─────────────────────────────────────────────

// Barrita de notificacion que baja desde arriba
class MnvNotificacion extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String app;
  final String titulo;
  final String texto;
  final bool resaltada;
  final VoidCallback onTap;

  const MnvNotificacion({
    super.key,
    required this.icono,
    required this.color,
    required this.app,
    required this.titulo,
    required this.texto,
    required this.resaltada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 6,
      left: 6,
      right: 6,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: -90, end: 0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (_, y, hijo) =>
            Transform.translate(offset: Offset(0, y), child: hijo),
        child: GestureDetector(
          onTap: onTap,
          child: MnvResalte(
            activo: resaltada,
            radio: 16,
            escala: 1.03,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MnvColores.borde),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(9)),
                    child: Icon(icono, color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$app · ahora',
                            style: const TextStyle(
                                color: MnvColores.suave2, fontSize: 9.5)),
                        const SizedBox(height: 1),
                        Text(titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: MnvColores.texto,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold)),
                        Text(texto,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: MnvColores.suave, fontSize: 11)),
                      ],
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

// Check verde que rebota para confirmar que algo se guardo o envio
class MnvCheckConfirmacion extends StatelessWidget {
  final String texto;
  const MnvCheckConfirmacion({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, t, hijo) => Transform.scale(scale: t, child: hijo),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: MnvColores.verde,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: MnvColores.verde.withValues(alpha: 0.5),
                      blurRadius: 24)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 4),
                  Text(texto,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Ventanita de confirmacion dentro del celular (borrar, bloquear...)
class MnvDialogoSim extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final String textoCancelar;
  final String textoConfirmar;
  final Color colorConfirmar;
  final bool resaltarConfirmar;
  final VoidCallback onCancelar;
  final VoidCallback onConfirmar;

  const MnvDialogoSim({
    super.key,
    required this.titulo,
    required this.mensaje,
    required this.textoConfirmar,
    required this.onCancelar,
    required this.onConfirmar,
    this.textoCancelar = 'Cancelar',
    this.colorConfirmar = MnvColores.rojo,
    this.resaltarConfirmar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (_, t, hijo) => Transform.scale(scale: t, child: hijo),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        color: MnvColores.texto,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(mensaje,
                    style: const TextStyle(
                        color: MnvColores.suave, fontSize: 12, height: 1.4)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onCancelar,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Text(textoCancelar,
                            style: const TextStyle(
                                color: MnvColores.suave2,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onConfirmar,
                      child: MnvResalte(
                        activo: resaltarConfirmar,
                        radio: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorConfirmar,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(textoConfirmar,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
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
}

// Circulo con inicial o emoji para personas y remitentes
class MnvAvatar extends StatelessWidget {
  final String texto;
  final Color color;
  final double tam;
  const MnvAvatar(
      {super.key, required this.texto, required this.color, this.tam = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tam,
      height: tam,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Center(
        child: Text(texto,
            style: TextStyle(
                color: color,
                fontSize: tam * 0.42,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
