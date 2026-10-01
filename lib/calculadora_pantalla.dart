import 'dart:async'; // Para unawaited()
import 'package:flutter/material.dart';
import 'package:flutter_application_1/base_datos.dart';
import 'package:flutter_application_1/botones_pantalla.dart';
import 'package:flutter_application_1/historial_pantalla.dart';
import 'package:flutter_application_1/operacion.dart';

/// Pantalla principal de la calculadora.
/// Es StatefulWidget porque el display cambia cada vez que tocas un botón.
class CalculadoraPantalla extends StatefulWidget {
  const CalculadoraPantalla({super.key});

  @override
  State<CalculadoraPantalla> createState() => _CalculadoraPantallaState();
}

class _CalculadoraPantallaState extends State<CalculadoraPantalla> {
  // La operación se guarda en 3 partes:  number1  operand  number2
  // Ejemplo: "12" "+" "3"  ->  en pantalla se ve "12+3"
  String number1 = ""; // Primer número (dígitos 0-9 y punto)
  String number2 = ""; // Segundo número
  String operand = ""; // Operador: suma, resta, multiplicación o división

  // Se pone en true justo después de presionar "=" o "%".
  // Sirve para que, si tecleas un número nuevo, empiece una operación nueva
  // en lugar de pegarse al resultado (ej. resultado 8, tecleas 5 -> "5", no "85").
  bool mostrandoResultado = false;

  // Texto especial que se muestra si algo sale mal (ej. dividir entre 0)
  static const String textoError = "Error";

