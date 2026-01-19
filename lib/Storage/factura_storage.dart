import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Assets/Models/factura_model.dart';

class FacturaStorage {
  // Claves separadas por tipo
  static const String _keyFacturas = 'facturas';
  static const String _keyRecibosIngreso = 'recibos_ingreso';
  static const String _keyRecibosEgreso = 'recibos_egreso';

  // =================== GUARDAR ===================
  static Future<void> guardarArchivo(Factura factura, String tipo) async {
    final prefs = await SharedPreferences.getInstance();
    String key = _getKey(tipo);
    final List<String> lista = prefs.getStringList(key) ?? [];

    lista.add(jsonEncode(factura.toJson()));
    await prefs.setStringList(key, lista);
  }

  // =================== OBTENER ===================
  static Future<List<Factura>> obtenerArchivos(String tipo) async {
    final prefs = await SharedPreferences.getInstance();
    String key = _getKey(tipo);
    final List<String> lista = prefs.getStringList(key) ?? [];

    return lista.map((e) => Factura.fromJson(jsonDecode(e))).toList();
  }

  static Future<List<Factura>> obtenerFacturas() async {
    return obtenerArchivos('Factura');
  }

  static Future<List<Factura>> obtenerRecibosIngreso() async {
    return obtenerArchivos('Ingreso');
  }

  static Future<List<Factura>> obtenerRecibosEgreso() async {
    return obtenerArchivos('Egreso');
  }

  // =================== BORRAR ===================
  static Future<void> borrarArchivo(String numero, String tipo) async {
    final prefs = await SharedPreferences.getInstance();
    String key = _getKey(tipo);
    final List<String> lista = prefs.getStringList(key) ?? [];

    final List<String> listaActualizada = lista.where((f) {
      final factura = Factura.fromJson(jsonDecode(f));
      return factura.numero != numero;
    }).toList();

    await prefs.setStringList(key, listaActualizada);
  }

  // =================== HELPER ===================
  static String _getKey(String tipo) {
    switch (tipo) {
      case 'Ingreso':
        return _keyRecibosIngreso;
      case 'Egreso':
        return _keyRecibosEgreso;
      case 'Factura':
      default:
        return _keyFacturas;
    }
  }
}
