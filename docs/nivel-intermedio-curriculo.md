# Nivel Intermedio — Currículo

> **Básico:** "sé tocar, abrir, navegar, escribir y hacer una llamada".
> **Intermedio:** "sé usar las apps que usa mi familia y resolver tareas de la vida diaria sin pedir ayuda".

**Fecha:** 4 de octubre de 2026 · **Rama:** `ai/nivel-intermedio-v1`
**16 lecciones · 4 módulos · 160 pasos**

## Principios del nivel

1. **Cada módulo enseña una forma distinta de comunicarse u organizarse**, no la misma interfaz con otro color:

| Módulo | Para qué sirve en la vida | Interacción que lo distingue | Color de acento (de la paleta MNV) |
|---|---|---|---|
| 💬 WhatsApp | Familia y amigos: charla, audios, fotos | Burbujas, palomitas, gestos (mantener, deslizar) | Verde `#059669` |
| 📧 Correo | Lo formal: clínica, banco, trámites | Bandeja, remitente/asunto, adjuntos, formularios Para/Asunto | Azul `#0EA5E9` |
| ✉️ Mensajes | SMS: códigos, avisos, sin internet | Notificaciones, códigos, texto predictivo, selección múltiple | Morado `#6B4EFF` |
| 📅 Calendario | Organizar el tiempo: citas, pastillas | Cuadrícula de mes, selectores de fecha y hora, avisos | Amarillo `#FFB300` |

2. **Progresión dentro del nivel:** reconocer la app → leer → responder/crear → hacerlo seguro.
3. **Hilo conductor:** los personajes del básico siguen (María, la amiga del módulo Teléfono) y se suma la familia:
   **Carlos** (hijo), **Lucía** (nieta), **Clínica Los Andes** y el **Dr. Ramírez**. En el simulador "hoy" es **martes 6 de octubre**.
4. **Seguridad transversal (semilla del Detector de Fraude):** cada módulo cierra o incluye una práctica anti-estafa con las 4 banderas rojas del básico (apuran, piden plata/datos, asustan, demasiado bueno):
   WhatsApp → "Hola ma, este es mi número nuevo" · Correo → remitente falso y adjunto peligroso · Mensajes → código que nadie te debe pedir y SMS con link · Calendario no aplica.
5. **Teclado sin tortura:** escribir letra por letra solo cuando la habilidad es escribir (palabras cortas, letra siguiente resaltada). Para frases se enseñan las **sugerencias del teclado** (respuestas rápidas y texto predictivo), que existen en el celular real y le ahorran esfuerzo al adulto mayor.
6. **Nada real:** ninguna lección abre apps reales, pide permisos, usa logos de marcas ni datos personales. Nombres de bancos o EPS son ficticios (Banco Andino, Mi EPS).

## Prerrequisitos

- Nivel básico completo (o el usuario eligió intermedio): tocar, deslizar, abrir apps, teclado de letras (`guardar_contacto`), llamadas.
- Dentro de cada módulo, desbloqueo secuencial de `mapa_lecciones.dart`. En Mi Progreso, un módulo se desbloquea cuando el anterior está completo (comportamiento existente).

---

## Árbol del nivel

```text
Nivel Intermedio
├── M1 WhatsApp
│   ├── L1 whatsapp_conociendo        Conociendo WhatsApp           10 pasos
│   ├── L2 whatsapp_responder         Responder un mensaje          11 pasos
│   ├── L3 whatsapp_audios            Notas de voz                   8 pasos
│   ├── L4 whatsapp_fotos             Enviar y ver fotos            11 pasos
│   └── L5 whatsapp_seguro            WhatsApp seguro                9 pasos
├── M2 Correo electrónico
│   ├── L1 correo_bandeja             Conociendo tu correo          11 pasos
│   ├── L2 correo_adjuntos            Archivos adjuntos             10 pasos
│   ├── L3 correo_responder           Responder un correo           10 pasos
│   └── L4 correo_redactar            Escribir un correo nuevo      10 pasos
├── M3 Mensajes
│   ├── L1 mensajes_codigos           Códigos de verificación        9 pasos
│   ├── L2 mensajes_nuevo             Escribir un mensaje nuevo      9 pasos
│   └── L3 mensajes_organizar         Ordenar tus mensajes           9 pasos
└── M4 Calendario
    ├── L1 calendario_conociendo      Conociendo el calendario      10 pasos
    ├── L2 calendario_crear_evento    Agendar una cita              10 pasos
    ├── L3 calendario_recordatorios   Que el celular te avise       10 pasos
    └── L4 calendario_editar          Cambiar o cancelar una cita   10 pasos
```

