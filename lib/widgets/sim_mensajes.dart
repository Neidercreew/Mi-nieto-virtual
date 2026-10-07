import 'package:flutter/material.dart';
import 'mnv_leccion.dart';

// Piezas de la app de Mensajes (SMS) de practica.
// Acento morado de la paleta MNV para diferenciarla de WhatsApp.

class MsColores {
  static const Color acento = MnvColores.morado;
  static const Color fondo = Color(0xFFFAF9FF);
  static const Color burbujaOtro = Color(0xFFEDEAFF);
}

// Barra de navegacion de Android: atras, inicio, recientes
class MsBarraNavegacion extends StatelessWidget {
  final VoidCallback onAtras;
  final VoidCallback onInicio;
  final VoidCallback onRecientes;
  final bool resaltarAtras;

  const MsBarraNavegacion({
    super.key,
    required this.onAtras,
    required this.onInicio,
    required this.onRecientes,
    this.resaltarAtras = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      color: const Color(0xFF14142B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: onAtras,
            child: MnvResalte(
              activo: resaltarAtras,
              radio: 14,
              escala: 1.25,
              child: const SizedBox(
                width: 46,
                height: 30,
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
          GestureDetector(
            onTap: onInicio,
            child: const SizedBox(
              width: 46,
              height: 30,
              child: Icon(Icons.circle_outlined, color: Colors.white, size: 16),
            ),
          ),
          GestureDetector(
            onTap: onRecientes,
            child: const SizedBox(
              width: 46,
              height: 30,
              child: Icon(Icons.crop_square_rounded,
                  color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }
}

// Cabecera de la lista. En modo seleccion muestra cuantos hay y el basurero.
class MsCabeceraLista extends StatelessWidget {
  final bool modoSeleccion;
  final int seleccionados;
  final bool resaltarBuscar;
  final bool resaltarBorrar;
  final VoidCallback onBuscar;
  final VoidCallback onBorrar;
  final VoidCallback onCancelarSeleccion;

  const MsCabeceraLista({
    super.key,
    required this.onBuscar,
    required this.onBorrar,
    required this.onCancelarSeleccion,
    this.modoSeleccion = false,
    this.seleccionados = 0,
    this.resaltarBuscar = false,
    this.resaltarBorrar = false,
  });

  @override
  Widget build(BuildContext context) {
    if (modoSeleccion) {
      return Container(
        height: 50,
        color: MnvColores.lila,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: onCancelarSeleccion,
              child: const SizedBox(
                width: 40,
                height: 40,
                child:
                    Icon(Icons.close_rounded, color: MnvColores.texto, size: 22),
              ),
            ),
            Expanded(child: Text('$seleccionados seleccionado${seleccionados == 1 ? '' : 's'}',
                style: const TextStyle(
                    color: MnvColores.texto,
                    fontSize: 15,
                    fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            GestureDetector(
              onTap: onBorrar,
              child: MnvResalte(
                activo: resaltarBorrar,
                radio: 18,
                escala: 1.2,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.delete_outline_rounded,
                      color: MnvColores.rojo, size: 23),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      );
    }
    return Container(
      height: 50,
      color: MsColores.fondo,
      padding: const EdgeInsets.only(left: 14, right: 4),
      child: Row(
        children: [
          const Text('Mensajes',
              style: TextStyle(
                  color: MnvColores.texto,
                  fontSize: 19,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: onBuscar,
            child: MnvResalte(
              activo: resaltarBuscar,
              radio: 18,
              escala: 1.2,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.search_rounded,
                    color: MnvColores.texto, size: 22),
              ),
            ),
          ),
          const SizedBox(
            width: 34,
            height: 40,
            child: Icon(Icons.more_vert_rounded,
                color: MnvColores.texto, size: 20),
          ),
        ],
      ),
    );
  }
}

// Fila de una conversacion de SMS
class MsFilaConversacion extends StatelessWidget {
  final String nombre;
  final String inicial;
  final Color color;
  final String ultimo;
  final String hora;
  final bool noLeido;
  final bool modoSeleccion;
  final bool seleccionada;
  final bool resaltada;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const MsFilaConversacion({
    super.key,
    required this.nombre,
    required this.inicial,
    required this.color,
    required this.ultimo,
    required this.hora,
    required this.onTap,
    this.onLongPress,
    this.noLeido = false,
    this.modoSeleccion = false,
    this.seleccionada = false,
    this.resaltada = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: MnvResalte(
        activo: resaltada,
        radio: 12,
        escala: 1.03,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 58,
          color: seleccionada
              ? MnvColores.lila
              : (resaltada ? MnvColores.amarilloSuave : MsColores.fondo),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (hijo, anim) =>
                    ScaleTransition(scale: anim, child: hijo),
                child: seleccionada
                    ? Container(
                        key: const ValueKey('check'),
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                            color: MsColores.acento, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 22),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('avatar'),
                        child: MnvAvatar(texto: inicial, color: color, tam: 38),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: MnvColores.texto,
                            fontSize: 13.5,
                            fontWeight:
                                noLeido ? FontWeight.w800 : FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(ultimo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: noLeido
                                ? MnvColores.texto
                                : MnvColores.suave2,
                            fontSize: 11.5,
                            fontWeight:
                                noLeido ? FontWeight.w600 : FontWeight.normal)),
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
                          color:
                              noLeido ? MsColores.acento : MnvColores.suave2,
                          fontSize: 10.5,
                          fontWeight:
                              noLeido ? FontWeight.bold : FontWeight.normal)),
                  const SizedBox(height: 5),
                  if (noLeido)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                          color: MsColores.acento, shape: BoxShape.circle),
                    )
                  else
                    const SizedBox(height: 9),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Cabecera de una conversacion abierta
class MsCabeceraConversacion extends StatelessWidget {
  final String nombre;
  final String inicial;
  final Color color;
  final String subtitulo;
  final VoidCallback onAtras;
  final List<Widget> acciones;

  const MsCabeceraConversacion({
    super.key,
    required this.nombre,
    required this.inicial,
    required this.color,
    required this.onAtras,
    this.subtitulo = '',
    this.acciones = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: Colors.white,
      padding: const EdgeInsets.only(left: 2, right: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAtras,
            child: const SizedBox(
              width: 38,
              height: 40,
              child: Icon(Icons.arrow_back_rounded,
                  color: MnvColores.texto, size: 22),
            ),
          ),
          MnvAvatar(texto: inicial, color: color, tam: 32),
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
                        color: MnvColores.texto,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                if (subtitulo.isNotEmpty)
                  Text(subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: MnvColores.suave2, fontSize: 10.5)),
              ],
            ),
          ),
          ...acciones,
        ],
      ),
    );
  }
}

// Burbuja de SMS: las propias en morado, las recibidas en lila
class MsBurbuja extends StatelessWidget {
  final String texto;
  final bool mia;
  final String hora;
  final String? estado;
  final Widget? contenido;

  const MsBurbuja({
    super.key,
    required this.texto,
    required this.mia,
    required this.hora,
    this.estado,
    this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mia ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Column(
          crossAxisAlignment:
              mia ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 195),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: mia ? MsColores.acento : MsColores.burbujaOtro,
                borderRadius: BorderRadius.circular(18),
              ),
              child: contenido ??
                  Text(texto,
                      style: TextStyle(
                          color: mia ? Colors.white : MnvColores.texto,
                          fontSize: 13,
                          height: 1.3)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                    estado == null ? hora : '$hora · $estado',
                    key: ValueKey('$hora$estado'),
                    style: TextStyle(
                        color: estado == 'Entregado'
                            ? MnvColores.verde
                            : MnvColores.suave2,
                        fontSize: 9.5,
                        fontWeight: estado == 'Entregado'
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Caja de escribir del SMS con boton de enviar
class MsCajaEscribir extends StatelessWidget {
  final String texto;
  final bool enfocada;
  final bool resaltarCaja;
  final bool resaltarEnviar;
  final VoidCallback onCaja;
  final VoidCallback onEnviar;

  const MsCajaEscribir({
    super.key,
    required this.texto,
    required this.enfocada,
    required this.onCaja,
    required this.onEnviar,
    this.resaltarCaja = false,
    this.resaltarEnviar = false,
  });

  @override
  Widget build(BuildContext context) {
    final hayTexto = texto.isNotEmpty;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline_rounded,
              color: MsColores.acento, size: 24),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: onCaja,
              child: MnvResalte(
                activo: resaltarCaja,
                radio: 20,
                escala: 1.03,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: MnvColores.lila,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: enfocada ? MsColores.acento : Colors.transparent,
                        width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(hayTexto ? texto : 'Mensaje de texto',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: hayTexto
                                    ? MnvColores.texto
                                    : MnvColores.suave2,
                                fontSize: 13)),
                      ),
                      if (enfocada)
                        Container(
                            width: 2,
                            height: 16,
                            margin: const EdgeInsets.only(left: 1),
                            color: MsColores.acento),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onEnviar,
            child: MnvResalte(
              activo: resaltarEnviar,
              circular: true,
              escala: 1.15,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hayTexto ? MsColores.acento : MnvColores.borde,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.send_rounded,
                    color: hayTexto ? Colors.white : MnvColores.suave2,
                    size: 19),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Boton flotante "Iniciar chat"
class MsBotonIniciarChat extends StatelessWidget {
  final bool resaltado;
  final VoidCallback onTap;
  const MsBotonIniciarChat(
      {super.key, required this.onTap, this.resaltado = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MnvResalte(
        activo: resaltado,
        radio: 18,
        escala: 1.08,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: MsColores.acento,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: MsColores.acento.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: const FittedBox(fit: BoxFit.scaleDown, child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_outlined, color: Colors.white, size: 19),
              SizedBox(width: 8),
              Text('Iniciar chat',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          )),
        ),
      ),
    );
  }
}
