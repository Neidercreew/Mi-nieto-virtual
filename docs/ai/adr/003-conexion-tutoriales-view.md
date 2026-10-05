# ADR-003 — Conexión en `tutoriales_view.dart` con el mismo patrón de la rama Nequi

**Estado:** Aceptado · **Fecha:** 2026-10-04

## Contexto
`tutoriales_view.dart` es el único archivo que choca entre ramas. `feature/nivel-avanzado` ya agregó en Mi Progreso la llave `'nivel'` por módulo, el getter `_tituloNivel` y el filtro `todosLosModulos.where((m) => m['nivel'] == _nivelUsuario)`.

## Decisión
- Se mantiene la convención existente (no se crea un `lecciones_intermedio.dart`): import + `LeccionMapa` dentro de la `TutorialApp` + entradas en `_buildMiProgreso()` con el formato exacto.
- En Mi Progreso se usan **los mismos nombres y la misma forma** que Alejandro, para que al mergear las líneas iguales no choquen y el resto sea "quedarse con los dos bloques".
- Las tarjetas intermedias reciben `icono` (Material Icons, sin logos) y su `onTap`.

## Alternativa descartada
Partir el registro en `lecciones_intermedio.dart`: está en el roadmap de pulido, pero cambiaría la convención que Ney domina justo antes de la sustentación.