Todas las lecciones terminan en `tip` → `accion_real` → `celebracion`, como en el básico.

---

## M1 — WhatsApp

**Competencia:** comunicarse con la familia por WhatsApp (leer, responder, audios, fotos) y reconocer un intento de estafa.
**Componentes compartidos:** `lib/widgets/sim_whatsapp.dart` (cabecera verde, fila de chat, burbujas con palomitas, caja de escribir) + teclado de `mnv_leccion.dart`.

### L1 `whatsapp_conociendo` — Conociendo WhatsApp 💬 (10)
- **Objetivo:** ubicarse en WhatsApp: lista de chats, no leídos, palomitas y pestañas.
- **Pasos:** 0 intro · 1 abrir la app desde el inicio · 2 (info) cómo se lee una fila de chat · 3 abrir el chat con el circulito verde · 4 volver con ← (el circulito desaparece) · 5 tocar las 3 palomitas de tus mensajes (✓ enviado, ✓✓ entregado, ✓✓ azul leído) · 6 entrar a Llamadas y volver a Chats · 7 tip: sin internet sale 🕓 · 8 acción real · 9 celebración.
- **Pantallas:** inicio, chats, chat Lucía, chat María, llamadas. **Animaciones:** pulso, badge que se va, globito explicativo de palomitas, barra de ubicación.
- **Transferible:** abrir WhatsApp, saber quién escribió y si leyeron su mensaje.
- **Riesgos:** confundir chat leído/no leído → la guía lo explica; volver desde Llamadas cuenta como objetivo solo si antes estuvo en Llamadas.

### L2 `whatsapp_responder` — Responder un mensaje ✍️ (11)
- **Objetivo:** responder a Carlos escribiendo, con sugerencias, emoji y respuesta citada.
- **Pasos:** 0 intro · 1 abrir chat de Carlos · 2 tocar la caja "Mensaje" (sube el teclado) · 3 escribir "hola" (letra resaltada, ⌫ si se equivoca) · 4 tocar una respuesta sugerida · 5 abrir emojis y elegir ❤️ · 6 enviar ➤ y ver 🕓→✓→✓✓→azul y "escribiendo…" · 7 deslizar a la derecha la pregunta del postre para citarla y responder con sugerencia · 8 tip: borrar y "eliminar para todos" · 9 acción real · 10 celebración.
- **Interacciones nuevas:** teclado QWERTY, panel de emojis, arrastre horizontal (citar).
- **Riesgos:** escribir mal → guía amable + ⌫; el objetivo del paso 3 solo se cumple con "hola" exacto.

### L3 `whatsapp_audios` — Notas de voz 🎤 (8)
- **Objetivo:** escuchar y mandar audios sin miedo.
- **Pasos:** 0 intro · 1 tocar ▶ y escuchar el audio de Lucía hasta el final · 2 mantener presionado 🎤 al menos 2 s y soltar (se envía) · 3 grabar y deslizar a la izquierda para cancelar · 4 grabar, deslizar arriba al candado 🔒 y luego enviar ➤ · 5 tip · 6 acción real · 7 celebración.
- **Interacciones nuevas:** pulsación larga, arrastre durante la pulsación, candado. **Animaciones:** ondas de sonido, contador rojo, barra de reproducción.
- **Riesgos:** solo tocar el micrófono → guía "deja el dedo ahí"; soltar antes de 2 s → "muy cortito".

