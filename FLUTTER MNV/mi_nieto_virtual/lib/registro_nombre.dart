import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_principal.dart';
import 'services/api_service.dart'; // nuevo

class RegistroNombreScreen extends StatefulWidget {
  const RegistroNombreScreen({super.key});

  @override
  State<RegistroNombreScreen> createState() => _RegistroNombreScreenState();
}

class _RegistroNombreScreenState extends State<RegistroNombreScreen> {
  final TextEditingController _nombreController = TextEditingController();
  bool _cargando = false; //  para mostrar loading mientras llama al backend

  Future<void> _guardarNombre() async {
    if (_nombreController.text.trim().isEmpty) return;

    setState(() => _cargando = true);

    final prefs = await SharedPreferences.getInstance();
    final nombre = _nombreController.text.trim();
    await prefs.setString('nombre_usuario', nombre);

    // Crea el usuario en el backend y guarda su ID
    final nivel = prefs.getString('nivel_usuario') ?? 'basico';
    final userId = await ApiService.crearUsuario(nombre, nivel);
    if (userId != null) {
      await prefs.setString('usuario_id', userId);
      print('✅ Usuario creado con ID: $userId');
    } else {
      print('⚠️ Sin conexión, modo offline');
    }

    if (!mounted) return;
    setState(() => _cargando = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MenuPrincipalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_pin, size: 100, color: Color(0xFF6200EE)),
              const SizedBox(height: 20),
              const Text(
                "¡Bienvenido! ¿Cómo te llamas?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: "Tu nombre o apodo",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              // Muestra loading o el botón según estado
              _cargando
                  ? const CircularProgressIndicator(
                      color: Color(0xFF6200EE),
                    )
                  : ElevatedButton(
                      onPressed: _guardarNombre,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE),
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Continuar",
                          style:
                              TextStyle(color: Colors.white, fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}