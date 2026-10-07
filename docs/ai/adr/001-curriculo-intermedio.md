# ADR-001 — Currículo del Nivel Intermedio: 16 lecciones en 4 módulos

**Estado:** Aceptado · **Fecha:** 2026-10-04

## Contexto
El grid ya tenía cuatro tarjetas intermedias (WhatsApp, Gmail, Mensajes, Calendario) sin contenido. El prompt pide un currículo real, sin relleno y sin cuatro copias del mismo simulador.

## Decisión
- WhatsApp 5 · Correo 4 · Mensajes 3 · Calendario 4 = **16 lecciones, 157 pasos** (detalle en `docs/nivel-intermedio-curriculo.md`).
- Cada módulo con su propia forma de interacción y su color de acento tomado de la paleta MNV.
- La seguridad (anti-estafas) se reparte: una lección completa en WhatsApp y prácticas dentro de Correo y Mensajes.
- Mensajes no repite `escribir_mensaje` del básico: se enfoca en lo que solo pasa por SMS (códigos, sin internet, links falsos).

## Alternativas descartadas
- **5 lecciones por módulo (20):** obligaba a inventar pasos en Mensajes y Calendario. Descartado por relleno.
- **Un módulo "Seguridad" aparte:** separa la práctica del contexto donde ocurre la estafa.

## Riesgo
Ney suele recortar pasos en la revisión. Cada lección está diseñada para poder quitar el paso de tip sin romper nada.
