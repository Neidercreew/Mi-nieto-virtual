# Auditoría previa — Nivel Intermedio (MNV)

**Fecha:** 4 de octubre de 2026
**Rama base:** `main` @ `0b4b5e0` (feat: leccion contestar una llamada)
**Rama de trabajo:** `ai/nivel-intermedio-v1`
**Respaldo:** `respaldo-antes-ai-nivel-intermedio` (apunta a `0b4b5e0`)

## 1. Estado de Git verificado

| Verificación | Resultado |
|---|---|
| Raíz del clon de trabajo | `mi-nieto-virtual` (clon de `github.com/Neidercreew/Mi-nieto-virtual`) |
| `git status` en `main` | limpio, al día con `origin/main` |
| Ramas remotas | `main`, `feature/nivel-avanzado` (Alejandro). **No existe** `feature/nivel-intermedio` en GitHub |
| Copia local de Ney (PC) | en la rama `prueba-merge-pr` probando el PR de Nequi. **No se tocó.** |

La copia local tiene `nequi_simulador.dart` y lecciones Nequi sin estar en `main`. Por eso el trabajo se hizo en un clon aparte, partiendo de `origin/main`, sin hacer checkout ni stash en el PC de Ney.

## 2. Arquitectura detectada (coincide con el handoff)

- Flutter con lecciones quemadas en el cliente; backend Node/Express solo guarda progreso y autentica.
- `ApiService.guardarPaso(userId, leccionId, paso, completada:)` acepta cualquier `leccionId` → **no hace falta tocar el backend**.
- `ApiService.obtenerProgreso` devuelve `{progreso: [{leccionId, paso, completada}]}`.
- Sesión en `SharedPreferences`: `usuario_id`, `nombre_usuario`, `nivel_usuario`, `telefono_usuario`.

## 3. Archivos relevantes

| Archivo | Rol | Notas |
|---|---|---|
| `lib/tutoriales_view.dart` | Grid de módulos por nivel + pestaña Mi Progreso | Las 4 tarjetas intermedias existen pero **sin `onTap`** (caen al `DetalleTutorialScreen` de prueba). Mi Progreso tiene la lista quemada **solo del básico** y el título fijo "Nivel Básico". |
| `lib/mapa_lecciones.dart` | Mapa Duolingo del módulo | Desbloqueo secuencial dentro del módulo; retoma con `builderConPaso(pasoGuardado)` si `pasoGuardado > 0`. Genérico: sirve tal cual para el intermedio. |
| `lib/services/api_service.dart` | HTTP | Sin cambios. |
| `lib/tutorial_contestar_llamada.dart` | Lección más reciente | Patrón de referencia: barra de ubicación, chasis 270×520, `AnimatedSwitcher`, pulso, gesto de deslizar, confeti. |
| `lib/tutorial_guardar_contacto.dart` | Lección con teclado | Teclado QWERTY (teclas 23×34) con letra esperada resaltada, teclado numérico, check de guardado. |

## 4. Patrones heredados que se respetan

- Archivo `tutorial_<nombre>.dart`, `const String _leccionId`, `pasoInicial` con `.clamp`.
- Lista `_pasos` de `Map<String, dynamic>` con `tipo` / `titulo` / `instruccion` / `objetivo` / `ayuda` / `icono` / `colorIcono`.
- Métodos `_prepararPaso()`, `_revisarObjetivo()`, `_tocarEnSimulador(accion)`, `_avanzar()`.
- Botón gris con ayuda → verde "¡Lo lograste! Siguiente →" solo con objetivo cumplido.
- Guía amarilla, nunca errores rojos.
- Guardado: `guardarPaso(userId, _leccionId, _pasoActual + 1, completada: esUltimo)`.

## 5. Componentes reutilizables identificados

Hoy cada lección duplica ~350 líneas de "marco": barra de progreso, caja morada, guía amarilla, botón, trofeo, chasis del simulador, barra de ubicación y teclados. El handoff ya planea "extraer el teclado numérico y el QWERTY a widgets compartidos" en la fase de pulido.

Decisión (ver ADR-002): para el intermedio se crea `lib/widgets/mnv_leccion.dart` con esos piezas visuales **idénticas en estilo** a las del básico. Las lecciones básicas **no se tocan**.

## 6. Hallazgos (no se corrigen en esta rama, quedan reportados)

| # | Hallazgo | Evidencia | Impacto |
|---|---|---|---|
| H1 | Id distinto en Mi Progreso | `tutoriales_view.dart` usa `'telefono_guardar_contactos'` (con **s**) pero la lección guarda `'telefono_guardar_contacto'` | En Mi Progreso, "Guardar un contacto" nunca sale completada y bloquea visualmente las siguientes del módulo Teléfono. Fix de 1 carácter, pero es del básico: lo decide Ney. |
| H2 | `test/widget_test.dart` es el test de contador por defecto | Busca un `'0'` y un ícono `+` que no existen en `MiNietoVirtual` | `flutter test` ya fallaba antes de esta rama. |
| H3 | Código muerto `_navIcon` / `_navIndex` | `tutoriales_view.dart` | Ya listado en el handoff. |
| H4 | `print` en `api_service.dart` | lint `avoid_print` | Informativo. |
| H5 | Uso de `withOpacity` (deprecado desde Flutter 3.27) | todas las lecciones básicas | Genera avisos `deprecated_member_use` en `flutter analyze`. El código nuevo usa `withValues(alpha:)` para no sumar avisos. |

## 7. Puntos de conflicto previstos

- **`tutoriales_view.dart` vs `feature/nivel-avanzado`:** Alejandro ya agregó la llave `'nivel'` a cada módulo de Mi Progreso, un getter `_tituloNivel` y el filtro `todosLosModulos.where(...)`. Esta rama usa **exactamente el mismo patrón y los mismos nombres** para que, al mergear, los bloques coincidan y el conflicto sea solo "quedarse con los dos" (imports, tarjeta Nequi vs tarjetas intermedias, módulos de Mi Progreso).
- **`analysis_options.yaml`:** no se toca (Alejandro sí lo cambia).

## 8. Limitaciones del entorno de esta sesión

- No hay terminal en el PC de Ney (solo lectura y copia de archivos).
- En el entorno de la IA la red bloquea `storage.googleapis.com` y `pub.dev`: **no se pudo instalar Flutter ni Dart**. Por tanto `flutter analyze`, `flutter test`, `flutter build web` y `flutter run -d chrome` se corren en el PC de Ney (ver `nivel-intermedio-entrega.md`, sección 11). Se compensó con revisión de código línea por línea, pero **no se declara PASS sin esa evidencia**.
