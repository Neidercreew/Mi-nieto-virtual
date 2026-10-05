# Entrega — Nivel Intermedio v1

**Fecha:** 4 de octubre de 2026 · **Rama:** `ai/nivel-intermedio-v1` · **Base:** `main` @ `0b4b5e0`

## 1. Resumen ejecutivo

El Nivel Intermedio existe dentro de MNV: **4 módulos, 16 lecciones, 157 pasos**, todos con simulador propio, objetivos verificables, guías amarillas, reanudación desde cualquier paso, guardado de progreso con el mecanismo existente y celebración con confeti. Está conectado en Tutoriales y Mi Progreso muestra el nivel del usuario.

Cada módulo tiene su propia interacción: WhatsApp (burbujas, palomitas, pulsación larga para audios, deslizar para citar), Correo (bandeja, remitente/asunto, PDF con doble toque, formularios), Mensajes (notificaciones, códigos, texto predictivo, selección múltiple) y Calendario (cuadrícula, selectores de fecha y hora, avisos, repetición). Todo es ficticio y autocontenido.

**Lo que falta, sin maquillaje:** compilar y correr. En la sesión de la IA no hubo forma de instalar Flutter. Se verificó sintaxis y API contra el código real de Flutter (ver QA), pero `flutter analyze`, `flutter test` y `flutter run -d chrome` se tienen que correr en tu PC (sección 11).

## 2. Módulos

| Módulo | Lecciones | Pasos | Estado |
|---|---:|---:|---|
| 💬 WhatsApp | 5 | 49 | ✅ implementado · ⏳ correr en PC |
| 📧 Correo electrónico | 4 | 41 | ✅ implementado · ⏳ correr en PC |
| ✉️ Mensajes | 3 | 27 | ✅ implementado · ⏳ correr en PC |
| 📅 Calendario | 4 | 40 | ✅ implementado · ⏳ correr en PC |

Detalle de cada lección: `docs/nivel-intermedio-curriculo.md`.

## 3. Archivos creados

**Lecciones (16)**
```
lib/tutorial_whatsapp_conociendo.dart      lib/tutorial_correo_bandeja.dart
lib/tutorial_whatsapp_responder.dart       lib/tutorial_correo_adjuntos.dart
lib/tutorial_whatsapp_audios.dart          lib/tutorial_correo_responder.dart
lib/tutorial_whatsapp_fotos.dart           lib/tutorial_correo_redactar.dart
lib/tutorial_whatsapp_seguro.dart          lib/tutorial_mensajes_codigos.dart
lib/tutorial_calendario_conociendo.dart    lib/tutorial_mensajes_nuevo.dart
lib/tutorial_calendario_crear_evento.dart  lib/tutorial_mensajes_organizar.dart
lib/tutorial_calendario_recordatorios.dart
lib/tutorial_calendario_editar.dart
```

**Piezas compartidas (5)**
```
lib/widgets/mnv_leccion.dart      marco de leccion, teclados, resalte, notificacion, dialogo
lib/widgets/sim_whatsapp.dart     chats, burbujas, palomitas, caja de escribir, emojis
lib/widgets/sim_correo.dart       bandeja, fila de correo, vista de correo, campos, menu
lib/widgets/sim_mensajes.dart     lista SMS, burbujas, barra de navegacion Android
lib/widgets/sim_calendario.dart   mes, selectores de fecha y hora, detalle de evento
```

**Pruebas y documentos**
```
test/nivel_intermedio_test.dart
docs/nivel-intermedio-curriculo.md
docs/ai/mnv-intermedio-audit.md
docs/ai/nivel-intermedio-qa.md
docs/ai/nivel-intermedio-entrega.md
docs/ai/adr/001-curriculo-intermedio.md
docs/ai/adr/002-widgets-compartidos.md
docs/ai/adr/003-conexion-tutoriales-view.md
docs/ai/adr/004-teclado-y-sugerencias.md
docs/ai/adr/005-fecha-ficticia.md
```

## 4. Archivos modificados

Solo uno: **`lib/tutoriales_view.dart`**, en las tres zonas de siempre:

1. 16 imports nuevos debajo de `tutorial_contestar_llamada.dart`.
2. Las 4 `TutorialApp` intermedias reciben `icono` (Material Icons, sin logos) y `onTap` con su `MapaLeccionesScreen`. "Whatsapp" → "WhatsApp" y "Gmail// correo" → "Correo electrónico".
3. Mi Progreso: getter `_tituloNivel`, llave `'nivel'` en cada módulo, módulos intermedios y filtro por nivel. **Mismo patrón y mismos nombres que la rama de Alejandro**, para que el merge sea "quedarse con los dos bloques".

No se tocó ninguna lección básica, ni `api_service.dart`, ni `mapa_lecciones.dart`, ni `pubspec.yaml`.

## 5. Componentes reutilizados

- Patrón de lección completo del handoff (`_leccionId`, `pasoInicial` con `.clamp`, `_pasos`, `_prepararPaso`, `_revisarObjetivo`, `_tocarEnSimulador`, `_avanzar`).
- `MapaLeccionesScreen` y `LeccionMapa` tal cual (desbloqueo, continuar, practicar de nuevo).
- `ApiService.guardarPaso` (a través de `mnvGuardarPaso`, que hace lo mismo que el `_avanzar` del básico).
- Estilo del básico copiado en `mnv_leccion.dart`: caja morada, barra de progreso animada, guía amarilla, botón de 58 px, chasis 270×520, barra de ubicación con destello ámbar, pulso de resalte, confeti, check elástico, notificación con `easeOutBack`, teclado que sube con `AnimatedSlide`.
- Teclado QWERTY y numérico del `guardar_contacto`, extraídos a widgets (el handoff ya lo tenía planeado para el pulido).

