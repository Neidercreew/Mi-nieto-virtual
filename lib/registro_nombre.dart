import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_principal.dart';
import 'services/api_service.dart';

class RegistroNombreScreen extends StatefulWidget {
  const RegistroNombreScreen({super.key});

  @override
  State<RegistroNombreScreen> createState() => _RegistroNombreScreenState();
}

class _RegistroNombreScreenState extends State<RegistroNombreScreen> {
  // ─────────────────────────────────────────────────────────
  // PASOS DEL REGISTRO
  // 0 = nombre | 1 = telefono | 2 = crear PIN | 3 = confirmar PIN
  // ─────────────────────────────────────────────────────────
  int _paso = 0;

  final TextEditingController _nombreController = TextEditingController();
  String _telefono = '';
  String _pin = '';
  String _pinConfirmacion = '';

  bool _cargando = false;
  String? _error;

  // Avanza al siguiente paso del registro
  void _siguientePaso() {
    setState(() {
      _error = null;
      _paso++;
    });
  }

  void _pasoAnterior() {
    setState(() {
      _error = null;
      if (_paso == 3) _pinConfirmacion = '';
      if (_paso == 2) _pin = '';
      _paso--;
    });
  }

  // Cuando tocan un numero del teclado
  void _tocarNumero(String n) {
    setState(() {
      _error = null;
      if (_paso == 1) {
        if (_telefono.length < 10) _telefono += n;
      } else if (_paso == 2) {
        if (_pin.length < 4) {
          _pin += n;
          // Al completar 4 digitos, pasa a confirmar
          if (_pin.length == 4) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted) _siguientePaso();
            });
          }
        }
      } else if (_paso == 3) {
        if (_pinConfirmacion.length < 4) {
          _pinConfirmacion += n;
          if (_pinConfirmacion.length == 4) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted) _verificarPines();
            });
          }
        }
      }
    });
  }

  void _borrarNumero() {
    setState(() {
      _error = null;
      if (_paso == 1 && _telefono.isNotEmpty) {
        _telefono = _telefono.substring(0, _telefono.length - 1);
      } else if (_paso == 2 && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      } else if (_paso == 3 && _pinConfirmacion.isNotEmpty) {
        _pinConfirmacion =
            _pinConfirmacion.substring(0, _pinConfirmacion.length - 1);
      }
    });
  }

  // Revisa que los dos PIN coincidan
  void _verificarPines() {
    if (_pin == _pinConfirmacion) {
      _crearCuenta();
    } else {
      setState(() {
        _error = 'Los números no coinciden. Intenta de nuevo.';
        _pinConfirmacion = '';
      });
    }
  }

  // Crea la cuenta en el backend
  Future<void> _crearCuenta() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final nombre = _nombreController.text.trim();
    final nivel = prefs.getString('nivel_usuario') ?? 'basico';

    final resultado =
        await ApiService.crearUsuario(nombre, nivel, _telefono, _pin);

    if (!mounted) return;

    if (resultado['ok'] == true) {
      // Guardamos todo localmente
      await prefs.setString('nombre_usuario', nombre);
      await prefs.setString('usuario_id', resultado['usuarioId']);
      await prefs.setString('telefono_usuario', _telefono);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuPrincipalScreen()),
      );
    } else {
      setState(() {
        _cargando = false;
        _error = resultado['mensaje'] ?? 'Algo salió mal';
        // Si el telefono ya existe, lo devolvemos a ese paso
        if (_error!.contains('número')) {
          _paso = 1;
          _pin = '';
          _pinConfirmacion = '';
        } else {
          _pinConfirmacion = '';
          _paso = 2;
          _pin = '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EEFF),
        elevation: 0,
        leading: _paso > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF6B4EFF)),
                onPressed: _cargando ? null : _pasoAnterior,
              )
            : null,
        centerTitle: true,
        title: const Text('Crear tu cuenta',
            style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: _cargando ? _buildCargando() : _buildContenido(),
      ),
    );
  }

  Widget _buildCargando() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF6B4EFF)),
          SizedBox(height: 20),
          Text('Creando tu cuenta...',
              style: TextStyle(
                  color: Color(0xFF555577),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    return Column(
      children: [
        _buildProgreso(),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildPasoActual(),
                if (_error != null) _buildError(),
              ],
            ),
          ),
        ),
        // Teclado numerico (solo en pasos que lo necesitan)
        if (_paso > 0) _buildTecladoNumerico(),
        // Boton continuar (solo en nombre y telefono)
        if (_paso == 0 || _paso == 1) _buildBotonContinuar(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProgreso() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(4, (i) {
          final activo = i <= _paso;
          return Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: activo
                    ? const Color(0xFF6B4EFF)
                    : const Color(0xFFDED8FF),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPasoActual() {
    switch (_paso) {
      case 0:
        return _buildPasoNombre();
      case 1:
        return _buildPasoTelefono();
      case 2:
        return _buildPasoPin(
          titulo: 'Crea tu clave secreta 🔐',
          subtitulo: 'Elige 4 números que recuerdes fácil',
          valor: _pin,
          consejo:
              'Como los números de tu cajero.\nPuedes anotarlos en un papel y guardarlo en un lugar seguro.',
        );
      case 3:
        return _buildPasoPin(
          titulo: 'Repite tu clave 🔐',
          subtitulo: 'Escribe otra vez los mismos 4 números',
          valor: _pinConfirmacion,
          consejo: 'Así nos aseguramos de que la recuerdes bien.',
        );
      default:
        return const SizedBox();
    }
  }

  // ── PASO 0: NOMBRE ────────────────────────────────────────
  Widget _buildPasoNombre() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6B4EFF).withOpacity(0.12),
              border: Border.all(
                  color: const Color(0xFF6B4EFF).withOpacity(0.3), width: 3),
            ),
            child: const Icon(Icons.person_rounded,
                size: 60, color: Color(0xFF6B4EFF)),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Bienvenido! 👋\n¿Cómo te llamas?',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3),
          ),
          const SizedBox(height: 10),
          const Text(
            'Así sabremos cómo saludarte',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF777799), fontSize: 15),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06), blurRadius: 10)
              ],
            ),
            child: TextField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Tu nombre',
                hintStyle: TextStyle(color: Color(0xFFAAAACC)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  // ── PASO 1: TELEFONO ──────────────────────────────────────
  Widget _buildPasoTelefono() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF059669).withOpacity(0.12),
              border: Border.all(
                  color: const Color(0xFF059669).withOpacity(0.3), width: 3),
            ),
            child: const Icon(Icons.phone_rounded,
                size: 46, color: Color(0xFF059669)),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tu número de celular 📱',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Con este número podrás entrar\ndesde cualquier celular',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF777799), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          // El numero que va escribiendo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: _telefono.isEmpty
                      ? const Color(0xFFDED8FF)
                      : const Color(0xFF6B4EFF),
                  width: 2),
            ),
            child: Center(
              child: Text(
                _telefono.isEmpty ? 'Toca los números 👇' : _formatoTel(_telefono),
                style: TextStyle(
                  color: _telefono.isEmpty
                      ? const Color(0xFFAAAACC)
                      : const Color(0xFF1A1A2E),
                  fontSize: _telefono.isEmpty ? 16 : 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: _telefono.isEmpty ? 0 : 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildConsejo(
              'Es el número de tu celular, el que le das a tu familia.'),
        ],
      ),
    );
  }

  // ── PASOS 2 y 3: EL PIN ───────────────────────────────────
  Widget _buildPasoPin({
    required String titulo,
    required String subtitulo,
    required String valor,
    required String consejo,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFB300).withOpacity(0.15),
              border: Border.all(
                  color: const Color(0xFFFFB300).withOpacity(0.4), width: 3),
            ),
            child: const Icon(Icons.lock_rounded,
                size: 46, color: Color(0xFFFFB300)),
          ),
          const SizedBox(height: 18),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF777799), fontSize: 15),
          ),
          const SizedBox(height: 24),
          // Los 4 puntitos del PIN
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final lleno = i < valor.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: lleno ? 26 : 22,
                height: lleno ? 26 : 22,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lleno
                      ? const Color(0xFF6B4EFF)
                      : Colors.transparent,
                  border: Border.all(
                      color: lleno
                          ? const Color(0xFF6B4EFF)
                          : const Color(0xFFCCC5EE),
                      width: 2.5),
                  boxShadow: lleno
                      ? [
                          BoxShadow(
                              color: const Color(0xFF6B4EFF).withOpacity(0.4),
                              blurRadius: 8)
                        ]
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          _buildConsejo(consejo),
        ],
      ),
    );
  }

  // Cajita de consejo cálido
  Widget _buildConsejo(String texto) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFFFB300).withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded,
              color: Color(0xFFFFB300), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                  color: Color(0xFF854F0B), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE53E3E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE53E3E), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Color(0xFFE53E3E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!,
                style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── TECLADO NUMERICO GRANDE ───────────────────────────────
  Widget _buildTecladoNumerico() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          _filaNumeros(['1', '2', '3']),
          _filaNumeros(['4', '5', '6']),
          _filaNumeros(['7', '8', '9']),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 70),
              _teclaNumero('0'),
              _teclaBorrar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filaNumeros(List<String> nums) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: nums.map((n) => _teclaNumero(n)).toList(),
    );
  }

  Widget _teclaNumero(String n) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _tocarNumero(n),
          child: Container(
            width: 70,
            height: 58,
            alignment: Alignment.center,
            child: Text(n,
                style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 26,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _teclaBorrar() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Material(
        color: const Color(0xFFDED8FF),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _borrarNumero,
          child: Container(
            width: 70,
            height: 58,
            alignment: Alignment.center,
            child: const Icon(Icons.backspace_rounded,
                color: Color(0xFF6B4EFF), size: 24),
          ),
        ),
      ),
    );
  }

  // ── BOTON CONTINUAR ───────────────────────────────────────
  Widget _buildBotonContinuar() {
    bool habilitado;
    if (_paso == 0) {
      habilitado = _nombreController.text.trim().isNotEmpty;
    } else {
      habilitado = _telefono.length == 10;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      child: GestureDetector(
        onTap: habilitado ? _siguientePaso : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color: habilitado
                ? const Color(0xFF6B4EFF)
                : const Color(0xFFBBBBCC),
            borderRadius: BorderRadius.circular(18),
            boxShadow: habilitado
                ? [
                    BoxShadow(
                        color: const Color(0xFF6B4EFF).withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              _paso == 0
                  ? 'Continuar →'
                  : (_telefono.length == 10
                      ? 'Continuar →'
                      : 'Faltan ${10 - _telefono.length} números'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  String _formatoTel(String n) {
    if (n.length <= 3) return n;
    if (n.length <= 6) return '${n.substring(0, 3)} ${n.substring(3)}';
    return '${n.substring(0, 3)} ${n.substring(3, 6)} ${n.substring(6)}';
  }
}