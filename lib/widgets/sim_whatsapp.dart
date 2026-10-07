import 'package:flutter/material.dart';
import 'mnv_leccion.dart';

// Piezas del WhatsApp de practica. Es una app de mentiras: no usa el
// logo ni nada de la app real, solo se parece lo suficiente para que
// la habilidad se transfiera al celular de verdad.

class WaColores {
  static const Color verde = MnvColores.verde;
  static const Color verdeOscuro = Color(0xFF065F46);
  static const Color fondoChat = Color(0xFFF2EEE6);
  static const Color burbujaMia = Color(0xFFDCF8C6);
  static const Color leido = MnvColores.azul;
}

// Cabecera verde de la lista de chats
class WaCabeceraLista extends StatelessWidget {
  final String titulo;
  const WaCabeceraLista({super.key, this.titulo = 'WhatsApp'});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: WaColores.verde,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Text(titulo,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}

// Una fila de la lista de chats
class WaFilaChat extends StatelessWidget {
  final String nombre;
  final String inicial;
  final Color color;
  final String ultimo;
  final String hora;
  final int noLeidos;
  final String? estadoMio;
  final bool resaltada;
  final VoidCallback onTap;

  const WaFilaChat({
    super.key,
    required this.nombre,
    required this.inicial,
    required this.color,
    required this.ultimo,
    required this.hora,
    required this.onTap,
    this.noLeidos = 0,
    this.estadoMio,
    this.resaltada = false,
  });

