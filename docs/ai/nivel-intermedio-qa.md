# QA — Nivel Intermedio

**Rama:** `ai/nivel-intermedio-v1` · **Fecha:** 4 de octubre de 2026

## Regla de esta matriz

**No se marca PASS sin evidencia de ejecución.** En la sesión de la IA no se pudo instalar Flutter (red bloqueada hacia `storage.googleapis.com` y `pub.dev`), así que lo que sí se pudo verificar se dice con su herramienta, y lo que falta queda en **PENDIENTE (PC de Ney)**.

## 1. Verificaciones que SÍ se ejecutaron (con evidencia)

| # | Verificación | Herramienta | Resultado |
|---|---|---|---|
| V1 | Sintaxis Dart de los 21 archivos nuevos + `tutoriales_view.dart` + test | Parser Dart (tree-sitter), calibrado con archivos del básico | ✅ 0 errores |
| V2 | Cada constructor usado existe y recibe parámetros válidos (nombres, `required`, posicionales) | Script propio contra el código fuente real de Flutter (`flutter/flutter` @ `53d381d`), `confetti` y el proyecto. Probado primero con un archivo con 8 errores sembrados: los detectó todos | ✅ 0 problemas |
| V3 | Todos los `Icons.*`, `MnvColores.*`, `WaColores.*`, `CoColores.*`, `MsColores.*`, `CaColores.*` existen | Mismo script (8.825 íconos de Flutter) | ✅ 0 problemas |
| V4 | `leccionId` idéntico en archivo, `LeccionMapa` y Mi Progreso; número de pasos de Mi Progreso = largo real de `_pasos` | Script de cruce | ✅ 16/16 |
| V5 | Sin `Container` con `color` + `decoration` a la vez; sin `Border` no uniforme con `borderRadius` | Script + revisión | ✅ (2 casos corregidos antes del commit) |
| V6 | Todo `Positioned` cae directo en un `Stack`; todo `Expanded`/`Spacer`/`ListView` tiene altura acotada | Revisión manual archivo por archivo | ✅ |
| V7 | Presupuesto de altura del simulador (489 px útiles) en las pantallas con teclado | Cálculo manual (ver tabla 4) | ✅ |
| V8 | Controladores liberados: `ConfettiController`, `AnimationController` (`MnvResalte`), todos los `Timer` cancelados en `dispose()` y en `_prepararPaso()` | Revisión manual | ✅ |
| V9 | Ningún dato real: sin permisos, sin URLs abiertas, sin APIs nuevas, sin credenciales | `grep` de `url_launcher`, `http`, `Permission`, `launch` en archivos nuevos | ✅ 0 coincidencias |

## 2. Pruebas automáticas escritas (ejecutar en el PC)

`test/nivel_intermedio_test.dart`:

1. **Reanudación total:** abre las 16 lecciones en **cada uno de sus 157 pasos** (como si se retomara desde el paso guardado) en una pantalla de 360×780 y exige cero excepciones. Un `RenderFlex overflowed` hace fallar la prueba.
2. **Recorridos con toques:** toque equivocado → guía amarilla y botón gris; toque correcto → botón verde ("¡Lo lograste! Siguiente →") en WhatsApp, Correo, Mensajes y Calendario. Escritura con teclado ("hola") y teclado numérico (482913).
3. **Avanzar:** el botón guarda el paso (SharedPreferences simulado) y pasa al siguiente.

```powershell
flutter test test/nivel_intermedio_test.dart
```

> `test/widget_test.dart` es el test de contador que trae Flutter por defecto y **ya fallaba en `main`** (hallazgo H2 de la auditoría). Por eso se corre solo el archivo nuevo.

## 3. Matriz por lección

Columnas: **Est.** = verificación estática V1–V8 · **Test** = cubierta por la prueba automática · **Run** = jugada en Chrome por Ney.

