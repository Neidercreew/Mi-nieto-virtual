import 'package:flutter/material.dart';

// Piezas compartidas por todas las lecciones de Nequi.
// Todo es simulado: plata, movimientos y datos de practica.

// ------------------------------------------------------------
// COLORES Y DATOS DE PRACTICA
// ------------------------------------------------------------

class NequiColores {
  // App Nequi simulada
  static const magenta = Color(0xFFDA0081);
  static const morado = Color(0xFF200020);
  static const rosaSuave = Color(0xFFFFE3F3);
  static const fondoApp = Color(0xFFFBF7FA);

  // Paleta oficial MNV
  static const mnvMorado = Color(0xFF6B4EFF);
  static const mnvMoradoSec = Color(0xFF8B5CF6);
  static const mnvVerde = Color(0xFF059669);
  static const mnvAmarillo = Color(0xFFFFB300);
  static const mnvRojo = Color(0xFFE53E3E);
  static const mnvFondo = Color(0xFFF0EEFF);
  static const textoOscuro = Color(0xFF1A1A2E);
  static const textoSuave = Color(0xFF777799);
  static const borde = Color(0xFFDED8FF);
  static const textoConsejo = Color(0xFF854F0B);
}

// Saldo inicial de practica, igual en todas las lecciones
const int saldoPractica = 250000;

// Convierte 150000 en "$ 150.000"
String formatoPesos(int valor) {
  final negativo = valor < 0;
  final s = valor.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${negativo ? '-' : ''}\$ ${buf.toString()}';
}

class NequiMovimiento {
  final String descripcion;
  final int valor; // positivo = entra, negativo = sale
  final String fecha;
  final IconData icono;
  const NequiMovimiento(this.descripcion, this.valor, this.fecha, this.icono);
}

// Hilo conductor: Andres es el nieto
const List<NequiMovimiento> movimientosPractica = [
  NequiMovimiento('Andrés (tu nieto) te envió', 50000, 'Hoy', Icons.favorite_rounded),
  NequiMovimiento('Pago en Panadería La Espiga', -8500, 'Ayer', Icons.bakery_dining_rounded),
  NequiMovimiento('Recarga en tienda de barrio', 100000, '28 sep', Icons.storefront_rounded),
  NequiMovimiento('Le enviaste a Gloria', -20000, '25 sep', Icons.send_rounded),
];

// ------------------------------------------------------------
// ANIMACION DE RESALTE (pulso estandar MNV)
// ------------------------------------------------------------

class NequiPulso extends StatefulWidget {
  final bool activo;
  final Widget child;
  final double radio;
  final double escala;
  const NequiPulso({
    super.key,
    required this.activo,
    required this.child,
    this.radio = 16,
    this.escala = 1.12,
  });

  @override
  State<NequiPulso> createState() => _NequiPulsoState();
}

