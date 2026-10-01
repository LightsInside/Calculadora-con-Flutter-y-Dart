import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_application_1/operacion.dart';

/// Maneja toda la comunicación con la base de datos SQLite.
///
/// Usa el patrón Singleton: solo existe UNA instancia en toda la app
/// (BaseDatos.instancia), así no se abre la base de datos varias veces.
class BaseDatos {
  // Constructor privado: nadie de afuera puede hacer BaseDatos()
  BaseDatos.bd();

  // La única instancia que usará toda la app
  static final BaseDatos instancia = BaseDatos.bd();

  static const String _nombreArchivo = 'calculadora.db';
  static const int _version = 1; // Súbela si algún día cambias la estructura de la tabla
  static const String tablaOperaciones = 'operaciones';

  // Guardamos el Future (no la Database) para que, si dos partes de la app
  // piden la base de datos al mismo tiempo, se abra solo una vez
  Future<Database>? _dbFuture;

  /// Regresa la base de datos, abriéndola la primera vez que se pide.
  Future<Database> get database => _dbFuture ??= _abrir();

  /// Abre (o crea, si no existe) el archivo de la base de datos.
  Future<Database> _abrir() async {
    // getDatabasesPath() da la carpeta correcta según el sistema (Android, iOS, etc.)
    final ruta = join(await getDatabasesPath(), _nombreArchivo);

    return openDatabase(
      ruta,
      version: _version,
      onCreate: _crearTablas, // Solo se ejecuta la PRIMERA vez que se crea el archivo
    );
  }

  /// Crea la tabla y mete unos datos de ejemplo.
  Future<void> _crearTablas(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablaOperaciones (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        expresion  TEXT    NOT NULL,
        resultado  TEXT    NOT NULL,
        fecha      TEXT    NOT NULL
      )
    ''');

    // ---- DATOS DE EJEMPLO (opcional) ----
    // Sirven para que el historial no salga vacío la primera vez.
    // Si no los quieres, borra este bloque y desinstala/reinstala la app
    // (onCreate solo corre cuando el archivo .db no existe).
    final ahora = DateTime.now();
    final ejemplos = [
      Operacion(expresion: '2+2', resultado: '4', fecha: ahora.subtract(const Duration(minutes: 30))),
      Operacion(expresion: '10÷4', resultado: '2.5', fecha: ahora.subtract(const Duration(minutes: 20))),
      Operacion(expresion: '7×6', resultado: '42', fecha: ahora.subtract(const Duration(minutes: 10))),
    ];

    // Un batch mete todas las filas en una sola transacción (más rápido y seguro)
    final batch = db.batch();
    for (final op in ejemplos) {
      batch.insert(tablaOperaciones, op.toMap());
    }
    await batch.commit(noResult: true);
  }

  // ============================================================
  //  CRUD (Create, Read, Update, Delete)
  // ============================================================

  /// Guarda una operación nueva. Regresa el id que le asignó SQLite.
  Future<int> insertarOperacion(Operacion operacion) async {
    final db = await database;
    return db.insert(tablaOperaciones, operacion.toMap());
  }

  /// Regresa todas las operaciones, de la más reciente a la más vieja.
  Future<List<Operacion>> obtenerOperaciones() async {
    final db = await database;
    final filas = await db.query(tablaOperaciones, orderBy: 'id DESC');
    // Convierte cada fila (Map) en un objeto Operacion
    return filas.map(Operacion.fromMap).toList();
  }

  /// Borra una operación por su id.
  Future<int> eliminarOperacion(int id) async {
    final db = await database;
    // Los "?" + whereArgs evitan inyección SQL: nunca metas valores directo en el string
    return db.delete(tablaOperaciones, where: 'id = ?', whereArgs: [id]);
  }

  /// Borra TODO el historial.
  Future<int> eliminarTodas() async {
    final db = await database;
    return db.delete(tablaOperaciones);
  }
}