### L4 `whatsapp_fotos` — Enviar y ver fotos 📸 (11)
- **Objetivo:** enviar una foto de la galería con comentario y abrir una foto recibida.
- **Pasos:** 0 intro · 1 tocar el clip 📎 · 2 elegir Galería · 3 elegir la foto del jardín 🌻 · 4 agregar comentario con sugerencia · 5 enviar (barra de carga → ✓✓) · 6 tocar la foto que mandó Lucía · 7 volver al chat con ← · 8 tip · 9 acción real · 10 celebración.
- **Pantallas:** chat, menú adjuntar, galería, vista previa, visor a pantalla completa.
- **Riesgos:** tocar Cámara en vez de Galería → guía.

### L5 `whatsapp_seguro` — WhatsApp seguro 🛡️ (9)
- **Objetivo:** reconocer la estafa "número nuevo", verificar, bloquear y no caer en cadenas.
- **Pasos:** 0 intro · 1 abrir el chat del número desconocido · 2 encontrar las 3 banderas rojas tocando las frases (detective) · 3 verificar llamando a Carlos a su número de siempre · 4 bloquear y reportar · 5 tocar la etiqueta "Reenviado muchas veces" de una cadena · 6 tip: nunca dar el código de 6 números · 7 acción real: palabra clave familiar · 8 celebración.
- **Riesgos:** tocar el link de la cadena → guía, no abre nada.

## M2 — Correo electrónico

**Competencia:** manejar el correo para trámites formales: leer, abrir adjuntos, responder y escribir, detectando correos falsos.
**Componentes compartidos:** `lib/widgets/sim_correo.dart` (bandeja, fila de correo en negrita, vista de correo, campo de formulario).

### L1 `correo_bandeja` — Conociendo tu correo 📧 (11)
- **Pasos:** 0 intro (el buzón de la casa) · 1 abrir Correo · 2 (info) remitente, asunto, fecha, negrita = no leído · 3 abrir el correo de la Clínica · 4 tocar remitente, asunto y fecha · 5 volver a la bandeja (ya no está en negrita) · 6 marcar con estrella ☆ · 7 buscar "factura" con la lupa · 8 tip: correo vs WhatsApp · 9 acción real · 10 celebración.
- **Transferible:** encontrar y leer un correo importante.

### L2 `correo_adjuntos` — Archivos adjuntos 📎 (10)
- **Pasos:** 0 intro (el papel dentro del sobre) · 1 abrir el correo con clip · 2 abrir `Resultados.pdf` · 3 doble toque para acercar · 4 descargar ⬇ · 5 en un correo "URGENTE", tocar el remitente para ver la dirección real · 6 reportar spam · 7 tip: señales de correo falso · 8 acción real · 9 celebración.
- **Interacciones nuevas:** visor de documento, doble toque, dirección que se despliega.

### L3 `correo_responder` — Responder un correo ↩️ (10)
- **Pasos:** 0 intro · 1 abrir "Confirme su cita" · 2 tocar Responder (Reenviar da guía) · 3 (info) Para y "Re:" ya vienen puestos · 4 armar saludo, mensaje y despedida con sugerencias · 5 enviar con el avión de arriba · 6 abrir el menú ☰ y ver Enviados · 7 tip: estructura formal · 8 acción real · 9 celebración.
- **Transferible:** responder a una entidad con lenguaje formal; saber que lo enviado queda guardado.

### L4 `correo_redactar` — Escribir un correo nuevo ✉️ (10)
- **Pasos:** 0 intro (Lucía pide la receta) · 1 Redactar ✏️ · 2 Para: escribir "luc" y elegir la sugerencia · 3 Asunto con sugerencia · 4 cuerpo con sugerencias · 5 adjuntar la foto de la receta · 6 enviar · 7 tip: revisar el Para · 8 acción real · 9 celebración.
- **Riesgos:** intentar enviar sin destinatario → guía amable.

## M3 — Mensajes (SMS)

