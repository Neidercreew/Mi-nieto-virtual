# Análisis e integración de niveles — antes del merge a `main`

**Fecha:** 6 de octubre de 2026 · **Rama:** `ai/integracion-niveles` · **Base:** `main` @ `0b4b5e0`

Esta rama ya junta todo lo que va a `main`: nivel intermedio + PR #1 de Alejandro (Nequi) + arreglos. `main` es ancestro directo de esta rama, así que **el merge final es fast-forward y no puede tener conflictos**.

## 1. Estado del repositorio

| Rama | Commit | Qué es |
|---|---|---|
| `main` | `0b4b5e0` | Básico (19 lecciones) |
| `feature/nivel-avanzado` (PR #1, Alejandro) | `c187f99` | Nequi, 7 lecciones (la última, Anti estafas, del 5 oct) |
| `ai/nivel-intermedio-v1` | `50eb4a1` | Intermedio, 16 lecciones |
| **`ai/integracion-niveles`** | esta | Todo lo anterior + arreglos |

PRs pendientes de Alejandro: **solo el #1** (9 commits, 11 archivos). GitHub lo marca `mergeable: clean` contra `main` actual.

## 2. Conflictos y cómo se resolvieron

Único archivo en conflicto: `lib/tutoriales_view.dart`.

| Bloque | Resolución |
|---|---|
| Imports | Los dos: 16 del intermedio + 5 de Nequi |
| `final todosLosModulos = [` | Mismo código, distinta sangría → se deja uno |
| `final modulos = ...where(...)` | Igual |
| `Text(_tituloNivel, ...)` | Igual |
| **Trampa sin marca de conflicto** | Git dejó el getter `_tituloNivel` **dos veces** (Alejandro y el intermedio lo pusieron en sitios distintos). No compila. Se dejó uno. |

## 3. Revisión del PR #1 (Nequi)

| Revisión | Resultado |
|---|---|
| Sintaxis Dart de los 8 archivos | ✅ |
| Constructores, parámetros e íconos contra el código fuente real de Flutter | ✅ 0 problemas |
| `leccionId` igual en archivo, mapa y Mi Progreso; nº de pasos coincide | ✅ 7/7 |
| `pasoInicial` + `clamp`, `_prepararPaso` reconstruye por datos del paso | ✅ |
| Controladores liberados en `dispose`, timers cancelados, `mounted` después de `await` | ✅ |
| Sin URLs, permisos ni datos reales | ✅ |
| Guardia de doble toque | 6/7 la tienen; **`meter_plata` no** → corregido en el arreglo A3 |
| `pubspec.lock` | Lo generó un Flutter más nuevo (`meta 1.19.0`). `flutter pub get` lo ajusta a tu versión; no rompe nada |

## 4. Arreglos aplicados (cada uno en su propio commit)

| # | Problema (con evidencia) | Arreglo | Commit |
|---|---|---|---|
| A1 | Mi Progreso usaba `telefono_guardar_contactos` (con **s**); la lección guarda `telefono_guardar_contacto`. "Guardar un contacto" nunca salía completada | Id corregido | `fix(progreso): ids y pasos…` |
| A2 | Mi Progreso decía 36 pasos para Configuraciones; el archivo tiene **34** | 36 → 34 | mismo |
| A3 | `_avanzar` espera el guardado en el servidor (hasta 5 s) antes de pasar de paso. Un **doble toque** en ese tiempo avanzaba **dos pasos**, y en el último paso hacía `Navigator.pop` dos veces: **cerraba también el mapa**. Ninguna lección del básico ni del intermedio tenía guardia | Guardia `_avanzando` en las 39 lecciones con `_avanzar` (el cuerpo original queda intacto en `_avanzarPaso`). Guardia al terminar en Botones, Moviéndote y Pantalla táctil | `fix(lecciones): un doble toque…` |
| A4 | **"Desbloqueo intermitente"** (bug del handoff). Causa en el código: `guardarPaso` y `obtenerProgreso` usaban un timeout de **5 s** y tragaban el error. Railway y Atlas M0 se duermen y el primer request tarda más → se perdía el `completada` (la siguiente lección quedaba bloqueada) y el mapa recibía `null` (todo bloqueado menos la primera) | `api_service.dart`: copia local del progreso en el celular, envío por detrás sin hacer esperar al usuario, pasos pendientes que se reenvían solos, mezcla servidor + local (una lección completada nunca vuelve a bloquearse), timeout de 12 s (6 s si ya hay copia). **Mismo formato de respuesta**: mapa, Mi Progreso y perfil no cambian | `fix(progreso): no perder pasos…` |
| A5 | Al retomar el intermedio justo en la celebración no salía el confeti | Confeti también al retomar | con A3 |
| A6 | Código muerto `_navIcon/_navIndex`; imports sin uso (`gestures`, `proximamente_screen`); `mapa_lecciones` importaba `'../services/…'` | Limpieza | `chore: limpiar…` |
| A7 | `test/widget_test.dart` era el test de contador por defecto y siempre fallaba | Prueba de humo real de la bienvenida | `test: …` |

## 5. Pruebas nuevas

| Archivo | Qué prueba |
|---|---|
| `test/widget_test.dart` | La app abre en la bienvenida con "Empezar" y "Ya tengo mi cuenta" |
| `test/nivel_intermedio_test.dart` | 16 lecciones × cada paso (157 aperturas) en 360×780 + recorridos con toques |
| `test/nivel_avanzado_test.dart` | 7 lecciones de Nequi × cada paso (99 aperturas) en 360×780 |
| `test/progreso_sin_conexion_test.dart` | Sin servidor: el paso no se pierde, una lección completada no se descompleta, dos cuentas no se mezclan |

## 6. Verificación final de la rama

| Chequeo | Resultado |
|---|---|
| Sintaxis de todo `lib/` y `test/` | ✅ 0 errores |
| Constructores / parámetros / íconos / colores contra Flutter | ✅ 0 problemas |
| Imports faltantes, identificadores privados sin declarar, argumentos de métodos | ✅ (4 avisos revisados a mano: falsos positivos del verificador) |
| 42 lecciones: mapa = Mi Progreso = archivo (id y nº de pasos) | ✅ 42/42 |
| `tutoriales_view.dart`: 48 imports, sin duplicados ni archivos faltantes | ✅ |
| `main` es ancestro de la rama | ✅ merge fast-forward |

## 7. Lo que NO se verificó (honesto)

- **Compilar y correr.** En el entorno de la IA no hay Flutter y el PC no estaba conectado. `flutter analyze`, `flutter test` y `flutter run -d chrome` siguen pendientes. Es el último filtro antes del merge.
- **Selfie que queda en `foto_tomada` (handoff):** el `_prepararPaso` actual reconstruye bien todos los pasos. No hay evidencia de que el bug siga; se deja sin tocar hasta verlo correr.
- **Avisos `withOpacity` (405 usos en 34 archivos del básico y Nequi):** son avisos de deprecación, no errores. No se tocaron para no cambiar 34 archivos sin necesidad.
- Mi Progreso bloquea el primer tema de un módulo hasta terminar el anterior, pero el mapa deja entrar. Es una decisión de diseño que ya existía; no se cambió.
