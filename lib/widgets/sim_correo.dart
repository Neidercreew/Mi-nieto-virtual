import 'package:flutter/material.dart';
import 'mnv_leccion.dart';

// Piezas de la app de Correo de practica (parecida a Gmail, sin logos).
// El color de acento del modulo es el azul de la paleta MNV.

class CoColores {
  static const Color acento = MnvColores.azul;
  static const Color fondo = Color(0xFFF6F8FC);
  static const Color barra = Color(0xFFE9EEF6);
}

// Un correo de la bandeja
class CoCorreo {
  final String clave;
  final String remitente;
  final String inicial;
  final Color color;
  final String asunto;
  final String extracto;
  final String fecha;
  final bool adjunto;
  final bool spam;
  const CoCorreo({
    required this.clave,
    required this.remitente,
    required this.inicial,
    required this.color,
    required this.asunto,
    required this.extracto,
    required this.fecha,
    this.adjunto = false,
    this.spam = false,
  });
}

// Barra de busqueda redondeada con menu y avatar
class CoBarraBusqueda extends StatelessWidget {
  final String texto;
  final bool activa;
  final bool resaltada;
  final bool resaltarMenu;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  const CoBarraBusqueda({
    super.key,
    required this.onTap,
    required this.onMenu,
    this.texto = '',
    this.activa = false,
    this.resaltada = false,
    this.resaltarMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CoColores.fondo,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: GestureDetector(
        onTap: onTap,
        child: MnvResalte(
          activo: resaltada,
          radio: 24,
          escala: 1.03,
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: CoColores.barra,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: activa ? CoColores.acento : Colors.transparent,
                  width: 1.5),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onMenu,
                  child: MnvResalte(
                    activo: resaltarMenu,
                    radio: 18,
                    escala: 1.2,
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(Icons.menu_rounded,
                          color: MnvColores.suave, size: 21),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                      texto.isEmpty ? 'Buscar en el correo' : texto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: texto.isEmpty
                              ? MnvColores.suave2
                              : MnvColores.texto,
                          fontSize: 13)),
                ),
                if (activa)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.search_rounded,
                        color: CoColores.acento, size: 20),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: MnvAvatar(
                        texto: 'Tú', color: MnvColores.morado, tam: 30),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Fila de un correo. Los no leidos van en negrita.
class CoFilaCorreo extends StatelessWidget {
  final CoCorreo correo;
  final bool noLeido;
  final bool destacado;
  final bool resaltada;
  final bool resaltarEstrella;
  final VoidCallback onTap;
  final VoidCallback onEstrella;

  const CoFilaCorreo({
    super.key,
    required this.correo,
    required this.onTap,
    required this.onEstrella,
    this.noLeido = false,
    this.destacado = false,
    this.resaltada = false,
    this.resaltarEstrella = false,
  });