  // ============================================================
  //  INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Lo que se ve en el display: la operación completa, o "0" si está vacía
    final operacion = "$number1$operand$number2";
    final textoDisplay = operacion.isEmpty ? "0" : operacion;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Limita el ancho para que en tablet/web no se vea gigante
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                // ---------- BOTÓN DE HISTORIAL ----------
                // Arriba a la derecha; abre la pantalla con las operaciones guardadas
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    tooltip: "Ver historial",
                    icon: const Icon(Icons.history, color: Colors.white70, size: 30),
                    onPressed: _abrirHistorial,
                  ),
                ),

                // ---------- DISPLAY ----------
                Expanded(
                  flex: 1, // 1/3 de la altura para el display
                  child: Container(
                    alignment: Alignment.bottomRight,
                    padding: const EdgeInsets.all(16),
                    // FittedBox encoge el texto si el número es muy largo,
                    // así nunca se desborda de la pantalla
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomRight,
                      child: Text(
                        textoDisplay,
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 231, 227, 227),
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),

                // ---------- TECLADO ----------
                Expanded(
                  flex: 2, // 2/3 de la altura para los botones
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    physics: const NeverScrollableScrollPhysics(), // El teclado no hace scroll
                    itemCount: Btn.buttonValues.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // 4 columnas
                      crossAxisSpacing: 8, // Espacio horizontal entre botones
                      mainAxisSpacing: 8, // Espacio vertical entre botones
                      childAspectRatio: 1.1, // Botones un poco más anchos que altos
                    ),
                    itemBuilder: (context, index) {
                      return buildButton(Btn.buttonValues[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye un botón del teclado con el texto [e].
  Widget buildButton(String e) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        color: _colorBoton(e),
        // Clip.hardEdge recorta el efecto de "ripple" del InkWell
        // para que no se salga de la forma redondeada del botón
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: const BorderSide(color: Color.fromARGB(128, 120, 96, 96)),
        ),
        child: InkWell(
          onTap: () => onBtnTap(e),
          child: Center(
            child: Text(
              e,
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Decide el color de cada botón según su tipo.
  Color _colorBoton(String e) {
    // Botones de borrar / limpiar
    if ([Btn.del, Btn.clr].contains(e)) return Colors.blueGrey;

    // Operadores, porcentaje e igual
    if ([
      Btn.multiplo,
      Btn.per,
      Btn.add,
      Btn.dividir,
      Btn.restar,
      Btn.resultado,
    ].contains(e)) {
      return Colors.orange;
    }

    // Números y punto
    return Colors.black12;
  }

  // ============================================================
  //  LÓGICA
  // ============================================================

  /// Punto de entrada: se ejecuta cada vez que tocas un botón.
  /// Revisa qué botón fue y manda llamar la función correspondiente.
  void onBtnTap(String valor) {
    setState(() {
      // Si en pantalla hay "Error", cualquier botón limpia primero
      if (number1 == textoError) _limpiarTodo();

      if (valor == Btn.del) {
        _borrarUltimo();
      } else if (valor == Btn.clr) {
        _limpiarTodo();
      } else if (valor == Btn.per) {
        _convertirAPorcentaje();
      } else if (valor == Btn.resultado) {
        _calcular();
      } else if (valor == Btn.punto || int.tryParse(valor) != null) {
        _agregarDigito(valor); // Es un número (0-9) o el punto
      } else {
        _elegirOperador(valor); // Lo que queda son los operadores (+ - × ÷)
      }
    });
  }

  /// Agrega un dígito o el punto al número que se está escribiendo.
  void _agregarDigito(String valor) {
    // Si acabas de ver un resultado y tecleas un número, empieza de cero
    if (mostrandoResultado) _limpiarTodo();

    // Sin operador todavía -> escribimos en number1; si ya hay, en number2
    if (operand.isEmpty) {
      number1 = _agregarA(number1, valor);
    } else {
      number2 = _agregarA(number2, valor);
    }
  }

  /// Regresa [numero] con [valor] agregado al final, respetando las reglas:
  /// - Solo un punto por número.
  /// - Si empiezas con punto, se convierte en "0." (se ve mejor que ".").
  /// - No permite ceros a la izquierda ("0" + "5" -> "5").
  String _agregarA(String numero, String valor) {
    if (valor == Btn.punto) {
      if (numero.contains(Btn.punto)) return numero; // Ya tiene punto, se ignora
      if (numero.isEmpty) return "0$valor"; // "." -> "0."
      return numero + valor;
    }

    if (numero == "0") return valor; // Reemplaza el cero inicial
    return numero + valor;
  }

  /// Guarda el operador elegido (+ - × ÷).
  void _elegirOperador(String op) {
    // No se puede empezar una operación con un operador
    if (number1.isEmpty) return;

    // Si ya hay operación completa (ej. "2+3") y presionas otro operador,
    // primero se resuelve: "2+3" + "×"  ->  "5×"
    if (number2.isNotEmpty) {
      _calcular();
      if (number1 == textoError) return; // Si falló (ej. ÷0), no seguimos
    }

    // Si ya había operador y number2 está vacío, simplemente se reemplaza
    // (útil si te equivocaste de operador)
    operand = op;
    mostrandoResultado = false;
  }

  /// Resuelve la operación "number1 operand number2" y deja el resultado en number1.
  void _calcular() {
    // Si falta alguna parte, no hay nada que calcular
    if (number1.isEmpty || operand.isEmpty || number2.isEmpty) return;

    final a = double.tryParse(number1);
    final b = double.tryParse(number2);
    if (a == null || b == null) return;

    double resultado;
    if (operand == Btn.add) {
      resultado = a + b;
    } else if (operand == Btn.restar) {
      resultado = a - b;
    } else if (operand == Btn.multiplo) {
      resultado = a * b;
    } else if (operand == Btn.dividir) {
      if (b == 0) {
        _mostrarError(); // Dividir entre cero no está definido
        return;
      }
      resultado = a / b;
    } else {
      return; // Operador desconocido, no hacemos nada
    }

    // Guardamos cómo se veía la operación ANTES de sobrescribir number1
    final expresion = "$number1$operand$number2";

    // El resultado se vuelve el nuevo number1 para poder seguir operando con él
    number1 = _formatear(resultado);
    operand = "";
    number2 = "";
    mostrandoResultado = true;

    // Guarda la operación en la base de datos.
    // unawaited = "lánzalo y no esperes": la calculadora no se congela mientras se guarda
    unawaited(_guardarOperacion(expresion, number1));
  }

  /// Convierte el número actual a porcentaje (lo divide entre 100).
  void _convertirAPorcentaje() {
    // Si hay operación completa, primero la resolvemos
    if (number1.isNotEmpty && operand.isNotEmpty && number2.isNotEmpty) {
      _calcular();
      if (number1 == textoError) return;
    }

    // Si hay operador pero falta number2 (ej. "50+"), no hay qué convertir
    if (operand.isNotEmpty) return;

    final numero = double.tryParse(number1);
    if (numero == null) return;

    number1 = _formatear(numero / 100);
    mostrandoResultado = true;
  }

  /// Borra el último carácter (botón DEL).
  /// El orden importa: primero number2, luego el operador, luego number1.
  void _borrarUltimo() {
    if (number2.isNotEmpty) {
      number2 = number2.substring(0, number2.length - 1);
    } else if (operand.isNotEmpty) {
      operand = "";
    } else if (number1.isNotEmpty) {
      number1 = number1.substring(0, number1.length - 1);
      // Si de un negativo como "-5" solo queda "-", lo limpiamos
      if (number1 == "-") number1 = "";
    }
    mostrandoResultado = false;
  }

  /// Limpia todo (botón C).
  void _limpiarTodo() {
    number1 = "";
    number2 = "";
    operand = "";
    mostrandoResultado = false;
  }

  /// Muestra "Error" en el display. El siguiente botón que toques lo limpia.
  void _mostrarError() {
    number1 = textoError;
    operand = "";
    number2 = "";
    mostrandoResultado = false;
  }

  // ============================================================
  //  HISTORIAL / BASE DE DATOS
  // ============================================================

  /// Guarda una operación en SQLite. Si falla, solo lo imprime en consola
  /// para no romper la calculadora.
  Future<void> _guardarOperacion(String expresion, String resultado) async {
    if (resultado == textoError) return; // No guardamos operaciones con error
    try {
      await BaseDatos.instancia.insertarOperacion(
        Operacion(
          expresion: expresion,
          resultado: resultado,
          fecha: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint("Error al guardar la operación: $e");
    }
  }

  /// Navega a la pantalla del historial.
  /// Navigator.push "apila" la nueva pantalla encima de la calculadora;
  /// la flecha de regresar del AppBar hace el pop automáticamente.
  void _abrirHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistorialPantalla()),
    );
  }

  /// Convierte un double a texto bonito para el display:
  /// - 8.0          -> "8"
  /// - 0.1 + 0.2    -> "0.3" (y no "0.30000000000000004")
  /// - 5.500        -> "5.5"
  String _formatear(double valor) {
    if (valor.isNaN || valor.isInfinite) return textoError;

    // Redondea a 10 decimales para quitar el "ruido" de los doubles
    var texto = valor.toStringAsFixed(10);

    // Quita los ceros sobrantes al final y el punto si quedó solito
    texto = texto.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

    if (texto == "-0") texto = "0"; // Evita mostrar "-0"
    return texto;
  }
}
