# ADR-004 — Escritura: letra por letra solo para palabras cortas; frases con sugerencias del teclado

**Estado:** Aceptado · **Fecha:** 2026-10-04

## Contexto
El teclado del simulador tiene teclas de 23 px (como un celular real). Escribir una frase completa letra por letra es lento y frustrante para un adulto mayor y no enseña nada nuevo después de la primera palabra.

## Decisión
- Escritura manual con letra siguiente resaltada solo para palabras de 3–4 letras ("hola", "luc", "ma", "cita").
- Frases con la **barra de sugerencias** del teclado (respuestas sugeridas en WhatsApp y Correo, texto predictivo palabra por palabra en Mensajes). Es una función real de los teclados Android/iOS y reduce el esfuerzo motor.
- Si teclea una letra distinta, se escribe igual y aparece la guía "toca ⌫ para borrar": así practica corregir.

## Riesgo
Algunos celulares tienen las sugerencias apagadas. El tip lo menciona.
