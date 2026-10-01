import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
/// Versión para web (Chrome).
///
/// En el navegador, SQLite corre como WebAssembly. Hay que decirle a sqflite
/// que use ese "motor" ANTES de abrir la base de datos.
/// Los datos se guardan dentro del navegador (IndexedDB).
void configurarBaseDatos() {
  databaseFactory = databaseFactoryFfiWeb;
}
