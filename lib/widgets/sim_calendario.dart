import 'package:flutter/material.dart';
import 'mnv_leccion.dart';

// Piezas del Calendario de practica. En el simulador "hoy" es martes
// 6 de octubre de 2026 (ver ADR-005). Las semanas empiezan en lunes,
// como en los almanaques de Colombia.

class CaColores {
  // Ambar oscuro: derivado del amarillo de la paleta, con buen contraste
  static const Color acento = Color(0xFFD97706);
  static const Color acentoSuave = Color(0xFFFFF4DA);
  static const Color fondo = Colors.white;
}

const List<String> caNombresMes = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
];
const List<String> caNombresDia = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
];
const List<String> caDiasCortos = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

// "jue, 8 oct"
String caFechaCorta(int anio, int mes, int dia) {
  final d = DateTime(anio, mes, dia);
  return '${caDiasCortos[d.weekday - 1]}, $dia ${caNombresMes[mes - 1].substring(0, 3)}';
}

// "jueves"
String caNombreDia(int anio, int mes, int dia) =>
    caNombresDia[DateTime(anio, mes, dia).weekday - 1];

// "9:30 a. m."
String caHoraTexto(int hora, int minuto, bool pm) =>
    '$hora:${minuto.toString().padLeft(2, '0')} ${pm ? 'p. m.' : 'a. m.'}';

// Un evento del calendario
class CaEvento {
  final String clave;
  final int mes;
  final int dia;
  final String emoji;
  final String titulo;
  final String hora;
  final Color color;
  const CaEvento(this.clave, this.mes, this.dia, this.emoji, this.titulo,
      this.hora, this.color);
}

// Cabecera con el nombre del mes y flechas
class CaCabeceraMes extends StatelessWidget {
  final int anio;
  final int mes;
  final bool resaltarAnterior;
  final bool resaltarSiguiente;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  const CaCabeceraMes({
    super.key,
    required this.anio,
    required this.mes,
    required this.onAnterior,
    required this.onSiguiente,
    this.resaltarAnterior = false,
    this.resaltarSiguiente = false,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = caNombresMes[mes - 1];
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text('${nombre[0].toUpperCase()}${nombre.substring(1)} $anio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: MnvColores.texto,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ),
          _flecha(Icons.chevron_left_rounded, resaltarAnterior, onAnterior),
          _flecha(Icons.chevron_right_rounded, resaltarSiguiente, onSiguiente),
        ],
      ),
    );
  }

  Widget _flecha(IconData icono, bool resaltar, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MnvResalte(
        activo: resaltar,
        radio: 18,
        escala: 1.2,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icono, color: MnvColores.texto, size: 26),
        ),
      ),
    );
  }
}

// Cuadricula del mes. Los dias con evento llevan un puntico.
class CaMes extends StatelessWidget {
  final int anio;
  final int mes;
  final int? hoy;
  final int? seleccionado;
  final Map<int, Color> puntos;
  final Set<int> resaltados;
  final ValueChanged<int> onDia;
  final double celda;

  const CaMes({
    super.key,
    required this.anio,
    required this.mes,
    required this.onDia,
    this.hoy,
    this.seleccionado,
    this.puntos = const {},
    this.resaltados = const {},
    this.celda = 36,
  });

