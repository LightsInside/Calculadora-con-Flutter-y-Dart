import 'package:flutter/material.dart';
import 'package:flutter_application_1/base_datos.dart';
import 'package:flutter_application_1/operacion.dart';

/// Pantalla que muestra todas las operaciones guardadas en la base de datos.
class HistorialPantalla extends StatefulWidget {
  const HistorialPantalla({super.key});

  @override
  State<HistorialPantalla> createState() => _HistorialPantallaState();
}

class _HistorialPantallaState extends State<HistorialPantalla> {
  List<Operacion> _operaciones = []; // Lo que se muestra en la lista
  bool _cargando = true; // true mientras se leen los datos
  String? _error; // Mensaje de error si algo falla al leer

  @override
  void initState() {
    super.initState();
    _cargarOperaciones(); // Lee la base de datos en cuanto se abre la pantalla
  }

  /// Lee todas las operaciones de la base de datos.
  Future<void> _cargarOperaciones() async {
    try {
      final datos = await BaseDatos.instancia.obtenerOperaciones();
      if (!mounted) return; // Si el usuario ya salió de la pantalla, no hacemos nada
      setState(() {
        _operaciones = datos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el historial:\n$e';
        _cargando = false;
      });
    }
  }

  /// Borra una operación (se llama al deslizarla hacia la izquierda).
  Future<void> _eliminar(Operacion op) async {
    // Primero la quitamos de la lista en pantalla (Dismissible lo exige así)
    setState(() => _operaciones.removeWhere((o) => o.id == op.id));
    // Luego la borramos de la base de datos
    await BaseDatos.instancia.eliminarOperacion(op.id!);
  }

  /// Pide confirmación y borra todo el historial.
  Future<void> _eliminarTodas() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar todo el historial?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return; // Canceló o cerró el diálogo

    await BaseDatos.instancia.eliminarTodas();
    if (!mounted) return;
    setState(() => _operaciones = []);
  }

  /// Convierte la fecha a texto tipo "29/09/2026 10:26" sin usar paquetes extra.
  String _formatearFecha(DateTime f) {
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    return '${dosDigitos(f.day)}/${dosDigitos(f.month)}/${f.year} '
        '${dosDigitos(f.hour)}:${dosDigitos(f.minute)}';
  }

  // ============================================================
  //  INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white, // Color del título y de la flecha de regresar
        actions: [
          // El botón de borrar todo solo aparece si hay algo que borrar
          if (_operaciones.isNotEmpty)
            IconButton(
              tooltip: 'Borrar todo',
              icon: const Icon(Icons.delete_sweep),
              onPressed: _eliminarTodas,
            ),
        ],
      ),
      body: _construirCuerpo(),
    );
  }

  /// Decide qué mostrar: cargando, error, lista vacía o la lista.
  Widget _construirCuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    if (_operaciones.isEmpty) {
      return const Center(
        child: Text(
          'Aún no hay operaciones 🙃',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _operaciones.length,
      separatorBuilder: (_, _) => const Divider(color: Colors.white12),
      itemBuilder: (context, index) {
        final op = _operaciones[index];

        // Dismissible permite borrar la operación deslizándola a la izquierda
        return Dismissible(
          key: ValueKey(op.id), // Cada elemento necesita una llave única
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _eliminar(op),
          child: ListTile(
            title: Text(
              op.expresion,
              style: const TextStyle(color: Colors.white70, fontSize: 20),
            ),
            subtitle: Text(
              _formatearFecha(op.fecha),
              style: const TextStyle(color: Colors.white38),
            ),
            trailing: Text(
              '= ${op.resultado}',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