| Módulo | Lección | Pasos | Est. | Reanudación (test) | Toque malo → guía | Celebración | Run Chrome | Estado |
|---|---|---:|:-:|:-:|:-:|:-:|:-:|---|
| WhatsApp | whatsapp_conociendo | 10 | ✅ | escrita | escrita | ✅ código | ⏳ | PENDIENTE (PC) |
| WhatsApp | whatsapp_responder | 11 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |
| WhatsApp | whatsapp_audios | 8 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |
| WhatsApp | whatsapp_fotos | 11 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |
| WhatsApp | whatsapp_seguro | 9 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |
| Correo | correo_bandeja | 11 | ✅ | escrita | escrita | ✅ código | ⏳ | PENDIENTE (PC) |
| Correo | correo_adjuntos | 10 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |
| Correo | correo_responder | 10 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |
| Correo | correo_redactar | 10 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |
| Mensajes | mensajes_codigos | 9 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |
| Mensajes | mensajes_nuevo | 9 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |
| Mensajes | mensajes_organizar | 9 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |
| Calendario | calendario_conociendo | 10 | ✅ | escrita | escrita | ✅ código | ⏳ | PENDIENTE (PC) |
| Calendario | calendario_crear_evento | 10 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |
| Calendario | calendario_recordatorios | 10 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |
| Calendario | calendario_editar | 10 | ✅ | escrita | ✅ código | ✅ código | ⏳ | PENDIENTE (PC) |

"✅ código" = el comportamiento está implementado y revisado en el código, pero falta verlo correr.

## 4. Presupuesto de altura (pantallas más cargadas)

Altura útil del celular: 520 − 31 (barra de ubicación) = **489 px**.

| Pantalla | Partes fijas | Queda para la lista |
|---|---|---|
| WhatsApp responder, paso 7 (citando + teclado con sugerencias) | 52 + 44 + 54 + 198 = 348 | 141 (lista con scroll) |
| Correo bandeja buscando | 56 + 20 + 198 = 274 | 215 |
| Correo redactar con teclado y sugerencias | 46 + 42 + 42 + 198 = 328 | 161 |
| Mensajes código con teclado numérico + atajo | 46 + 136 + 218 + 34 = 434 | 55 (Spacer) |
| Mensajes "estafa" con teclado | 52 + 110 + 52 + 198 + 34 = 446 | 43 (Spacer) |
| Calendario noviembre (6 semanas) | 44 + 46 + 236 + 8 = 334 | 155 |
| Calendario formulario con teclado | 48 + 41 + 132 + 198 = 419 | 70 (Spacer) |

## 5. Checklist para la corrida en Chrome (Ney)

Para cada módulo: Menú → Tutoriales → (nivel intermedio) → módulo → L1 … última.

- [ ] Abre desde el mapa y muestra "Paso 1 de N".
- [ ] En cada práctica, tocar algo equivocado muestra guía amarilla y el botón sigue gris.
- [ ] La acción correcta pone el botón verde.
- [ ] Salir a mitad (flecha ←), volver a entrar → "Quedaste en el paso X" → Continuar → el simulador aparece en el estado correcto.
- [ ] Última pantalla: confeti + "¡Terminé!" → vuelve al mapa con la lección ✓ y la siguiente desbloqueada.
- [ ] Mi Progreso dice "Nivel Intermedio" y cuenta las 16 lecciones.
- [ ] Gestos con mouse: mantener presionado (audios, selección múltiple, menú del SMS falso), arrastrar a la derecha (citar), arrastrar el mes, doble clic (PDF).
- [ ] Consola sin `RenderFlex overflowed`.

## 6. Regresión del básico (Ney)

- [ ] Bienvenida, registro, login, perfil, menú principal.
- [ ] Nivel básico: abrir una lección vieja y guardar un paso.
- [ ] Mi Progreso en nivel básico sigue diciendo "Nivel Básico" con sus 4 módulos.
- [ ] Cerrar sesión y volver a entrar.