## 6. Dependencias nuevas

Ninguna. Solo `flutter`, `shared_preferences` y `confetti`, que ya estaban.

## 7. Cambios de backend

Ninguno. El backend acepta cualquier `leccionId`.

## 8. Pruebas ejecutadas

| Prueba | Resultado |
|---|---|
| Sintaxis Dart (parser) de todo lo nuevo | ✅ 0 errores |
| Constructores, parámetros, íconos y colores contra el código fuente real de Flutter | ✅ 0 problemas (el verificador detectó 8/8 errores sembrados a propósito) |
| Cruce `leccionId` / mapa / Mi Progreso / número de pasos | ✅ 16/16 |
| `flutter analyze` | ⏳ no ejecutable en la sesión → PC |
| `flutter test test/nivel_intermedio_test.dart` | ⏳ escrito, no ejecutado → PC |
| `flutter build web` / `flutter run -d chrome` | ⏳ PC |

## 9. Issues conocidos

| # | Issue | Impacto |
|---|---|---|
| I1 | **No compilado todavía.** Puede salir algún error de tipos que el parser no detecta. | Si sale, pégame la salida de `flutter analyze` y lo corrijo con evidencia. |
| I2 | El selector de hora sube los minutos de 15 en 15 (simplificación para que sean 2 toques). | Pedagógicamente suficiente; el celular real usa rueda o reloj. |
| I3 | Hallazgo H1 (del básico): Mi Progreso usa `telefono_guardar_contactos` con **s**. No se corrigió aquí porque es del básico. | "Guardar un contacto" no sale completada en Mi Progreso. Fix de una letra. |
| I4 | `test/widget_test.dart` (contador por defecto) ya fallaba en `main`. | `flutter test` sin argumentos falla por ese archivo, no por el intermedio. |
| I5 | Mi Progreso, igual que antes, desbloquea el primer módulo de cada nivel. Un usuario que cambia a intermedio ve WhatsApp disponible aunque no haya terminado el básico. | Es el comportamiento existente; se respetó. |
| I6 | Textos dentro del simulador de 10–13 px (igual que el básico). | Revisar en celular real si se leen bien. |

## 10. Riesgos para revisar

- **Merge con `feature/nivel-avanzado`:** chocan en `tutoriales_view.dart` (imports, tarjetas, módulos de Mi Progreso). El getter `_tituloNivel` y el filtro son idénticos, así que se queda una sola copia de eso y los dos bloques de lo demás.
- **Gestos con mouse en Chrome:** pulsación larga (audios, selección), arrastres (citar, mes) y doble clic (PDF). Flutter los soporta con mouse, pero hay que probarlos.
- **Largo de lecciones:** 8 a 11 pasos. Si quieres recortar, los pasos `tip` se pueden quitar sin romper nada (hay que actualizar el número de pasos en Mi Progreso).

## 11. Cómo probarlo (sin tocar tu `prueba-merge-pr`)

En PowerShell, desde tu repo. Esto crea **una carpeta aparte** con la rama nueva; tu carpeta actual queda igual:

```powershell
cd "C:\Users\neide\adm web V\FLUTTER MNV\mi_nieto_virtual"
git rev-parse --show-toplevel          # debe terminar en mi_nieto_virtual
git status                             # solo mirar, no se toca nada
git fetch origin
git worktree add -b ai/nivel-intermedio-v1 "..\mnv-ai-intermedio" origin/ai/nivel-intermedio-v1
cd "..\mnv-ai-intermedio"
git branch --show-current              # ai/nivel-intermedio-v1
flutter pub get
flutter analyze
flutter test test/nivel_intermedio_test.dart
flutter run -d chrome
```

En la app: **Perfil → Tu nivel → Intermedio** (o el ícono de ajustes en Tutoriales) → **Tutoriales** → WhatsApp / Correo / Mensajes / Calendario → lección 1.

Para borrar la carpeta de prueba después (no borra la rama):

```powershell
cd "C:\Users\neide\adm web V\FLUTTER MNV\mi_nieto_virtual"
git worktree remove "..\mnv-ai-intermedio"
```

## 12. Git

```text
base branch:      main @ 0b4b5e0
feature branch:   ai/nivel-intermedio-v1 (en GitHub)
respaldo:         respaldo-antes-ai-nivel-intermedio @ 0b4b5e0 (en GitHub)
último commit:    ver `git log -1 origin/ai/nivel-intermedio-v1`
archivos:         31 nuevos, 1 modificado (lib/tutoriales_view.dart)
merge a main:     NO hecho (a propósito)
```

## 13. Checklist de revisión humana

```text
[ ] currículo            docs/nivel-intermedio-curriculo.md
[ ] navegación           Tutoriales → módulo → mapa → lección → volver
[ ] WhatsApp             5 lecciones
[ ] Gmail / Correo       4 lecciones
[ ] Mensajes             3 lecciones
[ ] Calendario           4 lecciones
[ ] progreso             se guarda y Mi Progreso dice "Nivel Intermedio"
[ ] reanudación          salir a mitad y "Continuar"
[ ] accesibilidad        tamaños y contraste en celular real
[ ] animaciones          pulso, barra de ubicación, palomitas, audio, check
[ ] errores              flutter analyze limpio de errores
[ ] rendimiento          sin tirones en Chrome
[ ] Git                  rama aislada, sin merge
[ ] regresión del básico una lección vieja + login + perfil
```
