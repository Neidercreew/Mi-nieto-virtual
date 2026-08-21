import 'package:flutter/material.dart';

class ProximamenteScreen extends StatelessWidget {
  final String titulo;
  const ProximamenteScreen({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EFFE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF534AB7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(titulo,
            style: const TextStyle(color: Color(0xFF3C3489), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🚀', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('¡Próximamente!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3C3489))),
            SizedBox(height: 8),
            Text('Esta lección estará disponible pronto',
                style: TextStyle(fontSize: 14, color: Color(0xFF7F77DD))),
          ],
        ),
      ),
    );
  }
}