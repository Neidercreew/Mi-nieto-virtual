import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

class TutorialBotonesScreen extends StatefulWidget {
  const TutorialBotonesScreen({super.key});

  @override
  State<TutorialBotonesScreen> createState() => _TutorialBotonesScreenState();
}

class _TutorialBotonesScreenState extends State<TutorialBotonesScreen> {
  @override
void initState() {
  super.initState();
  HardwareKeyboard.instance.addHandler(_onKey);
}

@override
void dispose() {
  HardwareKeyboard.instance.removeHandler(_onKey);
  super.dispose();
}

bool _onKey(KeyEvent event) {
  if (event is KeyDownEvent) {
    final key = event.logicalKey;
    final botonActual = _pasos[_pasoActual]['boton'];

    if (key == LogicalKeyboardKey.audioVolumeUp &&
        botonActual == 'volumen_arriba') {
      _vibrarYAvanzar();
      return true;
    }
    if (key == LogicalKeyboardKey.audioVolumeDown &&
        botonActual == 'volumen_abajo') {
      _vibrarYAvanzar();
      return true;
    }
    if (key == LogicalKeyboardKey.power &&
        botonActual == 'power') {
      _vibrarYAvanzar();
      return true;
    }
  }
  return false;
}
  int _pasoActual = 0;
  bool _mostrarFelicitacion = false;

  final List<Map<String, String>> _pasos = [
    {
      'instruccion': 'Este es tu celular.\nConoce sus botones principales.',
      'boton': 'ninguno',
    },
    {
      'instruccion': '¡Toca el botón de\nSUBIR VOLUMEN! 🔊',
      'boton': 'volumen_arriba',
    },
    {
      'instruccion': '¡Ahora toca el botón de\nBAJAR VOLUMEN! 🔇',
      'boton': 'volumen_abajo',
    },
    {
      'instruccion': '¡Perfecto! Ahora toca el\nbotón de APAGAR/ENCENDER 🔴',
      'boton': 'power',
    },
  ];

  Future<void> _vibrarYAvanzar() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 300);
      }
    } catch (e) {
      // En emulador no vibra pero sigue funcionando
    }

    setState(() => _mostrarFelicitacion = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _mostrarFelicitacion = false;
        if (_pasoActual < _pasos.length - 1) {
          _pasoActual++;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_pasoActual];
    final esPrimerPaso = _pasoActual == 0;
    final esUltimoPaso = _pasoActual == _pasos.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF0EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EEFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF6B4EFF)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Conociendo tu celular',
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4EFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    paso['instruccion']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: _buildCelular(paso['boton']!),
                ),
              ),
              if (esPrimerPaso || esUltimoPaso)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GestureDetector(
                    onTap: () {
                      if (esUltimoPaso) {
                        Navigator.pop(context);
                      } else {
                        setState(() => _pasoActual++);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: esUltimoPaso
                            ? const Color(0xFF059669)
                            : const Color(0xFF6B4EFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          esUltimoPaso ? '¡Terminé! 🎉' : 'Empezar →',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_mostrarFelicitacion) _buildFelicitacion(),
        ],
      ),
    );
  }

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

  Widget _buildCelular(String botonActivo) {
    return SizedBox(
      width: 220,
      height: 400,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 26,
            right: 26,
            top: 20,
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D44),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_android_rounded,
                    color: Colors.white.withOpacity(0.3),
                    size: 60,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '10:30',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botón SUBIR VOLUMEN
          Positioned(
            right: 0,
            top: 90,
            child: _buildBoton(
              activo: botonActivo == 'volumen_arriba',
              onTap: botonActivo == 'volumen_arriba' ? _vibrarYAvanzar : null,
              child: Container(
                width: 14,
                height: 50,
                decoration: BoxDecoration(
                  color: botonActivo == 'volumen_arriba'
                      ? const Color(0xFF6B4EFF)
                      : const Color(0xFF3A3A5C),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  boxShadow: botonActivo == 'volumen_arriba'
                      ? [BoxShadow(
                          color: const Color(0xFF6B4EFF).withOpacity(0.6),
                          blurRadius: 12,
                        )]
                      : null,
                ),
              ),
            ),
          ),
          if (botonActivo == 'volumen_arriba')
            Positioned(
              right: 20,
              top: 95,
              child: _buildEtiqueta('🔊 Subir\nvolumen'),
            ),
          // Botón BAJAR VOLUMEN
          Positioned(
            right: 0,
            top: 155,
            child: _buildBoton(
              activo: botonActivo == 'volumen_abajo',
              onTap: botonActivo == 'volumen_abajo' ? _vibrarYAvanzar : null,
              child: Container(
                width: 14,
                height: 50,
                decoration: BoxDecoration(
                  color: botonActivo == 'volumen_abajo'
                      ? const Color(0xFF6B4EFF)
                      : const Color(0xFF3A3A5C),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  boxShadow: botonActivo == 'volumen_abajo'
                      ? [BoxShadow(
                          color: const Color(0xFF6B4EFF).withOpacity(0.6),
                          blurRadius: 12,
                        )]
                      : null,
                ),
              ),
            ),
          ),
          if (botonActivo == 'volumen_abajo')
            Positioned(
              right: 20,
              top: 160,
              child: _buildEtiqueta('🔇 Bajar\nvolumen'),
            ),
          // Botón POWER
          Positioned(
            left: 0,
            top: 120,
            child: _buildBoton(
              activo: botonActivo == 'power',
              onTap: botonActivo == 'power' ? _vibrarYAvanzar : null,
              child: Container(
                width: 14,
                height: 65,
                decoration: BoxDecoration(
                  color: botonActivo == 'power'
                      ? const Color(0xFFE53E3E)
                      : const Color(0xFF3A3A5C),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  boxShadow: botonActivo == 'power'
                      ? [BoxShadow(
                          color: const Color(0xFFE53E3E).withOpacity(0.6),
                          blurRadius: 12,
                        )]
                      : null,
                ),
              ),
            ),
          ),
          if (botonActivo == 'power')
            Positioned(
              left: 20,
              top: 128,
              child: _buildEtiqueta('🔴 Apagar /\nEncender'),
            ),
        ],
      ),
    );
  }

  Widget _buildBoton({
    required bool activo,
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: activo
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.15),
              duration: const Duration(milliseconds: 600),
              builder: (_, scale, __) => Transform.scale(
                scale: scale,
                child: child,
              ),
            )
          : child,
    );
  }

  Widget _buildEtiqueta(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildFelicitacion() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
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
    );
  }
}