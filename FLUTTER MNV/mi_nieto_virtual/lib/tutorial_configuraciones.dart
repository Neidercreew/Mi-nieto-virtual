import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:torch_light/torch_light.dart';
import 'services/api_service.dart';

const String _leccionId = 'configuraciones_esenciales';

class TutorialConfiguracionesScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialConfiguracionesScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialConfiguracionesScreen> createState() =>
      _TutorialConfiguracionesScreenState();
}

class _TutorialConfiguracionesScreenState
    extends State<TutorialConfiguracionesScreen>
    with TickerProviderStateMixin {
  int _pasoActual = 0;
  bool _mostrarFelicitacion = false;
  double _brilloActual = 0.5;
  bool _linternaEncendida = false;

  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  final List<Map<String, dynamic>> _pasos = [
    // INTRO
    {
      'tipo': 'intro',
      'titulo': 'Configuraciones\nesenciales ⚙️',
      'instruccion': 'Hoy vas a aprender a controlar las cosas más importantes de tu celular.\n\n¡Es más fácil de lo que crees!',
      'icono': Icons.settings_rounded,
      'colorIcono': const Color(0xFF6B4EFF),
    },
    // WIFI — analogia
    {
      'tipo': 'analogia',
      'titulo': '¿Qué es el WiFi? 📶',
      'instruccion': 'El WiFi es como la señal de una emisora de radio.\n\nTu celular necesita "sintonizarse" a la señal de internet de tu casa para conectarse.',
      'icono': Icons.wifi_rounded,
      'colorIcono': const Color(0xFF0EA5E9),
    },
    // WIFI — muestra panel
    {
      'tipo': 'muestra_panel',
      'titulo': 'Así se ve el WiFi\nen tu celular',
      'instruccion': 'Cuando deslizas desde arriba hacia abajo aparece este panel.\n\nMira el símbolo del WiFi 👇 — lo vamos a tocar.',
      'icono': Icons.wifi_rounded,
      'colorIcono': const Color(0xFF0EA5E9),
      'iconoResaltado': Icons.wifi_rounded,
      'etiquetaResaltada': 'WiFi',
    },
    // WIFI — accion 1
    {
      'tipo': 'accion',
      'titulo': 'PASO 1 DE 2\nDesliza desde arriba',
      'instruccion': 'Pon tu dedo en la parte de ARRIBA de tu celular real.\n\nAhora deslízalo hacia ABAJO lentamente hasta que aparezca el panel.',
      'icono': Icons.swipe_down_rounded,
      'colorIcono': const Color(0xFF0EA5E9),
      'confirmacion': '✅ Ya apareció el panel',
    },
    // WIFI — accion 2
    {
      'tipo': 'accion',
      'titulo': 'PASO 2 DE 2\nToca el WiFi',
      'instruccion': 'Busca el símbolo 📶 en el panel.\n\nTócalo una vez con el dedo.',
      'icono': Icons.wifi_rounded,
      'colorIcono': const Color(0xFF0EA5E9),
      'confirmacion': '✅ Ya toqué el WiFi',
    },
    // WIFI — verificacion
    {
      'tipo': 'verificacion',
      'titulo': '¿Lo ves de color? 🎨',
      'instruccion': 'Si el símbolo del WiFi se puso azul o verde...\n\n¡Está ACTIVADO! ✅\n\nSi sigue gris, tócalo una vez más.',
      'icono': Icons.check_circle_rounded,
      'colorIcono': const Color(0xFF059669),
    },
    // DATOS — analogia
    {
      'tipo': 'analogia',
      'titulo': '¿Qué son los\ndatos móviles? 📡',
      'instruccion': 'Los datos móviles son como el combustible de un carro.\n\nCuando no tienes WiFi, tu celular usa este "combustible" para conectarse a internet.',
      'icono': Icons.signal_cellular_alt_rounded,
      'colorIcono': const Color(0xFF8B5CF6),
    },
    // DATOS — muestra panel
    {
      'tipo': 'muestra_panel',
      'titulo': 'Así se ven los\ndatos móviles',
      'instruccion': 'En el mismo panel de arriba, busca este símbolo 📡\n\nCuando está de color, los datos están activos.',
      'icono': Icons.signal_cellular_alt_rounded,
      'colorIcono': const Color(0xFF8B5CF6),
      'iconoResaltado': Icons.signal_cellular_alt_rounded,
      'etiquetaResaltada': 'Datos',
    },
    // DATOS — accion
    {
      'tipo': 'accion',
      'titulo': 'PASO 1 DE 1\nActiva los datos',
      'instruccion': 'En el panel de arriba toca el símbolo de la señal 📡\n\nTócalo para activarlo o desactivarlo.',
      'icono': Icons.signal_cellular_alt_rounded,
      'colorIcono': const Color(0xFF8B5CF6),
      'confirmacion': '✅ Ya lo encontré y toqué',
    },
    // DATOS — tip
    {
      'tipo': 'tip',
      'titulo': '💡 Tip importante',
      'instruccion': 'En casa → usa el WiFi 🏠\n\nEn la calle → usa los datos 🚶\n\nAsí no gastas el combustible de tu celular cuando no lo necesitas.',
      'icono': Icons.lightbulb_rounded,
      'colorIcono': const Color(0xFFFFB300),
    },
    // BRILLO — analogia
    {
      'tipo': 'analogia',
      'titulo': '¿Qué es el brillo? ☀️',
      'instruccion': 'El brillo de la pantalla es como la perilla de luz de una lámpara.\n\nPuedes subirlo para ver mejor o bajarlo para ahorrar batería.',
      'icono': Icons.brightness_6_rounded,
      'colorIcono': const Color(0xFFFFB300),
    },
    // BRILLO — muestra panel
    {
      'tipo': 'muestra_panel',
      'titulo': 'Así se ve la\nbarrita de brillo',
      'instruccion': 'En el panel de arriba verás una barrita larga con un sol ☀️\n\nDesliza el dedo sobre ella para controlar el brillo.',
      'icono': Icons.brightness_6_rounded,
      'colorIcono': const Color(0xFFFFB300),
      'iconoResaltado': Icons.brightness_6_rounded,
      'etiquetaResaltada': 'Brillo',
      'mostrarBrillo': true,
    },
    // BRILLO — accion interactiva
    {
      'tipo': 'accion_brillo',
      'titulo': 'Prueba el brillo\nen tu celular',
      'instruccion': 'Mueve la barrita de abajo para ver cómo cambia el brillo de tu pantalla.\n\nCuando estés listo toca "Lo hice".',
      'icono': Icons.brightness_6_rounded,
      'colorIcono': const Color(0xFFFFB300),
      'confirmacion': '✅ Lo hice',
    },
    // MODO AVION — analogia
    {
      'tipo': 'analogia',
      'titulo': '¿Qué es el\nmodo avión? ✈️',
      'instruccion': 'Cuando subes a un avión te piden apagar el celular.\n\nEl modo avión apaga todas las señales — pero el celular sigue encendido.',
      'icono': Icons.airplanemode_active_rounded,
      'colorIcono': const Color(0xFF0EA5E9),
    },
    // MODO AVION — tip
    {
      'tipo': 'tip',
      'titulo': '¿Cuándo usarlo?',
      'instruccion': '✈️ En un avión\n\n🏥 En un hospital\n\n🔋 Para ahorrar batería\n\n🔇 Cuando no quieres llamadas',
      'icono': Icons.airplanemode_active_rounded,
      'colorIcono': const Color(0xFF0EA5E9),
    },
    // MODO AVION — muestra panel
    {
      'tipo': 'muestra_panel',
      'titulo': 'Así se ve el\nmodo avión',
      'instruccion': 'En el panel de arriba busca el símbolo del avión ✈️\n\nCuando está de color, el modo avión está activo.',
      'icono': Icons.airplanemode_active_rounded,
      'colorIcono': const Color(0xFF0EA5E9),
      'iconoResaltado': Icons.airplanemode_active_rounded,
      'etiquetaResaltada': 'Avión',
    },
    // MODO AVION — accion
    {
      'tipo': 'accion',
      'titulo': 'PASO 1 DE 1\nEncuéntralo',
      'instruccion': 'En el panel de arriba busca el avión ✈️\n\nTócalo una vez para activarlo.\nTócalo de nuevo para desactivarlo.',
      'icono': Icons.airplanemode_active_rounded,
      'colorIcono': const Color(0xFF0EA5E9),
      'confirmacion': '✅ Ya lo encontré',
    },
    // LINTERNA — analogia
    {
      'tipo': 'analogia',
      'titulo': '¡Tu celular tiene\nlinterna! 🔦',
      'instruccion': 'Tu celular tiene una linterna que usa la luz de la cámara trasera.\n\nEs muy útil en la oscuridad o cuando buscas algo.',
      'icono': Icons.flashlight_on_rounded,
      'colorIcono': const Color(0xFFFFB300),
    },
    // LINTERNA — accion interactiva
    {
      'tipo': 'accion_linterna',
      'titulo': 'Enciende tu linterna\ndesde aquí 🔦',
      'instruccion': 'Toca el botón de abajo para encender y apagar la linterna real de tu celular.\n\nObserva cómo la luz de atrás se enciende.',
      'icono': Icons.flashlight_on_rounded,
      'colorIcono': const Color(0xFFFFB300),
      'confirmacion': '✅ Ya practiqué la linterna',
    },
    // LINTERNA — muestra panel
    {
      'tipo': 'muestra_panel',
      'titulo': 'También puedes\nactivarla desde arriba',
      'instruccion': 'En el panel de arriba también aparece el símbolo de la linterna 🔦\n\nTócalo para encenderla rápido.',
      'icono': Icons.flashlight_on_rounded,
      'colorIcono': const Color(0xFFFFB300),
      'iconoResaltado': Icons.flashlight_on_rounded,
      'etiquetaResaltada': 'Linterna',
    },
    // TAMAÑO LETRA — analogia
    {
      'tipo': 'analogia',
      'titulo': '¿Letras muy\npequeñas? 🔤',
      'instruccion': 'Si las letras de tu celular se ven muy pequeñas, puedes hacerlas más grandes.\n\nEs como elegir el tamaño de letra en un libro.',
      'icono': Icons.text_fields_rounded,
      'colorIcono': const Color(0xFF8B5CF6),
    },
    // TAMAÑO LETRA — muestra ajustes
    {
      'tipo': 'muestra_ajustes',
      'titulo': 'Así se ve la\npantalla de Ajustes',
      'instruccion': 'Cuando abres Ajustes ⚙️ verás una lista como esta.\n\nBusca "Pantalla" — la vamos a tocar.',
      'icono': Icons.settings_rounded,
      'colorIcono': const Color(0xFF8B5CF6),
      'itemResaltado': 'Pantalla',
      'items': ['Conexiones', 'Pantalla', 'Sonido', 'Seguridad', 'Almacenamiento'],
    },
    // TAMAÑO LETRA — accion 1
    {
      'tipo': 'accion',
      'titulo': 'PASO 1 DE 3\nAbre Ajustes',
      'instruccion': 'Busca el ícono del engranaje ⚙️ en tu pantalla principal y tócalo.',
      'icono': Icons.settings_rounded,
      'colorIcono': const Color(0xFF8B5CF6),
      'confirmacion': '✅ Ya abrí Ajustes',
    },
    // TAMAÑO LETRA — accion 2
    {
      'tipo': 'accion',
      'titulo': 'PASO 2 DE 3\nToca Pantalla',
      'instruccion': 'Dentro de Ajustes, desliza hacia abajo y busca la palabra\n"Pantalla" o "Display".\n\nTócala.',
      'icono': Icons.display_settings_rounded,
      'colorIcono': const Color(0xFF8B5CF6),
      'confirmacion': '✅ Ya toqué Pantalla',
    },
    // TAMAÑO LETRA — accion 3
    {
      'tipo': 'accion',
      'titulo': 'PASO 3 DE 3\nCambia el tamaño',
      'instruccion': 'Busca "Tamaño de fuente" o "Tamaño de letra".\n\nMueve el control hacia la derecha para hacer las letras más grandes.',
      'icono': Icons.text_increase_rounded,
      'colorIcono': const Color(0xFF8B5CF6),
      'confirmacion': '✅ Ya cambié el tamaño',
    },
    // PIN — analogia
    {
      'tipo': 'analogia',
      'titulo': '¿Qué es el PIN? 🔐',
      'instruccion': 'El PIN es como la llave de tu casa.\n\nSin ese número, nadie puede entrar a tu celular aunque lo encuentre.',
      'icono': Icons.lock_rounded,
      'colorIcono': const Color(0xFFE53E3E),
    },
    // PIN — tip
    {
      'tipo': 'tip',
      'titulo': '💡 ¿Cómo elegir\nun buen PIN?',
      'instruccion': '❌ No uses tu fecha de nacimiento\n\n❌ No uses 1234 o 0000\n\n✅ Usa un número que solo tú conozcas\n\n✅ Escríbelo en un papel y guárdalo',
      'icono': Icons.lock_rounded,
      'colorIcono': const Color(0xFFE53E3E),
    },
    // PIN — muestra ajustes
    {
      'tipo': 'muestra_ajustes',
      'titulo': 'Así se ve\nSeguridad en Ajustes',
      'instruccion': 'Dentro de Ajustes busca "Seguridad" o "Bloqueo de pantalla".\n\nLa vamos a tocar para poner tu PIN.',
      'icono': Icons.security_rounded,
      'colorIcono': const Color(0xFFE53E3E),
      'itemResaltado': 'Seguridad',
      'items': ['Conexiones', 'Pantalla', 'Sonido', 'Seguridad', 'Almacenamiento'],
    },
    // PIN — accion 1
    {
      'tipo': 'accion',
      'titulo': 'PASO 1 DE 2\nAbre Seguridad',
      'instruccion': 'Abre Ajustes ⚙️\n\nBusca "Seguridad" o "Bloqueo de pantalla" y tócalo.',
      'icono': Icons.security_rounded,
      'colorIcono': const Color(0xFFE53E3E),
      'confirmacion': '✅ Ya abrí Seguridad',
    },
    // PIN — accion 2
    {
      'tipo': 'accion',
      'titulo': 'PASO 2 DE 2\nElige PIN',
      'instruccion': 'Busca "Bloqueo de pantalla" o "Tipo de bloqueo".\n\nElige "PIN" e ingresa tu número secreto.',
      'icono': Icons.lock_rounded,
      'colorIcono': const Color(0xFFE53E3E),
      'confirmacion': '✅ Ya configuré mi PIN',
    },
    // ALMACENAMIENTO — analogia
    {
      'tipo': 'analogia',
      'titulo': '¿Qué es el\nalmacenamiento? 🗄️',
      'instruccion': 'El almacenamiento es como el cajón de tu celular.\n\nCada foto, video y app ocupa espacio. Cuando el cajón se llena, el celular se vuelve lento.',
      'icono': Icons.storage_rounded,
      'colorIcono': const Color(0xFF059669),
    },
    // ALMACENAMIENTO — muestra ajustes
    {
      'tipo': 'muestra_ajustes',
      'titulo': 'Así se ve\nAlmacenamiento',
      'instruccion': 'Dentro de Ajustes busca "Almacenamiento" o "Memoria".\n\nAhí verás cuánto espacio tienes disponible.',
      'icono': Icons.storage_rounded,
      'colorIcono': const Color(0xFF059669),
      'itemResaltado': 'Almacenamiento',
      'items': ['Conexiones', 'Pantalla', 'Sonido', 'Seguridad', 'Almacenamiento'],
    },
    // ALMACENAMIENTO — accion
    {
      'tipo': 'accion',
      'titulo': 'PASO 1 DE 1\nRevisa tu espacio',
      'instruccion': 'Abre Ajustes ⚙️\n\nBusca "Almacenamiento" o "Memoria" y tócalo.\n\nVerás cuánto espacio libre tienes.',
      'icono': Icons.storage_rounded,
      'colorIcono': const Color(0xFF059669),
      'confirmacion': '✅ Ya revisé mi espacio',
    },
    // CELEBRACION
    {
      'tipo': 'celebracion',
      'titulo': '¡Lo lograste! 🏆',
      'instruccion': 'Ya sabes controlar las cosas más importantes de tu celular.\n\nWiFi ✅   Datos ✅   Brillo ✅\nLinterna ✅   Letras ✅   PIN ✅\nAlmacenamiento ✅',
      'icono': Icons.emoji_events_rounded,
      'colorIcono': const Color(0xFFFFB300),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial;
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _flashAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );
    _cargarBrilloActual();
  }

  @override
  void dispose() {
    _flashController.dispose();
    if (_linternaEncendida) TorchLight.disableTorch();
    super.dispose();
  }

  Future<void> _cargarBrilloActual() async {
    try {
      final brillo = await ScreenBrightness().current;
      if (mounted) setState(() => _brilloActual = brillo);
    } catch (_) {}
  }

  Future<void> _cambiarBrillo(double valor) async {
    setState(() => _brilloActual = valor);
    try {
      await ScreenBrightness().setScreenBrightness(valor);
    } catch (_) {}
  }

  Future<void> _toggleLinterna() async {
    try {
      if (_linternaEncendida) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      setState(() => _linternaEncendida = !_linternaEncendida);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La linterna no está disponible en este dispositivo'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _avanzar() async {
    if (_mostrarFelicitacion) return;

    if (_pasos[_pasoActual]['tipo'] == 'accion_linterna' && _linternaEncendida) {
      await TorchLight.disableTorch();
      setState(() => _linternaEncendida = false);
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('usuario_id');
    final esUltimo = _pasoActual == _pasos.length - 1;

    if (userId != null) {
      await ApiService.guardarPaso(
        userId, _leccionId, _pasoActual + 1,
        completada: esUltimo,
      );
    }

    if (esUltimo) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final tipo = _pasos[_pasoActual]['tipo'];
    if (tipo == 'accion' || tipo == 'accion_brillo') {
      setState(() => _mostrarFelicitacion = true);
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      setState(() {
        _mostrarFelicitacion = false;
        _pasoActual++;
      });
    } else {
      setState(() => _pasoActual++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_pasoActual];
    return Scaffold(
      backgroundColor: const Color(0xFFF0EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EEFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF6B4EFF)),
          onPressed: () {
            if (_linternaEncendida) TorchLight.disableTorch();
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'Configuraciones esenciales',
          style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildProgreso(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCajaInstruccion(paso),
              ),
              const SizedBox(height: 16),
              Expanded(child: Center(child: _buildIlustracion(paso))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: _buildBoton(paso),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Text(
            'Paso ${_pasoActual + 1} de ${_pasos.length}',
            style: const TextStyle(color: Color(0xFF6B4EFF), fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_pasoActual + 1) / _pasos.length,
              backgroundColor: const Color(0xFFDED8FF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCajaInstruccion(Map<String, dynamic> paso) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4EFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            paso['titulo'],
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            paso['instruccion'],
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildIlustracion(Map<String, dynamic> paso) {
    final tipo = paso['tipo'] as String;
    final icono = paso['icono'] as IconData;
    final color = paso['colorIcono'] as Color;

    switch (tipo) {
      case 'muestra_panel':
        return _buildPanelAjustesRapidos(
          paso['iconoResaltado'] as IconData,
          paso['etiquetaResaltada'] as String,
          color,
          mostrarBrillo: paso['mostrarBrillo'] == true,
        );
      case 'muestra_ajustes':
        return _buildPantallaAjustes(
          paso['items'] as List<dynamic>,
          paso['itemResaltado'] as String,
          color,
        );
      case 'accion_brillo':
        return _buildControlBrillo();
      case 'accion_linterna':
        return _buildControlLinterna();
      case 'celebracion':
        return _buildTrofeo();
      default:
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.3), width: 3),
          ),
          child: Center(child: Icon(icono, size: 75, color: color)),
        );
    }
  }

  Widget _buildPanelAjustesRapidos(
    IconData iconoResaltado,
    String etiquetaResaltada,
    Color colorResaltado, {
    bool mostrarBrillo = false,
  }) {
    final List<Map<String, dynamic>> iconos = [
      {'icono': Icons.wifi_rounded, 'label': 'WiFi'},
      {'icono': Icons.signal_cellular_alt_rounded, 'label': 'Datos'},
      {'icono': Icons.bluetooth_rounded, 'label': 'Bluetooth'},
      {'icono': Icons.airplanemode_active_rounded, 'label': 'Avión'},
      {'icono': Icons.flashlight_on_rounded, 'label': 'Linterna'},
      {'icono': Icons.do_not_disturb_on_rounded, 'label': 'Silencio'},
    ];

    return Container(
      width: 270,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('10:30', style: TextStyle(color: Colors.white, fontSize: 13)),
              Row(children: const [
                Icon(Icons.wifi_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Icon(Icons.battery_full_rounded, color: Colors.white, size: 14),
              ]),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: iconos.map((item) {
              final esResaltado = item['label'] == etiquetaResaltada;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: esResaltado ? colorResaltado : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: esResaltado ? Border.all(color: Colors.white, width: 2) : null,
                      boxShadow: esResaltado
                          ? [BoxShadow(color: colorResaltado.withOpacity(0.55), blurRadius: 14)]
                          : null,
                    ),
                    child: Icon(item['icono'] as IconData, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: esResaltado ? colorResaltado : Colors.white54,
                      fontSize: 10,
                      fontWeight: esResaltado ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          if (mostrarBrillo) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.brightness_low_rounded, color: Colors.white54, size: 18),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: const Color(0xFFFFB300),
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(value: _brilloActual, onChanged: _cambiarBrillo),
                  ),
                ),
                const Icon(Icons.brightness_high_rounded, color: Colors.white, size: 22),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPantallaAjustes(List<dynamic> items, String itemResaltado, Color colorResaltado) {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Ajustes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...items.map((item) {
            final esResaltado = item == itemResaltado;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: esResaltado ? colorResaltado.withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: esResaltado
                    ? Border.all(color: colorResaltado, width: 2)
                    : Border.all(color: Colors.transparent),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(_iconoParaItem(item as String),
                    color: esResaltado ? colorResaltado : Colors.grey, size: 22),
                title: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: esResaltado ? FontWeight.bold : FontWeight.normal,
                    color: esResaltado ? colorResaltado : const Color(0xFF1A1A2E),
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    color: esResaltado ? colorResaltado : Colors.grey, size: esResaltado ? 16 : 14),
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _iconoParaItem(String item) {
    switch (item) {
      case 'Conexiones': return Icons.wifi_rounded;
      case 'Pantalla': return Icons.display_settings_rounded;
      case 'Sonido': return Icons.volume_up_rounded;
      case 'Seguridad': return Icons.security_rounded;
      case 'Almacenamiento': return Icons.storage_rounded;
      default: return Icons.settings_rounded;
    }
  }

  Widget _buildControlBrillo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80 + (_brilloActual * 60),
          height: 80 + (_brilloActual * 60),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFB300).withOpacity(0.1 + _brilloActual * 0.3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withOpacity(0.2 + _brilloActual * 0.5),
                blurRadius: 20 + _brilloActual * 30,
                spreadRadius: _brilloActual * 10,
              ),
            ],
          ),
          child: Icon(Icons.wb_sunny_rounded, size: 50 + (_brilloActual * 30), color: const Color(0xFFFFB300)),
        ),
        const SizedBox(height: 24),
        Text(
          '${(_brilloActual * 100).toInt()}%',
          style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.brightness_low_rounded, color: Color(0xFFFFB300), size: 20),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                    activeTrackColor: const Color(0xFFFFB300),
                    inactiveTrackColor: const Color(0xFFDED8FF),
                    thumbColor: const Color(0xFFFFB300),
                    overlayColor: const Color(0xFFFFB300).withOpacity(0.2),
                  ),
                  child: Slider(value: _brilloActual, onChanged: _cambiarBrillo),
                ),
              ),
              const Icon(Icons.brightness_high_rounded, color: Color(0xFFFFB300), size: 26),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlLinterna() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 180,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cuerpo del celular
              Container(
                width: 140,
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _linternaEncendida
                          ? const Color(0xFFFFB300).withOpacity(0.6)
                          : Colors.black.withOpacity(0.3),
                      blurRadius: _linternaEncendida ? 30 : 15,
                      spreadRadius: _linternaEncendida ? 8 : 0,
                    ),
                  ],
                ),
              ),
              // Camara trasera
              Positioned(
                top: 30,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2D2D44),
                    border: Border.all(color: Colors.grey.shade700, width: 2),
                  ),
                  child: const Center(child: Icon(Icons.camera_rounded, color: Colors.grey, size: 20)),
                ),
              ),
              // Flash animado
              if (_linternaEncendida)
                Positioned(
                  top: 36,
                  right: 28,
                  child: AnimatedBuilder(
                    animation: _flashAnimation,
                    builder: (_, __) => Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(_flashAnimation.value),
                            blurRadius: 20 * _flashAnimation.value,
                            spreadRadius: 6 * _flashAnimation.value,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Pantalla del celular
              Positioned(
                bottom: 20,
                child: Container(
                  width: 110,
                  height: 140,
                  decoration: BoxDecoration(
                    color: _linternaEncendida ? const Color(0xFF2D2D44) : const Color(0xFF111122),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      _linternaEncendida ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                      color: _linternaEncendida ? const Color(0xFFFFB300) : Colors.grey.shade700,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Boton de encender/apagar
        GestureDetector(
          onTap: _toggleLinterna,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: _linternaEncendida ? const Color(0xFFFFB300) : const Color(0xFF2D2D44),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: _linternaEncendida
                      ? const Color(0xFFFFB300).withOpacity(0.5)
                      : Colors.transparent,
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _linternaEncendida ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  _linternaEncendida ? 'Apagar linterna' : 'Encender linterna',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrofeo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFAEEDA),
            border: Border.all(color: const Color(0xFFEF9F27), width: 3),
          ),
          child: const Center(child: Text('🏆', style: TextStyle(fontSize: 70))),
        ),
        const SizedBox(height: 16),
        const Text(
          '¡Eres todo un experto!',
          style: TextStyle(color: Color(0xFF854F0B), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBoton(Map<String, dynamic> paso) {
    final tipo = paso['tipo'] as String;
    final esUltimo = _pasoActual == _pasos.length - 1;

    String texto;
    Color color;

    if (esUltimo) {
      texto = '¡Terminé! 🎉';
      color = const Color(0xFF059669);
    } else if (tipo == 'accion' || tipo == 'accion_brillo' || tipo == 'accion_linterna') {
      texto = paso['confirmacion'] ?? '✅ Lo hice';
      color = const Color(0xFF059669);
    } else {
      texto = 'Entendido, siguiente →';
      color = const Color(0xFF6B4EFF);
    }

    return GestureDetector(
      onTap: _avanzar,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5)),
          ],
        ),
        child: Center(
          child: Text(
            texto,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎉', style: TextStyle(fontSize: 60)),
                SizedBox(height: 16),
                Text('¡Muy bien!', style: TextStyle(color: Color(0xFF059669), fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Lo hiciste perfecto 👏', style: TextStyle(color: Color(0xFF555577), fontSize: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}