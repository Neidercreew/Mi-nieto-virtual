import 'package:flutter/material.dart'; //es para pedirle a flutter sus widgets y herramientas de diseño
import 'package:shared_preferences/shared_preferences.dart';//permite guardar cambios pequeños, como el nivel del usuario, sin necesidad de una base de datos completa
import 'tutoriales_view.dart';//le indica que existe otro archivo llamado tutoriales_screen.dart, que se usará para mostrar los tutoriales después de seleccionar el nivel

class SeleccionNivelScreen extends StatelessWidget {//clase principal, el statelesswidget hace que la pagina sea plana, sin animaciones o cambios dinámicos
  const SeleccionNivelScreen({super.key});

  Future<void> _guardarNivelYContinuar(
      BuildContext context, String nivel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nivel_usuario', nivel);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TutorialesScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Cuánto sabes\nde tecnología?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B21B6),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Elige el nivel que más se parezca a ti. '
                'Lo puedes cambiar después.',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              _TarjetaNivel(
                emoji: '🌱',
                titulo: 'Básico',
                descripcion: 'Nunca o casi nunca uso el celular solo.',
                color: const Color(0xFFEDE9FE),
                colorBorde: const Color(0xFF7C3AED),
                onTap: () => _guardarNivelYContinuar(context, 'basico'),
              ),
              const SizedBox(height: 16),
              _TarjetaNivel(
                emoji: '📱',
                titulo: 'Intermedio',
                descripcion: 'Uso algunas apps pero a veces me pierdo.',
                color: const Color(0xFFDBEAFE),
                colorBorde: const Color(0xFF2563EB),
                onTap: () => _guardarNivelYContinuar(context, 'intermedio'),
              ),
              const SizedBox(height: 16),
              _TarjetaNivel(
                emoji: '🚀',
                titulo: 'Avanzado',
                descripcion: 'Manejo bien el celular y quiero aprender más.',
                color: const Color(0xFFD1FAE5),
                colorBorde: const Color(0xFF059669),
                onTap: () => _guardarNivelYContinuar(context, 'avanzado'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaNivel extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String descripcion;
  final Color color;
  final Color colorBorde;
  final VoidCallback onTap;

  const _TarjetaNivel({
    required this.emoji,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.colorBorde,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorBorde, width: 2),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorBorde,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: colorBorde, size: 20),
          ],
        ),
      ),
    );
  }
}