**Diferencia con WhatsApp (justificada):** el SMS llega sin internet, es el canal de los **códigos de verificación**, avisos del operador y también de muchas estafas con links. El básico (`escribir_mensaje`, pendiente) enseña a responder un SMS; aquí se profundiza en lo que solo pasa por SMS.
**Componentes compartidos:** `lib/widgets/sim_mensajes.dart` (lista, burbuja SMS, notificación, barra de navegación ◁ ○ ▢).

### L1 `mensajes_codigos` — Códigos de verificación 🔢 (9)
- **Pasos:** 0 intro (la llave de tu casa) · 1 tocar la notificación del código · 2 volver a la app con ◁ · 3 escribir el código en las 6 casillas · 4 usar la sugerencia "pegar código" del teclado · 5 un desconocido pide el código: borrar la conversación sin responder · 6 tip · 7 acción real · 8 celebración.

### L2 `mensajes_nuevo` — Escribir un mensaje nuevo 🆕 (9)
- **Pasos:** 0 intro · 1 Iniciar chat · 2 buscar "ma" y elegir a María · 3 armar la frase con el **texto predictivo** palabra por palabra · 4 enviar (Enviado → Entregado) · 5 sin internet: el SMS sí sale · 6 tip: SMS vs WhatsApp · 7 acción real · 8 celebración.

### L3 `mensajes_organizar` — Ordenar tus mensajes 🧹 (9)
- **Pasos:** 0 intro · 1 buscar y abrir a Carlos · 2 mantener presionada una promoción (modo selección) · 3 marcar las 3 promociones (no a María) · 4 borrar con confirmación · 5 SMS falso con link: mantener presionado → bloquear y reportar · 6 tip · 7 acción real · 8 celebración.
- **Interacciones nuevas:** selección múltiple, diálogo de confirmación, menú contextual.

## M4 — Calendario

**Competencia:** organizar citas y tratamientos con el calendario y que el celular le avise.
**Componentes compartidos:** `lib/widgets/sim_calendario.dart` (cuadrícula de octubre/noviembre 2026, lista de eventos, selector de hora con ▲▼).

### L1 `calendario_conociendo` — Conociendo el calendario 📅 (10)
- **Pasos:** 0 intro (el almanaque de la cocina) · 1 abrir Calendario · 2 tocar hoy · 3 tocar el jueves (leer L M M J V S D) · 4 tocar el sábado con puntico (cumpleaños de María) · 5 ir a noviembre y volver (flechas o deslizar) · 6 vista Agenda · 7 tip · 8 acción real · 9 celebración.

### L2 `calendario_crear_evento` — Agendar una cita 🩺 (10)
- **Pasos:** 0 intro · 1 botón + · 2 título con sugerencia · 3 fecha: jueves 8 · 4 hora: 9:30 a.m. con ▲▼ · 5 guardar · 6 comprobar en el jueves · 7 tip · 8 acción real · 9 celebración.

### L3 `calendario_recordatorios` — Que el celular te avise 🔔 (10)
- **Pasos:** 0 intro · 1 abrir la cita · 2 editar · 3 poner dos avisos (1 día y 1 hora antes) · 4 guardar · 5 llega el aviso: tocar la notificación · 6 pastilla diaria: "Todos los días" y guardar · 7 tip · 8 acción real · 9 celebración.

### L4 `calendario_editar` — Cambiar o cancelar una cita ✏️ (10)
- **Pasos:** 0 intro · 1 abrir la cita del jueves · 2 editar · 3 fecha al viernes 9 · 4 hora a 2:00 p.m. (a.m./p.m.) · 5 guardar (el punto se mueve) · 6 eliminar la reunión del domingo con confirmación · 7 tip: "Deshacer" · 8 acción real · 9 celebración.

---

## Criterios de finalización (todas las lecciones)

- Cada paso `sim` tiene un objetivo que **solo** se cumple con la acción del usuario; los pasos `intro`/`sim_info`/`tip`/`accion_real` no tienen objetivo.
- `_prepararPaso()` reconstruye el estado completo de cada paso (se puede retomar en cualquiera).
- Último paso guarda `completada: true`; el mapa desbloquea la siguiente lección.
- Toque equivocado → guía amarilla, nunca error.
