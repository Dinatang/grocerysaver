# GrocerySaver

Aplicacion Flutter para comparar productos, revisar ofertas, consultar clima por ubicacion en Ecuador, escanear codigos y gestionar datos de perfil desde una sola interfaz.

## Resumen.

El proyecto esta orientado a compras inteligentes. La app consume una API REST propia y organiza la logica en capas simples:

- `views`: pantallas y widgets de interfaz.
- `viewmodels`: estado y logica de presentacion.
- `services`: integracion HTTP y utilidades de infraestructura.
- `models`: modelos de sesion y datos tipados.
- `components`: piezas visuales reutilizables.

## Funcionalidades actuales

- Onboarding inicial.
- Registro, login, verificacion debug y cierre de sesion.
- Carga de perfil y preferencias de notificaciones.
- Catalogo de categorias y productos.
- Comparador de precios por producto.
- Listado paginado de ofertas con filtros.
- Consulta de clima por ciudad, provincia y canton.
- Escaneo de barcode o QR con soporte para crear productos si no existen.
- Encolado y seguimiento de jobs para exportar productos.

## Estructura principal

```text
lib/
  components/    Widgets reutilizables de apoyo visual
  models/        Modelos del dominio usados en la UI
  services/      Clientes HTTP, config y helpers
  viewmodels/    Estado y coordinacion entre UI y servicios
  views/         Pantallas principales de la aplicacion
test/
  widget_test.dart
```

## Requisitos

- Flutter SDK 3.x
- Dart SDK compatible con `sdk: ^3.10.7`
- Un backend disponible bajo una URL base `/api`

Dependencias relevantes:

- `http`
- `google_fonts`
- `flutter_secure_storage`
- `mobile_scanner`

## Configuracion de API

La URL base se toma desde `API_BASE_URL` usando `--dart-define`.

Valores comunes:

- Web: `http://127.0.0.1:8000/api`
- Android emulator: `http://10.0.2.2:8000/api`
- Desktop local: `http://127.0.0.1:8000/api`
- Dispositivo fisico: `http://<tu-ip-local>:8000/api`

Ejemplo:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

## Instalacion

```bash
flutter pub get
```

## Ejecucion

### Web

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

### Android emulator

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

### Windows / desktop

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

## Calidad basica

Analisis estatico:

```bash
flutter analyze
```

Tests:

```bash
flutter test
```

## Requisitos del backend

El backend debe responder JSON y exponer, como minimo, estos grupos de endpoints:

- `/auth/...`
- `/stores/`
- `/categories/`
- `/products/`
- `/compare-prices/`
- `/offers/`
- `/weather/`
- `/geo/ecuador/provinces/`
- `/geo/ecuador/cantons/`
- `/products/scan/`
- `/profile/...`
- `/jobs/...`
- `/raffles/active/`

Tambien debe:

- Permitir CORS en desarrollo web.
- Exponer autenticacion basada en token Bearer.
- Responder headers de cache cuando aplique, por ejemplo `x-cache-status`.

## Flujo principal

1. El usuario entra por onboarding.
2. Inicia sesion o crea una cuenta.
3. Desde `Home` navega a categorias, comparador, ofertas, clima, escaneo y perfil.
4. Los `viewmodels` coordinan la UI y los `services`.
5. Los `services` consumen la API y traducen errores a mensajes manejables.

## Notas para desarrollo

- La app usa `flutter_secure_storage` para tokens.
- La configuracion de API vive en `lib/services/api_config.dart`.
- Los comentarios del codigo fueron ampliados para dejar documentada la intencion de cada modulo.
