// Elige automáticamente qué archivo usar según la plataforma:
// - En web (Chrome)       -> db_config_web.dart
// - En Android, iOS, etc. -> db_config_io.dart
//
// Así el código exclusivo de web NUNCA se compila para Android (y al revés),
// que es justo lo que hacía tronar la app en Android Studio.
export 'db_config_io.dart' if (dart.library.js_interop) 'db_config_web.dart';
