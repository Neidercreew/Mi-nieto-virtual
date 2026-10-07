# ADR-002 — Marco de lección y kits de simulador compartidos solo para el intermedio

**Estado:** Aceptado · **Fecha:** 2026-10-04

## Contexto
Cada lección básica repite ~350 líneas de marco (progreso, caja morada, guía, botón, trofeo, chasis, barra de ubicación, teclado). Repetirlo 16 veces más sumaría ~5.600 líneas idénticas y multiplicaría los lugares donde puede haber un error, sin compilador disponible en la sesión. El handoff ya planeaba extraer los teclados a widgets compartidos.

## Decisión
- `lib/widgets/mnv_leccion.dart`: paleta, `MnvResalte` (pulso con su propio controlador), progreso, caja de instrucción, guía, botón, ícono de paso, trofeo, chasis `MnvTelefonoPractica` con barra de ubicación, teclado de letras con barra de sugerencias, teclado numérico, notificación y check.
- Un kit por módulo (`sim_whatsapp.dart`, `sim_correo.dart`, `sim_mensajes.dart`, `sim_calendario.dart`) con las piezas que se repiten dentro de ese módulo.
- **Cada lección conserva el patrón completo**: `_leccionId`, `pasoInicial`, `_pasos`, `_prepararPaso()`, `_revisarObjetivo()`, `_tocarEnSimulador()`, `_avanzar()`. Lo compartido es solo visual.
- Las lecciones básicas **no se tocan**.

## Alternativas descartadas
- **Copiar el marco en cada archivo:** consistente con el básico pero frágil y largo.
- **Clase base abstracta de lección (herencia):** esconde el patrón que Ney ya domina; más difícil de leer para alguien aprendiendo Flutter.

## Riesgo
Si el estilo del básico cambia en la fase de pulido, hay que actualizar también `mnv_leccion.dart` (un solo lugar). A cambio, el retrofit del básico se vuelve trivial.
