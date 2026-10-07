import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/mnv_leccion.dart';
import 'widgets/sim_whatsapp.dart';

const String _leccionId = 'whatsapp_fotos';

class TutorialWhatsappFotosScreen extends StatefulWidget {
  final int pasoInicial;
  const TutorialWhatsappFotosScreen({super.key, this.pasoInicial = 0});

  @override
  State<TutorialWhatsappFotosScreen> createState() =>
      _TutorialWhatsappFotosScreenState();
}

// Una foto de mentiras: un emoji grande sobre un degradado
class _Foto {
  final String clave;
  final String emoji;
  final String nombre;
  final Color arriba;
  final Color abajo;
  const _Foto(this.clave, this.emoji, this.nombre, this.arriba, this.abajo);
}

class _TutorialWhatsappFotosScreenState
    extends State<TutorialWhatsappFotosScreen> {
  int _pasoActual = 0;

  // pantalla: chat | galeria | vista_previa | visor
  String _pantalla = 'chat';
  bool _menuAdjuntar = false;
  bool _tecladoAbierto = false;
  String _comentario = '';
  bool _fotoEnviada = false;
  double _subida = 0;
  bool _subidaLista = false;
  bool _respuestaLucia = false;
  bool _vioFotoGrande = false;
  bool _volvioAlChat = false;
  Timer? _timerSubida;
  Timer? _timerRespuesta;

  bool _objetivoCumplido = false;
  String? _mensajeGuia;
  late ConfettiController _confetti;

  static const List<_Foto> _galeria = [
    _Foto('jardin', '🌻', 'tu jardín', Color(0xFF7DD3FC), Color(0xFF86EFAC)),
    _Foto('perro', '🐕', 'el perro', Color(0xFFFDE68A), Color(0xFFFCA5A5)),
    _Foto('sopa', '🍲', 'el almuerzo', Color(0xFFFED7AA), Color(0xFFFCA5A5)),
    _Foto('iglesia', '⛪', 'la iglesia', Color(0xFFBAE6FD), Color(0xFFDDD6FE)),
    _Foto('atardecer', '🌅', 'el atardecer', Color(0xFFFDBA74), Color(0xFFC084FC)),
    _Foto('familia', '👨‍👩‍👧', 'la familia', Color(0xFFDDD6FE), Color(0xFFBFDBFE)),
    _Foto('cafe', '☕', 'el cafecito', Color(0xFFE7E5E4), Color(0xFFFDE68A)),
    _Foto('montana', '🏞️', 'el paseo', Color(0xFFA7F3D0), Color(0xFF7DD3FC)),
    _Foto('gato', '🐈', 'el gato', Color(0xFFFBCFE8), Color(0xFFFDE68A)),
  ];

  static const _Foto _fotoLucia =
      _Foto('torta', '🎂', 'la torta', Color(0xFFFBCFE8), Color(0xFFDDD6FE));

  final List<Map<String, dynamic>> _pasos = [
    {
      'tipo': 'intro',
      'titulo': 'Enviar y ver\nfotos 📸',
      'instruccion':
          'Lucía quiere ver cómo está tu jardín.\n\nHoy le mandas una foto que ya tienes guardada, con un mensajito, y aprendes a ver en grande las fotos que te mandan.',
      'icono': Icons.photo_rounded,
      'colorIcono': MnvColores.verde,
    },
    {
      'tipo': 'sim',
      'titulo': 'Toca el clip 📎',
      'instruccion':
          'Dentro de la cajita de escribir, a la derecha, hay un clip como el de los papeles.\n\nEse clip sirve para "pegar" cosas al mensaje. Tócalo.',
      'objetivo': 'menu_adjuntar',
      'ayuda': 'Toca el clip de la cajita',
    },
    {
      'tipo': 'sim',
      'titulo': 'Elige Galería 🖼️',
      'instruccion':
          'Salieron varias opciones. La foto del jardín ya está guardada en tu celular, en la Galería.\n\nToca Galería.',
      'objetivo': 'galeria',
      'ayuda': 'Toca el círculo que dice Galería',
    },
    {
      'tipo': 'sim',
      'titulo': 'Busca la foto 🌻',
      'instruccion':
          'Estas son tus fotos. Busca la del jardín, la del girasol, y tócala.',
      'objetivo': 'foto_elegida',
      'ayuda': 'Toca la foto del girasol',
    },
    {
      'tipo': 'sim',
      'titulo': 'Agrega un mensajito ✍️',
      'instruccion':
          'Antes de enviar puedes escribir algo abajo de la foto.\n\nToca "Añade un comentario" y elige la frase que te sugiere el teclado.',
      'objetivo': 'comentario',
      'ayuda': 'Toca la cajita y elige una frase',
    },
    {
      'tipo': 'sim',
      'titulo': '¡Envíala! ➤',
      'instruccion':
          'Toca la flecha verde.\n\nVerás un circulito mientras la foto se sube. Cuando salen los chulitos, ya le llegó.',
      'objetivo': 'foto_enviada',
      'ayuda': 'Toca la flecha verde y espera',
    },
    {
      'tipo': 'sim',
      'titulo': 'Lucía te mandó una foto 🎂',
      'instruccion':
          'Las fotos en el chat se ven chiquitas.\n\nToca la foto de Lucía para verla en grande.',
      'objetivo': 'foto_abierta',
      'ayuda': 'Toca la foto que mandó Lucía',
    },
    {
      'tipo': 'sim',
      'titulo': 'Vuelve al chat ⬅️',
      'instruccion':
          'La foto se ve en toda la pantalla, sobre fondo negro.\n\nPara regresar a la conversación toca la flecha de arriba a la izquierda.',
      'objetivo': 'volver_chat',
      'ayuda': 'Toca la flecha ← de arriba',
    },
    {
      'tipo': 'tip',
      'titulo': '💡 ¿Dónde quedan las fotos?',
      'instruccion':
          'Las fotos que te mandan normalmente se guardan solas en tu Galería, en un álbum que se llama WhatsApp.\n\nSi te pesa el celular, ahí puedes borrar las que ya no quieras.',
      'icono': Icons.photo_library_rounded,
      'colorIcono': MnvColores.amarillo,
    },
    {
      'tipo': 'accion_real',
      'titulo': 'Ahora en tu celular 📱',
      'instruccion':
          'Mándale a alguien de tu familia una foto que te guste, con un mensajito.\n\nY cuando te manden una, ábrela en grande y vuelve al chat.',
      'icono': Icons.smartphone_rounded,
      'colorIcono': MnvColores.verde,
    },
    {
      'tipo': 'celebracion',
      'titulo': '¡Ya compartes tus fotos! 🏆',
      'instruccion':
          'Usas el clip, eliges de la galería, pones comentario, envías y ves fotos en grande.\n\nAhora tu familia va a ver tu mundo. 👏',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = widget.pasoInicial.clamp(0, _pasos.length - 1);
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    _prepararPaso();
    // Si se retoma justo en la celebracion, tambien hay confeti
    if (_pasos[_pasoActual]['tipo'] == 'celebracion') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confetti.play();
      });
    }
  }

  @override
  void dispose() {
    _timerSubida?.cancel();
    _timerRespuesta?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _prepararPaso() {
    final paso = _pasos[_pasoActual];
    _timerSubida?.cancel();
    _timerRespuesta?.cancel();
    _mensajeGuia = null;
    _objetivoCumplido = paso['objetivo'] == null;

    _pantalla = 'chat';
    _menuAdjuntar = false;
    _tecladoAbierto = false;
    _comentario = '';
    _vioFotoGrande = false;
    _volvioAlChat = false;

    // Lo que ya quedo hecho en pasos anteriores
    _fotoEnviada = _pasoActual >= 6;
    _subida = _fotoEnviada ? 1 : 0;
    _subidaLista = _fotoEnviada;
    _respuestaLucia = _pasoActual >= 6;

    switch (_pasoActual) {
      case 2:
        _menuAdjuntar = true;
        break;
      case 3:
        _pantalla = 'galeria';
        break;
      case 4:
        _pantalla = 'vista_previa';
        break;
      case 5:
        _pantalla = 'vista_previa';
        _comentario = 'Mira mi jardín 🌻';
        break;
      case 7:
        _pantalla = 'visor';
        break;
    }
  }

  void _revisarObjetivo() {
    final objetivo = _pasos[_pasoActual]['objetivo'];
    if (objetivo == null) return;
    bool cumple = false;
    switch (objetivo) {
      case 'menu_adjuntar':
        cumple = _menuAdjuntar;
        break;
      case 'galeria':
        cumple = _pantalla == 'galeria';
        break;
      case 'foto_elegida':
        cumple = _pantalla == 'vista_previa';
        break;
      case 'comentario':
        cumple = _comentario.isNotEmpty;
        break;
      case 'foto_enviada':
        cumple = _subidaLista;
        break;
      case 'foto_abierta':
        cumple = _vioFotoGrande;
        break;
      case 'volver_chat':
        cumple = _volvioAlChat;
        break;
    }
    if (cumple) _objetivoCumplido = true;
  }

  // ─────────────────────────────────────────────
  // CEREBRO DEL SIMULADOR
  // ─────────────────────────────────────────────
  void _tocarEnSimulador(String accion, {String valor = ''}) {
    setState(() {
      _mensajeGuia = null;

      switch (accion) {
        case 'clip':
          if (_pasoActual >= 6) {
            _mensajeGuia = 'Ahora miramos la foto de Lucía';
          } else {
            _menuAdjuntar = !_menuAdjuntar;
          }
          break;
        case 'cerrar_menu':
          _menuAdjuntar = false;
          break;
        case 'adjuntar':
          if (valor == 'galeria') {
            _menuAdjuntar = false;
            _pantalla = 'galeria';
          } else if (valor == 'camara') {
            _mensajeGuia = 'La cámara es para tomar una foto nueva. La del jardín ya está en la Galería';
          } else {
            _mensajeGuia = 'Eso sirve para otras cosas. Hoy buscamos Galería';
          }
          break;

        case 'foto':
          if (valor == 'jardin') {
            _pantalla = 'vista_previa';
          } else {
            final f = _galeria.firstWhere((g) => g.clave == valor,
                orElse: () => _galeria.first);
            _mensajeGuia = 'Esa es la foto de ${f.nombre}. Busca la del girasol 🌻';
          }
          break;
        case 'cerrar_galeria':
          _pantalla = 'chat';
          break;

        case 'caja_comentario':
          _tecladoAbierto = true;
          break;
        case 'sugerencia':
          _comentario = valor;
          break;
        case 'letra':
          _mensajeGuia = 'Puedes escribir, pero es más fácil tocar una frase de arriba';
          break;

        case 'enviar_foto':
          if (_pasoActual == 4) {
            _mensajeGuia = _comentario.isEmpty
                ? 'Primero toca la cajita y elige una frase'
                : '¡Listo el comentario! Toca el botón verde de abajo para seguir';
            break;
          }
          if (_pasoActual != 5) break;
          _pantalla = 'chat';
          _tecladoAbierto = false;
          _fotoEnviada = true;
          _subida = 0;
          _subirFoto();
          break;
        case 'cancelar_previa':
          _pantalla = 'galeria';
          break;

        case 'foto_lucia':
          if (_pasoActual >= 6) {
            _pantalla = 'visor';
            _vioFotoGrande = true;
          }
          break;
        case 'foto_mia':
          _mensajeGuia = _pasoActual == 6
              ? 'Esa es la tuya. Toca la que mandó Lucía, la de la torta'
              : 'Esa es tu foto, ya enviada';
          break;
        case 'atras_visor':
          _pantalla = 'chat';
          _volvioAlChat = true;
          break;
        case 'tocar_visor':
          _mensajeGuia = 'Para volver toca la flecha de arriba a la izquierda';
          break;

        case 'otro':
          _mensajeGuia = 'Sigue la instrucción de la cajita morada';
          break;
      }

      _revisarObjetivo();
    });
  }

  // Barrita de subida y despues la respuesta de Lucia
  void _subirFoto() {
    _timerSubida?.cancel();
    _timerSubida = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _subida += 0.05;
        if (_subida >= 1) {
          _subida = 1;
          _subidaLista = true;
          t.cancel();
          // Lucia lee y contesta un momento despues
          _timerRespuesta?.cancel();
          _timerRespuesta = Timer(const Duration(milliseconds: 1600), () {
            if (mounted) setState(() => _respuestaLucia = true);
          });
        }
        _revisarObjetivo();
      });
    });
  }

  // Evita que un doble toque en el boton salte un paso o cierre dos pantallas
  bool _avanzando = false;

  Future<void> _avanzar() async {
    if (_avanzando) return;
    _avanzando = true;
    try {
      await _avanzarPaso();
    } finally {
      // Si la leccion ya se cerro el boton queda bloqueado
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        _avanzando = false;
      }
    }
  }

  Future<void> _avanzarPaso() async {
    if (!_objetivoCumplido) return;
    _timerSubida?.cancel();
    final esUltimo = _pasoActual == _pasos.length - 1;
    await mnvGuardarPaso(_leccionId, _pasoActual + 1, completada: esUltimo);

    if (esUltimo) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.pop(context);
      return;
    }
    if (!mounted) return;
    setState(() {
      _pasoActual++;
      _prepararPaso();
    });
    if (_pasos[_pasoActual]['tipo'] == 'celebracion') _confetti.play();
  }

  @override
  Widget build(BuildContext context) {
    return MnvLeccionLayout(
      tituloLeccion: 'Enviar y ver fotos',
      pasoActual: _pasoActual,
      totalPasos: _pasos.length,
      paso: _pasos[_pasoActual],
      construirSimulador: _buildSimulador,
      mensajeGuia: _mensajeGuia,
      objetivoCumplido: _objetivoCumplido,
      onAvanzar: _avanzar,
      confetti: _confetti,
      emojiTrofeo: '📸',
      textoTrofeo: '¡Ya compartes tus fotos!',
    );
  }

  // ═════════════════════════════════════════════
  // SIMULADOR
  // ═════════════════════════════════════════════
  String _ubicacion() {
    switch (_pantalla) {
      case 'galeria':
        return 'GALERÍA · ELEGIR FOTO';
      case 'vista_previa':
        return 'FOTO LISTA PARA ENVIAR';
      case 'visor':
        return 'FOTO EN GRANDE';
      default:
        return _menuAdjuntar ? 'CHAT CON LUCÍA · ADJUNTAR' : 'CHAT CON LUCÍA';
    }
  }

  Widget _buildSimulador() {
    return MnvTelefonoPractica(
      ubicacion: _ubicacion(),
      clavePantalla: _pantalla,
      pantalla: _buildPantalla(),
      encima: [
        if (_pantalla == 'chat' && _menuAdjuntar) _buildMenuAdjuntar(),
      ],
    );
  }

  Widget _buildPantalla() {
    switch (_pantalla) {
      case 'galeria':
        return _buildGaleria();
      case 'vista_previa':
        return _buildVistaPrevia();
      case 'visor':
        return _buildVisor();
      default:
        return _buildChat();
    }
  }

  Widget _foto(_Foto f, double ancho, double alto, {double radio = 10}) {
    return Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radio),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [f.arriba, f.abajo],
        ),
      ),
      child: Center(
        child: Text(f.emoji, style: TextStyle(fontSize: alto * 0.42)),
      ),
    );
  }

  Widget _buildChat() {
    final burbujas = <Widget>[
      const WaSeparadorFecha(texto: 'HOY'),
      const WaBurbuja(
          texto: 'Abue, ¿cómo está tu jardín? Quiero ver 🌱',
          mia: false,
          hora: '3:10 p. m.'),
    ];
    if (_fotoEnviada) {
      burbujas.add(WaBurbuja(
        texto: 'Mira mi jardín 🌻',
        mia: true,
        hora: '3:14 p. m.',
        estado: _subidaLista ? (_respuestaLucia ? 'leido' : 'entregado') : 'reloj',
        onTap: () => _tocarEnSimulador('foto_mia'),
        contenido: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _foto(_galeria.first, 160, 110),
              if (!_subidaLista)
                Container(
                  width: 160,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(
                        value: _subida,
                        strokeWidth: 4,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ));
    }
    if (_respuestaLucia) {
      burbujas.add(const WaBurbuja(
          texto: '¡Qué lindo, abue! 😍 Mira lo que hice yo',
          mia: false,
          hora: '3:16 p. m.'));
      burbujas.add(WaBurbuja(
        texto: '',
        mia: false,
        hora: '3:16 p. m.',
        resaltada: _pasoActual == 6,
        onTap: () => _tocarEnSimulador('foto_lucia'),
        contenido: _foto(_fotoLucia, 160, 110),
      ));
    }

    return Container(
      color: WaColores.fondoChat,
      child: Column(
        children: [
          WaCabeceraChat(
            nombre: 'Lucía (nieta)',
            inicial: 'L',
            color: MnvColores.morado,
            onAtras: () => _tocarEnSimulador('otro'),
          ),
          Expanded(
            child: ListView(
              reverse: true,
              padding: const EdgeInsets.only(bottom: 4),
              children: burbujas.reversed.toList(),
            ),
          ),
          WaCajaEscribir(
            texto: '',
            enfocada: false,
            resaltarClip: _pasoActual == 1 && !_menuAdjuntar,
            onCaja: () => _tocarEnSimulador('otro'),
            onEmoji: () => _tocarEnSimulador('otro'),
            onClip: () => _tocarEnSimulador('clip'),
            botonDerecho: WaBotonRedondo(
              icono: Icons.mic_rounded,
              onTap: () => _tocarEnSimulador('otro'),
            ),
          ),
        ],
      ),
    );
  }

  // Hoja con las opciones del clip
  Widget _buildMenuAdjuntar() {
    final opciones = [
      ['documento', 'Documento', Icons.insert_drive_file_rounded, MnvColores.morado2],
      ['camara', 'Cámara', Icons.photo_camera_rounded, MnvColores.rojo],
      ['galeria', 'Galería', Icons.photo_library_rounded, MnvColores.azul],
      ['audio', 'Audio', Icons.headphones_rounded, const Color(0xFFF97316)],
      ['ubicacion', 'Ubicación', Icons.location_on_rounded, MnvColores.verde],
      ['contacto', 'Contacto', Icons.person_rounded, MnvColores.amarillo],
    ];
    return Positioned.fill(
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _tocarEnSimulador('cerrar_menu'),
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            builder: (_, t, hijo) =>
                Transform.translate(offset: Offset(0, 200 * t), child: hijo),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 62),
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16)
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                runSpacing: 12,
                children: opciones.map((o) {
                  final clave = o[0] as String;
                  final nombre = o[1] as String;
                  final icono = o[2] as IconData;
                  final color = o[3] as Color;
                  return GestureDetector(
                    onTap: () => _tocarEnSimulador('adjuntar', valor: clave),
                    child: SizedBox(
                      width: 76,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MnvResalte(
                            activo: _pasoActual == 2 && clave == 'galeria',
                            circular: true,
                            escala: 1.15,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                              child: Icon(icono, color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(nombre,
                              style: const TextStyle(
                                  color: MnvColores.texto,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaleria() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 48,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: MnvColores.texto, size: 22),
                  onPressed: () => _tocarEnSimulador('cerrar_galeria'),
                ),
                Flexible(child: const Text('Galería',
                    style: TextStyle(
                        color: MnvColores.texto,
                        fontSize: 16,
                        fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Recientes',
                  style: TextStyle(color: MnvColores.suave2, fontSize: 12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _galeria.map((f) {
                return GestureDetector(
                  onTap: () => _tocarEnSimulador('foto', valor: f.clave),
                  child: MnvResalte(
                    activo: _pasoActual == 3 && f.clave == 'jardin',
                    radio: 10,
                    escala: 1.06,
                    child: _foto(f, 80, 80),
                  ),
                );
              }).toList(),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildVistaPrevia() {
    final resaltarCaja = _pasoActual == 4 && !_tecladoAbierto;
    final resaltarEnviar = _pasoActual == 5;
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                  onPressed: () => _tocarEnSimulador('cancelar_previa'),
                ),
                const Spacer(),
                const Icon(Icons.crop_rotate_rounded,
                    color: Colors.white70, size: 20),
                const SizedBox(width: 14),
                const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 10),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: _foto(_galeria.first, 230, _tecladoAbierto ? 120 : 220,
                  radio: 4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tocarEnSimulador('caja_comentario'),
                    child: MnvResalte(
                      activo: resaltarCaja,
                      radio: 22,
                      escala: 1.03,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A40),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                            _comentario.isEmpty
                                ? 'Añade un comentario...'
                                : _comentario,
                            style: TextStyle(
                                color: _comentario.isEmpty
                                    ? Colors.white54
                                    : Colors.white,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                WaBotonRedondo(
                  icono: Icons.send_rounded,
                  resaltado: resaltarEnviar,
                  onTap: () => _tocarEnSimulador('enviar_foto'),
                ),
              ],
            ),
          ),
          if (_tecladoAbierto)
            MnvTecladoLetras(
              onLetra: (_) => _tocarEnSimulador('letra'),
              onBorrar: () => setState(() => _comentario = ''),
              sugerencias: const ['Mira mi jardín 🌻', 'Para ti 💕', '¿Te gusta?'],
              sugerenciaResaltada: _comentario.isEmpty ? 'Mira mi jardín 🌻' : null,
              onSugerencia: (s) => _tocarEnSimulador('sugerencia', valor: s),
            ),
        ],
      ),
    );
  }

  Widget _buildVisor() {
    return GestureDetector(
      onTap: () => _tocarEnSimulador('tocar_visor'),
      child: Container(
        color: Colors.black,
        child: Column(
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _tocarEnSimulador('atras_visor'),
                    child: MnvResalte(
                      activo: _pasoActual == 7,
                      radio: 20,
                      escala: 1.15,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lucía (nieta)',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      Text('Hoy, 3:16 p. m.',
                          style: TextStyle(color: Colors.white60, fontSize: 10.5)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.star_border_rounded,
                      color: Colors.white70, size: 22),
                  const SizedBox(width: 12),
                  const Icon(Icons.share_rounded, color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.7, end: 1),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (_, t, hijo) =>
                      Transform.scale(scale: t, child: hijo),
                  child: _foto(_fotoLucia, 250, 300, radio: 0),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Text('Mira lo que hice yo',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
