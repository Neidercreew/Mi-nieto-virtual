import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_principal.dart';
import 'services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0 = telefono | 1 = PIN
  int _paso = 0;

  String _telefono = '';
  String _pin = '';

  bool _cargando = false;
  String? _error;

  void _siguientePaso() {
    setState(() {
      _error = null;
      _paso = 1;
    });
  }

  void _pasoAnterior() {
    setState(() {
      _error = null;
      _pin = '';
      _paso = 0;
    });
  }

  void _tocarNumero(String n) {
    setState(() {
      _error = null;
      if (_paso == 0) {
        if (_telefono.length < 10) _telefono += n;
      } else {
        if (_pin.length < 4) {
          _pin += n;
          if (_pin.length == 4) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted) _entrar();
            });
          }
        }
      }
    });
  }

  void _borrarNumero() {
    setState(() {
      _error = null;
      if (_paso == 0 && _telefono.isNotEmpty) {
        _telefono = _telefono.substring(0, _telefono.length - 1);
      } else if (_paso == 1 && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  // Intenta entrar con telefono + PIN
  Future<void> _entrar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final resultado = await ApiService.login(_telefono, _pin);

    if (!mounted) return;

    if (resultado['ok'] == true) {
      // Guardamos la sesion localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuario_id', resultado['usuarioId']);
      await prefs.setString('nombre_usuario', resultado['nombre'] ?? '');
      await prefs.setString('nivel_usuario', resultado['nivel'] ?? 'basico');
      await prefs.setString('telefono_usuario', _telefono);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuPrincipalScreen()),
      );
    } else {
      setState(() {
        _cargando = false;
        _error = resultado['mensaje'] ?? 'No pudimos entrar';
        _pin = '';
        // Si el numero no existe, lo devolvemos al paso del telefono
        if (_error!.contains('cuenta con ese número')) {
          _paso = 0;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF6B4EFF)),
          onPressed: _cargando
              ? null
              : () {
                  if (_paso == 1) {
                    _pasoAnterior();
                  } else {
                    Navigator.pop(context);
                  }
                },
        ),
        centerTitle: true,
        title: const Text('Entrar a tu cuenta',
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
          Text('Buscando tu cuenta...',
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
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _paso == 0 ? _buildPasoTelefono() : _buildPasoPin(),
                if (_error != null) _buildError(),
              ],
            ),
          ),
        ),
        _buildTecladoNumerico(),
        if (_paso == 0) _buildBotonContinuar(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── PASO 0: TELEFONO ──────────────────────────────────────
  Widget _buildPasoTelefono() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 16),
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
            '¡Qué bueno verte! 👋',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Escribe el número de celular\ncon el que te registraste',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Color(0xFF777799), fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
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
                _telefono.isEmpty
                    ? 'Toca los números 👇'
                    : _formatoTel(_telefono),
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
              'Con tu número y tu clave recuperas todo tu avance, aunque sea otro celular.'),
        ],
      ),
    );
  }

  // ── PASO 1: PIN ───────────────────────────────────────────
  Widget _buildPasoPin() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 16),
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
          const Text(
            'Tu clave secreta 🔐',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Escribe tus 4 números',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF777799), fontSize: 15),
          ),
          const SizedBox(height: 24),
          // Los 4 puntitos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final lleno = i < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: lleno ? 26 : 22,
                height: lleno ? 26 : 22,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lleno ? const Color(0xFF6B4EFF) : Colors.transparent,
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
          _buildConsejo(
              'Son los mismos 4 números que elegiste cuando creaste tu cuenta.'),
        ],
      ),
    );
  }

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

  Widget _buildBotonContinuar() {
    final habilitado = _telefono.length == 10;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      child: GestureDetector(
        onTap: habilitado ? _siguientePaso : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color:
                habilitado ? const Color(0xFF6B4EFF) : const Color(0xFFBBBBCC),
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
              habilitado
                  ? 'Continuar →'
                  : 'Faltan ${10 - _telefono.length} números',
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