class _NequiPulsoState extends State<NequiPulso> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _curva;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _curva = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    if (widget.activo) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant NequiPulso old) {
    super.didUpdateWidget(old);
    // Solo anima cuando esta resaltado
    if (widget.activo && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.activo && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.activo) return widget.child;
    return AnimatedBuilder(
      animation: _curva,
      child: widget.child,
      builder: (_, child) {
        final v = _curva.value;
        return Transform.scale(
          scale: 1 + (widget.escala - 1) * v,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radio),
              boxShadow: [
                BoxShadow(
                  color: NequiColores.mnvAmarillo.withOpacity(0.65),
                  blurRadius: 10 + 8 * v,
                  spreadRadius: 1 + 2 * v,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// MARCO DEL CELULAR SIMULADO
// ------------------------------------------------------------

class MarcoCelular extends StatelessWidget {
  final Widget child;
  final bool barraClara; // texto blanco en la barra de estado
  const MarcoCelular({super.key, required this.child, this.barraClara = false});

  @override
  Widget build(BuildContext context) {
    final colorBarra = barraClara ? Colors.white : NequiColores.textoOscuro;
    return Container(
      width: 290,
      height: 560,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(child: child),
            // Barra de estado encima de la pantalla
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                child: Row(
                  children: [
                    Text('10:30',
                        style: TextStyle(color: colorBarra, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Icon(Icons.signal_cellular_alt_rounded, size: 15, color: colorBarra),
                    const SizedBox(width: 4),
                    Icon(Icons.wifi_rounded, size: 15, color: colorBarra),
                    const SizedBox(width: 4),
                    Icon(Icons.battery_full_rounded, size: 15, color: colorBarra),
                  ],
                ),
              ),
            ),
            // Barrita inferior del celular
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 90,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorBarra.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Logo: usa el asset que ya existe en el proyecto
class NequiLogo extends StatelessWidget {
  final double tam;
  const NequiLogo({super.key, this.tam = 50});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(tam * 0.26),
      child: Image.asset(
        'assets/icons/nequi.png',
        width: tam,
        height: tam,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          width: tam,
          height: tam,
          color: NequiColores.magenta,
          child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: tam * 0.55),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// PANTALLA: ESCRITORIO DEL CELULAR (donde esta el icono de Nequi)
// ------------------------------------------------------------

class NequiEscritorio extends StatelessWidget {
  final Set<String> resaltados;
  final ValueChanged<String> onAccion;
  const NequiEscritorio({super.key, required this.resaltados, required this.onAccion});

  static const _apps = <Map<String, dynamic>>[
    {'id': 'telefono', 'nombre': 'Teléfono', 'icono': Icons.phone_rounded, 'color': Color(0xFF059669)},
    {'id': 'mensajes', 'nombre': 'Mensajes', 'icono': Icons.chat_bubble_rounded, 'color': Color(0xFF0EA5E9)},
    {'id': 'camara', 'nombre': 'Cámara', 'icono': Icons.photo_camera_rounded, 'color': Color(0xFF8B5CF6)},
    {'id': 'galeria', 'nombre': 'Galería', 'icono': Icons.photo_library_rounded, 'color': Color(0xFFFFB300)},
    {'id': 'reloj', 'nombre': 'Reloj', 'icono': Icons.alarm_rounded, 'color': Color(0xFF1A1A2E)},
    {'id': 'app_nequi', 'nombre': 'Nequi'},
    {'id': 'calendario', 'nombre': 'Calendario', 'icono': Icons.calendar_month_rounded, 'color': Color(0xFFE53E3E)},
    {'id': 'ajustes', 'nombre': 'Ajustes', 'icono': Icons.settings_rounded, 'color': Color(0xFF777799)},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6B4EFF), Color(0xFF3B2A99)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: Column(
        children: [
          const Text('10:30',
              style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w300)),
          const Text('Jueves, 1 de octubre', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 30),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 6,
            childAspectRatio: 0.75,
            children: _apps.map(_app).toList(),
          ),
        ],
      ),
    );
  }

  Widget _app(Map<String, dynamic> app) {
    final esNequi = app['id'] == 'app_nequi';
    final Widget icono = esNequi
        ? const NequiLogo(tam: 50)
        : Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: app['color'] as Color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(app['icono'] as IconData, color: Colors.white, size: 28),
          );
    return GestureDetector(
      onTap: () => onAccion(esNequi ? 'app_nequi' : 'app_otra'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NequiPulso(
            activo: esNequi && resaltados.contains('app_nequi'),
            radio: 14,
            escala: 1.18,
            child: icono,
          ),
          const SizedBox(height: 6),
          Text(
            app['nombre'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// TECLADO NUMERICO (clave y montos)
// ------------------------------------------------------------

class NequiTeclado extends StatelessWidget {
  final Set<String> resaltados;
  final ValueChanged<String> onTecla;
  const NequiTeclado({super.key, required this.resaltados, required this.onTecla});

  static const _filas = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _filas
          .map((fila) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: fila
                      .map((t) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: _tecla(t),
                          ))
                      .toList(),
                ),
              ))
          .toList(),
    );
  }

  Widget _tecla(String t) {
    if (t.isEmpty) return const SizedBox(width: 70, height: 52);
    final esBorrar = t == '⌫';
    return NequiPulso(
      activo: resaltados.contains(t),
      radio: 14,
      escala: 1.1,
      child: Material(
        color: esBorrar ? const Color(0xFFEDE9FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onTecla(t),
          child: SizedBox(
            width: 70,
            height: 52,
            child: Center(
              child: esBorrar
                  ? const Icon(Icons.backspace_rounded, color: NequiColores.mnvMorado, size: 24)
                  : Text(t,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600, color: NequiColores.textoOscuro)),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// PANTALLA: CLAVE DE ENTRADA
// ------------------------------------------------------------

class NequiPantallaClave extends StatelessWidget {
  final String nombre;
  final int digitos;
  final Set<String> resaltados;
  final ValueChanged<String> onAccion;
  const NequiPantallaClave({
    super.key,
    required this.nombre,
    required this.digitos,
    required this.resaltados,
    required this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 46, 16, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [NequiColores.magenta, NequiColores.morado],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const NequiLogo(tam: 52),
                const SizedBox(height: 10),
                Text('Hola, $nombre',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Escribe tu clave para entrar',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final lleno = i < digitos;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 9),
                width: lleno ? 18 : 16,
                height: lleno ? 18 : 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lleno ? NequiColores.magenta : Colors.transparent,
                  border: Border.all(color: NequiColores.magenta, width: 2),
                ),
              );
            }),
          ),
          const Spacer(),
          NequiTeclado(resaltados: resaltados, onTecla: onAccion),
          const SizedBox(height: 26),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// PANTALLA: INICIO DE NEQUI (saldo + botones)
// ------------------------------------------------------------

class NequiInicio extends StatelessWidget {
  final String nombre;
  final int saldo;
  final bool saldoVisible;
  final Set<String> resaltados;
  final Set<String> tocados; // botones ya explorados (muestran un chulito)
  final String? explicacion; // burbuja oscura de ayuda dentro del celular
  final ValueChanged<String> onAccion;
  const NequiInicio({
    super.key,
    required this.nombre,
    required this.saldo,
    required this.saldoVisible,
    required this.resaltados,
    required this.onAccion,
    this.tocados = const {},
    this.explicacion,
  });

  @override
  Widget build(BuildContext context) {
    final texto = explicacion;
    return Container(
      color: NequiColores.fondoApp,
      child: Stack(
        children: [
          Column(
            children: [
              _encabezado(),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: _tarjetaSaldo()),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _boton('envia', 'Envía', Icons.send_rounded),
                    _boton('pide', 'Pide', Icons.call_received_rounded),
                    _boton('saca', 'Saca', Icons.local_atm_rounded),
                    _boton('recarga', 'Recarga', Icons.add_card_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _filaAccion('qr', 'Paga con QR', Icons.qr_code_scanner_rounded),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _filaAccion('movimientos', 'Movimientos', Icons.receipt_long_rounded),
              ),
            ],
          ),
          if (texto != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 22,
              child: NequiBurbuja(key: ValueKey(texto), texto: texto),
            ),
        ],
      ),
    );
  }

  Widget _encabezado() {
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 12, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: NequiColores.rosaSuave,
            child: Text(inicial,
                style: const TextStyle(color: NequiColores.magenta, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hola,', style: TextStyle(fontSize: 12, color: NequiColores.textoSuave)),
                Text(nombre,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
              ],
            ),
          ),
          NequiPulso(
            activo: resaltados.contains('salir'),
            radio: 20,
            escala: 1.2,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 1,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onAccion('salir'),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.logout_rounded, color: NequiColores.magenta, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaSaldo() {
    return NequiPulso(
      activo: resaltados.contains('saldo'),
      radio: 22,
      escala: 1.04,
      child: GestureDetector(
        onTap: () => onAccion('saldo'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [NequiColores.magenta, NequiColores.morado],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Disponible', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const Spacer(),
                  NequiPulso(
                    activo: resaltados.contains('ojo'),
                    radio: 20,
                    escala: 1.25,
                    child: GestureDetector(
                      onTap: () => onAccion('ojo'),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          saldoVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  saldoVisible ? formatoPesos(saldo) : '\$ • • • • • •',
                  key: ValueKey(saldoVisible),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              const Text('Plata de práctica', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boton(String id, String texto, IconData icono) {
    final tocado = tocados.contains(id);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            NequiPulso(
              activo: resaltados.contains(id),
              radio: 18,
              escala: 1.15,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                elevation: 1.5,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onAccion(id),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Icon(icono, color: NequiColores.magenta, size: 26),
                  ),
                ),
              ),
            ),
            if (tocado)
              const Positioned(
                right: -4,
                top: -4,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: NequiColores.mnvVerde,
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(texto,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: NequiColores.textoOscuro)),
      ],
    );
  }

  Widget _filaAccion(String id, String texto, IconData icono) {
    return NequiPulso(
      activo: resaltados.contains(id),
      radio: 16,
      escala: 1.04,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onAccion(id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icono, color: NequiColores.magenta, size: 22),
                const SizedBox(width: 12),
                Text(texto,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: NequiColores.textoSuave),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Burbuja oscura que explica algo dentro del celular
class NequiBurbuja extends StatelessWidget {
  final String texto;
  const NequiBurbuja({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NequiColores.textoOscuro,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_rounded, color: NequiColores.mnvAmarillo, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(texto,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35)),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// PANTALLA: MOVIMIENTOS
// ------------------------------------------------------------

class NequiMovimientos extends StatelessWidget {
  final Set<String> resaltados;
  final ValueChanged<String> onAccion;
  final List<NequiMovimiento> movimientos;
  const NequiMovimientos({
    super.key,
    required this.resaltados,
    required this.onAccion,
    this.movimientos = movimientosPractica,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NequiColores.fondoApp,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 40, 16, 8),
            child: Row(
              children: [
                NequiPulso(
                  activo: resaltados.contains('atras'),
                  radio: 22,
                  escala: 1.2,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onAccion('atras'),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_rounded, color: NequiColores.textoOscuro),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Movimientos',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: NequiColores.textoOscuro)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: movimientos.map(_fila).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(NequiMovimiento m) {
    final entra = m.valor > 0;
    final color = entra ? NequiColores.mnvVerde : NequiColores.mnvRojo;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(m.icono, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.descripcion,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: NequiColores.textoOscuro)),
                Text(m.fecha, style: const TextStyle(fontSize: 11, color: NequiColores.textoSuave)),
              ],
            ),
          ),
          Text(
            entra ? '+ ${formatoPesos(m.valor)}' : formatoPesos(m.valor),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// PIEZAS DE LA LECCION (fuera del celular), estilo MNV
// ------------------------------------------------------------

class LeccionProgreso extends StatelessWidget {
  final int paso;
  final int total;
  const LeccionProgreso({super.key, required this.paso, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paso ${paso + 1} de $total',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: NequiColores.textoSuave)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (paso + 1) / total,
            minHeight: 8,
            backgroundColor: NequiColores.borde,
            valueColor: const AlwaysStoppedAnimation(NequiColores.mnvMorado),
          ),
        ),
      ],
    );
  }
}

class CajaInstruccion extends StatelessWidget {
  final String titulo;
  final String instruccion;
  const CajaInstruccion({super.key, required this.titulo, required this.instruccion});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(titulo),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NequiColores.mnvMorado,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: NequiColores.mnvMorado.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(instruccion, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35)),
          ],
        ),
      ),
    );
  }
}

// Guia suave cuando toca algo que no era
class MensajeGuia extends StatelessWidget {
  final String texto;
  const MensajeGuia({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NequiColores.mnvAmarillo.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NequiColores.mnvAmarillo, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.touch_app_rounded, color: NequiColores.mnvAmarillo, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto,
                style: const TextStyle(color: NequiColores.textoConsejo, fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// Cajita amarilla de consejo calido
class ConsejoCalido extends StatelessWidget {
  final String texto;
  const ConsejoCalido({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NequiColores.mnvAmarillo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NequiColores.mnvAmarillo.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: NequiColores.mnvAmarillo, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto,
                style: const TextStyle(color: NequiColores.textoConsejo, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// Boton inferior: verde si cumplio, gris con ayuda si no
class BotonLeccion extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;
  const BotonLeccion({super.key, required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: activo ? NequiColores.mnvVerde : const Color(0xFFE4E1F2),
        borderRadius: BorderRadius.circular(18),
        boxShadow: activo
            ? [BoxShadow(color: NequiColores.mnvVerde.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: activo ? onTap : null,
          child: Center(
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: activo ? Colors.white : const Color(0xFF555577),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}