# ADR-005 — En el simulador "hoy" es martes 6 de octubre de 2026

**Estado:** Aceptado · **Fecha:** 2026-10-04

## Contexto
Las lecciones de calendario dicen "el jueves", "el sábado". Si se usara `DateTime.now()`, los textos y objetivos cambiarían cada día y la reanudación podría caer en otro mes.

## Decisión
Fecha fija en todo el nivel: **martes 6 de octubre de 2026**. Las horas de los chats y correos son coherentes con esa fecha. La caja de instrucción lo dice la primera vez ("En este celular de práctica hoy es martes 6").

## Riesgo
Ninguno funcional; el usuario ya sabe que es un celular de mentiras.