  @override
  Widget build(BuildContext context) {
    final tieneNuevos = noLeidos > 0;
    return GestureDetector(
      onTap: onTap,
      child: MnvResalte(
        activo: resaltada,
        radio: 12,
        escala: 1.03,
        child: Container(
          height: 60,
          color: resaltada ? MnvColores.amarilloSuave : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              MnvAvatar(texto: inicial, color: color, tam: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: MnvColores.texto,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (estadoMio != null) ...[
                          WaPalomitas(estado: estadoMio!, tam: 14),
                          const SizedBox(width: 3),
                        ],
                        Expanded(
                          child: Text(ultimo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: tieneNuevos
                                      ? MnvColores.texto
                                      : MnvColores.suave2,
                                  fontSize: 12,
                                  fontWeight: tieneNuevos
                                      ? FontWeight.w600
                                      : FontWeight.normal)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(hora,
                      style: TextStyle(
                          color: tieneNuevos
                              ? WaColores.verde
                              : MnvColores.suave2,
                          fontSize: 10.5,
                          fontWeight: tieneNuevos
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (hijo, anim) =>
                        ScaleTransition(scale: anim, child: hijo),
                    child: tieneNuevos
                        ? Container(
                            key: const ValueKey('badge'),
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                                color: WaColores.verde,
                                shape: BoxShape.circle),
                            child: Center(
                              child: Text('$noLeidos',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('sin_badge'), width: 20, height: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pestañas de abajo: Chats, Novedades, Llamadas
class WaPestanas extends StatelessWidget {
  final String activa;
  final String? resaltada;
  final ValueChanged<String> onPestana;

  const WaPestanas({
    super.key,
    required this.activa,
    required this.onPestana,
    this.resaltada,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: MnvColores.borde)),
      ),
      child: Row(
        children: [
          _pestana('chats', 'Chats', Icons.chat_rounded),
          _pestana('novedades', 'Novedades', Icons.donut_large_rounded),
          _pestana('llamadas', 'Llamadas', Icons.call_rounded),
        ],
      ),
    );
  }

  Widget _pestana(String clave, String nombre, IconData icono) {
    final activo = activa == clave;
    return Expanded(
      child: GestureDetector(
        onTap: () => onPestana(clave),
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: MnvResalte(
            activo: resaltada == clave,
            radio: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: BoxDecoration(
                      color: activo
                          ? WaColores.verde.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icono,
                        size: 20,
                        color: activo ? WaColores.verdeOscuro : MnvColores.suave2),
                  ),
                  const SizedBox(height: 2),
                  Text(nombre,
                      style: TextStyle(
                          color: activo ? MnvColores.texto : MnvColores.suave2,
                          fontSize: 10.5,
                          fontWeight:
                              activo ? FontWeight.bold : FontWeight.w500)),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Cabecera de una conversacion abierta
class WaCabeceraChat extends StatelessWidget {
  final String nombre;
  final String inicial;
  final Color color;
  final String subtitulo;
  final bool resaltarAtras;
  final VoidCallback onAtras;
  final Widget? accion;

  const WaCabeceraChat({
    super.key,
    required this.nombre,
    required this.inicial,
    required this.color,
    required this.onAtras,
    this.subtitulo = 'en línea',
    this.resaltarAtras = false,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: WaColores.verde,
      padding: const EdgeInsets.only(left: 4, right: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAtras,
            child: MnvResalte(
              activo: resaltarAtras,
              radio: 20,
              escala: 1.15,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          MnvAvatar(texto: inicial, color: Colors.white, tam: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(subtitulo,
                      key: ValueKey(subtitulo),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10.5)),
                ),
              ],
            ),
          ),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}

// Palomitas: reloj (sin enviar), enviado, entregado, leido
class WaPalomitas extends StatelessWidget {
  final String estado;
  final double tam;
  const WaPalomitas({super.key, required this.estado, this.tam = 15});

  @override
  Widget build(BuildContext context) {
    switch (estado) {
      case 'reloj':
        return Icon(Icons.schedule_rounded,
            size: tam - 2, color: MnvColores.suave2);
      case 'enviado':
        return Icon(Icons.check_rounded, size: tam, color: MnvColores.suave2);
      case 'entregado':
        return Icon(Icons.done_all_rounded,
            size: tam, color: MnvColores.suave2);
      default:
        return Icon(Icons.done_all_rounded, size: tam, color: WaColores.leido);
    }
  }
}

// Burbuja de mensaje. Si mia es true va a la derecha en verde claro.
class WaBurbuja extends StatelessWidget {
  final String texto;
  final bool mia;
  final String hora;
  final String? estado;
  final bool resaltada;
  final VoidCallback? onTap;
  final String? citado;
  final Widget? contenido;
  final String? etiquetaArriba;

  const WaBurbuja({
    super.key,
    required this.texto,
    required this.mia,
    required this.hora,
    this.estado,
    this.resaltada = false,
    this.onTap,
    this.citado,
    this.contenido,
    this.etiquetaArriba,
  });

  @override
  Widget build(BuildContext context) {
    final burbuja = Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.fromLTRB(9, 6, 9, 5),
      decoration: BoxDecoration(
        color: mia ? WaColores.burbujaMia : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(mia ? 12 : 2),
          bottomRight: Radius.circular(mia ? 2 : 12),
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (etiquetaArriba != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(etiquetaArriba!,
                  style: const TextStyle(
                      color: MnvColores.suave2,
                      fontSize: 10,
                      fontStyle: FontStyle.italic)),
            ),
          if (citado != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 3,
                      height: 26,
                      color: WaColores.verde,
                      margin: const EdgeInsets.only(right: 5)),
                  Flexible(
                    child: Text(citado!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: MnvColores.suave, fontSize: 10.5)),
                  ),
                ],
              ),
            ),
          if (contenido != null) contenido!,
          if (texto.isNotEmpty)
            Text(texto,
                style: const TextStyle(
                    color: MnvColores.texto, fontSize: 13, height: 1.3)),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(hora,
                  style: const TextStyle(
                      color: MnvColores.suave2, fontSize: 9.5)),
              if (mia && estado != null) ...[
                const SizedBox(width: 3),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (hijo, anim) =>
                      ScaleTransition(scale: anim, child: hijo),
                  child: KeyedSubtree(
                    key: ValueKey(estado),
                    child: WaPalomitas(estado: estado!, tam: 14),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Align(
      alignment: mia ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: GestureDetector(
          onTap: onTap,
          child: MnvResalte(activo: resaltada, radio: 12, escala: 1.04,
              child: burbuja),
        ),
      ),
    );
  }
}

// Caja de escribir de la conversacion
class WaCajaEscribir extends StatelessWidget {
  final String texto;
  final bool enfocada;
  final bool resaltarCaja;
  final bool resaltarEmoji;
  final bool resaltarClip;
  final VoidCallback onCaja;
  final VoidCallback onEmoji;
  final VoidCallback onClip;
  final Widget botonDerecho;
  final String placeholder;

  const WaCajaEscribir({
    super.key,
    required this.texto,
    required this.enfocada,
    required this.onCaja,
    required this.onEmoji,
    required this.onClip,
    required this.botonDerecho,
    this.resaltarCaja = false,
    this.resaltarEmoji = false,
    this.resaltarClip = false,
    this.placeholder = 'Mensaje',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
      color: WaColores.fondoChat,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onCaja,
              child: MnvResalte(
                activo: resaltarCaja,
                radio: 22,
                escala: 1.03,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 42),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: enfocada ? WaColores.verde : Colors.transparent,
                        width: 1.5),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onEmoji,
                        child: MnvResalte(
                          activo: resaltarEmoji,
                          radio: 16,
                          escala: 1.2,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.emoji_emotions_outlined,
                                color: MnvColores.suave2, size: 21),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                    texto.isEmpty ? placeholder : texto,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: texto.isEmpty
                                            ? MnvColores.suave2
                                            : MnvColores.texto,
                                        fontSize: 13)),
                              ),
                              if (enfocada)
                                Container(
                                    width: 2,
                                    height: 16,
                                    margin: const EdgeInsets.only(left: 1),
                                    color: WaColores.verde),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onClip,
                        child: MnvResalte(
                          activo: resaltarClip,
                          radio: 16,
                          escala: 1.2,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.attach_file_rounded,
                                color: MnvColores.suave2, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          botonDerecho,
        ],
      ),
    );
  }
}

// Boton redondo verde (enviar o microfono)
class WaBotonRedondo extends StatelessWidget {
  final IconData icono;
  final bool resaltado;
  final VoidCallback? onTap;
  final Color color;
  const WaBotonRedondo({
    super.key,
    required this.icono,
    required this.onTap,
    this.resaltado = false,
    this.color = WaColores.verde,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MnvResalte(
        activo: resaltado,
        circular: true,
        escala: 1.15,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icono, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// Panel de emojis grandes que reemplaza al teclado
class WaPanelEmojis extends StatelessWidget {
  final String? resaltado;
  final ValueChanged<String> onEmoji;
  final VoidCallback onTeclado;

  const WaPanelEmojis({
    super.key,
    required this.onEmoji,
    required this.onTeclado,
    this.resaltado,
  });

  static const List<String> emojis = [
    '😊', '😂', '❤️', '🙏', '👍', '😘',
    '🥰', '👏', '🎉', '😢', '🌻', '☕',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE6E4F0),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: emojis.map((e) {
              return GestureDetector(
                onTap: () => onEmoji(e),
                child: MnvResalte(
                  activo: resaltado == e,
                  radio: 12,
                  escala: 1.15,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 21))),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTeclado,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_rounded, size: 16, color: MnvColores.suave),
                SizedBox(width: 4),
                Flexible(child: Text('Volver al teclado',
                    style: TextStyle(color: MnvColores.suave, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Separador con la fecha en medio del chat
class WaSeparadorFecha extends StatelessWidget {
  final String texto;
  const WaSeparadorFecha({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(texto,
            style: const TextStyle(color: MnvColores.suave, fontSize: 10)),
      ),
    );
  }
}
