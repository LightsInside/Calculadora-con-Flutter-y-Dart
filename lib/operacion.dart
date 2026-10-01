/// Modelo que representa UNA operación guardada en la base de datos.
/// Cada objeto Operacion = una fila de la tabla "operaciones".
class Operacion {
  final int? id; // Lo genera SQLite solito (AUTOINCREMENT), por eso puede ser null al crear
  final String expresion; // Lo que se tecleó, ej. "12+3"
  final String resultado; // El resultado, ej. "15"
  final DateTime fecha; // Cuándo se hizo la operación

  const Operacion({
    this.id,
    required this.expresion,
    required this.resultado,
    required this.fecha,
  });

  /// Convierte el objeto a un Map para poder guardarlo en SQLite.
  /// Las llaves del Map deben llamarse igual que las columnas de la tabla.
  Map<String, Object?> toMap() {
    return {
      // Si id es null NO lo mandamos, así SQLite genera uno nuevo automáticamente
      if (id != null) 'id': id,
      'expresion': expresion,
      'resultado': resultado,
      // SQLite no tiene tipo fecha, así que la guardamos como texto ISO 8601
      // (ej. "2026-09-29T10:26:00.000"), que se puede ordenar y convertir de vuelta
      'fecha': fecha.toIso8601String(),
    };
  }

  /// Crea un objeto Operacion a partir de una fila leída de SQLite.
  factory Operacion.fromMap(Map<String, Object?> mapa) {
    return Operacion(
      id: mapa['id'] as int,
      expresion: mapa['expresion'] as String,
      resultado: mapa['resultado'] as String,
      fecha: DateTime.parse(mapa['fecha'] as String),
    );
  }
}
