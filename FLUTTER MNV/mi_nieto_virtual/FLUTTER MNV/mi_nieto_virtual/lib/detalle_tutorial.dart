import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// MODELO DE PASO
// Cada tutorial tiene varios pasos, este modelo representa uno
// ─────────────────────────────────────────────────────────────
class PasoTutorial {
  final String titulo;        // ej: "Paso 1: Enciende tu celular"
  final String descripcion;   // explicación del paso
  final String imagenAsset;   // imagen que muestra el paso

  const PasoTutorial({
    required this.titulo,
    required this.descripcion,
    required this.imagenAsset,
  });
}

// ─────────────────────────────────────────────────────────────
// PANTALLA DE DETALLE
// Recibe el nombre del tutorial y su lista de pasos
// ─────────────────────────────────────────────────────────────
class DetalleTutorialScreen extends StatefulWidget {
  final String nombreTutorial;
  final List<PasoTutorial> pasos;

  const DetalleTutorialScreen({
    super.key,
    required this.nombreTutorial,
    required this.pasos,
  });

  @override
  State<DetalleTutorialScreen> createState() => _DetalleTutorialScreenState();
}

class _DetalleTutorialScreenState extends State<DetalleTutorialScreen> {
  int _pasoActual = 0; // empieza en el primer paso

  // Ir al siguiente paso
  void _siguiente() {
    if (_pasoActual < widget.pasos.length - 1) {
      setState(() => _pasoActual++);
    }
  }

  // Ir al paso anterior
  void _anterior() {
    if (_pasoActual > 0) {
      setState(() => _pasoActual--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paso = widget.pasos[_pasoActual];
    final esUltimoPaso = _pasoActual == widget.pasos.length - 1;
    final esPrimerPaso = _pasoActual == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0EEFF),
      // ── APP BAR ───────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EEFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF6B4EFF), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.nombreTutorial,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: Column(
        children: [
          // ── BARRA DE PROGRESO ────────────────────────────
          _buildBarraProgreso(),

          const SizedBox(height: 16),

          // ── CONTENIDO DEL PASO ───────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Imagen del paso
                  _buildImagenPaso(paso),

                  const SizedBox(height: 24),

                  // Título del paso
                  _buildTituloPaso(paso),

                  const SizedBox(height: 16),

                  // Descripción del paso
                  _buildDescripcionPaso(paso),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── BOTONES NAVEGACIÓN ───────────────────────────
          _buildBotonesNavegacion(esPrimerPaso, esUltimoPaso),
        ],
      ),
    );
  }

  // ── BARRA DE PROGRESO ──────────────────────────────────────
  Widget _buildBarraProgreso() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Texto: "Paso 1 de 5"
          Text(
            'Paso ${_pasoActual + 1} de ${widget.pasos.length}',
            style: const TextStyle(
              color: Color(0xFF6B4EFF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Barra visual de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_pasoActual + 1) / widget.pasos.length,
              backgroundColor: const Color(0xFFDED8FF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6B4EFF),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ── IMAGEN DEL PASO ────────────────────────────────────────
  Widget _buildImagenPaso(PasoTutorial paso) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          paso.imagenAsset,
          fit: BoxFit.contain,
          // Si no existe la imagen muestra placeholder
          errorBuilder: (_, __, ___) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_rounded,
                  size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Imagen próximamente',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TÍTULO DEL PASO ────────────────────────────────────────
  Widget _buildTituloPaso(PasoTutorial paso) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4EFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        paso.titulo,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
    );
  }

  // ── DESCRIPCIÓN DEL PASO ───────────────────────────────────
  Widget _buildDescripcionPaso(PasoTutorial paso) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        paso.descripcion,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 18, // letra grande para adulto mayor
          height: 1.6,
        ),
      ),
    );
  }

  // ── BOTONES NAVEGACIÓN ─────────────────────────────────────
  Widget _buildBotonesNavegacion(bool esPrimerPaso, bool esUltimoPaso) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón ANTERIOR
          if (!esPrimerPaso)
            Expanded(
              child: GestureDetector(
                onTap: _anterior,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded,
                          color: Color(0xFF6B4EFF), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Anterior',
                        style: TextStyle(
                          color: Color(0xFF6B4EFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!esPrimerPaso) const SizedBox(width: 12),

          // Botón SIGUIENTE o FINALIZAR
          Expanded(
            child: GestureDetector(
              onTap: esUltimoPaso
                  ? () => Navigator.pop(context) // vuelve a tutoriales
                  : _siguiente,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: esUltimoPaso
                      ? const Color(0xFF059669) // verde si es el último
                      : const Color(0xFF6B4EFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      esUltimoPaso ? '¡Listo! 🎉' : 'Siguiente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!esUltimoPaso) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 22),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}