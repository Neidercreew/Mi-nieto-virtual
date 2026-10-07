# Mi Nieto Virtual (MNV)

Aplicación móvil que enseña a adultos mayores a usar el celular con **guías asistidas paso a paso**. Cada lección muestra un celular simulado dentro de la app: la persona practica tocando, escribiendo y deslizando sin miedo a dañar nada ni a usar sus datos reales, y una guía amarilla le indica qué hacer cuando se equivoca.

Proyecto de grado del programa de Ingeniería de Sistemas (ciclo tecnológico) de la Corporación Tecnológica Industrial Colombiana **TEINCO**:
*Plataforma móvil de alfabetización digital interactiva basada en guías asistidas para el fortalecimiento de competencias tecnológicas en adultos mayores.*

## Contenido: 3 niveles, 42 lecciones

| Nivel | Módulos | Lecciones |
|---|---|---:|
| **Básico** | Conociendo tu celular · Cómo navegar · Cámara · Teléfono | 19 |
| **Intermedio** | WhatsApp · Correo electrónico · Mensajes · Calendario | 16 |
| **Avanzado** | Nequi (incluye *Nequi seguro*: prevención de estafas) | 7 |

Todas las lecciones usan simuladores ficticios: no abren apps reales, no envían mensajes ni mueven dinero.

## Funcionalidades

- Registro e ingreso con número de teléfono y PIN.
- Elección de nivel (básico, intermedio, avanzado), que se puede cambiar desde el perfil.
- Mapa de lecciones por módulo con desbloqueo en orden.
- Progreso guardado paso a paso: si la persona sale a mitad de una lección, puede **continuar** donde iba.
- Progreso a prueba de mala señal: se guarda una copia en el celular y se reenvía al servidor cuando vuelve la conexión.
- "Mi Progreso": resumen de lecciones completadas del nivel del usuario.
- Diseño accesible: letra grande, botones amplios, alto contraste y una sola acción principal por pantalla.

## Requisitos

| Herramienta | Versión |
|---|---|
| Flutter | 3.x con Dart `^3.11` (ver `pubspec.yaml`) |
| Android Studio o SDK de Android | Para correr en celular o generar el APK |
| Google Chrome | Para probar en el navegador |

La app se conecta a la API **[mnv-backend](https://github.com/Neidercreew/mnv-backend)** (Node.js, Express y MongoDB), desplegada en Railway.

## Instalación y uso

```bash
git clone https://github.com/Neidercreew/Mi-nieto-virtual.git
cd Mi-nieto-virtual
flutter pub get

# En el navegador
flutter run -d chrome

# En un celular Android conectado por USB
flutter run
```

### Generar el instalable para Android (APK)

```bash
flutter build apk --release
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`. Para instalarlo, cópialo al celular, ábrelo y permite *instalar apps de origen desconocido* si el celular lo pide.

## Configuración

La dirección de la API está en `lib/services/api_service.dart`:

```dart
static const String _base = 'https://mnv-backend-production.up.railway.app/api';
```

Para usar una API local con el emulador de Android, cambia esa línea por la que está comentada justo arriba (`http://10.0.2.2:3000/api`).

**Ojo:** el plan gratuito de Railway y de MongoDB Atlas se "duerme" con la inactividad. La primera petición del día puede tardar; la app lo soporta guardando el progreso en el celular mientras tanto. Si Atlas se pausa, hay que reanudarlo desde su consola.

## Pruebas

```bash
flutter analyze
flutter test
```

| Archivo | Qué prueba |
|---|---|
| `test/widget_test.dart` | La app abre en la pantalla de bienvenida |
| `test/nivel_intermedio_test.dart` | Las 16 lecciones del intermedio abren en cada paso sin errores, más recorridos con toques |
| `test/nivel_avanzado_test.dart` | Las 7 lecciones de Nequi abren en cada paso sin errores |
| `test/progreso_sin_conexion_test.dart` | El progreso no se pierde sin servidor y no se mezcla entre cuentas |

Las pruebas de lecciones abren cada paso en una pantalla de celular de 360×780. Si un texto no cabe, la prueba lista el paso y el `archivo:línea` exacto.

## Estructura del proyecto

```
lib/
├── main.dart                 Bienvenida y rutas iniciales
├── registro_nombre.dart      Registro (nombre, teléfono, PIN)
├── login_screen.dart         Ingreso con teléfono y PIN
├── seleccion_nivel.dart      Elección de nivel
├── menu_principal.dart       Menú principal
├── tutoriales_view.dart      Lista de módulos y "Mi Progreso"
├── mapa_lecciones.dart       Mapa de lecciones de un módulo (desbloqueo y continuar)
├── perfil_screen.dart        Perfil del usuario y cambio de nivel
├── services/
│   └── api_service.dart      Comunicación con la API y copia local del progreso
├── widgets/
│   ├── mnv_leccion.dart      Marco común de lección (guía, botones, teclados, resaltes)
│   ├── sim_whatsapp.dart     Simulador de WhatsApp
│   ├── sim_correo.dart       Simulador de correo
│   ├── sim_mensajes.dart     Simulador de mensajes de texto
│   └── sim_calendario.dart   Simulador de calendario
├── nequi_simulador.dart      Simulador de Nequi
└── tutorial_*.dart           Una lección por archivo (42)
test/                         Pruebas automáticas
docs/                         Currículo del nivel intermedio y decisiones técnicas
```

### Cómo está hecha una lección

Cada lección es un `StatefulWidget` con:

- `_leccionId`: identificador con el que se guarda el progreso.
- `pasoInicial`: paso desde el que se retoma.
- `_pasos`: lista de pasos (explicación, objetivo en el simulador o celebración).
- `_prepararPaso`: deja el simulador en el estado correcto de cada paso.
- `_tocarEnSimulador` y `_revisarObjetivo`: reciben los toques y validan si la persona hizo lo pedido.
- `_avanzar`: guarda el paso y pasa al siguiente.

## Documentación

- **Documento final del proyecto:** manual de instalación (Anexo B) y manual de usuario (Anexo C).
- `docs/nivel-intermedio-curriculo.md`: lecciones y objetivos del nivel intermedio.
- `docs/ai/adr/`: decisiones técnicas registradas.

## Autores

Estudiantes investigadores:
- Duvan Camilo Macias Escorcia
- Neider Steven Peña Riaño
- David Alejandro Sierra Buitrago

Corporación Tecnológica Industrial Colombiana TEINCO · Bogotá, 2026.
