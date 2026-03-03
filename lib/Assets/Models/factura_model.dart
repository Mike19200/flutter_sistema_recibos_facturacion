import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter_facturacion_sistema/Assets/Models/seleccion_empresa.dart';

class Factura {
  final String numero;
  final String ciudad;
  final String fecha;
  final String nombre;
  final String concepto;
  final String valor;
  final String valorTexto;
  final Uint8List? firma;
  final SeleccionEmpresa empresa;

  Factura({
    required this.numero,
    required this.ciudad,
    required this.fecha,
    required this.nombre,
    required this.concepto,
    required this.valor,
    required this.valorTexto,
    this.firma,
    required this.empresa,
  });

  // ===== SERIALIZAR =====
  Map<String, dynamic> toJson() => {
        'numero': numero,
        'ciudad': ciudad,
        'fecha': fecha,
        'nombre': nombre,
        'concepto': concepto,
        'valor': valor,
        'valorTexto': valorTexto,
        'firma': firma != null ? base64Encode(firma!) : null,
        'empresa': empresa.name, // ✅ CLAVE
      };

  // ===== DESERIALIZAR =====
  factory Factura.fromJson(Map<String, dynamic> json) => Factura(
        numero: json['numero'],
        ciudad: json['ciudad'],
        fecha: json['fecha'],
        nombre: json['nombre'],
        concepto: json['concepto'],
        valor: json['valor'],
        valorTexto: json['valorTexto'],
        firma: json['firma'] != null ? base64Decode(json['firma']) : null,
        empresa: SeleccionEmpresa.values.firstWhere(
          (e) => e.name == json['empresa'],
          orElse: () => SeleccionEmpresa.Kaleyman, // fallback seguro
        ),
      );
}