  @override
  Widget build(BuildContext context) {
    final peso = noLeido ? FontWeight.w800 : FontWeight.w500;
    final colorTexto = noLeido ? MnvColores.texto : MnvColores.suave;
    return GestureDetector(
      onTap: onTap,
      child: MnvResalte(
        activo: resaltada,
        radio: 12,
        escala: 1.03,
        child: Container(
          height: 62,
          color: resaltada ? MnvColores.amarilloSuave : CoColores.fondo,
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          child: Row(
            children: [
              MnvAvatar(texto: correo.inicial, color: correo.color, tam: 36),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(correo.remitente,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: colorTexto,
                                  fontSize: 13,
                                  fontWeight: peso)),
                        ),
                        Text(correo.fecha,
                            style: TextStyle(
                                color: noLeido
                                    ? MnvColores.texto
                                    : MnvColores.suave2,
                                fontSize: 10,
                                fontWeight: noLeido
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ],
                    ),
                    Text(correo.asunto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colorTexto, fontSize: 12, fontWeight: peso)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(correo.extracto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: MnvColores.suave2, fontSize: 11)),
                        ),
                        if (correo.adjunto)
                          const Padding(
                            padding: EdgeInsets.only(left: 3),
                            child: Icon(Icons.attach_file_rounded,
                                size: 14, color: MnvColores.suave),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEstrella,
                child: MnvResalte(
                  activo: resaltarEstrella,
                  radio: 16,
                  escala: 1.25,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (hijo, anim) =>
                          ScaleTransition(scale: anim, child: hijo),
                      child: Icon(
                          destacado
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          key: ValueKey(destacado),
                          color: destacado
                              ? MnvColores.amarillo
                              : MnvColores.suave2,
                          size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Boton flotante "Redactar"
class CoBotonRedactar extends StatelessWidget {
  final bool resaltado;
  final VoidCallback onTap;
  const CoBotonRedactar(
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
            color: const Color(0xFFC2E7FF),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, color: MnvColores.texto, size: 20),
              SizedBox(width: 8),
              Text('Redactar',
                  style: TextStyle(
                      color: MnvColores.texto,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// Barra superior de un correo abierto o de redactar
class CoBarraSuperior extends StatelessWidget {
  final VoidCallback onAtras;
  final bool resaltarAtras;
  final List<Widget> acciones;
  final String? titulo;

  const CoBarraSuperior({
    super.key,
    required this.onAtras,
    this.resaltarAtras = false,
    this.acciones = const [],
    this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAtras,
            child: MnvResalte(
              activo: resaltarAtras,
              radio: 20,
              escala: 1.15,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_rounded,
                    color: MnvColores.texto, size: 22),
              ),
            ),
          ),
          if (titulo != null)
            Text(titulo!,
                style: const TextStyle(
                    color: MnvColores.texto,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          const Spacer(),
          ...acciones,
        ],
      ),
    );
  }
}

// Icono de accion de la barra superior (enviar, adjuntar, borrar...)
class CoIconoAccion extends StatelessWidget {
  final IconData icono;
  final bool resaltado;
  final VoidCallback onTap;
  final Color color;
  const CoIconoAccion({
    super.key,
    required this.icono,
    required this.onTap,
    this.resaltado = false,
    this.color = MnvColores.suave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MnvResalte(
        activo: resaltado,
        radio: 18,
        escala: 1.2,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icono, color: color, size: 21),
        ),
      ),
    );
  }
}

// Fila de formulario: Para, Asunto
class CoCampo extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final String placeholder;
  final bool activo;
  final bool resaltado;
  final VoidCallback onTap;
  final Widget? extra;

  const CoCampo({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onTap,
    this.placeholder = '',
    this.activo = false,
    this.resaltado = false,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MnvResalte(
        activo: resaltado,
        radio: 8,
        escala: 1.02,
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: activo ? CoColores.fondo : Colors.white,
            border: const Border(bottom: BorderSide(color: MnvColores.borde)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                child: Text(etiqueta,
                    style: const TextStyle(
                        color: MnvColores.suave2, fontSize: 12.5)),
              ),
              Expanded(
                child: extra ??
                    Row(
                      children: [
                        Flexible(
                          child: Text(valor.isEmpty ? placeholder : valor,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: valor.isEmpty
                                      ? const Color(0xFFBBB6D8)
                                      : MnvColores.texto,
                                  fontSize: 13)),
                        ),
                        if (activo)
                          Container(
                              width: 2,
                              height: 16,
                              margin: const EdgeInsets.only(left: 1),
                              color: CoColores.acento),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Menu lateral (Recibidos, Destacados, Enviados, Spam, Papelera)
class CoMenuLateral extends StatelessWidget {
  final String activa;
  final String? resaltada;
  final ValueChanged<String> onOpcion;
  final VoidCallback onCerrar;

  const CoMenuLateral({
    super.key,
    required this.activa,
    required this.onOpcion,
    required this.onCerrar,
    this.resaltada,
  });

  @override
  Widget build(BuildContext context) {
    const opciones = [
      ['recibidos', 'Recibidos', Icons.inbox_rounded],
      ['destacados', 'Destacados', Icons.star_border_rounded],
      ['enviados', 'Enviados', Icons.send_outlined],
      ['spam', 'Spam', Icons.report_rounded],
      ['papelera', 'Papelera', Icons.delete_outline_rounded],
    ];
    return Positioned.fill(
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: -1, end: 0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            builder: (_, t, hijo) =>
                Transform.translate(offset: Offset(200 * t, 0), child: hijo),
            child: Container(
              width: 200,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 10, bottom: 12),
                    child: Text('Correo',
                        style: TextStyle(
                            color: MnvColores.rojo,
                            fontSize: 19,
                            fontWeight: FontWeight.bold)),
                  ),
                  ...opciones.map((o) {
                    final clave = o[0] as String;
                    final nombre = o[1] as String;
                    final icono = o[2] as IconData;
                    final esActiva = clave == activa;
                    return GestureDetector(
                      onTap: () => onOpcion(clave),
                      child: MnvResalte(
                        activo: resaltada == clave,
                        radio: 20,
                        escala: 1.04,
                        child: Container(
                          height: 42,
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: esActiva
                                ? const Color(0xFFD3E3FD)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(icono, size: 20, color: MnvColores.texto),
                              const SizedBox(width: 12),
                              Text(nombre,
                                  style: TextStyle(
                                      color: MnvColores.texto,
                                      fontSize: 13,
                                      fontWeight: esActiva
                                          ? FontWeight.bold
                                          : FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onCerrar,
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }
}

// Mensajito negro abajo: "Enviado", "Guardado"...
class CoAvisoAbajo extends StatelessWidget {
  final String texto;
  const CoAvisoAbajo({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 10,
      right: 10,
      bottom: 12,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 30, end: 0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (_, y, hijo) =>
              Transform.translate(offset: Offset(0, y), child: hijo),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B3C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF86EFAC), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(texto,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Tarjeta de un archivo adjunto
class CoAdjunto extends StatelessWidget {
  final String nombre;
  final String tamano;
  final IconData icono;
  final Color color;
  final bool resaltado;
  final VoidCallback onTap;

  const CoAdjunto({
    super.key,
    required this.nombre,
    required this.tamano,
    required this.onTap,
    this.icono = Icons.picture_as_pdf_rounded,
    this.color = MnvColores.rojo,
    this.resaltado = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MnvResalte(
        activo: resaltado,
        radio: 12,
        escala: 1.04,
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MnvColores.borde, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: MnvColores.texto,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    Text(tamano,
                        style: const TextStyle(
                            color: MnvColores.suave2, fontSize: 10.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Vista de un correo abierto: asunto, remitente, fecha, cuerpo,
// adjuntos y botones Responder / Reenviar.
class CoVistaCorreo extends StatelessWidget {
  final String asunto;
  final String remitente;
  final String direccion;
  final String inicial;
  final Color color;
  final String fecha;
  final String cuerpo;
  final bool mostrarDireccion;
  final Set<String> resaltar;
  final ValueChanged<String> onToque;
  final List<Widget> adjuntos;
  final Widget? pie;
  final bool destacado;

  const CoVistaCorreo({
    super.key,
    required this.asunto,
    required this.remitente,
    required this.direccion,
    required this.inicial,
    required this.color,
    required this.fecha,
    required this.cuerpo,
    required this.onToque,
    this.mostrarDireccion = false,
    this.resaltar = const {},
    this.adjuntos = const [],
    this.pie,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 6),
          child: GestureDetector(
            onTap: () => onToque('asunto'),
            child: MnvResalte(
              activo: resaltar.contains('asunto'),
              radio: 8,
              escala: 1.03,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(asunto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: MnvColores.texto,
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w600)),
                  ),
                  Icon(
                      destacado
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: destacado
                          ? MnvColores.amarillo
                          : MnvColores.suave2,
                      size: 20),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 10, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MnvAvatar(texto: inicial, color: color, tam: 34),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => onToque('remitente'),
                  child: MnvResalte(
                    activo: resaltar.contains('remitente'),
                    radio: 8,
                    escala: 1.03,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(remitente,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: MnvColores.texto,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                              mostrarDireccion
                                  ? '<$direccion>'
                                  : 'para mí  \u25BE',
                              style: TextStyle(
                                  color: mostrarDireccion
                                      ? MnvColores.rojo
                                      : MnvColores.suave2,
                                  fontSize: 11,
                                  fontWeight: mostrarDireccion
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onToque('fecha'),
                child: MnvResalte(
                  activo: resaltar.contains('fecha'),
                  radio: 8,
                  escala: 1.08,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(fecha,
                        style: const TextStyle(
                            color: MnvColores.suave2, fontSize: 11)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => onToque('cuerpo'),
                  child: Text(cuerpo,
                      style: const TextStyle(
                          color: MnvColores.texto, fontSize: 12.5, height: 1.45)),
                ),
                if (adjuntos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...adjuntos,
                ],
              ],
            ),
          ),
        ),
        if (pie != null) pie!,
      ],
    );
  }
}

// Botones redondeados de abajo: Responder y Reenviar
class CoBotonesResponder extends StatelessWidget {
  final bool resaltarResponder;
  final ValueChanged<String> onToque;
  const CoBotonesResponder(
      {super.key, required this.onToque, this.resaltarResponder = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToque('responder'),
              child: MnvResalte(
                activo: resaltarResponder,
                radio: 22,
                escala: 1.05,
                child: _boton(Icons.reply_rounded, 'Responder'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onToque('reenviar'),
              child: _boton(Icons.forward_rounded, 'Reenviar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boton(IconData icono, String texto) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC4C7C5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 18, color: MnvColores.texto),
          const SizedBox(width: 6),
          Text(texto,
              style: const TextStyle(
                  color: MnvColores.texto,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
