import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'services/api_service.dart'; //  para guardar progreso del tutorial

class TutorialBotonesScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialBotonesScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialBotonesScreen> createState() => _TutorialBotonesScreenState();
}

class _TutorialBotonesScreenState extends State<TutorialBotonesScreen> {
  int _pasoActual = 0;
  int _contadorBajar = 0;
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
      'instruccion': 'Mantén presionado el\nbotón de BAJAR VOLUMEN 🔇\nhasta que vibre 3 veces',
      'boton': 'volumen_abajo_triple',
    },
    {
      'instruccion': 'Este es el botón de\nAPAGAR/ENCENDER 🔴\n¡Si lo presionas\nse apaga la pantalla!',
      'boton': 'power_explicacion',
    },
    {
      'instruccion': 'Ahora toca el botón de\nSUBIR VOLUMEN una sola vez 👆',
      'boton': 'volumen_arriba_tap',
    },
    {
      'instruccion': 'Ahora MANTÉN presionado\nel botón de SUBIR VOLUMEN 🔊',
      'boton': 'volumen_arriba_hold',
    },
  ];

  bool _handler(KeyEvent event) {
    if (_mostrarFelicitacion) return false;

    final botonActual = _pasos[_pasoActual]['boton'];
    final key = event.logicalKey;

    if (event is KeyDownEvent) {
      if (key == LogicalKeyboardKey.audioVolumeUp) {
        if (botonActual == 'volumen_arriba' ||
            botonActual == 'volumen_arriba_tap') {
          _vibrarYAvanzar();
          return true;
        }
      }
      if (key == LogicalKeyboardKey.audioVolumeDown) {
        if (botonActual == 'volumen_abajo') {
          _vibrarYAvanzar();
          return true;
        }
        if (botonActual == 'volumen_abajo_triple') {
          _contadorBajar++;
          if (_contadorBajar >= 3) {
            _contadorBajar = 0;
            _vibrarYAvanzar();
          }
          return true;
        }
      }
    }

    if (event is KeyRepeatEvent) {
      if (key == LogicalKeyboardKey.audioVolumeUp &&
          botonActual == 'volumen_arriba_hold') {
        _vibrarYAvanzar();
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial; //esto hace que arranque desde el paso guardado
    HardwareKeyboard.instance.removeHandler(_handler);
    HardwareKeyboard.instance.addHandler(_handler);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handler);
    super.dispose();
  }

  Future<void> _vibrarYAvanzar() async {
    if (_mostrarFelicitacion) return;

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 300);
      }
    } catch (e) {
      // emulador no vibra
    }
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    if (userId != null) {
      final proximoPaso = _pasoActual + 1;
      await ApiService.guardarPaso(userId, 'conociendo_tu_celular', proximoPaso);
      print('📍 Paso $proximoPaso guardado para usuario $userId');
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
    final esPowerExplicacion = paso['boton'] == 'power_explicacion';

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
                child: Center(child: _buildCelular(paso['boton']!)),
              ),
              if (esPrimerPaso || esUltimoPaso || esPowerExplicacion)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GestureDetector(
                    onTap: () async {
                      if (esUltimoPaso) {
                         // Marca la lección como completada en el backend
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('usuario_id');
                        if (userId != null) {
                          await ApiService.guardarPaso(
                            userId,
                            'conociendo_tu_celular',
                            _pasos.length, // paso final = total de pasos = completada
                            completada: true,
                          );   
                         }
                        if (mounted) Navigator.pop(context); // regresa al mapa
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
                          esUltimoPaso ? '¡Terminé! 🎉' : 'Siguiente →',
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
                  Icon(Icons.phone_android_rounded,
                      color: Colors.white.withOpacity(0.3), size: 60),
                  const SizedBox(height: 8),
                  Text('10:30',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                      )),
                ],
              ),
            ),
          ),
          // Botón SUBIR VOLUMEN
          Positioned(
            right: 0,
            top: 90,
            child: Container(
              width: 14,
              height: 50,
              decoration: BoxDecoration(
                color: (botonActivo == 'volumen_arriba' ||
                        botonActivo == 'volumen_arriba_tap' ||
                        botonActivo == 'volumen_arriba_hold')
                    ? const Color(0xFF6B4EFF)
                    : const Color(0xFF3A3A5C),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: (botonActivo == 'volumen_arriba' ||
                        botonActivo == 'volumen_arriba_tap' ||
                        botonActivo == 'volumen_arriba_hold')
                    ? [
                        BoxShadow(
                            color: const Color(0xFF6B4EFF).withOpacity(0.6),
                            blurRadius: 12)
                      ]
                    : null,
              ),
            ),
          ),
          if (botonActivo == 'volumen_arriba' ||
              botonActivo == 'volumen_arriba_tap' ||
              botonActivo == 'volumen_arriba_hold')
            Positioned(
                right: 20,
                top: 95,
                child: _buildEtiqueta('🔊 Subir\nvolumen')),
          // Botón BAJAR VOLUMEN
          Positioned(
            right: 0,
            top: 155,
            child: Container(
              width: 14,
              height: 50,
              decoration: BoxDecoration(
                color: (botonActivo == 'volumen_abajo' ||
                        botonActivo == 'volumen_abajo_triple')
                    ? const Color(0xFF6B4EFF)
                    : const Color(0xFF3A3A5C),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: (botonActivo == 'volumen_abajo' ||
                        botonActivo == 'volumen_abajo_triple')
                    ? [
                        BoxShadow(
                            color: const Color(0xFF6B4EFF).withOpacity(0.6),
                            blurRadius: 12)
                      ]
                    : null,
              ),
            ),
          ),
          if (botonActivo == 'volumen_abajo' ||
              botonActivo == 'volumen_abajo_triple')
            Positioned(
                right: 20,
                top: 160,
                child: _buildEtiqueta('🔇 Bajar\nvolumen')),
          // Botón POWER
          Positioned(
            left: 0,
            top: 120,
            child: Container(
              width: 14,
              height: 65,
              decoration: BoxDecoration(
                color: botonActivo == 'power_explicacion'
                    ? const Color(0xFFE53E3E)
                    : const Color(0xFF3A3A5C),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                boxShadow: botonActivo == 'power_explicacion'
                    ? [
                        BoxShadow(
                            color: const Color(0xFFE53E3E).withOpacity(0.6),
                            blurRadius: 12)
                      ]
                    : null,
              ),
            ),
          ),
          if (botonActivo == 'power_explicacion')
            Positioned(
                left: 20,
                top: 128,
                child: _buildEtiqueta('🔴 Apagar /\nEncender')),
        ],
      ),
    );
  }

  Widget _buildEtiqueta(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
        ],
      ),
      child: Text(texto,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.4,
          )),
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
                Text('¡Muy bien!',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 8),
                Text('Lo hiciste perfecto 👏',
                    style: TextStyle(
                      color: Color(0xFF555577),
                      fontSize: 18,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}