  @override
  Widget build(BuildContext context) {
    final primero = DateTime(anio, mes, 1).weekday - 1;
    final diasMes = DateTime(anio, mes + 1, 0).day;
    final total = primero + diasMes;
    final filas = (total / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['L', 'M', 'M', 'J', 'V', 'S', 'D'].asMap().entries.map((e) {
            final finde = e.key >= 5;
            return SizedBox(
              width: celda,
              height: 20,
              child: Center(
                child: Text(e.value,
                    style: TextStyle(
                        color: finde ? CaColores.acento : MnvColores.suave2,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
        for (int f = 0; f < filas; f++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (c) {
              final dia = f * 7 + c - primero + 1;
              if (dia < 1 || dia > diasMes) {
                return SizedBox(width: celda, height: celda);
              }
              return _dia(dia);
            }),
          ),
      ],
    );
  }

  Widget _dia(int dia) {
    final esHoy = dia == hoy;
    final esSel = dia == seleccionado;
    final punto = puntos[dia];
    return GestureDetector(
      onTap: () => onDia(dia),
      child: SizedBox(
        width: celda,
        height: celda,
        child: Center(
          child: MnvResalte(
            activo: resaltados.contains(dia),
            circular: true,
            escala: 1.15,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: celda - 4,
              height: celda - 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: esHoy
                    ? CaColores.acento
                    : (esSel ? CaColores.acentoSuave : Colors.transparent),
                border: esSel && !esHoy
                    ? Border.all(color: CaColores.acento, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$dia',
                      style: TextStyle(
                          color: esHoy ? Colors.white : MnvColores.texto,
                          fontSize: 13,
                          fontWeight:
                              esHoy || esSel ? FontWeight.bold : FontWeight.w500)),
                  AnimatedOpacity(
                    opacity: punto != null ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: esHoy ? Colors.white : (punto ?? Colors.transparent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Pestañas Mes / Agenda
class CaPestanasVista extends StatelessWidget {
  final String activa;
  final String? resaltada;
  final ValueChanged<String> onCambio;

  const CaPestanasVista({
    super.key,
    required this.activa,
    required this.onCambio,
    this.resaltada,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _p('mes', 'Mes', Icons.calendar_view_month_rounded),
          _p('agenda', 'Agenda', Icons.view_agenda_outlined),
        ],
      ),
    );
  }

  Widget _p(String clave, String texto, IconData icono) {
    final sel = activa == clave;
    return Expanded(
      child: GestureDetector(
        onTap: () => onCambio(clave),
        child: MnvResalte(
          activo: resaltada == clave,
          radio: 16,
          escala: 1.05,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: sel ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono,
                    size: 15,
                    color: sel ? CaColores.acento : MnvColores.suave2),
                const SizedBox(width: 5),
                Flexible(child: Text(texto,
                    style: TextStyle(
                        color: sel ? MnvColores.texto : MnvColores.suave2,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.bold : FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Tarjeta de un evento en la lista
class CaFilaEvento extends StatelessWidget {
  final CaEvento evento;
  final bool resaltada;
  final VoidCallback onTap;
  final String? subtitulo;

  const CaFilaEvento({
    super.key,
    required this.evento,
    required this.onTap,
    this.resaltada = false,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MnvResalte(
        activo: resaltada,
        radio: 12,
        escala: 1.03,
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 3, 10, 3),
          padding: const EdgeInsets.fromLTRB(0, 8, 10, 8),
          decoration: BoxDecoration(
            color: evento.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 34,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: evento.color,
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(3)),
                ),
              ),
              Text(evento.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(evento.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: MnvColores.texto,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Text(subtitulo ?? evento.hora,
                        style: const TextStyle(
                            color: MnvColores.suave, fontSize: 11)),
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

// Boton redondo + para crear evento
class CaBotonMas extends StatelessWidget {
  final bool resaltado;
  final VoidCallback onTap;
  const CaBotonMas({super.key, required this.onTap, this.resaltado = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MnvResalte(
        activo: resaltado,
        radio: 18,
        escala: 1.12,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: CaColores.acento,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: CaColores.acento.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

// Fila tocable del formulario (fecha, hora, repetir...)
class CaFilaFormulario extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool resaltada;
  final VoidCallback onTap;
  final Color? colorTexto;

  const CaFilaFormulario({
    super.key,
    required this.icono,
    required this.texto,
    required this.onTap,
    this.resaltada = false,
    this.colorTexto,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MnvResalte(
        activo: resaltada,
        radio: 10,
        escala: 1.03,
        child: Container(
          height: 44,
          color: resaltada ? CaColores.acentoSuave : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icono, size: 20, color: MnvColores.suave),
              const SizedBox(width: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(texto,
                      key: ValueKey(texto),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: colorTexto ?? MnvColores.texto,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Barra superior del formulario: X y Guardar
class CaBarraFormulario extends StatelessWidget {
  final bool resaltarGuardar;
  final VoidCallback onCerrar;
  final VoidCallback onGuardar;
  const CaBarraFormulario({
    super.key,
    required this.onCerrar,
    required this.onGuardar,
    this.resaltarGuardar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCerrar,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.close_rounded, color: MnvColores.texto, size: 22),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onGuardar,
            child: MnvResalte(
              activo: resaltarGuardar,
              radio: 18,
              escala: 1.1,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: CaColores.acento,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text('Guardar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Ventana para elegir el dia en un calendario chiquito
class CaSelectorFecha extends StatelessWidget {
  final int anio;
  final int mes;
  final int seleccionado;
  final int? resaltado;
  final ValueChanged<int> onDia;
  final VoidCallback onCerrar;

  const CaSelectorFecha({
    super.key,
    required this.anio,
    required this.mes,
    required this.seleccionado,
    required this.onDia,
    required this.onCerrar,
    this.resaltado,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = caNombresMes[mes - 1];
    return Positioned.fill(
      child: GestureDetector(
        onTap: onCerrar,
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (_, t, hijo) => Transform.scale(scale: t, child: hijo),
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        'Elige el día · ${nombre[0].toUpperCase()}${nombre.substring(1)}',
                        style: const TextStyle(
                            color: MnvColores.texto,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    CaMes(
                      anio: anio,
                      mes: mes,
                      hoy: 6,
                      seleccionado: seleccionado,
                      resaltados: resaltado == null ? const {} : {resaltado!},
                      celda: 33,
                      onDia: onDia,
                    ),
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

// Ventana para elegir la hora con flechas grandes
class CaSelectorHora extends StatelessWidget {
  final int hora;
  final int minuto;
  final bool pm;
  final Set<String> resaltar;
  final ValueChanged<String> onAccion;

  const CaSelectorHora({
    super.key,
    required this.hora,
    required this.minuto,
    required this.pm,
    required this.onAccion,
    this.resaltar = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        alignment: Alignment.center,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (_, t, hijo) => Transform.scale(scale: t, child: hijo),
          child: Container(
            width: 236,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Elige la hora',
                    style: TextStyle(
                        color: MnvColores.texto,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _columna('$hora', 'hora_mas', 'hora_menos'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(':',
                          style: TextStyle(
                              color: MnvColores.texto,
                              fontSize: 30,
                              fontWeight: FontWeight.bold)),
                    ),
                    _columna(minuto.toString().padLeft(2, '0'), 'min_mas',
                        'min_menos'),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => onAccion('ampm'),
                      child: MnvResalte(
                        activo: resaltar.contains('ampm'),
                        radio: 12,
                        escala: 1.1,
                        child: Column(
                          children: [
                            _chipAmPm('a. m.', !pm),
                            const SizedBox(height: 4),
                            _chipAmPm('p. m.', pm),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => onAccion('listo'),
                  child: MnvResalte(
                    activo: resaltar.contains('listo'),
                    radio: 14,
                    escala: 1.05,
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: CaColores.acento,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('Listo',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _columna(String valor, String mas, String menos) {
    return Column(
      children: [
        _flecha(Icons.keyboard_arrow_up_rounded, mas),
        Container(
          width: 54,
          height: 46,
          decoration: BoxDecoration(
            color: CaColores.acentoSuave,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(valor,
                style: const TextStyle(
                    color: MnvColores.texto,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        _flecha(Icons.keyboard_arrow_down_rounded, menos),
      ],
    );
  }

  Widget _flecha(IconData icono, String accion) {
    return GestureDetector(
      onTap: () => onAccion(accion),
      child: MnvResalte(
        activo: resaltar.contains(accion),
        radio: 14,
        escala: 1.15,
        child: SizedBox(
          width: 50,
          height: 34,
          child: Icon(icono, color: CaColores.acento, size: 32),
        ),
      ),
    );
  }

  Widget _chipAmPm(String texto, bool activo) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 30,
      decoration: BoxDecoration(
        color: activo ? CaColores.acento : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CaColores.acento, width: 1.5),
      ),
      child: Center(
        child: Text(texto,
            style: TextStyle(
                color: activo ? Colors.white : CaColores.acento,
                fontSize: 11.5,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// Hoja de opciones que sube desde abajo (avisos, repetir)
class CaHojaOpciones extends StatelessWidget {
  final String titulo;
  final List<String> opciones;
  final String? resaltada;
  final ValueChanged<String> onOpcion;
  final VoidCallback onCerrar;

  const CaHojaOpciones({
    super.key,
    required this.titulo,
    required this.opciones,
    required this.onOpcion,
    required this.onCerrar,
    this.resaltada,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onCerrar,
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            builder: (_, t, hijo) =>
                Transform.translate(offset: Offset(0, 220 * t), child: hijo),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 8),
                    child: Text(titulo,
                        style: const TextStyle(
                            color: MnvColores.texto,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                  ...opciones.map((o) => GestureDetector(
                        onTap: () => onOpcion(o),
                        child: MnvResalte(
                          activo: resaltada == o,
                          radio: 12,
                          escala: 1.03,
                          child: Container(
                            height: 42,
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: resaltada == o
                                  ? CaColores.acentoSuave
                                  : const Color(0xFFF7F6FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(o,
                                style: const TextStyle(
                                    color: MnvColores.texto,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Detalle de un evento con botones editar y borrar
class CaDetalleEvento extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String fecha;
  final String hora;
  final Color color;
  final List<String> avisos;
  final String? repite;
  final Set<String> resaltar;
  final ValueChanged<String> onToque;

  const CaDetalleEvento({
    super.key,
    required this.emoji,
    required this.titulo,
    required this.fecha,
    required this.hora,
    required this.color,
    required this.onToque,
    this.avisos = const [],
    this.repite,
    this.resaltar = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _boton(Icons.arrow_back_rounded, 'atras', MnvColores.texto),
                const Spacer(),
                _boton(Icons.edit_outlined, 'editar', MnvColores.texto),
                _boton(Icons.delete_outline_rounded, 'borrar', MnvColores.rojo),
                const SizedBox(width: 4),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 5, right: 10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Text('$emoji $titulo',
                      style: const TextStyle(
                          color: MnvColores.texto,
                          fontSize: 19,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          _linea(Icons.event_rounded, fecha),
          _linea(Icons.schedule_rounded, hora),
          if (repite != null) _linea(Icons.repeat_rounded, repite!),
          _linea(Icons.notifications_none_rounded,
              avisos.isEmpty ? 'Sin avisos' : avisos.join('\n')),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _boton(IconData icono, String clave, Color color) {
    return GestureDetector(
      onTap: () => onToque(clave),
      child: MnvResalte(
        activo: resaltar.contains(clave),
        radio: 18,
        escala: 1.2,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icono, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _linea(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 19, color: MnvColores.suave),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    color: MnvColores.texto, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
